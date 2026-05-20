import AVFoundation
import Combine
import UIKit

/// Configures AVAudioSession for background audio operation and manages
/// the complete audio + network lifecycle.
@MainActor
final class BackgroundAudioManager: ObservableObject {
    @Published var isActive = false
    @Published var isTransmitting = false
    @Published var isMuted = false
    @Published var voxEnabled = false
    @Published var inputLevel: Float = 0.0
    @Published var isConnected = false
    @Published var peerCount: Int = 0
    @Published var channel: String = "alpha"
    @Published var hostAddress: String = "10.0.200.221"
    @Published var statusMessage: String = "Ready"
    @Published var peers: [String] = []

    let audioEngine = AudioEngine()
    let voxDetector = VoxDetector()
    let bridgeClient = MeshBridgeClient()

    private var cancellables = Set<AnyCancellable>()
    private var pttActive = false

    init() {
        // Load persisted settings from UserDefaults (@AppStorage compatible)
        let defaults = UserDefaults.standard
        if let savedHost = defaults.string(forKey: "meshtalk_host"), !savedHost.isEmpty {
            hostAddress = savedHost
        }
        if let savedChannel = defaults.string(forKey: "meshtalk_channel"), !savedChannel.isEmpty {
            channel = savedChannel
        }
    }

    func setup() {
        configureAudioSession()

        // Bind bridge client state
        bridgeClient.$isConnected
            .assign(to: &$isConnected)
        bridgeClient.$peerCount
            .assign(to: &$peerCount)

        // Proxy peer names from bridge client
        bridgeClient.$peers
            .map { $0.map(\.user) }
            .assign(to: &$peers)

        // Bind audio engine level
        audioEngine.$inputLevel
            .assign(to: &$inputLevel)

        // VOX detection → transmit state
        voxDetector.$isVoiceDetected
            .sink { [weak self] detected in
                guard let self = self, self.voxEnabled, !self.pttActive else { return }
                self.isTransmitting = detected
            }
            .store(in: &cancellables)

        // Feed input level to VOX detector
        audioEngine.$inputLevel
            .sink { [weak self] level in
                guard let self = self, self.voxEnabled else { return }
                self.voxDetector.update(level: level)
            }
            .store(in: &cancellables)

        // Re-activate audio session when app becomes active
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.configureAudioSession()
                if self.isActive {
                    print("[Audio] Re-activated audio session after becoming active")
                }
            }
        }
    }

    func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [
                .defaultToSpeaker,
                .allowBluetooth,
                .allowBluetoothA2DP,
                .mixWithOthers
            ])
            try session.setPreferredSampleRate(16000)
            try session.setPreferredIOBufferDuration(0.02) // 20ms
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            // Register for interruption notifications
            NotificationCenter.default.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleInterruption(notification)
            }

            NotificationCenter.default.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { notification in
                print("[Audio] Route changed: \(notification)")
            }
        } catch {
            print("[Audio] Session config error: \(error)")
            statusMessage = "Audio error: \(error.localizedDescription)"
        }
    }

    func startSession() {
        guard !isActive else { return }

        statusMessage = "Connecting..."

        bridgeClient.updateHost(hostAddress)
        bridgeClient.channel = channel

        // Connect bridge, providing audio playback callback
        bridgeClient.connect { [weak self] data in
            Task { @MainActor in
                guard let self = self, !self.isMuted else { return }
                self.audioEngine.playAudio(data: data)
            }
        }

        // Start audio engine (defensive stop first to avoid double-start)
        do {
            audioEngine.stop()
            try audioEngine.start { [weak self] pcmData in
                Task { @MainActor in
                    guard let self = self, self.isTransmitting else { return }
                    self.bridgeClient.sendAudio(pcmData)
                }
            }
        } catch {
            print("[Audio] Engine start error: \(error)")
            statusMessage = "Engine error: \(error.localizedDescription)"
            return
        }

        isActive = true
        statusMessage = "Connected to \(hostAddress)"
    }

    func stopSession() {
        audioEngine.stop()
        bridgeClient.disconnect()
        isActive = false
        isTransmitting = false
        statusMessage = "Disconnected"
    }

    func startPTT() {
        pttActive = true
        isTransmitting = true
    }

    func stopPTT() {
        pttActive = false
        if !voxEnabled {
            isTransmitting = false
        }
    }

    func switchChannel(_ newChannel: String) {
        channel = newChannel
        if isActive {
            statusMessage = "Switching to \(newChannel)..."
            bridgeClient.switchChannel(newChannel)
            statusMessage = "Connected — \(newChannel)"
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            print("[Audio] Interruption began")
            statusMessage = "Audio interrupted"
        case .ended:
            print("[Audio] Interruption ended")
            configureAudioSession()
            if isActive {
                statusMessage = "Resuming..."
                try? audioEngine.start { [weak self] pcmData in
                    Task { @MainActor in
                        guard let self = self, self.isTransmitting else { return }
                        self.bridgeClient.sendAudio(pcmData)
                    }
                }
                statusMessage = "Connected to \(hostAddress)"
            }
        @unknown default:
            break
        }
    }
}

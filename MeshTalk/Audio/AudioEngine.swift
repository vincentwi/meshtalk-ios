import AVFoundation
import Combine

/// Manages AVAudioEngine for capture and playback of PCM16 audio at 16kHz mono.
@MainActor
final class AudioEngine: ObservableObject {
    @Published var inputLevel: Float = 0.0
    @Published var isCapturing = false

    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private let captureFormat: AVAudioFormat
    private let playbackFormat: AVAudioFormat
    private var onCapturedAudio: (@Sendable (Data) -> Void)?

    // playback queue for thread-safe buffer scheduling
    private let playbackQueue = DispatchQueue(label: "com.openclaw.meshtalk.playback")
    // Shared reference for nonisolated playback access
    nonisolated(unsafe) private var _playerNodeRef: AVAudioPlayerNode?

    init() {
        // 16kHz, mono, Int16
        captureFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)!
        playbackFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
    }

    func start(onAudio: @escaping @Sendable (Data) -> Void) throws {
        onCapturedAudio = onAudio

        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: playbackFormat)

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Install tap - convert to 16kHz mono PCM16
        let desiredFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!

        // We need a converter if hardware format differs
        let converter = AVAudioConverter(from: inputFormat, to: desiredFormat)

        inputNode.installTap(onBus: 0, bufferSize: 1600, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            let frameCount = AVAudioFrameCount(1600)
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: desiredFormat, frameCapacity: frameCount) else { return }

            if let converter = converter {
                var error: NSError?
                var isDone = false
                converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                    if isDone {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                    isDone = true
                    outStatus.pointee = .haveData
                    return buffer
                }
                if error != nil { return }
            } else {
                // formats match
                convertedBuffer.frameLength = min(buffer.frameLength, frameCount)
                if let src = buffer.floatChannelData?[0], let dst = convertedBuffer.floatChannelData?[0] {
                    memcpy(dst, src, Int(convertedBuffer.frameLength) * MemoryLayout<Float>.size)
                }
            }

            // Calculate RMS for VU meter
            let rms = self.calculateRMS(buffer: convertedBuffer)
            Task { @MainActor in
                self.inputLevel = rms
            }

            // Convert float32 to PCM16 data
            let pcm16Data = self.floatToPCM16(buffer: convertedBuffer)
            self.onCapturedAudio?(pcm16Data)
        }

        engine.prepare()
        try engine.start()
        playerNode.play()

        self.engine = engine
        self.playerNode = playerNode
        self._playerNodeRef = playerNode
        isCapturing = true
    }

    func stop() {
        engine?.inputNode.removeTap(onBus: 0)
        playerNode?.stop()
        engine?.stop()
        engine = nil
        playerNode = nil
        _playerNodeRef = nil
        isCapturing = false
        inputLevel = 0
    }

    /// Schedule PCM16 data for playback
    nonisolated func playAudio(data: Data) {
        playbackQueue.async { [weak self] in
            guard let self = self,
                  let playerNode = self._playerNodeRef else { return }

            let frameCount = AVAudioFrameCount(data.count / 2) // 2 bytes per sample
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: self.playbackFormat,
                frameCapacity: frameCount
            ) else { return }
            buffer.frameLength = frameCount

            // Convert PCM16 to Float32
            data.withUnsafeBytes { rawBuffer in
                guard let src = rawBuffer.bindMemory(to: Int16.self).baseAddress,
                      let dst = buffer.floatChannelData?[0] else { return }
                for i in 0..<Int(frameCount) {
                    dst[i] = Float(src[i]) / 32768.0
                }
            }

            playerNode.scheduleBuffer(buffer, completionHandler: nil)
        }
    }

    private nonisolated func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        return sqrt(sum / Float(frameLength))
    }

    private nonisolated func floatToPCM16(buffer: AVAudioPCMBuffer) -> Data {
        guard let channelData = buffer.floatChannelData?[0] else { return Data() }
        let frameLength = Int(buffer.frameLength)
        var pcm16 = Data(count: frameLength * 2)

        pcm16.withUnsafeMutableBytes { rawBuffer in
            guard let dst = rawBuffer.bindMemory(to: Int16.self).baseAddress else { return }
            for i in 0..<frameLength {
                let clamped = max(-1.0, min(1.0, channelData[i]))
                dst[i] = Int16(clamped * 32767.0)
            }
        }
        return pcm16
    }
}

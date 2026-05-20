import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var manager: BackgroundAudioManager
    @State private var showSettings = false
    @State private var micPermissionGranted = false

    var body: some View {
        ZStack {
            // Warm cream background — Pi-inspired
            MeshColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Header
                headerView
                    .padding(.horizontal, MeshSpacing.screenH)
                    .padding(.top, 8)

                // MARK: - Peer strip
                PeerIndicatorView(peerNames: manager.peers)
                    .padding(.top, 12)
                    .padding(.horizontal, MeshSpacing.screenH)

                Spacer()

                // MARK: - Waveform
                WaveformView(
                    level: $manager.inputLevel,
                    isActive: manager.isActive,
                    isTransmitting: manager.isTransmitting
                )
                .frame(height: 100)
                .padding(.horizontal, MeshSpacing.screenH)
                .padding(.bottom, 24)

                // MARK: - PTT Button
                PTTButtonView(
                    isTransmitting: $manager.isTransmitting,
                    onPTTStart: {
                        if !manager.isActive {
                            manager.startSession()
                        }
                        manager.startPTT()
                        HapticManager.shared.pttStart()
                    },
                    onPTTEnd: {
                        manager.stopPTT()
                        HapticManager.shared.pttEnd()
                    }
                )
                .padding(.bottom, 12)

                // MARK: - Connection status text
                connectionStatusText
                    .padding(.bottom, 16)

                Spacer()

                // MARK: - Bottom area: organic waves behind control bar
                ZStack(alignment: .bottom) {
                    OrganicWaveView()
                        .frame(height: 160)
                        .allowsHitTesting(false)

                    ControlBarView(
                        voxEnabled: $manager.voxEnabled,
                        isMuted: $manager.isMuted,
                        onCloseTap: {
                            manager.stopSession()
                        }
                    )
                    .padding(.horizontal, MeshSpacing.screenH)
                    .padding(.bottom, 8)
                }
            }
        }
        .onAppear {
            requestMicPermission()
            manager.setup()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(manager)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 10) {
            // Green connection dot
            Circle()
                .fill(manager.isConnected ? MeshColors.accent : MeshColors.error)
                .frame(width: 10, height: 10)

            Text("MeshTalk")
                .font(MeshFonts.title)
                .foregroundColor(MeshColors.primaryText)

            Spacer()

            // Channel badge (dropdown menu)
            channelBadge

            // Settings gear
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(MeshColors.secondaryText)
            }
        }
    }

    // MARK: - Channel Badge

    private var channelBadge: some View {
        Menu {
            ForEach(MeshConfig.availableChannels, id: \.self) { ch in
                Button(action: { manager.switchChannel(ch) }) {
                    HStack {
                        Text(ch.uppercased())
                        if ch == manager.channel {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 12))
                Text(manager.channel.uppercased())
                    .font(MeshFonts.caption)
            }
            .foregroundColor(MeshColors.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(MeshColors.accentLight)
            )
        }
    }

    // MARK: - Connection Status Text

    private var connectionStatusText: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(manager.isConnected ? MeshColors.accent : MeshColors.error)
                .frame(width: 6, height: 6)

            Text(statusMessage)
                .font(MeshFonts.caption)
                .foregroundColor(MeshColors.secondaryText)
        }
    }

    private var statusMessage: String {
        if manager.isTransmitting {
            return "Transmitting..."
        } else if manager.isConnected {
            return "Connected · \(manager.peerCount) peer\(manager.peerCount == 1 ? "" : "s")"
        } else if manager.isActive {
            return "Connecting..."
        } else {
            return "Tap PTT to start"
        }
    }

    // MARK: - Permissions

    private func requestMicPermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                Task { @MainActor in
                    micPermissionGranted = granted
                    if !granted {
                        print("[Audio] Microphone permission denied")
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task { @MainActor in
                    micPermissionGranted = granted
                    if !granted {
                        print("[Audio] Microphone permission denied")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BackgroundAudioManager())
}

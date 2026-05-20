import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var audioManager: BackgroundAudioManager
    @Environment(\.dismiss) private var dismiss

    @State private var hostAddress: String = ""
    @State private var selectedChannel: String = "alpha"
    @State private var voxThreshold: Float = 0.02
    @State private var hangTime: Double = 1.5
    @State private var isMuted: Bool = false

    var body: some View {
        NavigationView {
            Form {
                serverSection
                audioSection
                channelSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(MeshColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        applySettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(MeshColors.accent)
                }
            }
            .tint(MeshColors.accent)
            .onAppear(perform: loadCurrentSettings)
        }
    }

    // MARK: - Sections

    private var serverSection: some View {
        Section {
            HStack {
                Image(systemName: "server.rack")
                    .foregroundColor(MeshColors.accent)
                    .frame(width: 24)
                TextField("Host address", text: $hostAddress)
                    .font(MeshFonts.mono)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
            }
        } header: {
            Text("Server")
                .foregroundColor(MeshColors.secondaryText)
        }
    }

    private var audioSection: some View {
        Section {
            VStack(alignment: .leading, spacing: MeshSpacing.xs) {
                HStack {
                    Text("VOX Threshold")
                        .font(MeshFonts.body)
                    Spacer()
                    Text(String(format: "%.3f", voxThreshold))
                        .font(MeshFonts.mono)
                        .foregroundColor(MeshColors.secondaryText)
                }
                Slider(value: $voxThreshold, in: 0.005...0.1, step: 0.005)
            }

            VStack(alignment: .leading, spacing: MeshSpacing.xs) {
                HStack {
                    Text("Hang Time")
                        .font(MeshFonts.body)
                    Spacer()
                    Text(String(format: "%.1fs", hangTime))
                        .font(MeshFonts.mono)
                        .foregroundColor(MeshColors.secondaryText)
                }
                Slider(value: $hangTime, in: 0.5...5.0, step: 0.5)
            }

            Toggle(isOn: $isMuted) {
                HStack {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(isMuted ? MeshColors.error : MeshColors.accent)
                        .frame(width: 24)
                    Text("Mute Output")
                }
            }
        } header: {
            Text("Audio")
                .foregroundColor(MeshColors.secondaryText)
        }
    }

    private var channelSection: some View {
        Section {
            Picker("Channel", selection: $selectedChannel) {
                ForEach(MeshConfig.availableChannels, id: \.self) { channel in
                    Text(channel.capitalized).tag(channel)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Channel")
                .foregroundColor(MeshColors.secondaryText)
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Bundle ID")
                Spacer()
                Text(Bundle.main.bundleIdentifier ?? "com.openclaw.meshtalk")
                    .font(MeshFonts.mono)
                    .foregroundColor(MeshColors.secondaryText)
            }

            HStack {
                Text("Audio Format")
                Spacer()
                Text("Opus 24kHz mono")
                    .font(MeshFonts.mono)
                    .foregroundColor(MeshColors.secondaryText)
            }

            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .font(MeshFonts.mono)
                    .foregroundColor(MeshColors.secondaryText)
            }
        } header: {
            Text("About")
                .foregroundColor(MeshColors.secondaryText)
        }
    }

    // MARK: - Actions

    private func loadCurrentSettings() {
        hostAddress = audioManager.hostAddress
        selectedChannel = audioManager.channel
        voxThreshold = audioManager.voxDetector.threshold
        hangTime = audioManager.voxDetector.hangTime
        isMuted = audioManager.isMuted
    }

    private func applySettings() {
        audioManager.hostAddress = hostAddress
        audioManager.voxDetector.threshold = voxThreshold
        audioManager.voxDetector.hangTime = hangTime
        audioManager.isMuted = isMuted
        if selectedChannel != audioManager.channel {
            audioManager.switchChannel(selectedChannel)
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif

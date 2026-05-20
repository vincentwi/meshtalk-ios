import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var audioManager: BackgroundAudioManager
    @AppStorage("meshtalk_onboarded") private var isOnboarded = false

    @State private var serverAddress: String = "10.0.200.221"
    @State private var selectedChannel: String = "alpha"
    @State private var userName: String = ""
    @State private var isConnecting = false

    var body: some View {
        ZStack {
            MeshColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                logoSection
                    .padding(.bottom, MeshSpacing.xxxl)

                // Form fields
                formSection
                    .padding(.horizontal, MeshSpacing.xxl)

                Spacer()

                // Connect button
                connectButton
                    .padding(.horizontal, MeshSpacing.xxl)
                    .padding(.bottom, MeshSpacing.xxxl)
            }
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: MeshSpacing.md) {
            ZStack {
                Circle()
                    .fill(MeshColors.accentLight)
                    .frame(width: 100, height: 100)

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(MeshColors.accent)
            }

            VStack(spacing: MeshSpacing.xxs) {
                Text("MeshTalk")
                    .font(MeshFonts.header)
                    .foregroundColor(MeshColors.primaryText)

                Text("Mesh Network Walkie-Talkie")
                    .font(MeshFonts.body)
                    .foregroundColor(MeshColors.secondaryText)
            }
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: MeshSpacing.md) {
            // Server address
            VStack(alignment: .leading, spacing: MeshSpacing.xxs) {
                Text("Server Address")
                    .font(MeshFonts.caption)
                    .foregroundColor(MeshColors.secondaryText)

                HStack {
                    Image(systemName: "server.rack")
                        .foregroundColor(MeshColors.accent)
                        .frame(width: 20)

                    TextField("ws://hostname:port", text: $serverAddress)
                        .font(MeshFonts.mono)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }
                .padding(MeshSpacing.sm)
                .background(MeshColors.surface)
                .cornerRadius(MeshSpacing.buttonRadius)
                .shadow(color: MeshColors.shadowColor, radius: 4, x: 0, y: 2)
            }

            // Channel selector
            VStack(alignment: .leading, spacing: MeshSpacing.xxs) {
                Text("Channel")
                    .font(MeshFonts.caption)
                    .foregroundColor(MeshColors.secondaryText)

                Picker("Channel", selection: $selectedChannel) {
                    ForEach(MeshConfig.availableChannels, id: \.self) { channel in
                        Text(channel.capitalized).tag(channel)
                    }
                }
                .pickerStyle(.segmented)
            }

            // User name
            VStack(alignment: .leading, spacing: MeshSpacing.xxs) {
                Text("Your Name")
                    .font(MeshFonts.caption)
                    .foregroundColor(MeshColors.secondaryText)

                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(MeshColors.accent)
                        .frame(width: 20)

                    TextField("Display name", text: $userName)
                        .font(MeshFonts.body)
                        .textInputAutocapitalization(.words)
                }
                .padding(MeshSpacing.sm)
                .background(MeshColors.surface)
                .cornerRadius(MeshSpacing.buttonRadius)
                .shadow(color: MeshColors.shadowColor, radius: 4, x: 0, y: 2)
            }
        }
    }

    // MARK: - Connect Button

    private var connectButton: some View {
        Button(action: connect) {
            HStack(spacing: MeshSpacing.xs) {
                if isConnecting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                }
                Text(isConnecting ? "Connecting..." : "Connect")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MeshSpacing.md)
            .background(
                canConnect
                    ? MeshColors.accent
                    : MeshColors.accent.opacity(0.4)
            )
            .cornerRadius(MeshSpacing.buttonRadius)
            .shadow(
                color: canConnect ? MeshColors.accent.opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(!canConnect || isConnecting)
        .animation(.easeInOut(duration: 0.2), value: canConnect)
    }

    // MARK: - Logic

    private var canConnect: Bool {
        !serverAddress.trimmingCharacters(in: .whitespaces).isEmpty &&
        !userName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func connect() {
        HapticManager.shared.buttonTap()
        isConnecting = true

        // Save settings
        audioManager.hostAddress = serverAddress.trimmingCharacters(in: .whitespaces)
        audioManager.switchChannel(selectedChannel)
        UserDefaults.standard.set(userName.trimmingCharacters(in: .whitespaces), forKey: "meshUserName")

        // Start session
        audioManager.setup()
        audioManager.startSession()

        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isConnecting = false
            isOnboarded = true
        }
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
#endif

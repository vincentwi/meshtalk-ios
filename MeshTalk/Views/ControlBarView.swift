import SwiftUI

struct ControlBarView: View {
    @Binding var voxEnabled: Bool
    @Binding var isMuted: Bool
    var onCaptionsTap: () -> Void = {}
    var onCloseTap: () -> Void = {}

    @State private var captionsActive = false

    var body: some View {
        HStack(spacing: MeshSpacing.xxl) {
            // VOX button
            ControlButton(
                icon: "waveform",
                label: "VOX",
                isActive: voxEnabled,
                action: { voxEnabled.toggle() }
            )

            // Mute button
            ControlButton(
                icon: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: isMuted ? "Unmute" : "Mute",
                isActive: isMuted,
                action: { isMuted.toggle() }
            )

            // Captions button
            ControlButton(
                icon: "text.quote",
                label: "Captions",
                isActive: captionsActive,
                action: {
                    captionsActive.toggle()
                    onCaptionsTap()
                }
            )

            // Close button
            ControlButton(
                icon: "xmark",
                label: "End",
                isActive: false,
                isDestructive: true,
                action: onCloseTap
            )
        }
        .padding(.horizontal, MeshSpacing.lg)
        .padding(.vertical, MeshSpacing.sm)
    }
}

private struct ControlButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    var isDestructive: Bool = false
    let action: () -> Void

    private let diameter: CGFloat = 56

    private var backgroundColor: Color {
        if isDestructive { return MeshColors.error.opacity(0.15) }
        return isActive ? MeshColors.accent : MeshColors.controlBg
    }

    private var iconColor: Color {
        if isDestructive { return MeshColors.error }
        return isActive ? .white : MeshColors.primaryText
    }

    var body: some View {
        VStack(spacing: MeshSpacing.xxs) {
            Button(action: {
                HapticManager.shared.buttonTap()
                action()
            }) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: diameter, height: diameter)
                        .shadow(
                            color: MeshColors.shadowColor,
                            radius: 4,
                            x: 0,
                            y: 2
                        )

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor)
                }
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isActive)

            Text(label)
                .font(MeshFonts.caption2)
                .foregroundColor(MeshColors.secondaryText)
        }
    }
}

#if DEBUG
struct ControlBarView_Previews: PreviewProvider {
    static var previews: some View {
        ControlBarView(
            voxEnabled: .constant(false),
            isMuted: .constant(false)
        )
        .padding()
        .background(MeshColors.background)
    }
}
#endif

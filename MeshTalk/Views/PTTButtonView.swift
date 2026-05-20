import SwiftUI

struct PTTButtonView: View {
    @Binding var isTransmitting: Bool
    var onPTTStart: () -> Void
    var onPTTEnd: () -> Void

    @State private var isPressed = false
    @State private var pulseScale: CGFloat = 1.0

    private let diameter: CGFloat = 160

    var body: some View {
        VStack(spacing: MeshSpacing.sm) {
            ZStack {
                // Outer pulse ring (visible when transmitting)
                if isTransmitting {
                    Circle()
                        .stroke(MeshColors.activeTX.opacity(0.3), lineWidth: 3)
                        .frame(width: diameter + 30, height: diameter + 30)
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - Double(pulseScale))
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: false),
                            value: pulseScale
                        )
                }

                // Glow shadow layer (when transmitting)
                if isTransmitting {
                    Circle()
                        .fill(MeshColors.activeTX.opacity(0.25))
                        .frame(width: diameter + 16, height: diameter + 16)
                        .blur(radius: 12)
                }

                // Main button circle
                Circle()
                    .fill(buttonFill)
                    .frame(width: diameter, height: diameter)
                    .shadow(
                        color: isTransmitting
                            ? MeshColors.activeTX.opacity(0.4)
                            : MeshColors.shadowColor,
                        radius: isTransmitting ? 16 : MeshColors.shadowRadius,
                        x: 0,
                        y: isTransmitting ? 0 : MeshColors.shadowY
                    )

                // Mic icon
                Image(systemName: isTransmitting ? "mic.fill" : "mic")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(isTransmitting ? .white : MeshColors.primaryText)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        onPTTStart()
                        startPulse()
                    }
                    .onEnded { _ in
                        isPressed = false
                        onPTTEnd()
                        stopPulse()
                    }
            )

            // Label
            Text(isTransmitting ? "Transmitting..." : "Hold to Talk")
                .font(MeshFonts.caption)
                .foregroundColor(
                    isTransmitting ? MeshColors.activeTX : MeshColors.secondaryText
                )
                .animation(.easeInOut(duration: 0.2), value: isTransmitting)
        }
    }

    private var buttonFill: AnyShapeStyle {
        if isTransmitting {
            AnyShapeStyle(MeshColors.pttActiveGradient)
        } else {
            AnyShapeStyle(MeshColors.controlBg)
        }
    }

    private func startPulse() {
        pulseScale = 1.0
        withAnimation(
            .easeInOut(duration: 1.2).repeatForever(autoreverses: false)
        ) {
            pulseScale = 1.5
        }
    }

    private func stopPulse() {
        withAnimation(.easeOut(duration: 0.3)) {
            pulseScale = 1.0
        }
    }
}

#if DEBUG
struct PTTButtonView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            PTTButtonView(
                isTransmitting: .constant(false),
                onPTTStart: {},
                onPTTEnd: {}
            )
            PTTButtonView(
                isTransmitting: .constant(true),
                onPTTStart: {},
                onPTTEnd: {}
            )
        }
        .padding()
        .background(MeshColors.background)
    }
}
#endif

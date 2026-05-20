import SwiftUI

struct WaveformView: View {
    @Binding var level: Float
    var isActive: Bool
    var isTransmitting: Bool = false

    private let barCount = 20
    private let barSpacing: CGFloat = 3

    var body: some View {
        HStack(spacing: barSpacing) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    level: level,
                    index: index,
                    totalBars: barCount,
                    isActive: isActive,
                    isTransmitting: isTransmitting
                )
            }
        }
        .frame(height: 60)
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
        .animation(.spring(response: 0.15, dampingFraction: 0.5), value: level)
    }
}

private struct WaveformBar: View {
    let level: Float
    let index: Int
    let totalBars: Int
    let isActive: Bool
    let isTransmitting: Bool

    private var normalizedPosition: Double {
        Double(index) / Double(totalBars - 1)
    }

    private var barHeight: CGFloat {
        guard isActive else { return 2 }

        let centerDistance = abs(normalizedPosition - 0.5) * 2.0
        let envelope = 1.0 - (centerDistance * centerDistance * 0.6)
        let levelFactor = Double(max(0.05, min(1.0, level)))

        // Add some pseudo-random variation per bar
        let seed = sin(Double(index) * 1.7 + Double(level) * 3.0)
        let variation = 0.7 + 0.3 * abs(seed)

        let height = envelope * levelFactor * variation * 50.0
        return max(2, CGFloat(height))
    }

    private var barColor: Color {
        isTransmitting ? MeshColors.activeTX : MeshColors.accent
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(barColor.opacity(isActive ? 1.0 : 0.3))
            .frame(maxWidth: .infinity, minHeight: 2, idealHeight: barHeight, maxHeight: barHeight)
            .animation(
                .spring(response: 0.2, dampingFraction: 0.55).delay(Double(index) * 0.008),
                value: level
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
    }
}

#if DEBUG
struct WaveformView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            WaveformView(level: .constant(0.7), isActive: true, isTransmitting: false)
            WaveformView(level: .constant(0.4), isActive: true, isTransmitting: true)
            WaveformView(level: .constant(0.0), isActive: false)
        }
        .padding()
        .background(MeshColors.background)
    }
}
#endif

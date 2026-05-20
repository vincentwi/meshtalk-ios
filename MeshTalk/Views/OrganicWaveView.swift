import SwiftUI

struct OrganicWaveView: View {
    @State private var phase: Double = 0

    private let waveHeight: CGFloat = 200
    private let layerConfigs: [(color: Color, amplitude: CGFloat, frequency: Double, speed: Double, yOffset: CGFloat)] = [
        (MeshColors.wave1, 18, 1.2, 0.8, 0),
        (MeshColors.wave2, 14, 1.5, 1.0, 30),
        (MeshColors.wave3, 10, 1.8, 1.3, 55),
        (MeshColors.wave4, 8, 2.2, 1.6, 75),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ForEach(0..<layerConfigs.count, id: \.self) { index in
                let config = layerConfigs[index]
                WaveShape(
                    phase: phase * config.speed,
                    amplitude: config.amplitude,
                    frequency: config.frequency
                )
                .fill(config.color.opacity(0.85))
                .frame(height: waveHeight - config.yOffset)
            }
        }
        .frame(height: waveHeight)
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            withAnimation(
                .linear(duration: 3.5)
                .repeatForever(autoreverses: false)
            ) {
                phase = .pi * 2
            }
        }
    }
}

private struct WaveShape: Shape {
    var phase: Double
    var amplitude: CGFloat
    var frequency: Double

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let midY = amplitude + 10 // top padding for wave crest

        path.move(to: CGPoint(x: 0, y: rect.height))

        // Bottom-left corner
        path.addLine(to: CGPoint(x: 0, y: midY))

        // Draw sine wave across top
        let steps = Int(width)
        for x in 0...steps {
            let relativeX = Double(x) / Double(steps)
            let sine = sin((relativeX * frequency * .pi * 2) + phase)
            let secondHarmonic = sin((relativeX * frequency * .pi * 4) + phase * 0.7) * 0.3
            let y = midY + CGFloat(sine + secondHarmonic) * amplitude
            path.addLine(to: CGPoint(x: CGFloat(x), y: y))
        }

        // Close path: bottom-right, bottom-left
        path.addLine(to: CGPoint(x: width, y: rect.height))
        path.closeSubpath()

        return path
    }
}

#if DEBUG
struct OrganicWaveView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            MeshColors.background.ignoresSafeArea()
            VStack {
                Spacer()
                OrganicWaveView()
            }
        }
    }
}
#endif

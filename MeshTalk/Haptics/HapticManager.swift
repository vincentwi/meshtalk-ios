import UIKit

final class HapticManager: Sendable {
    static let shared = HapticManager()

    private init() {}

    /// Heavy impact for PTT button press start
    func pttStart() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Light impact for PTT button release
    func pttEnd() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Notification feedback for connection state changes
    func connectionChange(success: Bool) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(success ? .success : .error)
    }

    /// Light impact for general button taps
    func buttonTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: 0.6)
    }

    /// Medium impact for mode toggles
    func toggle() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: 0.7)
    }
}

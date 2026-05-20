import Foundation
import Combine

/// Voice Activity Detection using RMS threshold and hang time.
@MainActor
final class VoxDetector: ObservableObject {
    @Published var isVoiceDetected = false
    @Published var threshold: Float = 0.015
    @Published var hangTime: TimeInterval = 0.8

    private var hangTimer: Task<Void, Never>?
    private var lastVoiceTime: Date = .distantPast

    /// Update with new audio level. Call from audio capture callback.
    func update(level: Float) {
        if level >= threshold {
            lastVoiceTime = Date()
            if !isVoiceDetected {
                isVoiceDetected = true
            }
            hangTimer?.cancel()
            hangTimer = Task { [weak self] in
                guard let self = self else { return }
                try? await Task.sleep(nanoseconds: UInt64(self.hangTime * 1_000_000_000))
                if !Task.isCancelled {
                    self.isVoiceDetected = false
                }
            }
        }
    }

    func reset() {
        hangTimer?.cancel()
        isVoiceDetected = false
    }
}

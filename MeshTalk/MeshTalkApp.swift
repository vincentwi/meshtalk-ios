import SwiftUI

@main
struct MeshTalkApp: App {
    @StateObject private var audioManager = BackgroundAudioManager()
    @AppStorage("meshtalk_onboarded") private var isOnboarded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if isOnboarded {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(audioManager)
            .preferredColorScheme(.light)
        }
    }
}

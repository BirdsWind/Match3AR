import SwiftUI

@main


struct MatchTreApp: App {
    var body: some Scene {
        #if os(visionOS)
        ImmersiveSpace(id: "MainImmersiveSpace") {
            GameView().ignoresSafeArea()
        }
        #else
        WindowGroup {
            GameView().ignoresSafeArea()
        }
        #endif
    }
}

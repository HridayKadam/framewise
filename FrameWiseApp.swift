import SwiftUI
import Combine

@main
struct FrameWiseApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(coordinator)
                .onAppear {
                    coordinator.start()
                }
        }
    }
}

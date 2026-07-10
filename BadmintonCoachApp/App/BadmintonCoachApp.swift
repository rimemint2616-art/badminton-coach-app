import SwiftUI

@main
struct BadmintonCoachApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(AppModelContainer.shared)
    }
}

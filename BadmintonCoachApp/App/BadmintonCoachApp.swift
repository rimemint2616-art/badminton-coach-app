import SwiftUI

@main
struct BadmintonCoachApp: App {
    /// XCTest実行中かどうか。ユニットテストはモデル/サービスを直接検証するため、
    /// テストホストで重いSwiftUI階層（RootTabView）を起動すると不要なクラッシュ要因になる。
    private var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var body: some Scene {
        WindowGroup {
            if isRunningUnitTests {
                Color.clear
            } else {
                RootTabView()
            }
        }
        .modelContainer(AppModelContainer.shared)
    }
}

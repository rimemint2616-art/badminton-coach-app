import SwiftUI

@main
struct BadmintonCoachApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                // アプリ全体が日本語UI固定のため、端末のリージョン設定に関わらず
                // 日付ピッカーなどのシステム標準UIも日本語表記に統一する。
                .environment(\.locale, Locale(identifier: "ja_JP"))
        }
        .modelContainer(AppModelContainer.shared)
    }
}

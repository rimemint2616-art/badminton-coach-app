import SwiftUI

/// アプリ全体で使う共通スタイル定義。今は最小限。機能が増えたらここに追加していく。
enum Theme {
    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
}

/// 設定タブから変更できる、アプリ全体の文字サイズ。
/// SwiftUIの `.dynamicTypeSize(_:)` に橋渡しし、`.headline`/`.body`/`.caption` など
/// 標準の文字スタイルを使っている箇所すべてに一括で反映される。
enum AppTextSize: String, CaseIterable, Identifiable {
    case standard, large, extraLarge, huge

    static let storageKey = "appTextSize"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "標準"
        case .large: return "大"
        case .extraLarge: return "特大"
        case .huge: return "最大"
        }
    }

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .standard: return .large
        case .large: return .xLarge
        case .extraLarge: return .xxLarge
        case .huge: return .xxxLarge
        }
    }
}

extension View {
    /// リスト内のカード風コンテナに使う共通スタイル
    func cardStyle() -> some View {
        self
            .padding(Theme.cardPadding)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

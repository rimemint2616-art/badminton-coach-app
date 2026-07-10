import SwiftUI

/// アプリ全体で使う共通スタイル定義。今は最小限。機能が増えたらここに追加していく。
enum Theme {
    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
}

extension View {
    /// リスト内のカード風コンテナに使う共通スタイル
    func cardStyle() -> some View {
        self
            .padding(Theme.cardPadding)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }
}

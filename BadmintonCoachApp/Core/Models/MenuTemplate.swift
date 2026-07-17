import Foundation
import SwiftData

/// カテゴリに紐づく、名前付きの再利用可能な練習メニュー（例:「4隅フットワーク（3コート版）」）。
/// 設定タブのカテゴリ別テンプレート管理画面、およびメニュー作成中の「新しいメニューを作成」
/// から作成・呼び出しできる。実際のメニューに使う際は中身をコピーするので、テンプレート自体を
/// 編集しても過去に使ったセクションには影響しない。
@Model
final class MenuTemplate {
    var id: UUID
    var name: String
    var createdAt: Date
    var category: MenuCategoryTag?

    /// このテンプレートの行。テンプレート削除時にまとめて削除（.cascade）。
    @Relationship(deleteRule: .cascade, inverse: \MenuTemplateItem.template)
    var items: [MenuTemplateItem] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        createdAt: Date = .now,
        category: MenuCategoryTag? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.category = category
    }

    var sortedItems: [MenuTemplateItem] {
        items.sorted { $0.orderIndex < $1.orderIndex }
    }
}

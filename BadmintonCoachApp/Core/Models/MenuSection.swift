import Foundation
import SwiftData

/// 練習メニューの1セクション（「体操」「フットワーク」「ノック練」など）。
/// タイトルは自由記述で、時間注記（「(約20分)」など）も込みで入力する想定。
@Model
final class MenuSection {
    var id: UUID
    var orderIndex: Int
    var title: String
    /// 「メニューを作る」のカテゴリボタンから作られた場合のカテゴリ。自由入力のセクションはnil。
    /// 逆参照はMenuCategoryTag.sections側で宣言。
    var category: MenuCategoryTag?

    var session: PracticeSession?

    /// このセクションの行。セクション削除時にまとめて削除（.cascade）。
    @Relationship(deleteRule: .cascade, inverse: \MenuSectionItem.section)
    var items: [MenuSectionItem] = []

    init(
        id: UUID = UUID(),
        orderIndex: Int = 0,
        title: String = "",
        category: MenuCategoryTag? = nil,
        session: PracticeSession? = nil
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.title = title
        self.category = category
        self.session = session
    }

    var sortedItems: [MenuSectionItem] {
        items.sorted { $0.orderIndex < $1.orderIndex }
    }
}

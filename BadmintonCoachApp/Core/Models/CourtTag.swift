import Foundation
import SwiftData

/// 練習メニューの「コート」に使うタグ。固定enumではなく可変データにしてあるのは、
/// 設定タブからコート数・呼び方を自由に追加・削除・並び替えできるようにするため。
@Model
final class CourtTag {
    var id: UUID
    var name: String
    var sortOrder: Int
    var isDefault: Bool

    /// このコートが割り当てられている練習メニューの行（多対多の逆参照）。
    /// これが無いとSwiftDataがCourtTag削除時にMenuSectionItem.courts側の参照を
    /// 正しく整理できず、削除済みのコートを指したままクラッシュする。
    var items: [MenuSectionItem] = []

    /// このコートが割り当てられているテンプレートの行（多対多の逆参照）。理由はitemsと同じ。
    var templateItems: [MenuTemplateItem] = []

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.isDefault = isDefault
    }
}

/// 初回起動時、および設定タブの「デフォルトに戻す」で使う既定のコートタグ一式。
enum DefaultCourtTags {
    static let names: [String] = ["1コート", "2コート", "3コート"]

    static func makeAll() -> [CourtTag] {
        names.enumerated().map { index, name in
            CourtTag(name: name, sortOrder: index, isDefault: true)
        }
    }
}

extension CourtTag {
    /// CourtTagが1件も無ければ既定タグを流し込む。既にデータがあれば何もしない。
    static func seedDefaultsIfNeeded(in context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<CourtTag>())) ?? 0
        guard count == 0 else { return }
        DefaultCourtTags.makeAll().forEach { context.insert($0) }
    }
}

import Foundation

/// 練習メニューの1行の編集中データ。SessionEditView/MenuSectionEditorView/MenuTemplateEditorViewの
/// 中でだけ使うメモリ上の値で、保存時にMenuSectionItem（またはMenuTemplateItem）へ変換される
/// （drillSelections: [PracticeMenu]と同じ方式）。
struct MenuSectionItemDraft: Identifiable {
    let id = UUID()
    var text: String = ""
    var shotsPerPerson: Int? = nil
    var sets: Int? = nil
    var indentLevel: Int = 0
    var isEmphasized: Bool = false
    var courtIDs: Set<UUID> = []
}

/// 練習メニューの1セクションの編集中データ。
struct MenuSectionDraft: Identifiable {
    let id = UUID()
    var title: String = ""
    /// 「メニューを作る」のカテゴリボタンから作られた場合のカテゴリID。自由入力ならnil。
    /// SwiftDataモデルを値型ドラフトに直接持たせず、IDで参照する（courtIDsと同じ方針）。
    var categoryID: UUID? = nil
    var items: [MenuSectionItemDraft] = []
}

extension MenuSectionDraft {
    /// 「毎回の練習で標準的に追加」がオンのカテゴリから、新規メニュー作成時に自動で
    /// 差し込む初期セクションを組み立てる。所要時間が設定されていればタイトルに埋め込む
    /// （例:「体操 5分」）。
    static func standardDrafts(from categoryTags: [MenuCategoryTag]) -> [MenuSectionDraft] {
        categoryTags
            .filter(\.isStandardEveryPractice)
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { tag in
                let title = tag.standardDurationMinutes.map { "\(tag.name) \($0)分" } ?? tag.name
                return MenuSectionDraft(title: title, categoryID: tag.id)
            }
    }
}

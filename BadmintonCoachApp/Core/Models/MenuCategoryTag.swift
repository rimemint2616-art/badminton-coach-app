import Foundation
import SwiftData

/// 練習メニューの「カテゴリ」（体操・フットワークなど）に使うタグ。固定enumではなく
/// 可変データにしてあるのは、設定タブからカテゴリの追加・削除・並び替えができるようにするため。
@Model
final class MenuCategoryTag {
    var id: UUID
    var name: String
    var sortOrder: Int
    var isDefault: Bool
    /// trueなら、新規メニュー作成時にこのカテゴリのセクションが自動で追加される（体操など）。
    var isStandardEveryPractice: Bool
    /// isStandardEveryPractice時の所要時間（分）。セクションタイトルに「体操 5分」のように埋め込む。
    var standardDurationMinutes: Int?
    /// trueなら、メニュー作成画面でこのカテゴリのボタンから保存済みテンプレートを呼び出せる。
    var supportsTemplateLibrary: Bool

    /// このカテゴリが設定されているセクション（1対多の逆参照）。タグ削除時もセクションは消さない（.nullify）。
    @Relationship(deleteRule: .nullify, inverse: \MenuSection.category)
    var sections: [MenuSection] = []

    /// このカテゴリに保存されたテンプレート（1対多の逆参照）。タグ削除時もテンプレートは消さない（.nullify）。
    @Relationship(deleteRule: .nullify, inverse: \MenuTemplate.category)
    var templates: [MenuTemplate] = []

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int,
        isDefault: Bool = false,
        isStandardEveryPractice: Bool = false,
        standardDurationMinutes: Int? = nil,
        supportsTemplateLibrary: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.isStandardEveryPractice = isStandardEveryPractice
        self.standardDurationMinutes = standardDurationMinutes
        self.supportsTemplateLibrary = supportsTemplateLibrary
    }
}

/// 初回起動時、および設定タブの「デフォルトに戻す」で使う既定のカテゴリ一式。
enum DefaultMenuCategoryTags {
    struct Definition {
        let name: String
        let isStandardEveryPractice: Bool
        let standardDurationMinutes: Int?
        let supportsTemplateLibrary: Bool
    }

    static let definitions: [Definition] = [
        Definition(name: "体操", isStandardEveryPractice: true, standardDurationMinutes: 5, supportsTemplateLibrary: false),
        Definition(name: "フットワーク", isStandardEveryPractice: false, standardDurationMinutes: nil, supportsTemplateLibrary: true),
        Definition(name: "ノック練", isStandardEveryPractice: false, standardDurationMinutes: nil, supportsTemplateLibrary: true),
        Definition(name: "パターン練", isStandardEveryPractice: false, standardDurationMinutes: nil, supportsTemplateLibrary: true),
        Definition(name: "ゲーム練", isStandardEveryPractice: false, standardDurationMinutes: nil, supportsTemplateLibrary: false)
    ]

    static func makeAll() -> [MenuCategoryTag] {
        definitions.enumerated().map { index, definition in
            MenuCategoryTag(
                name: definition.name,
                sortOrder: index,
                isDefault: true,
                isStandardEveryPractice: definition.isStandardEveryPractice,
                standardDurationMinutes: definition.standardDurationMinutes,
                supportsTemplateLibrary: definition.supportsTemplateLibrary
            )
        }
    }
}

extension MenuCategoryTag {
    /// MenuCategoryTagが1件も無ければ既定カテゴリを流し込む。既にデータがあれば何もしない。
    static func seedDefaultsIfNeeded(in context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<MenuCategoryTag>())) ?? 0
        guard count == 0 else { return }
        DefaultMenuCategoryTags.makeAll().forEach { context.insert($0) }
    }
}

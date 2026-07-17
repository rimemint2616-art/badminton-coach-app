import Foundation
import SwiftData

/// 練習メニューのセクション内の1行。本数×セット数や対戦カードの列挙などもすべて
/// 自由記述のテキストとして持つ（構造化しすぎず、紙のメニューの自由度を保つため）。
@Model
final class MenuSectionItem {
    var id: UUID
    var orderIndex: Int
    var text: String
    /// 1人あたりの球数（例:「8球」の8）。未設定はnil。
    var shotsPerPerson: Int?
    /// セット数（例:「2セット」の2）。未設定はnil。
    var sets: Int?
    /// 字下げの深さ（0〜2）。コート見出し→サブグループ→箇条書き、の3段構成に対応する。
    var indentLevel: Int
    /// 太字+強調色で目立たせるかどうか。色そのものは選べず、単一のフラグのみ。
    var isEmphasized: Bool

    var section: MenuSection?

    /// この行が対象とするコート（複数可、例:「1・2コート」なら2件）。
    @Relationship(inverse: \CourtTag.items)
    var courts: [CourtTag] = []

    init(
        id: UUID = UUID(),
        orderIndex: Int = 0,
        text: String = "",
        shotsPerPerson: Int? = nil,
        sets: Int? = nil,
        indentLevel: Int = 0,
        isEmphasized: Bool = false,
        section: MenuSection? = nil,
        courts: [CourtTag] = []
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.text = text
        self.shotsPerPerson = shotsPerPerson
        self.sets = sets
        self.indentLevel = indentLevel
        self.isEmphasized = isEmphasized
        self.section = section
        self.courts = courts
    }

    /// 「8球×2セット」のような、球数・セット数から組み立てる表示用の文字列。両方未設定ならnil。
    var repsSuffix: String? {
        switch (shotsPerPerson, sets) {
        case let (shots?, setCount?): return "\(shots)球×\(setCount)セット"
        case let (shots?, nil): return "\(shots)球"
        case let (nil, setCount?): return "\(setCount)セット"
        case (nil, nil): return nil
        }
    }

    /// textにrepsSuffixを続けた、画面・PDF共通の表示用文字列。
    var displayText: String {
        guard let repsSuffix else { return text }
        return text.isEmpty ? repsSuffix : "\(text) \(repsSuffix)"
    }
}

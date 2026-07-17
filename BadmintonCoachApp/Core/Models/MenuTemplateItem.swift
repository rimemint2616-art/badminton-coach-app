import Foundation
import SwiftData

/// MenuTemplateの1行。MenuSectionItemと同じ形のデータを、セッションに紐づかない
/// 再利用可能なテンプレートとして保持する。
@Model
final class MenuTemplateItem {
    var id: UUID
    var orderIndex: Int
    var text: String
    var shotsPerPerson: Int?
    var sets: Int?
    var indentLevel: Int
    var isEmphasized: Bool
    var template: MenuTemplate?

    /// 複数コート可（多対多）。CourtTag側の`templateItems`が逆参照。
    @Relationship(inverse: \CourtTag.templateItems)
    var courts: [CourtTag] = []

    init(
        id: UUID = UUID(),
        orderIndex: Int = 0,
        text: String = "",
        shotsPerPerson: Int? = nil,
        sets: Int? = nil,
        indentLevel: Int = 0,
        isEmphasized: Bool = false,
        template: MenuTemplate? = nil,
        courts: [CourtTag] = []
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.text = text
        self.shotsPerPerson = shotsPerPerson
        self.sets = sets
        self.indentLevel = indentLevel
        self.isEmphasized = isEmphasized
        self.template = template
        self.courts = courts
    }

    var repsSuffix: String? {
        switch (shotsPerPerson, sets) {
        case let (shots?, setCount?): return "\(shots)球×\(setCount)セット"
        case let (shots?, nil): return "\(shots)球"
        case let (nil, setCount?): return "\(setCount)セット"
        case (nil, nil): return nil
        }
    }
}

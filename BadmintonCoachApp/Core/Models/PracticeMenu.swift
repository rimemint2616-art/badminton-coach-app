import Foundation
import SwiftData

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    case beginner, intermediate, advanced

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "初級"
        case .intermediate: return "中級"
        case .advanced: return "上級"
        }
    }
}

/// 練習メニュー（ドリル）のライブラリ項目。
@Model
final class PracticeMenu {
    var id: UUID
    var name: String
    var descriptionText: String
    /// 対象スキルのタグ（例: "footwork", "netPlay", "smash"）。将来の絞り込み検索用。
    var targetSkillTags: [String]
    var durationMinutes: Int
    var equipment: String
    var difficultyLevel: DifficultyLevel
    @Attribute(.externalStorage) var diagramImage: Data?
    var createdAt: Date

    /// このメニューがスケジュールされたセッション項目。
    /// メニュー削除時は紐づく割り当ても一緒に削除する（.cascade）。
    @Relationship(deleteRule: .cascade, inverse: \SessionDrillItem.menu)
    var sessionItems: [SessionDrillItem] = []

    init(
        id: UUID = UUID(),
        name: String,
        descriptionText: String = "",
        targetSkillTags: [String] = [],
        durationMinutes: Int = 10,
        equipment: String = "",
        difficultyLevel: DifficultyLevel = .beginner,
        diagramImage: Data? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.targetSkillTags = targetSkillTags
        self.durationMinutes = durationMinutes
        self.equipment = equipment
        self.difficultyLevel = difficultyLevel
        self.diagramImage = diagramImage
        self.createdAt = createdAt
    }
}

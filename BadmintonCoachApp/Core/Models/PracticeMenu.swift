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

/// 練習メニュー（＝小カテゴリの具体メニュー定義）。
/// 大カテゴリ・中カテゴリに属し、本日の練習メニュー作成時に選んで追加する。
@Model
final class PracticeMenu {
    var id: UUID
    var name: String
    var descriptionText: String
    /// 対象スキルのタグ（例: "footwork", "netPlay", "smash"）。将来の絞り込み検索用。
    var targetSkillTags: [String]
    /// 本日の練習メニューに追加したときの初期の目安時間（分）。
    var durationMinutes: Int
    var equipment: String
    var difficultyLevel: DifficultyLevel

    /// 大カテゴリ（体操・フットワーク・ノック練・パターン練・ゲーム練）。
    var majorCategory: MajorCategory = MajorCategory.footwork
    /// 中カテゴリ（シングルス/ダブルス）。大カテゴリが中カテゴリを持たない場合は nil。
    var middleCategory: MiddleCategory?
    /// 毎回の練習の最初に自動追加するデフォルトメニュー（体操など）かどうか。
    var isDefaultMenu: Bool = false
    /// デフォルトメニュー内での並び順。
    var defaultOrderIndex: Int = 0

    @Attribute(.externalStorage) var diagramImage: Data?
    var createdAt: Date

    /// このメニューがスケジュールされたセッション項目。
    /// メニュー削除時は紐づく割り当ても一緒に削除する（.cascade）。
    @Relationship(deleteRule: .cascade, inverse: \SessionDrillItem.menu)
    var sessionItems: [SessionDrillItem] = []

    /// このメニューの測定方法（大カテゴリから決まる）。
    var format: MeasurementFormat { majorCategory.format }

    init(
        id: UUID = UUID(),
        name: String,
        descriptionText: String = "",
        targetSkillTags: [String] = [],
        durationMinutes: Int = 10,
        equipment: String = "",
        difficultyLevel: DifficultyLevel = .beginner,
        majorCategory: MajorCategory = .footwork,
        middleCategory: MiddleCategory? = nil,
        isDefaultMenu: Bool = false,
        defaultOrderIndex: Int = 0,
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
        self.majorCategory = majorCategory
        self.middleCategory = middleCategory
        self.isDefaultMenu = isDefaultMenu
        self.defaultOrderIndex = defaultOrderIndex
        self.diagramImage = diagramImage
        self.createdAt = createdAt
    }
}

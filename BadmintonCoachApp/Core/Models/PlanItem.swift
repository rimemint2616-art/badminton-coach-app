import Foundation
import SwiftData

/// 本日の練習メニューに並ぶ1項目。練習メニュー（drill）または休憩（rest）。
/// 参照元メニューの内容はスナップショットとして保持し、元メニューが編集・削除されても崩れないようにする。
@Model
final class PlanItem {
    var id: UUID
    var orderIndex: Int
    var kind: PlanItemKind

    /// 表示名（メニュー名のスナップショット。休憩は「休憩」）。
    var title: String
    /// 元メニューへの参照（あれば）。関係ではなくIDで保持し、削除に強くする。
    var menuID: UUID?

    var majorCategory: MajorCategory?
    var middleCategory: MiddleCategory?

    // 測定方法ごとのパラメータ（該当しないものはnil）
    var repUnit: RepUnit?           // 球/回（repsAndSets）
    var countPerPerson: Int?        // 1人あたりの球数/回数（repsAndSets）
    var sets: Int?                  // セット数（repsAndSets）
    var minutes: Int?               // 分（minutes）
    var matchPoints: Int?           // 何点マッチ（pointMatch）
    var matchCount: Int?            // 何マッチ（pointMatch）

    /// 時間予算の計算に使う目安時間（分）。すべての項目が持つ。
    var estimatedMinutes: Int
    var notes: String

    /// コートへの選手割り当て。
    var courts: [CourtAssignment]

    /// 親プラン。削除では消えない（PracticePlan.itemsの.cascadeが唯一の削除経路）。
    var plan: PracticePlan?

    init(
        id: UUID = UUID(),
        orderIndex: Int = 0,
        kind: PlanItemKind = .drill,
        title: String = "",
        menuID: UUID? = nil,
        majorCategory: MajorCategory? = nil,
        middleCategory: MiddleCategory? = nil,
        repUnit: RepUnit? = nil,
        countPerPerson: Int? = nil,
        sets: Int? = nil,
        minutes: Int? = nil,
        matchPoints: Int? = nil,
        matchCount: Int? = nil,
        estimatedMinutes: Int = 10,
        notes: String = "",
        courts: [CourtAssignment] = [],
        plan: PracticePlan? = nil
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.kind = kind
        self.title = title
        self.menuID = menuID
        self.majorCategory = majorCategory
        self.middleCategory = middleCategory
        self.repUnit = repUnit
        self.countPerPerson = countPerPerson
        self.sets = sets
        self.minutes = minutes
        self.matchPoints = matchPoints
        self.matchCount = matchCount
        self.estimatedMinutes = estimatedMinutes
        self.notes = notes
        self.courts = courts
        self.plan = plan
    }
}

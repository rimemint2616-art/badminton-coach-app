import Foundation
import SwiftData

/// 「本日の練習メニュー」。順序付きの練習項目（PlanItem）の集まり。
/// 独立したドキュメントとして保存し、後から呼び出して編集・PDF出力できる。
@Model
final class PracticePlan {
    var id: UUID
    var title: String
    var date: Date
    /// 目標時間（分）。合計がこれを超えると超過警告、下回ると保存時に確認する。
    var targetDurationMinutes: Int
    /// 休憩の既定設定（自動挿入で使う）。
    var breakIntervalMinutes: Int
    var breakDurationMinutes: Int
    var notes: String
    var createdAt: Date

    /// この本日の練習メニューに並ぶ項目。プラン削除でまとめて削除（.cascade）。
    @Relationship(deleteRule: .cascade, inverse: \PlanItem.plan)
    var items: [PlanItem] = []

    init(
        id: UUID = UUID(),
        title: String = "",
        date: Date = .now,
        targetDurationMinutes: Int = 120,
        breakIntervalMinutes: Int = 30,
        breakDurationMinutes: Int = 5,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.targetDurationMinutes = targetDurationMinutes
        self.breakIntervalMinutes = breakIntervalMinutes
        self.breakDurationMinutes = breakDurationMinutes
        self.notes = notes
        self.createdAt = createdAt
    }

    /// orderIndex順に並べた項目。
    var sortedItems: [PlanItem] {
        items.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// 全項目の合計時間（分）。
    var totalMinutes: Int {
        items.reduce(0) { $0 + $1.estimatedMinutes }
    }
}

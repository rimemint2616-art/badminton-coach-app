import Foundation
import SwiftData

/// 「生徒のランクに反映」を押した時点の、その生徒のランク戦での成績スナップショット。
/// 生徒のプロフィールから「どのランク戦で何位だったか」の履歴を追えるようにするために、
/// 反映のたびに1件ずつ残す（後からランク戦や参加者が変わっても履歴は変化しない）。
@Model
final class RankChallengeResultRecord {
    var id: UUID
    /// どのランク戦か（大会名。例:「7月ランク戦 決勝」）。
    var eventName: String
    var stageDisplayName: String
    var recordedAt: Date
    var position: Int
    var wins: Int
    var losses: Int
    var pointsFor: Int
    var pointsAgainst: Int

    var student: Student?

    init(
        id: UUID = UUID(),
        eventName: String,
        stageDisplayName: String,
        recordedAt: Date = .now,
        position: Int,
        wins: Int,
        losses: Int,
        pointsFor: Int,
        pointsAgainst: Int,
        student: Student? = nil
    ) {
        self.id = id
        self.eventName = eventName
        self.stageDisplayName = stageDisplayName
        self.recordedAt = recordedAt
        self.position = position
        self.wins = wins
        self.losses = losses
        self.pointsFor = pointsFor
        self.pointsAgainst = pointsAgainst
        self.student = student
    }

    var pointDifference: Int { pointsFor - pointsAgainst }
}

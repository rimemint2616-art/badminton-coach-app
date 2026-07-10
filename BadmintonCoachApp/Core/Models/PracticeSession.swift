import Foundation
import SwiftData

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case individual, group

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .individual: return "個人"
        case .group: return "グループ"
        }
    }
}

/// 練習スケジュールの1コマ。
@Model
final class PracticeSession {
    var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var location: String
    var sessionType: SessionType
    var notes: String

    /// 出席予定/実績の生徒（多対多）
    @Relationship(inverse: \Student.sessions)
    var attendees: [Student] = []

    /// このセッションに紐づく練習メニュー項目。セッション削除でまとめて削除（.cascade）。
    @Relationship(deleteRule: .cascade, inverse: \SessionDrillItem.session)
    var drillItems: [SessionDrillItem] = []

    /// このセッション中に記録された試合。セッション削除でも試合記録は残す（.nullify）。
    @Relationship(deleteRule: .nullify, inverse: \Match.session)
    var matches: [Match] = []

    init(
        id: UUID = UUID(),
        date: Date = .now,
        startTime: Date = .now,
        endTime: Date = .now,
        location: String = "",
        sessionType: SessionType = .group,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.sessionType = sessionType
        self.notes = notes
    }
}

import Foundation
import SwiftData

enum DominantHand: String, Codable, CaseIterable, Identifiable {
    case right, left

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .right: return "右利き"
        case .left: return "左利き"
        }
    }
}

enum StudentLevel: String, Codable, CaseIterable, Identifiable {
    case beginner, intermediate, advanced, competitive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "初級"
        case .intermediate: return "中級"
        case .advanced: return "上級"
        case .competitive: return "選手"
        }
    }
}

@Model
final class Student {
    var id: UUID
    var name: String
    var nameKana: String?
    var birthdate: Date?
    var dominantHand: DominantHand?
    var level: StudentLevel
    var joinedDate: Date
    var isArchived: Bool
    var notes: String
    @Attribute(.externalStorage) var photo: Data?

    /// 出席した練習セッション（多対多、PracticeSession.attendeesの逆関係）
    var sessions: [PracticeSession] = []

    /// player1として出場した試合。Student削除時にMatchは消さない（.nullify）。
    @Relationship(deleteRule: .nullify, inverse: \Match.player1)
    var matchesAsPlayer1: [Match] = []

    /// player2として出場した試合。Student削除時にMatchは消さない（.nullify）。
    @Relationship(deleteRule: .nullify, inverse: \Match.player2)
    var matchesAsPlayer2: [Match] = []

    /// この生徒へのフィードバック。Student削除時にFeedbackは消さない（.nullify）。
    @Relationship(deleteRule: .nullify, inverse: \Feedback.student)
    var feedbackEntries: [Feedback] = []

    /// この生徒向けに生成されたPDFレポートの記録。
    @Relationship(deleteRule: .nullify, inverse: \ReportRecord.student)
    var reportRecords: [ReportRecord] = []

    init(
        id: UUID = UUID(),
        name: String,
        nameKana: String? = nil,
        birthdate: Date? = nil,
        dominantHand: DominantHand? = nil,
        level: StudentLevel = .beginner,
        joinedDate: Date = .now,
        isArchived: Bool = false,
        notes: String = "",
        photo: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.nameKana = nameKana
        self.birthdate = birthdate
        self.dominantHand = dominantHand
        self.level = level
        self.joinedDate = joinedDate
        self.isArchived = isArchived
        self.notes = notes
        self.photo = photo
    }
}

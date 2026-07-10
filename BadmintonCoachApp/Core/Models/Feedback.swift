import Foundation
import SwiftData

enum FeedbackCategory: String, Codable, CaseIterable, Identifiable {
    case technique
    case tactics
    case fitness
    case mental

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .technique: return "技術"
        case .tactics: return "戦術"
        case .fitness: return "フィジカル"
        case .mental: return "メンタル"
        }
    }
}

/// フィードバックの発生源。今回はmanualのみ使用するが、
/// 将来AI解析を追加してもスキーマ変更なしで拡張できるようにしておく。
enum FeedbackSource: String, Codable, CaseIterable, Identifiable {
    case manual
    case aiGenerated

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .manual: return "手動入力"
        case .aiGenerated: return "AI生成"
        }
    }
}

@Model
final class Feedback {
    var id: UUID
    var date: Date
    var text: String
    var category: FeedbackCategory?
    var source: FeedbackSource
    /// AI生成時に使用したモデルのバージョン情報（今回は未使用、将来用に予約）
    var aiModelVersion: String?
    var createdAt: Date

    /// フィードバック対象の生徒（必須。SwiftDataの制約上optionalだが、
    /// 保存前に必ず値を設定するのをUI側で保証する）。
    var student: Student?
    var session: PracticeSession?
    var match: Match?
    var rally: Rally?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        text: String,
        category: FeedbackCategory? = nil,
        source: FeedbackSource = .manual,
        aiModelVersion: String? = nil,
        createdAt: Date = .now,
        student: Student? = nil,
        session: PracticeSession? = nil,
        match: Match? = nil,
        rally: Rally? = nil
    ) {
        self.id = id
        self.date = date
        self.text = text
        self.category = category
        self.source = source
        self.aiModelVersion = aiModelVersion
        self.createdAt = createdAt
        self.student = student
        self.session = session
        self.match = match
        self.rally = rally
    }
}

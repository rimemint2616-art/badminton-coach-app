import Foundation
import SwiftData

enum MatchType: String, Codable, CaseIterable, Identifiable {
    case singles, doubles

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .singles: return "シングルス"
        case .doubles: return "ダブルス"
        }
    }
}

/// 採点方式。ScoringRulesEngineがこの値を見てゲーム/マッチ終了を判定する。
enum ScoringFormat: String, Codable, CaseIterable, Identifiable {
    case bestOf3To21
    case singleGameTo21
    case bestOf3To15

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bestOf3To21: return "3ゲーム制 21点（デュース30点キャップ）"
        case .singleGameTo21: return "1ゲーム制 21点"
        case .bestOf3To15: return "3ゲーム制 15点"
        }
    }

    var pointsToWinGame: Int {
        switch self {
        case .bestOf3To21, .singleGameTo21: return 21
        case .bestOf3To15: return 15
        }
    }

    var capPoints: Int {
        pointsToWinGame == 21 ? 30 : pointsToWinGame
    }

    var gamesToWinMatch: Int {
        switch self {
        case .bestOf3To21, .bestOf3To15: return 2
        case .singleGameTo21: return 1
        }
    }
}

enum MatchStatus: String, Codable, CaseIterable, Identifiable {
    case inProgress, completed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inProgress: return "試合中"
        case .completed: return "終了"
        }
    }
}

/// 1ゲームの最終スコア（例: 21-18）。Matchのfinalスコアサマリーとして保持。
struct GameScore: Codable, Hashable {
    var gameNumber: Int
    var player1Score: Int
    var player2Score: Int
}

@Model
final class Match {
    var id: UUID
    var date: Date
    var matchType: MatchType
    var scoringFormat: ScoringFormat
    var status: MatchStatus
    var finalScoreSummary: [GameScore]

    /// プレイヤー1。Match削除時にStudentは消えない（Student側の.nullifyで管理）。
    var player1: Student?
    var player2: Student?

    /// この試合が紐づく練習セッション（任意）。
    var session: PracticeSession?

    /// この試合のラリー記録。Match削除時にRallyもまとめて削除（.cascade）。
    @Relationship(deleteRule: .cascade, inverse: \Rally.match)
    var rallies: [Rally] = []

    init(
        id: UUID = UUID(),
        date: Date = .now,
        matchType: MatchType = .singles,
        scoringFormat: ScoringFormat = .bestOf3To21,
        status: MatchStatus = .inProgress,
        finalScoreSummary: [GameScore] = [],
        player1: Student? = nil,
        player2: Student? = nil,
        session: PracticeSession? = nil
    ) {
        self.id = id
        self.date = date
        self.matchType = matchType
        self.scoringFormat = scoringFormat
        self.status = status
        self.finalScoreSummary = finalScoreSummary
        self.player1 = player1
        self.player2 = player2
        self.session = session
    }
}

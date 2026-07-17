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

/// 試合をどの粒度で記録するか。セットアップ画面で選び、Matchに保存しておくことで
/// 「続きを記録」時にどの画面へ戻ればよいか判断できるようにする。
enum MatchRecordingStyle: String, Codable, CaseIterable, Identifiable {
    case resultOnly
    case flow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .resultOnly: return "結果のみ"
        case .flow: return "流れ"
        }
    }

    var description: String {
        switch self {
        case .resultOnly: return "各ゲームの最終スコアだけをまとめて入力します"
        case .flow: return "ポイントごとの得点経過をその場で記録します"
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

/// 試合の種別タグ。ランク戦から作られた試合には、対応する段階のタグが自動で付く。
enum MatchTag: String, Codable, CaseIterable, Identifiable {
    case gamePractice
    case practiceMatch
    case rankChallengePreliminary
    case rankChallengeFinals
    case rankChallengePromotion
    case tournamentTeam
    case tournamentIndividual

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gamePractice: return "ゲーム練"
        case .practiceMatch: return "練習試合"
        case .rankChallengePreliminary: return "ランク戦(予選)"
        case .rankChallengeFinals: return "ランク戦(決勝)"
        case .rankChallengePromotion: return "ランク戦(入れ替え戦)"
        case .tournamentTeam: return "大会(団体戦)"
        case .tournamentIndividual: return "大会(個人戦)"
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
    var recordingStyle: MatchRecordingStyle
    /// 試合の種別タグ（ゲーム練・練習試合・ランク戦(予選)など）。未設定はnil。
    var tag: MatchTag?

    /// プレイヤー1。Match削除時にStudentは消えない（Student側の.nullifyで管理）。
    var player1: Student?
    var player2: Student?

    /// 生徒として登録されていない対外試合の相手などを表すための自由入力名。
    /// player1/player2がnilのときのみ表示に使う。
    var player1GuestName: String?
    var player2GuestName: String?

    /// この試合が紐づく練習セッション（任意）。
    var session: PracticeSession?

    /// この試合がランク戦の対戦表セルから開始された場合の、紐づく組み合わせ（任意）。
    var rankChallengePairing: RankChallengePairing?

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
        recordingStyle: MatchRecordingStyle = .flow,
        tag: MatchTag? = nil,
        player1: Student? = nil,
        player2: Student? = nil,
        player1GuestName: String? = nil,
        player2GuestName: String? = nil,
        session: PracticeSession? = nil
    ) {
        self.id = id
        self.date = date
        self.matchType = matchType
        self.scoringFormat = scoringFormat
        self.status = status
        self.finalScoreSummary = finalScoreSummary
        self.recordingStyle = recordingStyle
        self.tag = tag
        self.player1 = player1
        self.player2 = player2
        self.player1GuestName = player1GuestName
        self.player2GuestName = player2GuestName
        self.session = session
    }

    /// 表示用のプレイヤー名。生徒として登録されていれば生徒名、
    /// 対外試合などでゲスト名だけ入力されていればそちらを、どちらもなければデフォルト名を返す。
    var player1DisplayName: String { player1?.name ?? player1GuestName ?? "プレイヤー1" }
    var player2DisplayName: String { player2?.name ?? player2GuestName ?? "プレイヤー2" }
}

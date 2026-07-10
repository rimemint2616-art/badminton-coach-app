import Foundation

/// バドミントンのラリーポイント制ルールを扱う純粋ロジック。
/// SwiftDataに依存しないため、XCTestで単体テストしやすい。
enum ScoringRulesEngine {
    /// 現在のスコアからゲームの勝者を判定する。決着していなければnil。
    static func gameWinner(player1Score: Int, player2Score: Int, format: ScoringFormat) -> MatchSide? {
        let pointsToWin = format.pointsToWinGame
        let cap = format.capPoints
        let higher = max(player1Score, player2Score)
        let lower = min(player1Score, player2Score)

        guard higher >= pointsToWin, higher != lower else { return nil }

        // capPoints（例: 21点ゲームなら30点）に達したら、2点差ルールを無視してその時点のリードで決着。
        if higher >= cap {
            return player1Score > player2Score ? .player1 : .player2
        }

        guard higher - lower >= 2 else { return nil }
        return player1Score > player2Score ? .player1 : .player2
    }

    /// これまでの獲得ゲーム数からマッチの勝者を判定する。決着していなければnil。
    static func matchWinner(gamesWonByPlayer1: Int, gamesWonByPlayer2: Int, format: ScoringFormat) -> MatchSide? {
        let needed = format.gamesToWinMatch
        if gamesWonByPlayer1 >= needed { return .player1 }
        if gamesWonByPlayer2 >= needed { return .player2 }
        return nil
    }

    /// ラリーポイント制: そのラリーの勝者が次のサーバーになる。
    static func nextServer(rallyWinner: MatchSide) -> MatchSide {
        rallyWinner
    }
}

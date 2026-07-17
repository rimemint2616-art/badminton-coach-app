import Foundation
import SwiftData

/// 「流れ」モード用のビューモデル。LiveTaggingViewModelと違い、ショットの種類や
/// コート上の位置は記録せず、ポイントごとの得点経過だけをRallyとして保存する。
@Observable
final class FlowScoringViewModel {
    let match: Match
    private let modelContext: ModelContext

    var currentGameNumber: Int = 1
    var player1Score: Int = 0
    var player2Score: Int = 0
    var gamesWonByPlayer1: Int = 0
    var gamesWonByPlayer2: Int = 0
    var currentServer: MatchSide

    /// 直前にポイントを記録したRally。ポイントボタンをタップした直後に理由候補を
    /// 選んでもらい、このRallyへ後付けでタグ付けするために保持しておく。
    private(set) var lastRecordedRally: Rally?

    /// 次のゲームの先行サーバー。シングルスは前ゲームの勝者が次のサーブ、というルールに
    /// 従い、ゲーム終了時に自動でセットする（コーチに毎回聞かない）。
    private var nextGameServer: MatchSide = .player1

    var isGameOver = false
    var isMatchOver = false

    init(match: Match, modelContext: ModelContext, firstServer: MatchSide = .player1) {
        self.match = match
        self.modelContext = modelContext
        self.currentServer = firstServer
    }

    /// 記録済みのラリーから状態を復元して再開する（「続きを記録」用）。
    static func resuming(match: Match, modelContext: ModelContext) -> FlowScoringViewModel {
        let viewModel = FlowScoringViewModel(match: match, modelContext: modelContext)

        let completedGames = match.finalScoreSummary
        viewModel.gamesWonByPlayer1 = completedGames.filter { $0.player1Score > $0.player2Score }.count
        viewModel.gamesWonByPlayer2 = completedGames.filter { $0.player2Score > $0.player1Score }.count
        viewModel.currentGameNumber = completedGames.count + 1

        let currentGameRallies = match.rallies
            .filter { $0.gameNumber == viewModel.currentGameNumber }
            .sorted { $0.orderIndex < $1.orderIndex }

        if let last = currentGameRallies.last {
            viewModel.player1Score = last.player1ScoreAfterRally
            viewModel.player2Score = last.player2ScoreAfterRally
            viewModel.lastRecordedRally = last
            if let previous = currentGameRallies.dropLast().last {
                let player1Gained = last.player1ScoreAfterRally > previous.player1ScoreAfterRally
                viewModel.currentServer = player1Gained ? .player1 : .player2
            } else {
                let player1Gained = last.player1ScoreAfterRally > 0
                viewModel.currentServer = player1Gained ? .player1 : .player2
            }
        } else if let lastCompletedGame = completedGames.last {
            // 次のゲームがまだ始まっていない場合は、前のゲームの勝者を次のサーブとする。
            viewModel.currentServer = lastCompletedGame.player1Score > lastCompletedGame.player2Score ? .player1 : .player2
        }

        return viewModel
    }

    var player1Name: String { match.player1DisplayName }
    var player2Name: String { match.player2DisplayName }

    private var currentGameRallies: [Rally] {
        match.rallies
            .filter { $0.gameNumber == currentGameNumber }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    /// ポイントを獲得した側を記録し、Rallyとして保存する（ショット情報は残さない）。
    /// reasonにはそのポイントが決まった理由（設定タブで管理するタグの名前）を任意で記録できる。
    func awardPoint(to side: MatchSide, reason: String? = nil) {
        if side == .player1 {
            player1Score += 1
        } else {
            player2Score += 1
        }

        let rally = Rally(
            orderIndex: match.rallies.count,
            gameNumber: currentGameNumber,
            serverPlayer: currentServer == .player1 ? match.player1 : match.player2,
            player1ScoreAfterRally: player1Score,
            player2ScoreAfterRally: player2Score,
            endReason: reason,
            match: match
        )
        modelContext.insert(rally)
        match.rallies.append(rally)
        lastRecordedRally = rally

        currentServer = ScoringRulesEngine.nextServer(rallyWinner: side)
        evaluateGameAndMatchCompletion()
        try? modelContext.save()
    }

    /// 直前に記録したポイントへ、あとから理由を付ける（ポイントボタンをタップした直後に
    /// 表示される理由候補から選んだ場合に呼ばれる）。
    func tagLastPoint(reason: String) {
        guard let rally = lastRecordedRally else { return }
        rally.endReason = reason
        try? modelContext.save()
    }

    private func evaluateGameAndMatchCompletion() {
        guard let gameWinner = ScoringRulesEngine.gameWinner(
            player1Score: player1Score,
            player2Score: player2Score,
            format: match.scoringFormat
        ) else { return }

        if gameWinner == .player1 {
            gamesWonByPlayer1 += 1
        } else {
            gamesWonByPlayer2 += 1
        }
        match.finalScoreSummary.append(
            GameScore(gameNumber: currentGameNumber, player1Score: player1Score, player2Score: player2Score)
        )

        if ScoringRulesEngine.matchWinner(
            gamesWonByPlayer1: gamesWonByPlayer1,
            gamesWonByPlayer2: gamesWonByPlayer2,
            format: match.scoringFormat
        ) != nil {
            isMatchOver = true
            match.status = .completed
        } else {
            // シングルスは前ゲームの勝者が次のゲームの先行サーブになるため、確認せず自動で決める。
            nextGameServer = gameWinner
            isGameOver = true
        }
    }

    func startNextGame() {
        currentGameNumber += 1
        player1Score = 0
        player2Score = 0
        currentServer = nextGameServer
        isGameOver = false
    }

    /// 直近のポイントを取り消す。LiveTaggingViewModel.undoLastRallyと同じ考え方。
    func undoLastPoint() {
        guard let last = currentGameRallies.last else { return }

        if let recordedGameIndex = match.finalScoreSummary.firstIndex(where: { $0.gameNumber == last.gameNumber }) {
            let recordedGame = match.finalScoreSummary[recordedGameIndex]
            if recordedGame.player1Score > recordedGame.player2Score {
                gamesWonByPlayer1 = max(0, gamesWonByPlayer1 - 1)
            } else {
                gamesWonByPlayer2 = max(0, gamesWonByPlayer2 - 1)
            }
            match.finalScoreSummary.remove(at: recordedGameIndex)
        }

        match.rallies.removeAll { $0.id == last.id }
        modelContext.delete(last)
        lastRecordedRally = currentGameRallies.last

        let remaining = currentGameRallies.dropLast()
        if let previous = remaining.last {
            player1Score = previous.player1ScoreAfterRally
            player2Score = previous.player2ScoreAfterRally
            let beforePrevious = remaining.dropLast().last
            let priorPlayer1Score = beforePrevious?.player1ScoreAfterRally ?? 0
            currentServer = previous.player1ScoreAfterRally > priorPlayer1Score ? .player1 : .player2
        } else {
            player1Score = 0
            player2Score = 0
        }
        isGameOver = false
        isMatchOver = false
        match.status = .inProgress

        try? modelContext.save()
    }
}

extension FlowScoringViewModel: Hashable {
    static func == (lhs: FlowScoringViewModel, rhs: FlowScoringViewModel) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

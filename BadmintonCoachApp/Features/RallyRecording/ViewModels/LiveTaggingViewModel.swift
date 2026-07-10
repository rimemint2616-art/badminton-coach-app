import Foundation
import SwiftData
import SwiftUI

enum RecordingMode: String, CaseIterable, Identifiable {
    case detailed
    case quick

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .detailed: return "詳細"
        case .quick: return "簡易"
        }
    }
}

enum RallyEndKind {
    case winner
    case error
}

/// 未確定のショット。ラリーが終わるまではSwiftDataへ保存せず、この配列だけで保持する。
/// これにより「ショット単位のUndo」がSwiftDataの保存を伴わず軽量に行える。
struct PendingShot: Identifiable {
    let id = UUID()
    var orderIndex: Int
    var side: MatchSide
    var shotType: ShotType
    var courtX: Double
    var courtY: Double
    var result: ShotResult = .inPlay
}

@Observable
final class LiveTaggingViewModel {
    let match: Match
    private let modelContext: ModelContext

    var recordingMode: RecordingMode = .detailed
    var currentGameNumber: Int = 1
    var player1Score: Int = 0
    var player2Score: Int = 0
    var gamesWonByPlayer1: Int = 0
    var gamesWonByPlayer2: Int = 0
    var currentServer: MatchSide
    var pendingShots: [PendingShot] = []
    var pendingTapPoint: CGPoint?
    var quickModeShotCount: Int = 1

    var isGameOver = false
    var isMatchOver = false

    init(match: Match, modelContext: ModelContext, firstServer: MatchSide = .player1) {
        self.match = match
        self.modelContext = modelContext
        self.currentServer = firstServer
    }

    /// 記録済みのラリーから状態を復元して再開する（「続きを記録」用）。
    static func resuming(match: Match, modelContext: ModelContext) -> LiveTaggingViewModel {
        let viewModel = LiveTaggingViewModel(match: match, modelContext: modelContext)

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
            if let previous = currentGameRallies.dropLast().last {
                let player1Gained = last.player1ScoreAfterRally > previous.player1ScoreAfterRally
                viewModel.currentServer = player1Gained ? .player1 : .player2
            } else {
                let player1Gained = last.player1ScoreAfterRally > 0
                viewModel.currentServer = player1Gained ? .player1 : .player2
            }
        }

        return viewModel
    }

    var player1Name: String { match.player1?.name ?? "プレイヤー1" }
    var player2Name: String { match.player2?.name ?? "プレイヤー2" }

    /// 次に記録するショットの打者側（シングルスはサーブから厳密に交互）。
    var sideForNextShot: MatchSide {
        pendingShots.count % 2 == 0 ? currentServer : currentServer.opposite
    }

    var canEndRally: Bool { !pendingShots.isEmpty }

    func selectCourtPosition(_ point: CGPoint) {
        pendingTapPoint = point
    }

    func selectShotType(_ shotType: ShotType) {
        guard let point = pendingTapPoint else { return }
        let shot = PendingShot(
            orderIndex: pendingShots.count,
            side: sideForNextShot,
            shotType: shotType,
            courtX: point.x,
            courtY: point.y
        )
        pendingShots.append(shot)
        pendingTapPoint = nil
    }

    func undoLastPendingShot() {
        guard !pendingShots.isEmpty else { return }
        pendingShots.removeLast()
    }

    /// ポイント終了を記録し、Rally + Shotを永続化してスコア・サーブ権を更新する。
    func endRally(kind: RallyEndKind) {
        guard let lastIndex = pendingShots.indices.last else { return }

        pendingShots[lastIndex].result = (kind == .winner) ? .winner : .unforcedError
        let decidingShot = pendingShots[lastIndex]
        let pointWinnerSide: MatchSide = (kind == .winner) ? decidingShot.side : decidingShot.side.opposite
        let endReason: RallyEndReason = (kind == .winner) ? .winner : .unforcedError

        if pointWinnerSide == .player1 {
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
            endReason: endReason,
            manualShotCount: recordingMode == .quick ? max(quickModeShotCount, pendingShots.count) : nil,
            match: match
        )
        modelContext.insert(rally)
        match.rallies.append(rally)

        for pending in pendingShots {
            let shot = Shot(
                orderIndex: pending.orderIndex,
                player: pending.side == .player1 ? match.player1 : match.player2,
                shotType: pending.shotType,
                courtX: pending.courtX,
                courtY: pending.courtY,
                result: pending.result,
                rally: rally
            )
            modelContext.insert(shot)
            rally.shots.append(shot)
        }

        pendingShots.removeAll()
        pendingTapPoint = nil
        quickModeShotCount = 1
        currentServer = ScoringRulesEngine.nextServer(rallyWinner: pointWinnerSide)

        evaluateGameAndMatchCompletion()
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

        if let matchWinner = ScoringRulesEngine.matchWinner(
            gamesWonByPlayer1: gamesWonByPlayer1,
            gamesWonByPlayer2: gamesWonByPlayer2,
            format: match.scoringFormat
        ) {
            isMatchOver = true
            match.status = .completed
            _ = matchWinner
        } else {
            isGameOver = true
        }
    }

    func startNextGame(firstServer: MatchSide) {
        currentGameNumber += 1
        player1Score = 0
        player2Score = 0
        currentServer = firstServer
        isGameOver = false
    }

    /// 直近のラリーを丸ごと取り消す（ShotもRallyのcascadeでまとめて削除される）。
    /// スコアは残っているラリーの scoreAfterRally から復元するので再計算ロジックを持たない。
    /// 取り消すラリーがゲームを決めたラリーだった場合は finalScoreSummary / 獲得ゲーム数も巻き戻す。
    /// （ゲーム境界をまたいだ取り消し、つまり次のゲームを開始した後に前のゲーム最後のラリーを
    /// 取り消すことはMVPでは未対応）
    func undoLastRally() {
        let currentGameRallies = match.rallies
            .filter { $0.gameNumber == currentGameNumber }
            .sorted { $0.orderIndex < $1.orderIndex }
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

extension LiveTaggingViewModel: Hashable {
    static func == (lhs: LiveTaggingViewModel, rhs: LiveTaggingViewModel) -> Bool {
        lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

import XCTest
@testable import BadmintonCoachApp

final class ScoringRulesEngineTests: XCTestCase {
    func testGameNotOverBelowPointsToWin() {
        XCTAssertNil(ScoringRulesEngine.gameWinner(player1Score: 15, player2Score: 19, format: .bestOf3To21))
    }

    func testGameOverWithClearMargin() {
        XCTAssertEqual(ScoringRulesEngine.gameWinner(player1Score: 21, player2Score: 15, format: .bestOf3To21), .player1)
    }

    func testGameNotOverWithoutTwoPointMargin() {
        XCTAssertNil(ScoringRulesEngine.gameWinner(player1Score: 21, player2Score: 20, format: .bestOf3To21))
    }

    func testGameOverWithDeuceMargin() {
        XCTAssertEqual(ScoringRulesEngine.gameWinner(player1Score: 22, player2Score: 20, format: .bestOf3To21), .player1)
    }

    func testGameNotOverAtCapWithoutLead() {
        XCTAssertNil(ScoringRulesEngine.gameWinner(player1Score: 29, player2Score: 29, format: .bestOf3To21))
    }

    func testGameOverAtCapIgnoresTwoPointRule() {
        XCTAssertEqual(ScoringRulesEngine.gameWinner(player1Score: 30, player2Score: 29, format: .bestOf3To21), .player1)
    }

    func testMatchWinnerRequiresEnoughGames() {
        XCTAssertNil(ScoringRulesEngine.matchWinner(gamesWonByPlayer1: 1, gamesWonByPlayer2: 0, format: .bestOf3To21))
        XCTAssertEqual(ScoringRulesEngine.matchWinner(gamesWonByPlayer1: 2, gamesWonByPlayer2: 0, format: .bestOf3To21), .player1)
    }

    func testSingleGameFormatMatchWinner() {
        XCTAssertEqual(ScoringRulesEngine.matchWinner(gamesWonByPlayer1: 1, gamesWonByPlayer2: 0, format: .singleGameTo21), .player1)
    }

    func testNextServerIsRallyWinner() {
        XCTAssertEqual(ScoringRulesEngine.nextServer(rallyWinner: .player2), .player2)
    }
}

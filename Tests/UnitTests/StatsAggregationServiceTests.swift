import XCTest
import SwiftData
@testable import BadmintonCoachApp

@MainActor
final class StatsAggregationServiceTests: XCTestCase {
    private func makeInMemoryContext() throws -> ModelContext {
        let configuration = ModelConfiguration(schema: Schema(SchemaV1.models), isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Schema(SchemaV1.models),
            migrationPlan: AppMigrationPlan.self,
            configurations: [configuration]
        )
        return container.mainContext
    }

    func testStatsComputesShotDistributionAndRallyLength() throws {
        let context = try makeInMemoryContext()
        let player1 = Student(name: "選手1")
        let player2 = Student(name: "選手2")
        context.insert(player1)
        context.insert(player2)

        let match = Match(status: .completed, player1: player1, player2: player2)
        context.insert(match)

        // ラリー1: 3打(serve, clear, smash)でplayer1のウィナー
        let rally1 = Rally(orderIndex: 0, serverPlayer: player1, player1ScoreAfterRally: 1, player2ScoreAfterRally: 0, endReason: .winner, match: match)
        context.insert(rally1)
        match.rallies.append(rally1)
        let shots1: [(ShotType, Student, ShotResult)] = [
            (.serve, player1, .inPlay),
            (.clear, player2, .inPlay),
            (.smash, player1, .winner)
        ]
        for (index, entry) in shots1.enumerated() {
            let shot = Shot(orderIndex: index, player: entry.1, shotType: entry.0, courtX: 0.5, courtY: 0.5, result: entry.2, rally: rally1)
            context.insert(shot)
            rally1.shots.append(shot)
        }

        // ラリー2: 1打(serve)でplayer2側のエラー(サービスフォルト扱い)
        let rally2 = Rally(orderIndex: 1, serverPlayer: player2, player1ScoreAfterRally: 2, player2ScoreAfterRally: 0, endReason: .unforcedError, match: match)
        context.insert(rally2)
        match.rallies.append(rally2)
        let errorShot = Shot(orderIndex: 0, player: player2, shotType: .serve, courtX: 0.1, courtY: 0.1, result: .unforcedError, rally: rally2)
        context.insert(errorShot)
        rally2.shots.append(errorShot)

        try context.save()

        let stats = StatsAggregationService.stats(for: match)

        XCTAssertEqual(stats.totalRallies, 2)
        XCTAssertEqual(stats.longestRallyLength, 3)
        XCTAssertEqual(stats.averageRallyLength, 2.0, accuracy: 0.001)
        XCTAssertEqual(stats.winnerShotCounts["選手1"], 1)
        XCTAssertEqual(stats.errorShotCounts["選手2"], 1)

        let serveCount = stats.shotTypeDistribution.first { $0.shotType == .serve }?.count
        XCTAssertEqual(serveCount, 2)
    }

    func testManualShotCountUsedInQuickMode() throws {
        let context = try makeInMemoryContext()
        let player1 = Student(name: "選手1")
        let player2 = Student(name: "選手2")
        context.insert(player1)
        context.insert(player2)

        let match = Match(player1: player1, player2: player2)
        context.insert(match)

        let rally = Rally(orderIndex: 0, serverPlayer: player1, player1ScoreAfterRally: 1, player2ScoreAfterRally: 0, endReason: .winner, manualShotCount: 12, match: match)
        context.insert(rally)
        match.rallies.append(rally)
        let shot = Shot(orderIndex: 0, player: player1, shotType: .smash, courtX: 0.5, courtY: 0.5, result: .winner, rally: rally)
        context.insert(shot)
        rally.shots.append(shot)

        try context.save()

        let stats = StatsAggregationService.stats(for: match)
        XCTAssertEqual(stats.longestRallyLength, 12, "簡易モードではmanualShotCountが実際の打数として優先されるべき")
    }
}

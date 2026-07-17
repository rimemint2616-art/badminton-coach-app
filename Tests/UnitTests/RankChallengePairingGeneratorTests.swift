import XCTest
@testable import BadmintonCoachApp

final class RankChallengePairingGeneratorTests: XCTestCase {
    func testRoundRobinWithoutBlocksGeneratesAllPairs() {
        let students = (1...4).map { Student(name: "選手\($0)") }
        let pairings = RankChallengePairingGenerator.generate(participants: students, blockCount: 1)

        // 4人総当たりなら組み合わせは 4C2 = 6
        XCTAssertEqual(pairings.count, 6)
        XCTAssertTrue(pairings.allSatisfy { $0.blockName == nil })

        let names = Set(pairings.map { Set([$0.player1.name, $0.player2.name]) })
        XCTAssertEqual(names.count, 6, "同じ組み合わせが重複していないこと")
    }

    func testBlockDivisionSplitsParticipantsAndOnlyPairsWithinBlock() {
        let students = (1...6).map { Student(name: "選手\($0)") }
        let pairings = RankChallengePairingGenerator.generate(participants: students, blockCount: 2)

        // 6人を2ブロックに分けると各ブロック3人 → 各ブロック 3C2 = 3試合、計6試合
        XCTAssertEqual(pairings.count, 6)

        let blockNames = Set(pairings.compactMap { $0.blockName })
        XCTAssertEqual(blockNames, ["Aブロック", "Bブロック"])

        for pairing in pairings {
            XCTAssertNotNil(pairing.blockName)
        }
    }

    func testFewerThanTwoParticipantsProducesNoPairings() {
        XCTAssertTrue(RankChallengePairingGenerator.generate(participants: [], blockCount: 1).isEmpty)
        XCTAssertTrue(RankChallengePairingGenerator.generate(participants: [Student(name: "単独")], blockCount: 1).isEmpty)
    }

    func testRankOrderDistributionDealsRoundRobinLikeCards() {
        // ランク1〜9を3ブロックに分けると、1,4,7 / 2,5,8 / 3,6,9 のように
        // 1人ずつ順番に各ブロックへ配られるはず。
        let students = (1...9).map { Student(name: "選手\($0)", rank: $0) }
        let pairings = RankChallengePairingGenerator.generate(participants: students, blockCount: 3, mode: .byRank)

        func block(containing rank: Int) -> Set<Int> {
            let pairing = pairings.first { $0.player1.rank == rank || $0.player2.rank == rank }!
            return Set(pairings.filter { $0.blockName == pairing.blockName }
                .flatMap { [$0.player1.rank, $0.player2.rank] }
                .compactMap { $0 })
        }

        XCTAssertEqual(block(containing: 1), [1, 4, 7])
        XCTAssertEqual(block(containing: 2), [2, 5, 8])
        XCTAssertEqual(block(containing: 3), [3, 6, 9])
    }

    func testRandomModeStillCoversAllParticipantsExactlyOnce() {
        let students = (1...9).map { Student(name: "選手\($0)", rank: $0) }
        let pairings = RankChallengePairingGenerator.generate(participants: students, blockCount: 3, mode: .random)

        let allIDs = pairings.flatMap { [$0.player1.id, $0.player2.id] }
        XCTAssertEqual(Set(allIDs).count, 9, "ランダムモードでも全員が過不足なく振り分けられること")
    }

    func testPreviewBlockSizesMatchesActualGeneration() {
        let students = (1...11).map { Student(name: "選手\($0)", rank: $0) }
        let sizes = RankChallengePairingGenerator.previewBlockSizes(participants: students, blockCount: 3)

        XCTAssertEqual(sizes.reduce(0, +), 11)
        XCTAssertEqual(Set(sizes), [3, 4])

        let pairings = RankChallengePairingGenerator.generate(participants: students, blockCount: 3)
        let actualSizes = RankChallengePairingGenerator.blockLabels.prefix(3).map { label in
            Set(pairings.filter { $0.blockName == "\(label)ブロック" }
                .flatMap { [$0.player1.id, $0.player2.id] }).count
        }
        XCTAssertEqual(actualSizes, sizes, "previewBlockSizesは実際にgenerateされる各ブロックの人数と一致すること")
    }

    func testCustomBlockSizesAreRespected() {
        let students = (1...11).map { Student(name: "選手\($0)", rank: $0) }
        let customSizes = [5, 3, 3]
        let pairings = RankChallengePairingGenerator.generate(participants: students, blockCount: 3, blockSizes: customSizes)

        let actualSizes = RankChallengePairingGenerator.blockLabels.prefix(3).map { label in
            Set(pairings.filter { $0.blockName == "\(label)ブロック" }
                .flatMap { [$0.player1.id, $0.player2.id] }).count
        }
        XCTAssertEqual(actualSizes, customSizes)
    }

    func testMatchNumbersAreSequentialWithinEachBlock() {
        let students = (1...4).map { Student(name: "選手\($0)", rank: $0) }
        let pairings = RankChallengePairingGenerator.generate(participants: students, blockCount: 1)

        XCTAssertEqual(Set(pairings.map(\.matchNumber)), Set(1...6))
    }

    func testStandingsCalculatorRanksByWinsThenPointDifference() {
        let a = Student(name: "A")
        let b = Student(name: "B")
        let c = Student(name: "C")

        let pairing1 = RankChallengePairing(player1: a, player2: b, player1Score: 21, player2Score: 15)
        let pairing2 = RankChallengePairing(player1: a, player2: c, player1Score: 10, player2Score: 21)
        let pairing3 = RankChallengePairing(player1: b, player2: c, player1Score: 21, player2Score: 18)

        let standings = RankChallengeStandingCalculator.standings(for: [pairing1, pairing2, pairing3], participants: [a, b, c])

        // 全員1勝1敗なので得失点差で並ぶはず（C:+8, B:+3, A:-5）
        XCTAssertEqual(standings.map(\.student.name), ["C", "B", "A"])
        XCTAssertEqual(standings.map(\.wins), [1, 1, 1])
    }
}

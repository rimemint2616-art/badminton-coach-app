import XCTest
@testable import BadmintonCoachApp

final class RankChallengeStageGeneratorTests: XCTestCase {
    /// 予選イベントを組み立てるヘルパー。2ブロック×3人、各ブロックとも
    /// 1人目が全勝、2人目が1勝、3人目が全敗になるよう結果を仕込む。
    private func makePreliminaryEvent() -> (event: RankChallengeEvent, players: [String: Student]) {
        let a1 = Student(name: "a1")
        let a2 = Student(name: "a2")
        let a3 = Student(name: "a3")
        let b1 = Student(name: "b1")
        let b2 = Student(name: "b2")
        let b3 = Student(name: "b3")

        let event = RankChallengeEvent(name: "予選", useBlocks: true, participants: [a1, a2, a3, b1, b2, b3])

        func addPairing(_ block: String, _ number: Int, _ p1: Student, _ p2: Student, _ s1: Int, _ s2: Int) {
            let pairing = RankChallengePairing(blockName: block, matchNumber: number, player1: p1, player2: p2, player1Score: s1, player2Score: s2, event: event)
            event.pairings.append(pairing)
        }

        addPairing("Aブロック", 1, a1, a2, 21, 15)
        addPairing("Aブロック", 2, a1, a3, 21, 10)
        addPairing("Aブロック", 3, a2, a3, 21, 18)
        addPairing("Bブロック", 1, b1, b2, 21, 15)
        addPairing("Bブロック", 2, b1, b3, 21, 10)
        addPairing("Bブロック", 3, b2, b3, 21, 18)

        return (event, ["a1": a1, "a2": a2, "a3": a3, "b1": b1, "b2": b2, "b3": b3])
    }

    func testPositionGroupShapesGroupByFinishingPosition() {
        let (event, _) = makePreliminaryEvent()
        let shapes = RankChallengeStageGenerator.positionGroupShapes(from: event)

        XCTAssertEqual(shapes.map(\.name), ["1位ブロック", "2位ブロック", "3位ブロック"])
        XCTAssertEqual(shapes.map(\.position), [0, 1, 2])
        XCTAssertTrue(shapes.allSatisfy { Set($0.sourceBlocks) == Set(["Aブロック", "Bブロック"]) })
    }

    func testPositionGroupShapesWorkEvenWithNoResultsYet() {
        // 結果が1件も無くても、ブロックの人数だけから「形」は決まるはず。
        let a1 = Student(name: "a1")
        let a2 = Student(name: "a2")
        let b1 = Student(name: "b1")
        let b2 = Student(name: "b2")
        let event = RankChallengeEvent(name: "予選", useBlocks: true, participants: [a1, a2, b1, b2])
        event.pairings.append(RankChallengePairing(blockName: "Aブロック", matchNumber: 1, player1: a1, player2: a2, event: event))
        event.pairings.append(RankChallengePairing(blockName: "Bブロック", matchNumber: 1, player1: b1, player2: b2, event: event))

        let shapes = RankChallengeStageGenerator.positionGroupShapes(from: event)
        XCTAssertEqual(shapes.map(\.name), ["1位ブロック", "2位ブロック"])
    }

    func testGeneratePairingsForShapesCreatesOneMatchPerPair() {
        let (event, _) = makePreliminaryEvent()
        let shapes = RankChallengeStageGenerator.positionGroupShapes(from: event)
        let generated = RankChallengeStageGenerator.generatePairings(forShapes: shapes)

        // 各グループ2ブロック分なので、1グループにつき1試合、計3試合。
        XCTAssertEqual(generated.count, 3)
        XCTAssertEqual(Set(generated.map(\.blockName)), Set(["1位ブロック", "2位ブロック", "3位ブロック"]))
        XCTAssertTrue(generated.allSatisfy { $0.source1.position == $0.source2.position })
    }

    func testResolvingSourcedPairingsPicksCurrentStandings() {
        let (event, players) = makePreliminaryEvent()
        let shapes = RankChallengeStageGenerator.positionGroupShapes(from: event)
        let generated = RankChallengeStageGenerator.generatePairings(forShapes: shapes)

        let finalsEvent = RankChallengeEvent(name: "決勝", useBlocks: true, stageKind: .finals, previousStage: event)
        let pairings = generated.map { item in
            RankChallengePairing(
                blockName: item.blockName,
                matchNumber: item.matchNumber,
                sourceBlockName1: item.source1.blockName,
                sourcePosition1: item.source1.position,
                sourceBlockName2: item.source2.blockName,
                sourcePosition2: item.source2.position,
                event: finalsEvent
            )
        }
        finalsEvent.pairings.append(contentsOf: pairings)

        for pairing in pairings {
            pairing.syncPlayersFromSource(previousStage: event)
        }

        let firstPlaceCard = pairings.first { $0.blockName == "1位ブロック" }!
        XCTAssertEqual(Set([firstPlaceCard.player1?.id, firstPlaceCard.player2?.id]), Set([players["a1"]!.id, players["b1"]!.id]))
    }

    func testPromotionPlayoffPairsAdjacentBlockBoundaries() {
        let (prelimEvent, players) = makePreliminaryEvent()
        let shapes = RankChallengeStageGenerator.positionGroupShapes(from: prelimEvent)
        let generated = RankChallengeStageGenerator.generatePairings(forShapes: shapes)

        let finalsEvent = RankChallengeEvent(name: "決勝", useBlocks: true, stageKind: .finals, previousStage: prelimEvent)
        let a1 = players["a1"]!, b1 = players["b1"]!
        let a2 = players["a2"]!, b2 = players["b2"]!
        let a3 = players["a3"]!, b3 = players["b3"]!

        // 決勝ブロックを組み立てる: 1位ブロックはa1が勝つ、2位ブロックはb2が勝つ、3位ブロックはa3が勝つ。
        _ = generated
        finalsEvent.pairings.append(RankChallengePairing(blockName: "1位ブロック", matchNumber: 1, player1: a1, player2: b1, player1Score: 2, player2Score: 0, event: finalsEvent))
        finalsEvent.pairings.append(RankChallengePairing(blockName: "2位ブロック", matchNumber: 1, player1: a2, player2: b2, player1Score: 0, player2Score: 2, event: finalsEvent))
        finalsEvent.pairings.append(RankChallengePairing(blockName: "3位ブロック", matchNumber: 1, player1: a3, player2: b3, player1Score: 2, player2Score: 0, event: finalsEvent))

        let playoffs = RankChallengeStageGenerator.promotionPlayoffPairings(from: finalsEvent)

        XCTAssertEqual(playoffs.count, 2, "3ブロックなら境界は2つ（1位⇔2位、2位⇔3位）")

        let boundary1 = playoffs[0]
        XCTAssertEqual(boundary1.source1.blockName, "1位ブロック")
        XCTAssertEqual(boundary1.source1.position, 1, "1位ブロックの最下位(2番目, index=1)")
        XCTAssertEqual(boundary1.source2.blockName, "2位ブロック")
        XCTAssertEqual(boundary1.source2.position, 0, "2位ブロックの最上位")

        let boundary2 = playoffs[1]
        XCTAssertEqual(boundary2.source1.blockName, "2位ブロック")
        XCTAssertEqual(boundary2.source2.blockName, "3位ブロック")
    }

    func testPositionGroupShapesRequiresAtLeastTwoBlocks() {
        let event = RankChallengeEvent(name: "単一ブロック", useBlocks: false)
        XCTAssertTrue(RankChallengeStageGenerator.positionGroupShapes(from: event).isEmpty)
    }
}

import Foundation

/// 予選ブロックの結果から決勝ブロック（1位ブロック・2位ブロックなど）を、
/// 決勝ブロックの結果から入れ替え戦のカードを作るための純粋関数群。
///
/// 生成するカードはplayer1/player2を固定値では持たず、「前段階のこのブロックの
/// この順位」という参照（sourceBlockName/sourcePosition）だけを持つ。予選が全部
/// 終わっていない空の状態でも決勝ブロックの「形」自体はブロック人数から確定できるため、
/// 作成した直後は暫定の並び（未消化なら同着扱い）で埋まり、以後は結果が入るたびに
/// RankChallengePairing.syncPlayersFromSource(previousStage:)で自動的に更新される。
enum RankChallengeStageGenerator {
    /// 位置グループの「形」。例:「1位ブロック」は予選のA/B/Cブロックそれぞれの1位（0位）から成る。
    struct PositionGroupShape {
        let name: String
        let position: Int
        let sourceBlocks: [String]
    }

    /// 前段階のあるブロックの、特定の順位を指す参照。
    struct SourceRef {
        let blockName: String
        let position: Int
    }

    /// 前段階から作る新しいカード1件分。player1/player2は決めず、参照のみ持つ。
    struct SourcedPairing {
        let blockName: String
        let matchNumber: Int
        let source1: SourceRef
        let source2: SourceRef
    }

    /// 予選イベントの各ブロックの人数から、決勝用のクロス編成グループの「形」を作る。
    /// ブロックの人数だけで決まるため、結果が1件も入っていなくても呼び出せる。
    static func positionGroupShapes(from event: RankChallengeEvent) -> [PositionGroupShape] {
        let blocks = event.blockNames
        guard blocks.count >= 2 else { return [] }

        let sizeByBlock = Dictionary(uniqueKeysWithValues: blocks.map { block -> (String, Int) in
            let ids = Set(event.pairings(inBlock: block).flatMap { [$0.player1?.id, $0.player2?.id].compactMap { $0 } })
            return (block, ids.count)
        })
        let maxPosition = sizeByBlock.values.max() ?? 0

        var shapes: [PositionGroupShape] = []
        for position in 0..<maxPosition {
            let contributingBlocks = blocks.filter { (sizeByBlock[$0] ?? 0) > position }
            if contributingBlocks.count >= 2 {
                shapes.append(PositionGroupShape(name: "\(position + 1)位ブロック", position: position, sourceBlocks: contributingBlocks))
            }
        }
        return shapes
    }

    /// 各位置グループの「形」から、グループ内総当たりのカード（参照のみ）を生成する。
    static func generatePairings(forShapes shapes: [PositionGroupShape]) -> [SourcedPairing] {
        var result: [SourcedPairing] = []
        for shape in shapes {
            var matchNumber = 1
            for i in 0..<shape.sourceBlocks.count {
                for j in (i + 1)..<shape.sourceBlocks.count {
                    result.append(
                        SourcedPairing(
                            blockName: shape.name,
                            matchNumber: matchNumber,
                            source1: SourceRef(blockName: shape.sourceBlocks[i], position: shape.position),
                            source2: SourceRef(blockName: shape.sourceBlocks[j], position: shape.position)
                        )
                    )
                    matchNumber += 1
                }
            }
        }
        return result
    }

    /// 決勝ブロックの人数から、隣接するブロック間の入れ替え戦カード（参照のみ）を作る
    /// （例: 1位ブロック最下位 vs 2位ブロック最上位）。
    static func promotionPlayoffPairings(from finalsEvent: RankChallengeEvent) -> [SourcedPairing] {
        let blocks = finalsEvent.blockNames
        guard blocks.count >= 2 else { return [] }

        let sizeByBlock = Dictionary(uniqueKeysWithValues: blocks.map { block -> (String, Int) in
            let ids = Set(finalsEvent.pairings(inBlock: block).flatMap { [$0.player1?.id, $0.player2?.id].compactMap { $0 } })
            return (block, ids.count)
        })

        var result: [SourcedPairing] = []
        for i in 0..<(blocks.count - 1) {
            let upperBlock = blocks[i]
            let lowerBlock = blocks[i + 1]
            let upperLastPosition = (sizeByBlock[upperBlock] ?? 0) - 1
            guard upperLastPosition >= 0 else { continue }

            result.append(
                SourcedPairing(
                    blockName: "\(upperBlock)⇔\(lowerBlock)入れ替え戦",
                    matchNumber: 1,
                    source1: SourceRef(blockName: upperBlock, position: upperLastPosition),
                    source2: SourceRef(blockName: lowerBlock, position: 0)
                )
            )
        }
        return result
    }
}

import Foundation

/// ランク戦の組み合わせ（総当たり、または複数ブロックに分けての総当たり）を生成する。
enum RankChallengePairingGenerator {
    struct GeneratedPairing {
        let blockName: String?
        let matchNumber: Int
        let player1: Student
        let player2: Student
    }

    /// ブロックへの振り分け順。ランク順なら1,4,7 / 2,5,8 / 3,6,9のように配る。
    enum DistributionMode: Hashable {
        case byRank
        case random
    }

    static let blockLabels = ["A", "B", "C", "D", "E", "F", "G", "H"]

    /// 参加者数をブロック数に均等に分けたときの、各ブロックの人数（ブロック順）。
    /// 組み合わせを作る前に「4人・4人・3人になります」とコーチへ確認するために使う。
    static func evenBlockSizes(participantCount: Int, blockCount: Int) -> [Int] {
        guard blockCount >= 1 else { return [participantCount] }
        let base = participantCount / blockCount
        let remainder = participantCount % blockCount
        return (0..<blockCount).map { $0 < remainder ? base + 1 : base }
    }

    /// `blockCount`が1以下なら参加者全員での単純な総当たり、2以上ならブロックに分けたうえで
    /// ブロック内総当たりの組み合わせを生成する。
    /// `blockSizes`を指定すると、そのブロックごとの人数に従って振り分ける
    /// （省略時は`evenBlockSizes`で均等に近い人数を自動計算する）。
    static func generate(
        participants: [Student],
        blockCount: Int,
        mode: DistributionMode = .byRank,
        blockSizes: [Int]? = nil
    ) -> [GeneratedPairing] {
        guard participants.count >= 2 else { return [] }

        if blockCount <= 1 {
            return roundRobinPairings(in: participants, blockName: nil)
        }

        let blocks = distributeIntoBlocks(
            participants: participants,
            blockCount: blockCount,
            mode: mode,
            blockSizes: blockSizes
        )

        var result: [GeneratedPairing] = []
        for (index, block) in blocks.enumerated() where block.count >= 2 {
            let blockName = index < blockLabels.count ? "\(blockLabels[index])ブロック" : "第\(index + 1)ブロック"
            result.append(contentsOf: roundRobinPairings(in: block, blockName: blockName))
        }
        return result
    }

    /// 参加者を各ブロックへ振り分けた結果（人数の確認・プレビュー用）。
    static func previewDistribution(
        participants: [Student],
        blockCount: Int,
        mode: DistributionMode = .byRank,
        blockSizes: [Int]? = nil
    ) -> [[Student]] {
        distributeIntoBlocks(participants: participants, blockCount: blockCount, mode: mode, blockSizes: blockSizes)
    }

    /// 各ブロックの人数だけを知りたいとき用（内訳の確認ダイアログなどで使う）。
    static func previewBlockSizes(
        participants: [Student],
        blockCount: Int,
        mode: DistributionMode = .byRank,
        blockSizes: [Int]? = nil
    ) -> [Int] {
        previewDistribution(participants: participants, blockCount: blockCount, mode: mode, blockSizes: blockSizes).map(\.count)
    }

    /// 参加者を並べ替えたうえで（ランク順、またはランダム）、指定の人数枠に順番に配っていく。
    /// 枠が均等なら「1人目→ブロックA、2人目→ブロックB、3人目→ブロックC、4人目→ブロックA…」
    /// と一巡ごとに割り振るので、ランク順モードでは 1,4,7 / 2,5,8 / 3,6,9 のような
    /// 組み合わせになる。
    private static func distributeIntoBlocks(
        participants: [Student],
        blockCount: Int,
        mode: DistributionMode,
        blockSizes: [Int]?
    ) -> [[Student]] {
        guard blockCount >= 1 else { return [participants] }

        let ordered: [Student]
        switch mode {
        case .byRank:
            ordered = participants.sorted { lhs, rhs in
                switch (lhs.rank, rhs.rank) {
                case let (l?, r?): return l < r
                case (nil, nil): return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                case (nil, _): return false
                case (_, nil): return true
                }
            }
        case .random:
            ordered = participants.shuffled()
        }

        var capacities = blockSizes ?? evenBlockSizes(participantCount: participants.count, blockCount: blockCount)
        // blockSizesの合計が参加者数と食い違う場合でも配りきれるよう、不足分は均等割りで補う。
        if capacities.count != blockCount {
            capacities = evenBlockSizes(participantCount: participants.count, blockCount: blockCount)
        }

        var blocks: [[Student]] = Array(repeating: [], count: blockCount)
        var blockIndex = 0
        var attempts = 0
        for student in ordered {
            while capacities[blockIndex] <= 0 && attempts < blockCount {
                blockIndex = (blockIndex + 1) % blockCount
                attempts += 1
            }
            attempts = 0
            blocks[blockIndex].append(student)
            capacities[blockIndex] -= 1
            blockIndex = (blockIndex + 1) % blockCount
        }
        return blocks
    }

    private static func roundRobinPairings(in group: [Student], blockName: String?) -> [GeneratedPairing] {
        var result: [GeneratedPairing] = []
        var matchNumber = 1
        for i in 0..<group.count {
            for j in (i + 1)..<group.count {
                result.append(GeneratedPairing(blockName: blockName, matchNumber: matchNumber, player1: group[i], player2: group[j]))
                matchNumber += 1
            }
        }
        return result
    }
}

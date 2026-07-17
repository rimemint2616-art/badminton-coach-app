import Foundation
import SwiftData

/// ランク戦のどの段階か。予選の結果から決勝ブロックを、決勝の結果から入れ替え戦を
/// 手動で作成していく想定。
enum RankChallengeStageKind: String, Codable {
    case preliminary
    case finals
    case promotionPlayoff

    var displayName: String {
        switch self {
        case .preliminary: return "予選"
        case .finals: return "決勝"
        case .promotionPlayoff: return "入れ替え戦"
        }
    }

    /// この段階のカードから試合を開始したとき、Matchに自動で付与するタグ。
    var matchTag: MatchTag {
        switch self {
        case .preliminary: return .rankChallengePreliminary
        case .finals: return .rankChallengeFinals
        case .promotionPlayoff: return .rankChallengePromotion
        }
    }
}

/// 部内のランク戦（総当たり、または複数ブロックに分けての総当たり）1回分。
@Model
final class RankChallengeEvent {
    var id: UUID
    var name: String
    var date: Date
    /// ブロックに分けたかどうか。falseなら参加者全員での総当たり。
    var useBlocks: Bool
    var stageKindRawValue: String

    @Relationship var participants: [Student] = []

    /// この大会の組み合わせ。イベント削除時にまとめて削除（.cascade）。
    @Relationship(deleteRule: .cascade, inverse: \RankChallengePairing.event)
    var pairings: [RankChallengePairing] = []

    /// 元になった前段階（決勝なら予選、入れ替え戦なら決勝）。予選ならnil。
    var previousStage: RankChallengeEvent?

    /// このイベントから作られた次の段階（決勝・入れ替え戦）。イベント削除時はnilに戻る（.nullify）。
    @Relationship(deleteRule: .nullify, inverse: \RankChallengeEvent.previousStage)
    var nextStages: [RankChallengeEvent] = []

    var stageKind: RankChallengeStageKind {
        get { RankChallengeStageKind(rawValue: stageKindRawValue) ?? .preliminary }
        set { stageKindRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        date: Date = .now,
        useBlocks: Bool = false,
        participants: [Student] = [],
        stageKind: RankChallengeStageKind = .preliminary,
        previousStage: RankChallengeEvent? = nil
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.useBlocks = useBlocks
        self.participants = participants
        self.stageKindRawValue = stageKind.rawValue
        self.previousStage = previousStage
    }

    /// ブロック名の一覧。ブロック分けしていない場合は空。
    /// pairingsはSwiftDataのリレーションのため取得順が安定しないので、必ず並べ直す。
    /// 「1位ブロック」のように数字から始まる名前は数字順、それ以外
    /// （「Aブロック」など）は文字列順（A→B→C…）で並ぶようにする。
    var blockNames: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for pairing in pairings {
            if let block = pairing.blockName, !seen.contains(block) {
                seen.insert(block)
                result.append(block)
            }
        }
        return result.sorted { lhs, rhs in
            let l = Self.leadingNumber(in: lhs)
            let r = Self.leadingNumber(in: rhs)
            if let l, let r, l != r { return l < r }
            return lhs < rhs
        }
    }

    private static func leadingNumber(in text: String) -> Int? {
        let digits = text.prefix(while: \.isNumber)
        return digits.isEmpty ? nil : Int(digits)
    }

    func pairings(inBlock block: String?) -> [RankChallengePairing] {
        pairings.filter { $0.blockName == block }
    }

    /// ブロックごと（ブロック分けなしなら全体で1つ）の順位表。
    /// 参加者はstage.participants（決勝・入れ替え戦では予選の結果次第で更新が遅れうる）
    /// ではなく、そのブロックの対戦カードのplayer1/player2から直接求める。こうすることで、
    /// 決勝・入れ替え戦のカードの中身が随時解決され続けても順位表が必ず一致するようにする。
    func standings(inBlock block: String?) -> [RankChallengeStanding] {
        let blockPairings = pairings(inBlock: block)
        var seen = Set<UUID>()
        var blockParticipants: [Student] = []
        for pairing in blockPairings {
            for candidate in [pairing.player1, pairing.player2].compactMap({ $0 }) where !seen.contains(candidate.id) {
                seen.insert(candidate.id)
                blockParticipants.append(candidate)
            }
        }
        return RankChallengeStandingCalculator.standings(for: blockPairings, participants: blockParticipants)
    }

    /// 全ブロックの順位表をブロック順（決勝なら1位ブロック→2位ブロック…）に連結した、
    /// 大会全体としての総合順位。決勝ブロックのように、ブロックの並び順そのものが
    /// 実力順を意味する場合に使う。
    var overallStandings: [RankChallengeStanding] {
        let blocks: [String?] = useBlocks ? blockNames : [nil]
        return blocks.flatMap { standings(inBlock: $0) }
    }

    /// 組み合わせが1件以上あり、全て結果が入っているか（次の段階を作れる状態か）。
    var isFullyCompleted: Bool {
        !pairings.isEmpty && pairings.allSatisfy(\.isCompleted)
    }
}

/// ランク戦の1組み合わせ（対戦カード）。結果は後からスコアを入力する。
@Model
final class RankChallengePairing {
    var id: UUID
    /// ブロック分けした場合の所属ブロック名（例:「Aブロック」）。分けていなければnil。
    var blockName: String?
    /// ブロック内の対戦番号（1始まり）。対戦表のセルに「A5」のように表示する。
    var matchNumber: Int
    var player1: Student?
    var player2: Student?
    var player1Score: Int?
    var player2Score: Int?

    /// player1/player2を固定値ではなく「前段階のこのブロックのこの順位」から都度解決したい場合に使う
    /// （決勝ブロック・入れ替え戦で、予選の結果が随時反映されて対戦カードが埋まっていくようにするため）。
    /// nilなら通常どおりplayer1/player2をそのまま使う。
    var sourceBlockName1: String?
    var sourcePosition1: Int?
    var sourceBlockName2: String?
    var sourcePosition2: Int?

    /// 対戦表のセルをタップして開始した実際の試合記録。Match削除時はnilに戻る（.nullify）。
    @Relationship(deleteRule: .nullify, inverse: \Match.rankChallengePairing)
    var match: Match?

    var event: RankChallengeEvent?

    init(
        id: UUID = UUID(),
        blockName: String? = nil,
        matchNumber: Int = 0,
        player1: Student? = nil,
        player2: Student? = nil,
        player1Score: Int? = nil,
        player2Score: Int? = nil,
        sourceBlockName1: String? = nil,
        sourcePosition1: Int? = nil,
        sourceBlockName2: String? = nil,
        sourcePosition2: Int? = nil,
        match: Match? = nil,
        event: RankChallengeEvent? = nil
    ) {
        self.id = id
        self.blockName = blockName
        self.matchNumber = matchNumber
        self.player1 = player1
        self.player2 = player2
        self.player1Score = player1Score
        self.player2Score = player2Score
        self.sourceBlockName1 = sourceBlockName1
        self.sourcePosition1 = sourcePosition1
        self.sourceBlockName2 = sourceBlockName2
        self.sourcePosition2 = sourcePosition2
        self.match = match
        self.event = event
    }

    /// 前段階（予選/決勝）の現在の順位から、player1/player2を解決し直す。
    /// まだ試合を開始していない（matchがnil）カードのみ更新する。結果が随時反映されて
    /// 対戦カードが埋まっていくようにするための仕組み。
    func syncPlayersFromSource(previousStage: RankChallengeEvent?) {
        guard match == nil else { return }
        if let sourceBlockName1, let sourcePosition1 {
            let standings = previousStage?.standings(inBlock: sourceBlockName1) ?? []
            player1 = sourcePosition1 < standings.count ? standings[sourcePosition1].student : nil
        }
        if let sourceBlockName2, let sourcePosition2 {
            let standings = previousStage?.standings(inBlock: sourceBlockName2) ?? []
            player2 = sourcePosition2 < standings.count ? standings[sourcePosition2].student : nil
        }
    }

    /// ブロック対戦表のセルに表示する対戦コード（例:「A5」）。
    var matchCode: String {
        let letter = blockName?.first.map(String.init) ?? ""
        return "\(letter)\(matchNumber)"
    }

    /// 紐づくMatchが終了していれば、そのゲーム勝敗数をスコアとして保存領域(player1Score/player2Score)にも
    /// 書き戻しておく。表示・順位計算自体はcurrentPlayer1Score/currentPlayer2Scoreが常にMatchから
    /// 直接ライブで読むため必須ではないが、後でMatchが削除された場合にも結果を失わないための保険。
    func syncScoreFromMatch() {
        guard let match, match.status == .completed else { return }
        player1Score = match.finalScoreSummary.filter { $0.player1Score > $0.player2Score }.count
        player2Score = match.finalScoreSummary.filter { $0.player2Score > $0.player1Score }.count
    }

    /// 表示・順位計算に使うスコア。紐づくMatchが終了していればそこから直接読み、
    /// なければ保存済みのスコア（Matchが無い/未確定の場合や手入力のテストデータ用）を返す。
    /// こうすることで、明示的な同期(syncScoreFromMatch)を挟まなくても、Matchの結果が
    /// 変わった瞬間に対戦表・順位表が自動的に更新される。
    var currentPlayer1Score: Int? {
        if let match, match.status == .completed {
            return match.finalScoreSummary.filter { $0.player1Score > $0.player2Score }.count
        }
        return player1Score
    }

    var currentPlayer2Score: Int? {
        if let match, match.status == .completed {
            return match.finalScoreSummary.filter { $0.player2Score > $0.player1Score }.count
        }
        return player2Score
    }

    var isCompleted: Bool { currentPlayer1Score != nil && currentPlayer2Score != nil }

    var winner: Student? {
        guard let s1 = currentPlayer1Score, let s2 = currentPlayer2Score, s1 != s2 else { return nil }
        return s1 > s2 ? player1 : player2
    }

    /// player1/player2がまだ解決されていない(決勝・入れ替え戦で前段階の順位待ち)場合は「未定」、
    /// 対戦相手が生徒データごと削除された場合も同じ表示になる（このアプリでは実質起こらない想定）。
    var player1DisplayName: String { player1?.name ?? "未定" }
    var player2DisplayName: String { player2?.name ?? "未定" }
}

/// 順位表の1行。
struct RankChallengeStanding: Identifiable {
    let student: Student
    let wins: Int
    let losses: Int
    let pointsFor: Int
    let pointsAgainst: Int

    var id: UUID { student.id }
    var pointDifference: Int { pointsFor - pointsAgainst }
}

/// 順位決定ロジック: 勝利ゲーム数 → 得失点差 → その中(同点者同士)の対戦成績、の順で決める。
enum RankChallengeStandingCalculator {
    static func standings(for pairings: [RankChallengePairing], participants: [Student]) -> [RankChallengeStanding] {
        var winsByID: [UUID: Int] = [:]
        var lossesByID: [UUID: Int] = [:]
        var forByID: [UUID: Int] = [:]
        var againstByID: [UUID: Int] = [:]

        for pairing in pairings {
            guard let p1 = pairing.player1, let p2 = pairing.player2,
                  let s1 = pairing.currentPlayer1Score, let s2 = pairing.currentPlayer2Score else { continue }
            forByID[p1.id, default: 0] += s1
            againstByID[p1.id, default: 0] += s2
            forByID[p2.id, default: 0] += s2
            againstByID[p2.id, default: 0] += s1
            if s1 > s2 {
                winsByID[p1.id, default: 0] += 1
                lossesByID[p2.id, default: 0] += 1
            } else if s2 > s1 {
                winsByID[p2.id, default: 0] += 1
                lossesByID[p1.id, default: 0] += 1
            }
        }

        let standings = participants.map { student in
            RankChallengeStanding(
                student: student,
                wins: winsByID[student.id] ?? 0,
                losses: lossesByID[student.id] ?? 0,
                pointsFor: forByID[student.id] ?? 0,
                pointsAgainst: againstByID[student.id] ?? 0
            )
        }

        let grouped = Dictionary(grouping: standings) { TieKey(wins: $0.wins, diff: $0.pointDifference) }
        let orderedKeys = grouped.keys.sorted { lhs, rhs in
            if lhs.wins != rhs.wins { return lhs.wins > rhs.wins }
            return lhs.diff > rhs.diff
        }

        var result: [RankChallengeStanding] = []
        for key in orderedKeys {
            let group = grouped[key] ?? []
            result.append(contentsOf: group.count > 1 ? breakTie(group, pairings: pairings) : group)
        }
        return result
    }

    private struct TieKey: Hashable {
        let wins: Int
        let diff: Int
    }

    /// 勝利数・得失点差が同点のグループ内を、その中だけの対戦成績（直接対決の勝ち数）で並べ直す。
    /// それでも同点なら名前順にフォールバックする。
    private static func breakTie(_ group: [RankChallengeStanding], pairings: [RankChallengePairing]) -> [RankChallengeStanding] {
        let ids = Set(group.map(\.student.id))
        var headToHeadWins: [UUID: Int] = [:]
        for pairing in pairings {
            guard let p1 = pairing.player1, let p2 = pairing.player2, ids.contains(p1.id), ids.contains(p2.id),
                  let s1 = pairing.currentPlayer1Score, let s2 = pairing.currentPlayer2Score, s1 != s2 else { continue }
            if s1 > s2 {
                headToHeadWins[p1.id, default: 0] += 1
            } else {
                headToHeadWins[p2.id, default: 0] += 1
            }
        }
        return group.sorted { lhs, rhs in
            let l = headToHeadWins[lhs.student.id] ?? 0
            let r = headToHeadWins[rhs.student.id] ?? 0
            if l != r { return l > r }
            return lhs.student.name.localizedStandardCompare(rhs.student.name) == .orderedAscending
        }
    }
}

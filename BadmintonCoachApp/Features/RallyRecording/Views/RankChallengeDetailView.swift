import SwiftUI
import SwiftData

/// ランク戦1系統（予選→決勝→入れ替え戦）の詳細。上部のタブで段階を切り替えて表示する。
/// ブロックごとに対戦表（グリッド）と順位表を表示し、マスをタップすると自動的にその対戦の
/// 試合記録を開始できる。ブロックの人数が2人以下、または入れ替え戦の対戦は対戦表にせず
/// 一覧形式で表示する。人数が多すぎてグリッドが大きくなりすぎる場合も一覧形式に切り替える。
struct RankChallengeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var event: RankChallengeEvent
    @State private var activeMatch: Match?
    @State private var isPresentingSwap = false
    @State private var selectedTabKey: String
    @State private var isPresentingFinalsConfirmation = false
    @State private var pendingFinalsShapes: [RankChallengeStageGenerator.PositionGroupShape] = []
    @State private var pendingFinalsSourceStage: RankChallengeEvent?
    @State private var isPresentingRankReflectionConfirmation = false
    private let japanese = Locale(identifier: "ja_JP")

    /// この人数を超えるブロックは、グリッドが大きくなりすぎるため一覧形式で表示する。
    private let gridDisplayThreshold = 8

    init(event: RankChallengeEvent) {
        self.event = event
        _selectedTabKey = State(initialValue: event.id.uuidString)
    }

    /// 予選を起点に、決勝・入れ替え戦へと続く一連の段階。
    private var chain: [RankChallengeEvent] {
        var root = event
        while let previous = root.previousStage { root = previous }
        var result = [root]
        var current = root
        while let next = current.nextStages.sorted(by: { $0.date < $1.date }).first {
            result.append(next)
            current = next
        }
        return result
    }

    private var currentStage: RankChallengeEvent? {
        chain.first { $0.id.uuidString == selectedTabKey }
    }

    /// 総合順位（決勝ブロック、またはブロック分けなしの総当たりで意味を持つ）を出せる段階。
    private var standingsSourceStage: RankChallengeEvent? {
        chain.last { $0.isFullyCompleted && ($0.stageKind == .finals || !$0.useBlocks) }
    }

    var body: some View {
        VStack(spacing: 0) {
            stageTabBar

            Group {
                if let stage = currentStage {
                    stageList(stage)
                } else {
                    rankingList
                }
            }
        }
        .navigationTitle(chain.first?.name ?? event.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let stage = currentStage, !stage.pairings.contains(where: \.isCompleted), stage.participants.count > 2 {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingSwap = true
                    } label: {
                        Label("選手を入れ替え", systemImage: "arrow.left.arrow.right")
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingSwap) {
            if let stage = currentStage {
                RankChallengeSwapSheet(event: stage, onSwap: { a, b in swapPlayers(a, b, in: stage) })
            }
        }
        .navigationDestination(item: $activeMatch) { match in
            MatchRecordingView(match: match, modelContext: modelContext)
        }
        .confirmationDialog(
            "決勝ブロックを作成しますか？",
            isPresented: $isPresentingFinalsConfirmation,
            titleVisibility: .visible
        ) {
            Button("作成する") { confirmCreateFinals() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text(
                pendingFinalsShapes.map { "\($0.name): \($0.sourceBlocks.count)名" }.joined(separator: "\n")
                + "\n\n予選の結果が確定していなくても作成できます。以後、予選の結果を記録するたびに対戦カードの中身が自動的に更新されます。"
            )
        }
        .confirmationDialog(
            "この順位を生徒のランクに反映しますか？",
            isPresented: $isPresentingRankReflectionConfirmation,
            titleVisibility: .visible
        ) {
            Button("反映する") { reflectRankingToStudents() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("参加している生徒の順位を基準に、生徒全員のランク番号(1〜)を振り直します。この操作は取り消せません。")
        }
        .onAppear {
            syncAll()
        }
    }

    /// 予選/決勝/入替/ランクを切り替えるタブ。ネイティブのセグメントピッカーだと小さすぎるため、
    /// MatchListViewの試合一覧/ランク戦の切り替えと同じ見た目の、大きめのボタン列にしている。
    private var stageTabBar: some View {
        HStack(spacing: 8) {
            ForEach(chain) { stage in
                stageTabButton(title: stage.stageKind.displayName, isSelected: selectedTabKey == stage.id.uuidString) {
                    selectedTabKey = stage.id.uuidString
                }
            }
            stageTabButton(title: "ランク", isSelected: selectedTabKey == "ranking") {
                selectedTabKey = "ranking"
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func stageTabButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                .background(
                    isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: Theme.cornerRadius)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 段階ごとの一覧

    @ViewBuilder
    private func stageList(_ stage: RankChallengeEvent) -> some View {
        List {
            Section("大会情報") {
                LabeledContent("段階", value: stage.stageKind.displayName)
                LabeledContent(
                    "日付",
                    value: stage.date.formatted(.dateTime.year().month().day().weekday(.abbreviated).locale(japanese))
                )
                LabeledContent("参加者", value: "\(stage.participants.count)名")
                LabeledContent("方式", value: stage.useBlocks ? "ブロック分け総当たり" : "総当たり")
            }

            if stage.stageKind == .preliminary && stage.useBlocks
                && !stage.nextStages.contains(where: { $0.stageKind == .finals }) {
                Section {
                    Button("決勝ブロックを作成") { attemptCreateFinals(from: stage) }
                } footer: {
                    Text("各予選ブロックの現在の順位から、1位ブロック・2位ブロックなどの決勝ブロックを作ります。予選の結果が確定していなくても作成できます。")
                }
            } else if stage.stageKind == .finals
                && !stage.nextStages.contains(where: { $0.stageKind == .promotionPlayoff }) {
                Section {
                    Button("入れ替え戦を作成") { createPromotionPlayoff(from: stage) }
                } footer: {
                    Text("隣接するブロック同士で、上位・下位を入れ替えるための対戦カードを作ります。")
                }
            }

            ForEach(blocks(for: stage), id: \.self) { block in
                blockSection(stage: stage, block: block)
            }
        }
    }

    @ViewBuilder
    private func blockSection(stage: RankChallengeEvent, block: String?) -> some View {
        let participants = blockParticipants(stage: stage, block: block)
        let pairings = stage.pairings(inBlock: block)
        let standings = stage.standings(inBlock: block)
        let useGrid = participants.count > 2 && participants.count <= gridDisplayThreshold && stage.stageKind != .promotionPlayoff

        Section(block ?? "組み合わせ") {
            if useGrid {
                HStack(alignment: .top, spacing: 16) {
                    RankChallengeBlockGridView(
                        blockLabel: block?.first.map(String.init) ?? "",
                        participants: participants,
                        pairings: pairings,
                        onTapPairing: { pairing in openRecording(for: pairing, stage: stage) }
                    )
                    standingsList(standings)
                        .frame(minWidth: 260, maxWidth: 340, alignment: .top)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            } else {
                ForEach(pairings) { pairing in
                    Button {
                        openRecording(for: pairing, stage: stage)
                    } label: {
                        pairingListRow(pairing)
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        if !useGrid {
            Section("\(block.map { "\($0) " } ?? "")順位表") {
                standingsRows(standings)
            }
        }
    }

    @ViewBuilder
    private var rankingList: some View {
        List {
            if let source = standingsSourceStage {
                Section("総合順位（\(source.name)）") {
                    standingsRows(source.overallStandings)
                    Button("生徒のランクに反映") {
                        isPresentingRankReflectionConfirmation = true
                    }
                }
            } else {
                Section {
                    Text("決勝（またはブロック分けなしの総当たり）が全て終わると、ここに総合順位が表示されます。")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func blocks(for stage: RankChallengeEvent) -> [String?] {
        stage.useBlocks ? stage.blockNames : [nil]
    }

    /// グリッドの隣に表示する順位表。グリッドの行の高さと揃え、勝敗数・得点・失点・得失点差を表示する。
    @ViewBuilder
    private func standingsList(_ standings: [RankChallengeStanding]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("順位表")
                .font(.headline)
                .padding(.bottom, 6)
            ForEach(Array(standings.enumerated()), id: \.element.id) { index, standing in
                HStack(spacing: 8) {
                    Text("\(index + 1)位")
                        .font(.title3.weight(.bold))
                        .frame(width: 44, alignment: .leading)
                    Text(standing.student.name)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(standing.wins)勝\(standing.losses)敗")
                            .font(.subheadline.weight(.semibold))
                        Text("\(standing.pointsFor)-\(standing.pointsAgainst) (\(standing.pointDifference >= 0 ? "+" : "")\(standing.pointDifference))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: RankChallengeBlockGridView.cellHeight)
                if index < standings.count - 1 {
                    Divider()
                }
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func standingsRows(_ standings: [RankChallengeStanding]) -> some View {
        ForEach(Array(standings.enumerated()), id: \.element.id) { index, standing in
            HStack {
                Text("\(index + 1)位")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 50, alignment: .leading)
                Text(standing.student.name)
                Spacer()
                Text("\(standing.wins)勝\(standing.losses)敗")
                    .foregroundStyle(.secondary)
                Text("\(standing.pointsFor)-\(standing.pointsAgainst)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .trailing)
                Text(standing.pointDifference >= 0 ? "+\(standing.pointDifference)" : "\(standing.pointDifference)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
        }
    }

    private func pairingListRow(_ pairing: RankChallengePairing) -> some View {
        HStack {
            HStack(spacing: 4) {
                if pairing.winner?.id == pairing.player1?.id {
                    Image(systemName: "crown.fill").foregroundStyle(.yellow)
                }
                Text(pairing.player1DisplayName)
                    .fontWeight(pairing.winner?.id == pairing.player1?.id ? .bold : .regular)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if pairing.isCompleted, let s1 = pairing.currentPlayer1Score, let s2 = pairing.currentPlayer2Score {
                Text("\(s1) - \(s2)")
                    .font(.subheadline.weight(.semibold))
            } else {
                Text(pairing.matchCode)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                Text(pairing.player2DisplayName)
                    .fontWeight(pairing.winner?.id == pairing.player2?.id ? .bold : .regular)
                if pairing.winner?.id == pairing.player2?.id {
                    Image(systemName: "crown.fill").foregroundStyle(.yellow)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .foregroundStyle(.primary)
    }

    /// ブロック内の参加者を、組み合わせ生成時と同じランク順で並べる
    /// （対戦表の行・列の順番を組み合わせ作成時と一致させるため）。
    private func blockParticipants(stage: RankChallengeEvent, block: String?) -> [Student] {
        var seen = Set<UUID>()
        var students: [Student] = []
        for pairing in stage.pairings(inBlock: block) {
            for candidate in [pairing.player1, pairing.player2].compactMap({ $0 }) {
                if !seen.contains(candidate.id) {
                    seen.insert(candidate.id)
                    students.append(candidate)
                }
            }
        }
        return students.sorted { lhs, rhs in
            switch (lhs.rank, rhs.rank) {
            case let (l?, r?): return l < r
            case (nil, nil): return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            case (nil, _): return false
            case (_, nil): return true
            }
        }
    }

    /// 対戦表のマスをタップしたときの処理。まだ試合記録が無ければ新規作成して紐づけ、
    /// あれば既存の記録を開いて続きから記録・確認できるようにする。
    private func openRecording(for pairing: RankChallengePairing, stage: RankChallengeEvent) {
        if let existing = pairing.match {
            activeMatch = existing
            return
        }
        guard let p1 = pairing.player1, let p2 = pairing.player2 else { return }
        let match = Match(recordingStyle: .resultOnly, tag: stage.stageKind.matchTag, player1: p1, player2: p2)
        modelContext.insert(match)
        pairing.match = match
        try? modelContext.save()
        activeMatch = match
    }

    /// このランク戦系統の全カードについて、紐づく試合記録があればスコアを反映し、
    /// 決勝・入れ替え戦のカードは前段階の現在の順位からplayer1/player2を解決し直す。
    private func syncAll() {
        for stage in chain {
            for pairing in stage.pairings {
                pairing.syncPlayersFromSource(previousStage: stage.previousStage)
                if pairing.match != nil {
                    pairing.syncScoreFromMatch()
                }
            }
            // 決勝・入れ替え戦は前段階の順位が動くたびメンバーが変わりうるので、
            // participants（人数表示・入れ替え可否の判定に使う）もその都度作り直す。
            if stage.previousStage != nil {
                stage.participants = resolvedParticipants(of: stage)
            }
        }
        try? modelContext.save()
    }

    /// 「この人とこの人を入れ替えたい」を実現する。2人のブロック・対戦相手をまるごと交換する。
    private func swapPlayers(_ a: Student, _ b: Student, in stage: RankChallengeEvent) {
        for pairing in stage.pairings {
            if pairing.player1?.id == a.id {
                pairing.player1 = b
            } else if pairing.player1?.id == b.id {
                pairing.player1 = a
            }
            if pairing.player2?.id == a.id {
                pairing.player2 = b
            } else if pairing.player2?.id == b.id {
                pairing.player2 = a
            }
        }
        try? modelContext.save()
    }

    /// 予選の現在の順位（未確定でも可）から決勝ブロックの構成案を作り、確認ダイアログを表示する。
    private func attemptCreateFinals(from stage: RankChallengeEvent) {
        let shapes = RankChallengeStageGenerator.positionGroupShapes(from: stage)
        guard !shapes.isEmpty else { return }
        pendingFinalsShapes = shapes
        pendingFinalsSourceStage = stage
        isPresentingFinalsConfirmation = true
    }

    /// 確認後、実際に決勝ブロックのイベント・組み合わせ（参照のみ）を作成し、そのまま開く。
    private func confirmCreateFinals() {
        guard let source = pendingFinalsSourceStage, !pendingFinalsShapes.isEmpty else { return }

        let finalsEvent = RankChallengeEvent(
            name: "\(source.name) 決勝",
            useBlocks: true,
            stageKind: .finals,
            previousStage: source
        )
        modelContext.insert(finalsEvent)

        for item in RankChallengeStageGenerator.generatePairings(forShapes: pendingFinalsShapes) {
            let pairing = RankChallengePairing(
                blockName: item.blockName,
                matchNumber: item.matchNumber,
                sourceBlockName1: item.source1.blockName,
                sourcePosition1: item.source1.position,
                sourceBlockName2: item.source2.blockName,
                sourcePosition2: item.source2.position,
                event: finalsEvent
            )
            pairing.syncPlayersFromSource(previousStage: source)
            modelContext.insert(pairing)
            finalsEvent.pairings.append(pairing)
        }
        finalsEvent.participants = resolvedParticipants(of: finalsEvent)

        try? modelContext.save()
        selectedTabKey = finalsEvent.id.uuidString
    }

    /// 決勝ブロックの現在の順位（未確定でも可）から入れ替え戦のイベント・組み合わせを作成し、そのまま開く。
    private func createPromotionPlayoff(from stage: RankChallengeEvent) {
        let generated = RankChallengeStageGenerator.promotionPlayoffPairings(from: stage)
        guard !generated.isEmpty else { return }

        let playoffEvent = RankChallengeEvent(
            name: "\(stage.name) 入れ替え戦",
            useBlocks: true,
            stageKind: .promotionPlayoff,
            previousStage: stage
        )
        modelContext.insert(playoffEvent)

        for item in generated {
            let pairing = RankChallengePairing(
                blockName: item.blockName,
                matchNumber: item.matchNumber,
                sourceBlockName1: item.source1.blockName,
                sourcePosition1: item.source1.position,
                sourceBlockName2: item.source2.blockName,
                sourcePosition2: item.source2.position,
                event: playoffEvent
            )
            pairing.syncPlayersFromSource(previousStage: stage)
            modelContext.insert(pairing)
            playoffEvent.pairings.append(pairing)
        }
        playoffEvent.participants = resolvedParticipants(of: playoffEvent)

        try? modelContext.save()
        selectedTabKey = playoffEvent.id.uuidString
    }

    private func resolvedParticipants(of stage: RankChallengeEvent) -> [Student] {
        var seen = Set<UUID>()
        var participants: [Student] = []
        for pairing in stage.pairings {
            for candidate in [pairing.player1, pairing.player2].compactMap({ $0 }) where !seen.contains(candidate.id) {
                seen.insert(candidate.id)
                participants.append(candidate)
            }
        }
        return participants
    }

    /// 総合順位の順番で、参加している生徒のrankを埋め込みつつ、参加していない生徒は
    /// 反映前の相対順位を保ったまま、生徒全員分のランクを1から詰め直す。
    /// あわせて、各生徒のランク戦履歴（何位だったか）を1件ずつ記録する。
    private func reflectRankingToStudents() {
        guard let source = standingsSourceStage else { return }
        let standings = source.overallStandings
        let participantIDs = Set(standings.map(\.student.id))

        let allStudents = (try? modelContext.fetch(FetchDescriptor<Student>())) ?? []
        let currentOrder = allStudents.sorted { lhs, rhs in
            switch (lhs.rank, rhs.rank) {
            case let (l?, r?): return l < r
            case (nil, nil): return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            case (nil, _): return false
            case (_, nil): return true
            }
        }

        var standingsIterator = standings.makeIterator()
        let merged: [Student] = currentOrder.map { student in
            guard participantIDs.contains(student.id) else { return student }
            return standingsIterator.next()?.student ?? student
        }
        for (index, student) in merged.enumerated() {
            student.rank = index + 1
        }

        let now = Date.now
        for (index, standing) in standings.enumerated() {
            let record = RankChallengeResultRecord(
                eventName: source.name,
                stageDisplayName: source.stageKind.displayName,
                recordedAt: now,
                position: index + 1,
                wins: standing.wins,
                losses: standing.losses,
                pointsFor: standing.pointsFor,
                pointsAgainst: standing.pointsAgainst,
                student: standing.student
            )
            modelContext.insert(record)
        }

        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        let container = AppModelContainer.preview
        let event = RankChallengeEvent(name: "プレビュー大会")
        container.mainContext.insert(event)
        return RankChallengeDetailView(event: event)
    }
    .modelContainer(AppModelContainer.preview)
}

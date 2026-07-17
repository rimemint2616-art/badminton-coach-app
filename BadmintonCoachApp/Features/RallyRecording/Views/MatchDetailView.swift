import SwiftUI
import SwiftData

struct MatchDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let match: Match
    @State private var resumingViewModel: LiveTaggingViewModel?

    private var stats: MatchStats {
        StatsAggregationService.stats(for: match)
    }

    private var heatmapMarkers: [CourtShotMarker] {
        stats.shotMarkers.map { marker in
            CourtShotMarker(
                position: CGPoint(x: marker.courtX, y: marker.courtY),
                color: marker.result == .winner ? .green : (marker.result == .inPlay ? .gray : .red)
            )
        }
    }

    var body: some View {
        List {
            matchInfoSection
            if !stats.finalScoreSummary.isEmpty {
                scoreSection
            }
            rallyStatsSection
            if !stats.shotTypeDistribution.isEmpty {
                shotDistributionSection
            }
            if !stats.winnerShotCounts.isEmpty || !stats.errorShotCounts.isEmpty {
                winnerErrorSection
            }
            if !heatmapMarkers.isEmpty {
                heatmapSection
            }
        }
        .navigationTitle("試合詳細")
        .navigationDestination(item: $resumingViewModel) { viewModel in
            LiveTaggingView(viewModel: viewModel)
        }
    }

    private var matchInfoSection: some View {
        Section("試合情報") {
            LabeledContent("対戦", value: "\(stats.player1Name) vs \(stats.player2Name)")
            LabeledContent("日時", value: match.date.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("状態", value: match.status.displayName)
            if let winnerName = stats.winnerName {
                LabeledContent("勝者", value: winnerName)
            }
            if match.status == .inProgress {
                Button("続きを記録") {
                    resumingViewModel = LiveTaggingViewModel.resuming(match: match, modelContext: modelContext)
                }
            }
        }
    }

    private var scoreSection: some View {
        Section("スコア") {
            ForEach(stats.finalScoreSummary, id: \.gameNumber) { game in
                LabeledContent("ゲーム\(game.gameNumber)", value: "\(game.player1Score) - \(game.player2Score)")
            }
        }
    }

    private var rallyStatsSection: some View {
        Section("ラリー統計") {
            LabeledContent("総ラリー数", value: "\(stats.totalRallies)")
            LabeledContent("平均ラリー打数", value: String(format: "%.1f", stats.averageRallyLength))
            LabeledContent("最長ラリー打数", value: "\(stats.longestRallyLength)")
        }
    }

    private var shotDistributionSection: some View {
        let maxCount = stats.shotTypeDistribution.map(\.count).max() ?? 1
        return Section("ショット種類分布") {
            ForEach(stats.shotTypeDistribution) { entry in
                shotDistributionRow(entry: entry, maxCount: maxCount)
            }
        }
    }

    private func shotDistributionRow(entry: ShotTypeCount, maxCount: Int) -> some View {
        HStack {
            Text(entry.shotType.displayName)
                .frame(width: 100, alignment: .leading)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * CGFloat(entry.count) / CGFloat(maxCount))
            }
            .frame(height: 16)
            Text("\(entry.count)")
                .font(.caption)
                .frame(width: 30, alignment: .trailing)
        }
    }

    private var winnerErrorSection: some View {
        Section("ウィナー / エラー") {
            LabeledContent("\(stats.player1Name) ウィナー", value: "\(stats.winnerShotCounts[stats.player1Name] ?? 0)")
            LabeledContent("\(stats.player1Name) エラー", value: "\(stats.errorShotCounts[stats.player1Name] ?? 0)")
            LabeledContent("\(stats.player2Name) ウィナー", value: "\(stats.winnerShotCounts[stats.player2Name] ?? 0)")
            LabeledContent("\(stats.player2Name) エラー", value: "\(stats.errorShotCounts[stats.player2Name] ?? 0)")
        }
    }

    private var heatmapSection: some View {
        Section("ショット着地ヒートマップ") {
            CourtDiagramView(markers: heatmapMarkers)
                .frame(maxHeight: 320)
        }
    }
}

#Preview {
    NavigationStack {
        let container = AppModelContainer.preview
        let student1 = Student(name: "選手A")
        let student2 = Student(name: "選手B")
        let match = Match(player1: student1, player2: student2)
        MatchDetailView(match: match)
    }
    .modelContainer(AppModelContainer.preview)
}

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

            if !stats.finalScoreSummary.isEmpty {
                Section("スコア") {
                    ForEach(stats.finalScoreSummary, id: \.gameNumber) { game in
                        LabeledContent("ゲーム\(game.gameNumber)", value: "\(game.player1Score) - \(game.player2Score)")
                    }
                }
            }

            Section("ラリー統計") {
                LabeledContent("総ラリー数", value: "\(stats.totalRallies)")
                LabeledContent("平均ラリー打数", value: String(format: "%.1f", stats.averageRallyLength))
                LabeledContent("最長ラリー打数", value: "\(stats.longestRallyLength)")
            }

            if !stats.shotTypeDistribution.isEmpty {
                Section("ショット種類分布") {
                    let maxCount = stats.shotTypeDistribution.map(\.count).max() ?? 1
                    ForEach(stats.shotTypeDistribution) { entry in
                        HStack {
                            Text(entry.shotType.displayName)
                                .frame(width: 100, alignment: .leading)
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.accent)
                                    .frame(width: geo.size.width * CGFloat(entry.count) / CGFloat(maxCount))
                            }
                            .frame(height: 16)
                            Text("\(entry.count)")
                                .font(.caption)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }

            if !stats.winnerShotCounts.isEmpty || !stats.errorShotCounts.isEmpty {
                Section("ウィナー / エラー") {
                    LabeledContent("\(stats.player1Name) ウィナー", value: "\(stats.winnerShotCounts[stats.player1Name] ?? 0)")
                    LabeledContent("\(stats.player1Name) エラー", value: "\(stats.errorShotCounts[stats.player1Name] ?? 0)")
                    LabeledContent("\(stats.player2Name) ウィナー", value: "\(stats.winnerShotCounts[stats.player2Name] ?? 0)")
                    LabeledContent("\(stats.player2Name) エラー", value: "\(stats.errorShotCounts[stats.player2Name] ?? 0)")
                }
            }

            if !heatmapMarkers.isEmpty {
                Section("ショット着地ヒートマップ") {
                    CourtDiagramView(markers: heatmapMarkers)
                        .frame(maxHeight: 320)
                }
            }
        }
        .navigationTitle("試合詳細")
        .navigationDestination(item: $resumingViewModel) { viewModel in
            LiveTaggingView(viewModel: viewModel)
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

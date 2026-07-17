import SwiftUI
import SwiftData

struct MatchDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let match: Match
    @State private var resumingMatch: Match?
    private let japanese = Locale(identifier: "ja_JP")

    private var stats: MatchStats {
        StatsAggregationService.stats(for: match)
    }

    private var gamesWonByPlayer1: Int {
        stats.finalScoreSummary.filter { $0.player1Score > $0.player2Score }.count
    }
    private var gamesWonByPlayer2: Int {
        stats.finalScoreSummary.filter { $0.player2Score > $0.player1Score }.count
    }

    var body: some View {
        List {
            matchInfoSection
            if !stats.finalScoreSummary.isEmpty {
                scoreSection
            }
            if match.recordingStyle == .flow {
                pointsSummarySection
                if !stats.pointReasonBreakdownPlayer1.isEmpty {
                    reasonBreakdownSection(playerName: stats.player1Name, breakdown: stats.pointReasonBreakdownPlayer1)
                }
                if !stats.pointReasonBreakdownPlayer2.isEmpty {
                    reasonBreakdownSection(playerName: stats.player2Name, breakdown: stats.pointReasonBreakdownPlayer2)
                }
            }
        }
        .navigationTitle("試合詳細")
        .navigationDestination(item: $resumingMatch) { match in
            MatchRecordingView(match: match, modelContext: modelContext)
        }
    }

    @ViewBuilder
    private var matchInfoSection: some View {
        Section("試合情報") {
            if stats.finalScoreSummary.isEmpty {
                LabeledContent("対戦", value: "\(stats.player1Name) vs \(stats.player2Name)")
            } else {
                MatchResultSummaryView(
                    player1Name: stats.player1Name,
                    player2Name: stats.player2Name,
                    gamesWonByPlayer1: gamesWonByPlayer1,
                    gamesWonByPlayer2: gamesWonByPlayer2
                )
                .font(.title3)
                .padding(.vertical, 4)
            }
            LabeledContent(
                "日時",
                value: match.date.formatted(
                    .dateTime.year().month().day().weekday(.abbreviated).hour().minute()
                        .locale(japanese)
                )
            )
            LabeledContent("状態", value: match.status.displayName)
            LabeledContent("記録方法", value: match.recordingStyle.displayName)
            if let tag = match.tag {
                LabeledContent("タグ", value: tag.displayName)
            }
            if match.status == .inProgress {
                Button("続きを記録") {
                    resumingMatch = match
                }
            }
        }
    }

    @ViewBuilder
    private var scoreSection: some View {
        Section("スコア") {
            ForEach(stats.finalScoreSummary, id: \.gameNumber) { game in
                LabeledContent("ゲーム\(game.gameNumber)", value: "\(game.player1Score) - \(game.player2Score)")
            }
        }
    }

    @ViewBuilder
    private var pointsSummarySection: some View {
        Section("ポイント統計") {
            LabeledContent("総ポイント数", value: "\(stats.totalRallies)")
            LabeledContent("\(stats.player1Name)の獲得ポイント", value: "\(stats.pointsWonByPlayer1)")
            LabeledContent("\(stats.player2Name)の獲得ポイント", value: "\(stats.pointsWonByPlayer2)")
        }
    }

    @ViewBuilder
    private func reasonBreakdownSection(playerName: String, breakdown: [PointReasonBreakdownEntry]) -> some View {
        Section("\(playerName)の得点理由の内訳") {
            ForEach(breakdown) { entry in
                LabeledContent(entry.reason, value: "\(entry.count)件 (\(Int(entry.percentage.rounded()))%)")
            }
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

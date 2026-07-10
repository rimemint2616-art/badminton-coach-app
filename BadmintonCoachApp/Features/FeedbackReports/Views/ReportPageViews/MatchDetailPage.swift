import SwiftUI

struct MatchDetailPage: View {
    let match: MatchStats

    private var heatmapMarkers: [CourtShotMarker] {
        match.shotMarkers.map { marker in
            CourtShotMarker(
                position: CGPoint(x: marker.courtX, y: marker.courtY),
                color: marker.result == .winner ? .green : (marker.result == .inPlay ? .gray : .red)
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(match.player1Name) vs \(match.player2Name)")
                .font(.system(size: 18, weight: .bold))
            Text(match.date.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            if !match.finalScoreSummary.isEmpty {
                HStack(spacing: 16) {
                    ForEach(match.finalScoreSummary, id: \.gameNumber) { game in
                        Text("G\(game.gameNumber): \(game.player1Score)-\(game.player2Score)")
                            .font(.system(size: 12))
                    }
                }
            }

            HStack(spacing: 24) {
                statBlock(label: "総ラリー数", value: "\(match.totalRallies)")
                statBlock(label: "平均打数", value: String(format: "%.1f", match.averageRallyLength))
                statBlock(label: "最長打数", value: "\(match.longestRallyLength)")
            }

            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ショット着地")
                        .font(.system(size: 12, weight: .semibold))
                    CourtDiagramView(markers: heatmapMarkers)
                        .frame(width: 180, height: 180 / CourtDimensions.aspectRatio)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("ウィナー / エラー")
                        .font(.system(size: 12, weight: .semibold))
                    LabeledContent("\(match.player1Name) ウィナー", value: "\(match.winnerShotCounts[match.player1Name] ?? 0)")
                    LabeledContent("\(match.player1Name) エラー", value: "\(match.errorShotCounts[match.player1Name] ?? 0)")
                    LabeledContent("\(match.player2Name) ウィナー", value: "\(match.winnerShotCounts[match.player2Name] ?? 0)")
                    LabeledContent("\(match.player2Name) エラー", value: "\(match.errorShotCounts[match.player2Name] ?? 0)")
                }
                .font(.system(size: 11))
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.white)
    }

    private func statBlock(label: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MatchDetailPage(match: PreviewReportData.sampleMatch)
        .frame(width: 595, height: 842)
}

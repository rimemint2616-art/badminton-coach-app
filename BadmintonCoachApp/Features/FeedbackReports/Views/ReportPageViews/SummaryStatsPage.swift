import SwiftUI
import Charts

struct SummaryStatsPage: View {
    let data: StudentReportData

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("期間サマリー")
                .font(.system(size: 20, weight: .bold))

            HStack(spacing: 24) {
                summaryStat(label: "試合数", value: "\(data.totalMatches)")
                summaryStat(label: "勝利", value: "\(data.wins)")
                summaryStat(label: "敗北", value: "\(data.losses)")
                summaryStat(label: "勝率", value: winRateText)
            }

            Text("ショット種類の分布（全試合合計）")
                .font(.system(size: 14, weight: .semibold))

            if data.aggregateShotTypeDistribution.isEmpty {
                Text("ショットデータがありません")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            } else {
                Chart(data.aggregateShotTypeDistribution) { entry in
                    BarMark(
                        x: .value("回数", entry.count),
                        y: .value("種類", entry.shotType.displayName)
                    )
                }
                .frame(height: CGFloat(data.aggregateShotTypeDistribution.count) * 24 + 40)
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.white)
    }

    private var winRateText: String {
        guard data.totalMatches > 0 else { return "-" }
        let rate = Double(data.wins) / Double(data.totalMatches) * 100
        return String(format: "%.0f%%", rate)
    }

    private func summaryStat(label: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SummaryStatsPage(data: PreviewReportData.sample)
        .frame(width: 595, height: 842)
}

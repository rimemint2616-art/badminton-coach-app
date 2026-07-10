import SwiftUI

struct CoverPage: View {
    let data: StudentReportData

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("バドミントン練習レポート")
                .font(.system(size: 28, weight: .bold))
            Text(data.studentName)
                .font(.system(size: 22, weight: .semibold))
            Text("\(data.dateRangeStart.formatted(date: .abbreviated, time: .omitted)) 〜 \(data.dateRangeEnd.formatted(date: .abbreviated, time: .omitted))")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            HStack(spacing: 32) {
                statBlock(label: "試合数", value: "\(data.totalMatches)")
                statBlock(label: "勝利", value: "\(data.wins)")
                statBlock(label: "敗北", value: "\(data.losses)")
            }
            .padding(.top, 16)

            Spacer()
            Text("生成日: \(Date().formatted(date: .abbreviated, time: .shortened))")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
    }

    private func statBlock(label: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    CoverPage(data: PreviewReportData.sample)
        .frame(width: 595, height: 842)
}

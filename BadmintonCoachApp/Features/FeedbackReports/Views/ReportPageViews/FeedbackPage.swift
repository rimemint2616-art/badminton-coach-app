import SwiftUI

struct FeedbackPage: View {
    let entries: [FeedbackSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("コーチからのフィードバック")
                .font(.system(size: 20, weight: .bold))

            ForEach(entries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let category = entry.category {
                            Text(category)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        Spacer()
                        Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Text(entry.text)
                        .font(.system(size: 12))
                }
                .padding(.bottom, 8)
                Divider()
            }

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.white)
    }
}

#Preview {
    FeedbackPage(entries: PreviewReportData.sample.feedbackEntries)
        .frame(width: 595, height: 842)
}

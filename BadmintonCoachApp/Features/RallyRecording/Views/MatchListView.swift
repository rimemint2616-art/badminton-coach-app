import SwiftUI
import SwiftData

struct MatchListView: View {
    @Query(sort: [SortDescriptor(\Match.date, order: .reverse)]) private var matches: [Match]
    @State private var isPresentingSetup = false

    var body: some View {
        NavigationStack {
            Group {
                if matches.isEmpty {
                    ContentUnavailableView(
                        "試合記録がありません",
                        systemImage: "sportscourt",
                        description: Text("右上の＋から試合を開始してください")
                    )
                } else {
                    List(matches) { match in
                        NavigationLink(value: match) {
                            MatchRow(match: match)
                        }
                    }
                }
            }
            .navigationTitle("ラリー記録")
            .navigationDestination(for: Match.self) { match in
                MatchDetailView(match: match)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingSetup = true
                    } label: {
                        Label("試合を開始", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingSetup) {
                MatchSetupView()
            }
        }
    }
}

private struct MatchRow: View {
    let match: Match

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(match.player1?.name ?? "?") vs \(match.player2?.name ?? "?")")
                    .font(.headline)
                Text(match.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(match.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(match.status == .completed ? .green.opacity(0.2) : .orange.opacity(0.2), in: Capsule())
                if !match.finalScoreSummary.isEmpty {
                    Text(match.finalScoreSummary.map { "\($0.player1Score)-\($0.player2Score)" }.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    MatchListView()
        .modelContainer(AppModelContainer.preview)
}

import SwiftUI
import SwiftData

/// ランク戦（総当たり／ブロック分け大会）の一覧。
struct RankChallengeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\RankChallengeEvent.date, order: .reverse)]) private var allEvents: [RankChallengeEvent]
    @State private var isPresentingSetup = false

    /// 決勝・入れ替え戦は予選の詳細画面から辿れるので、一覧には予選（トップレベル）だけを出す。
    private var events: [RankChallengeEvent] {
        allEvents.filter { $0.previousStage == nil }
    }

    var body: some View {
        Group {
            if events.isEmpty {
                ContentUnavailableView(
                    "ランク戦がありません",
                    systemImage: "trophy",
                    description: Text("右上の＋からランク戦を作成してください")
                )
            } else {
                List {
                    ForEach(events) { event in
                        NavigationLink(value: event) {
                            RankChallengeRow(event: event)
                        }
                    }
                    .onDelete(perform: deleteEvents)
                }
            }
        }
        .navigationDestination(for: RankChallengeEvent.self) { event in
            RankChallengeDetailView(event: event)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isPresentingSetup = true
                } label: {
                    Label("ランク戦を作成", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingSetup) {
            RankChallengeSetupView()
        }
    }

    private func deleteEvents(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(events[index])
        }
    }
}

private struct RankChallengeRow: View {
    let event: RankChallengeEvent
    private let japanese = Locale(identifier: "ja_JP")

    private var completedCount: Int {
        event.pairings.filter(\.isCompleted).count
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                HStack(spacing: 6) {
                    Text(event.date.formatted(.dateTime.year().month().day().weekday(.abbreviated).locale(japanese)))
                    if !event.nextStages.isEmpty {
                        Text("・\(event.nextStages.map { $0.stageKind.displayName }.joined(separator: "/"))あり")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(completedCount)/\(event.pairings.count)試合")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.15), in: Capsule())
        }
    }
}

#Preview {
    NavigationStack {
        RankChallengeListView()
    }
    .modelContainer(AppModelContainer.preview)
}

import SwiftUI
import SwiftData

struct ScheduleAgendaView: View {
    @Query(sort: [SortDescriptor(\PracticeSession.date)]) private var allSessions: [PracticeSession]
    @State private var isPresentingNewSession = false
    @State private var selectedDate: Date = .now

    private var groupedSessions: [(day: Date, sessions: [PracticeSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allSessions) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted().map { day in
            (day: day, sessions: grouped[day]!.sorted { $0.startTime < $1.startTime })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if groupedSessions.isEmpty {
                    ContentUnavailableView(
                        "練習予定がありません",
                        systemImage: "calendar.badge.plus",
                        description: Text("右上の＋からスケジュールを追加してください")
                    )
                } else {
                    List {
                        ForEach(groupedSessions, id: \.day) { group in
                            Section(group.day.formatted(date: .complete, time: .omitted)) {
                                ForEach(group.sessions) { session in
                                    NavigationLink(value: session) {
                                        SessionRow(session: session)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("スケジュール")
            .navigationDestination(for: PracticeSession.self) { session in
                SessionDetailView(session: session)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingNewSession = true
                    } label: {
                        Label("練習を追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewSession) {
                SessionEditView(session: nil)
            }
        }
    }
}

private struct SessionRow: View {
    let session: PracticeSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(session.startTime.formatted(date: .omitted, time: .shortened)) - \(session.endTime.formatted(date: .omitted, time: .shortened))")
                    .font(.headline)
                if !session.location.isEmpty {
                    Text(session.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(session.attendees.count)名")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.15), in: Capsule())
        }
    }
}

#Preview {
    ScheduleAgendaView()
        .modelContainer(AppModelContainer.preview)
}

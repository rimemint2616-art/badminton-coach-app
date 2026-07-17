import SwiftUI
import SwiftData

struct ScheduleAgendaView: View {
    /// RootTabViewは各タブをZStack内に常時マウントしたまま透明度だけ切り替えているため
    /// （タブ切り替えでスクロール位置を失わないように）、`onAppear`はアプリ起動時に一度しか
    /// 呼ばれない。また、既にスケジュールタブを開いている状態で再度タブをタップしても
    /// 選択状態(selectedTab)自体は変化しない。そのため、タブがタップされるたびに増える
    /// カウンタをRootTabViewから受け取り、`onChange`で検知して毎回スクロールし直す。
    var scrollToTodayTrigger: Int = 0

    @Query(sort: [SortDescriptor(\PracticeSession.date)]) private var allSessions: [PracticeSession]
    @State private var isPresentingNewSession = false
    @State private var isPresentingPhotoImport = false

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
                    ScrollViewReader { proxy in
                        List {
                            ForEach(groupedSessions, id: \.day) { group in
                                DayHeader(day: group.day)
                                    .padding(.top, 12)
                                    .listRowSeparator(.hidden)
                                    .id(group.day)

                                ForEach(group.sessions) { session in
                                    NavigationLink(value: session) {
                                        SessionRow(session: session)
                                    }
                                    .listRowBackground(session.eventCategory.color.opacity(0.15))
                                }
                            }
                        }
                        .onAppear {
                            scrollToToday(proxy: proxy)
                        }
                        .onChange(of: scrollToTodayTrigger) { _, _ in
                            scrollToToday(proxy: proxy)
                        }
                    }
                }
            }
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingPhotoImport = true
                    } label: {
                        Label("写真から取り込む", systemImage: "text.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewSession) {
                SessionEditView(session: nil)
            }
            .sheet(isPresented: $isPresentingPhotoImport) {
                SchedulePhotoImportView()
            }
        }
    }

    private func scrollToToday(proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        if let todayGroup = groupedSessions.first(where: { calendar.isDateInToday($0.day) })
            ?? groupedSessions.first(where: { $0.day >= calendar.startOfDay(for: .now) }) {
            // Listの行がまだ配置されきっていない直後のタイミングだとscrollTo自体が
            // 効かないことがあるため、レイアウト完了を待つ程度に少し遅らせて呼ぶ。
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation {
                    proxy.scrollTo(todayGroup.day, anchor: .top)
                }
            }
        }
    }
}

/// 日付をひと目でわかるようにする、大きめの曜日＋日付バッジのセクションヘッダー。
private struct DayHeader: View {
    let day: Date

    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }

    /// アプリ全体が日本語UIのため、端末のリージョン設定に関わらず日付表記を日本語に固定する。
    private let japanese = Locale(identifier: "ja_JP")

    /// 「14日」のような接尾辞なしの、丸バッジに収まる日番号だけの文字列。
    private var dayNumberText: String {
        String(Calendar.current.component(.day, from: day))
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(day.formatted(.dateTime.weekday(.abbreviated).locale(japanese)))
                    .font(.caption.weight(.semibold))
                Text(dayNumberText)
                    .font(.title2.weight(.bold))
                    .frame(width: 40, height: 40)
                    .background(isToday ? Color.accentColor : Color.clear, in: Circle())
                    .foregroundStyle(isToday ? Color.white : Color.primary)
            }
            .foregroundStyle(isToday ? Color.accentColor : Color.primary)

            Text(day.formatted(.dateTime.year().month(.wide).locale(japanese)))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .textCase(nil)
    }
}

private struct SessionRow: View {
    let session: PracticeSession

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(session.eventCategory.displayName)
                        .font(.title3.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(session.eventCategory.color, in: Capsule())
                        .foregroundStyle(.white)

                    if !session.title.isEmpty {
                        Text(session.title)
                            .font(.title3.weight(.semibold))
                    }

                    Text(session.isAllDay ? "終日" : "\(session.startTime.formatted(date: .omitted, time: .shortened)) - \(session.endTime.formatted(date: .omitted, time: .shortened))")
                        .font(.title3.weight(.semibold))
                }
                if !session.location.isEmpty {
                    Text(session.location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(session.attendees.count)名")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.15), in: Capsule())
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    ScheduleAgendaView()
        .modelContainer(AppModelContainer.preview)
}

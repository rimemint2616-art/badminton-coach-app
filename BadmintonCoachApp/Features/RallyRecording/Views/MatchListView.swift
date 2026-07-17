import SwiftUI
import SwiftData

private enum MatchTabSection: String, CaseIterable, Identifiable {
    case matches, rankChallenge

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .matches: return "試合一覧"
        case .rankChallenge: return "ランク戦"
        }
    }
}

struct MatchListView: View {
    @Query(sort: [SortDescriptor(\Match.date, order: .reverse)]) private var matches: [Match]
    @State private var isPresentingSetup = false
    @State private var section: MatchTabSection = .matches

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sectionSwitcher

                Group {
                    switch section {
                    case .matches:
                        matchListContent
                    case .rankChallenge:
                        RankChallengeListView()
                    }
                }
            }
            .navigationDestination(for: Match.self) { match in
                MatchDetailView(match: match)
            }
            .toolbar {
                if section == .matches {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            isPresentingSetup = true
                        } label: {
                            Label("試合を開始", systemImage: "plus")
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $isPresentingSetup) {
                MatchSetupView()
            }
        }
    }

    /// 試合が増えてきても管理しやすいよう、日付ごとの「フォルダ」にまとめる。
    private var dateFolders: [MatchDateFolder] {
        let groups = Dictionary(grouping: matches) { Calendar.current.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in
            MatchDateFolder(day: day, matches: (groups[day] ?? []).sorted { $0.date > $1.date })
        }
    }

    @ViewBuilder
    private var matchListContent: some View {
        if matches.isEmpty {
            ContentUnavailableView(
                "試合記録がありません",
                systemImage: "figure.badminton",
                description: Text("右上の＋から試合を開始してください")
            )
        } else {
            List(dateFolders) { folder in
                NavigationLink(value: folder) {
                    MatchDateFolderRow(folder: folder)
                }
            }
            .navigationDestination(for: MatchDateFolder.self) { folder in
                MatchDateFolderDetailView(folder: folder)
            }
        }
    }

    private var sectionSwitcher: some View {
        HStack(spacing: 8) {
            ForEach(MatchTabSection.allCases) { item in
                Button {
                    section = item
                } label: {
                    Text(item.displayName)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(section == item ? Color.accentColor : Color.primary)
                        .background(
                            section == item ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

/// 同じ日にまとめた試合の「フォルダ」。
private struct MatchDateFolder: Identifiable, Hashable {
    let day: Date
    let matches: [Match]

    var id: Date { day }

    static func == (lhs: MatchDateFolder, rhs: MatchDateFolder) -> Bool { lhs.day == rhs.day }
    func hash(into hasher: inout Hasher) { hasher.combine(day) }
}

private struct MatchDateFolderRow: View {
    let folder: MatchDateFolder
    private let japanese = Locale(identifier: "ja_JP")

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(
                    folder.day.formatted(
                        .dateTime.year().month().day().weekday(.abbreviated).locale(japanese)
                    )
                )
                .font(.headline)
                Text("\(folder.matches.count)試合")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MatchDateFolderDetailView: View {
    let folder: MatchDateFolder
    private let japanese = Locale(identifier: "ja_JP")

    var body: some View {
        List(folder.matches) { match in
            NavigationLink(value: match) {
                MatchRow(match: match)
            }
        }
        .navigationTitle(
            folder.day.formatted(.dateTime.year().month().day().weekday(.abbreviated).locale(japanese))
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MatchRow: View {
    let match: Match
    private let japanese = Locale(identifier: "ja_JP")

    private var gamesWonByPlayer1: Int {
        match.finalScoreSummary.filter { $0.player1Score > $0.player2Score }.count
    }
    private var gamesWonByPlayer2: Int {
        match.finalScoreSummary.filter { $0.player2Score > $0.player1Score }.count
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                if match.finalScoreSummary.isEmpty {
                    Text("\(match.player1DisplayName) vs \(match.player2DisplayName)")
                        .font(.headline)
                } else {
                    MatchResultSummaryView(
                        player1Name: match.player1DisplayName,
                        player2Name: match.player2DisplayName,
                        gamesWonByPlayer1: gamesWonByPlayer1,
                        gamesWonByPlayer2: gamesWonByPlayer2
                    )
                    .font(.headline)
                }
                HStack(spacing: 6) {
                    Text(
                        match.date.formatted(
                            .dateTime.year().month().day().weekday(.abbreviated).hour().minute()
                                .locale(japanese)
                        )
                    )
                    if let tag = match.tag {
                        Text(tag.displayName)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.15), in: Capsule())
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(match.status.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(match.status == .completed ? .green.opacity(0.2) : .orange.opacity(0.2), in: Capsule())
        }
    }
}

#Preview {
    MatchListView()
        .modelContainer(AppModelContainer.preview)
}

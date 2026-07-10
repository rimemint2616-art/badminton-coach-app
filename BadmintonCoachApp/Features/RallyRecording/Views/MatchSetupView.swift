import SwiftUI
import SwiftData

/// 試合開始前のセットアップ画面。対戦者・採点方式・先行サーブを選び、
/// Matchを作成してLiveTaggingViewへ遷移する。
struct MatchSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Student.name)]) private var allStudents: [Student]

    /// スケジュールから起動した場合、出席生徒だけに絞り込むために渡す。
    var presetSession: PracticeSession?

    @State private var player1: Student?
    @State private var player2: Student?
    @State private var scoringFormat: ScoringFormat = .bestOf3To21
    @State private var firstServer: MatchSide = .player1
    @State private var createdMatch: Match?

    private var candidateStudents: [Student] {
        let base = allStudents.filter { !$0.isArchived }
        if let session = presetSession, !session.attendees.isEmpty {
            let attendeeIDs = Set(session.attendees.map(\.id))
            return base.filter { attendeeIDs.contains($0.id) }
        }
        return base
    }

    private var isValid: Bool {
        player1 != nil && player2 != nil && player1 !== player2
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("対戦者") {
                    Picker("プレイヤー1", selection: $player1) {
                        Text("選択してください").tag(Student?.none)
                        ForEach(candidateStudents) { student in
                            Text(student.name).tag(Student?.some(student))
                        }
                    }
                    Picker("プレイヤー2", selection: $player2) {
                        Text("選択してください").tag(Student?.none)
                        ForEach(candidateStudents) { student in
                            Text(student.name).tag(Student?.some(student))
                        }
                    }
                    if player1 != nil && player1 === player2 {
                        Text("同じ生徒を2回選ぶことはできません")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("採点方式") {
                    Picker("方式", selection: $scoringFormat) {
                        ForEach(ScoringFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                }

                Section("先行サーブ") {
                    Picker("最初のサーバー", selection: $firstServer) {
                        Text(player1?.name ?? "プレイヤー1").tag(MatchSide.player1)
                        Text(player2?.name ?? "プレイヤー2").tag(MatchSide.player2)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("試合セットアップ")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("試合開始") { startMatch() }
                        .disabled(!isValid)
                }
            }
            .navigationDestination(item: $createdMatch) { match in
                LiveTaggingView(match: match, modelContext: modelContext, firstServer: firstServer)
            }
        }
    }

    private func startMatch() {
        guard let player1, let player2 else { return }
        let match = Match(
            matchType: .singles,
            scoringFormat: scoringFormat,
            status: .inProgress,
            player1: player1,
            player2: player2,
            session: presetSession
        )
        modelContext.insert(match)
        presetSession?.matches.append(match)
        try? modelContext.save()
        createdMatch = match
    }
}

#Preview {
    MatchSetupView()
        .modelContainer(AppModelContainer.preview)
}

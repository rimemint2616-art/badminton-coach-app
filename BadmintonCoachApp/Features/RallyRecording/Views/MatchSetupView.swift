import SwiftUI
import SwiftData

/// プレイヤーを生徒一覧から選ぶか、名前を直接入力するかを切り替えるためのモード。
/// 対外試合など、生徒として登録していない相手を記録したいケースに対応する。
enum PlayerSelectionMode: String, CaseIterable, Identifiable {
    case student
    case guest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .student: return "生徒から選ぶ"
        case .guest: return "名前を入力"
        }
    }
}

/// 試合開始前のセットアップ画面。対戦者・採点方式・先行サーブを選び、
/// Matchを作成してLiveTaggingViewへ遷移する。
struct MatchSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Student.name)]) private var allStudents: [Student]

    /// スケジュールから起動した場合、出席生徒だけに絞り込むために渡す。
    var presetSession: PracticeSession?

    @State private var player1Mode: PlayerSelectionMode = .student
    @State private var player2Mode: PlayerSelectionMode = .student
    @State private var player1: Student?
    @State private var player2: Student?
    @State private var player1GuestName: String = ""
    @State private var player2GuestName: String = ""
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
        let player1Valid = player1Mode == .guest || player1 != nil
        let player2Valid = player2Mode == .guest || player2 != nil
        let notSameStudent = !(player1Mode == .student && player2Mode == .student && player1 != nil && player1 === player2)
        return player1Valid && player2Valid && notSameStudent
    }

    private var resolvedPlayer1Name: String {
        switch player1Mode {
        case .student: return player1?.name ?? "プレイヤー1"
        case .guest: return player1GuestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "プレイヤー1" : player1GuestName
        }
    }

    private var resolvedPlayer2Name: String {
        switch player2Mode {
        case .student: return player2?.name ?? "プレイヤー2"
        case .guest: return player2GuestName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "プレイヤー2" : player2GuestName
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("対戦者") {
                    playerFields(
                        label: "プレイヤー1",
                        mode: $player1Mode,
                        student: $player1,
                        guestName: $player1GuestName
                    )
                    playerFields(
                        label: "プレイヤー2",
                        mode: $player2Mode,
                        student: $player2,
                        guestName: $player2GuestName
                    )
                    if player1Mode == .student && player2Mode == .student && player1 != nil && player1 === player2 {
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
                        Text(resolvedPlayer1Name).tag(MatchSide.player1)
                        Text(resolvedPlayer2Name).tag(MatchSide.player2)
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

    @ViewBuilder
    private func playerFields(
        label: String,
        mode: Binding<PlayerSelectionMode>,
        student: Binding<Student?>,
        guestName: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker(label, selection: mode) {
                ForEach(PlayerSelectionMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if mode.wrappedValue == .student {
                Picker(label, selection: student) {
                    Text("選択してください").tag(Student?.none)
                    ForEach(candidateStudents) { candidate in
                        Text(candidate.name).tag(Student?.some(candidate))
                    }
                }
                .labelsHidden()
            } else {
                TextField("名前（対外選手など、空欄でも開始できます）", text: guestName)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.vertical, 4)
    }

    private func startMatch() {
        guard isValid else { return }
        let trimmedGuest1 = player1GuestName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGuest2 = player2GuestName.trimmingCharacters(in: .whitespacesAndNewlines)

        let match = Match(
            matchType: .singles,
            scoringFormat: scoringFormat,
            status: .inProgress,
            player1: player1Mode == .student ? player1 : nil,
            player2: player2Mode == .student ? player2 : nil,
            player1GuestName: player1Mode == .guest && !trimmedGuest1.isEmpty ? trimmedGuest1 : nil,
            player2GuestName: player2Mode == .guest && !trimmedGuest2.isEmpty ? trimmedGuest2 : nil,
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

import SwiftUI
import SwiftData

/// 「結果のみ」モード用の入力行。テキストフィールドで空欄を扱えるよう文字列で保持する。
private struct GameScoreInput: Identifiable {
    let id = UUID()
    var gameNumber: Int
    var player1Text: String = ""
    var player2Text: String = ""
}

/// 試合結果（各ゲームの最終スコア）だけをまとめて入力する画面。
/// ライブでの得点操作やラリー記録は行わず、保存した時点で試合を完了扱いにする。
struct SimpleResultEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var match: Match

    @State private var rows: [GameScoreInput]

    /// currentGameDraftScoreは「流れ」モードから切り替えた直後、記録途中だったゲームの
    /// スコアを引き継いで下書き行として表示するために使う。
    init(match: Match, currentGameDraftScore: (player1: Int, player2: Int)? = nil) {
        self.match = match
        var initialRows = match.finalScoreSummary.map {
            GameScoreInput(gameNumber: $0.gameNumber, player1Text: String($0.player1Score), player2Text: String($0.player2Score))
        }
        if let draft = currentGameDraftScore {
            initialRows.append(
                GameScoreInput(gameNumber: initialRows.count + 1, player1Text: String(draft.player1), player2Text: String(draft.player2))
            )
        }
        if initialRows.isEmpty {
            initialRows = [GameScoreInput(gameNumber: 1)]
        }
        _rows = State(initialValue: initialRows)
    }

    private var maxGames: Int {
        match.scoringFormat.gamesToWinMatch * 2 - 1
    }

    private var isValid: Bool {
        rows.contains { Int($0.player1Text) != nil && Int($0.player2Text) != nil }
    }

    var body: some View {
        Form {
            Section {
                Text("\(match.player1DisplayName) vs \(match.player2DisplayName)")
                    .font(.headline)
                Text(match.scoringFormat.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("各ゲームの最終スコア") {
                ForEach($rows) { $row in
                    HStack {
                        Text("\(row.gameNumber)ゲーム目")
                            .frame(width: 90, alignment: .leading)
                        TextField(match.player1DisplayName, text: $row.player1Text)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                        Text("-")
                        TextField(match.player2DisplayName, text: $row.player2Text)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .onDelete { offsets in
                    rows.remove(atOffsets: offsets)
                }

                if rows.count < maxGames {
                    Button {
                        rows.append(GameScoreInput(gameNumber: rows.count + 1))
                    } label: {
                        Label("ゲームを追加", systemImage: "plus")
                    }
                }
            }
        }
        .navigationTitle("試合結果を入力")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
                    .disabled(!isValid)
            }
        }
    }

    private func save() {
        let scores: [GameScore] = rows.compactMap { row in
            guard let p1 = Int(row.player1Text), let p2 = Int(row.player2Text) else { return nil }
            return GameScore(gameNumber: row.gameNumber, player1Score: p1, player2Score: p2)
        }
        match.finalScoreSummary = scores
        match.status = .completed
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        let container = AppModelContainer.preview
        let match = Match(recordingStyle: .resultOnly)
        container.mainContext.insert(match)
        return SimpleResultEntryView(match: match)
    }
    .modelContainer(AppModelContainer.preview)
}

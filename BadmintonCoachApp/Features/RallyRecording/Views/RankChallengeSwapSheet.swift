import SwiftUI

/// 組み合わせ表を作った後、「この人とこの人を入れ替えたい」場合に使うシート。
/// 選んだ2人のブロック・対戦相手をまるごと入れ替える。
struct RankChallengeSwapSheet: View {
    @Environment(\.dismiss) private var dismiss
    let event: RankChallengeEvent
    let onSwap: (Student, Student) -> Void

    @State private var studentAID: UUID?
    @State private var studentBID: UUID?

    private var participants: [Student] {
        event.participants.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("選手A", selection: $studentAID) {
                        Text("選択してください").tag(UUID?.none)
                        ForEach(participants) { student in
                            Text(student.name).tag(Optional(student.id))
                        }
                    }
                    Picker("選手B", selection: $studentBID) {
                        Text("選択してください").tag(UUID?.none)
                        ForEach(participants) { student in
                            Text(student.name).tag(Optional(student.id))
                        }
                    }
                } footer: {
                    Text("選んだ2人のブロック・対戦相手をまるごと入れ替えます。結果がまだ入っていない組み合わせでのみ行えます。")
                }
            }
            .navigationTitle("選手を入れ替え")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("入れ替える") {
                        guard let a = participants.first(where: { $0.id == studentAID }),
                              let b = participants.first(where: { $0.id == studentBID }) else { return }
                        onSwap(a, b)
                        dismiss()
                    }
                    .disabled(studentAID == nil || studentBID == nil || studentAID == studentBID)
                }
            }
        }
    }
}

#Preview {
    let event = RankChallengeEvent(name: "プレビュー大会")
    return RankChallengeSwapSheet(event: event, onSwap: { _, _ in })
}

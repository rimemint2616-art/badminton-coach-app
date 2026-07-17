import SwiftUI

/// カテゴリボタンから開く、球数・セット数・コートを選んで手早く項目を追加するシート。
/// 字下げ・強調など細かい調整は追加後にMenuSectionEditorViewから行う。
struct MenuQuickAddItemView: View {
    @Environment(\.dismiss) private var dismiss
    let category: MenuCategoryTag
    let availableCourts: [CourtTag]
    let onAdd: (MenuSectionItemDraft) -> Void

    @State private var text = ""
    @State private var shotsPerPerson = 0
    @State private var sets = 0
    @State private var courtIDs: Set<UUID> = []

    private var isValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("内容") {
                    TextField("例: スマッシュ", text: $text)
                }

                Section("1人あたりの球数・セット数") {
                    Stepper(shotsPerPerson > 0 ? "\(shotsPerPerson)球" : "球数を指定しない", value: $shotsPerPerson, in: 0...30)
                    Stepper(sets > 0 ? "\(sets)セット" : "セット数を指定しない", value: $sets, in: 0...10)
                }

                Section("コートの割り振り") {
                    if availableCourts.isEmpty {
                        Text("設定タブからコートを追加してください")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(availableCourts) { court in
                            Button {
                                toggle(court)
                            } label: {
                                HStack {
                                    Text(court.name)
                                    Spacer()
                                    if courtIDs.contains(court.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加", action: addItem)
                        .disabled(!isValid)
                }
            }
        }
    }

    private func toggle(_ court: CourtTag) {
        if courtIDs.contains(court.id) {
            courtIDs.remove(court.id)
        } else {
            courtIDs.insert(court.id)
        }
    }

    private func addItem() {
        guard isValid else { return }
        var draft = MenuSectionItemDraft(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
        draft.shotsPerPerson = shotsPerPerson > 0 ? shotsPerPerson : nil
        draft.sets = sets > 0 ? sets : nil
        draft.courtIDs = courtIDs
        onAdd(draft)
        dismiss()
    }
}

#Preview {
    MenuQuickAddItemView(category: MenuCategoryTag(name: "ノック練", sortOrder: 0), availableCourts: [], onAdd: { _ in })
}

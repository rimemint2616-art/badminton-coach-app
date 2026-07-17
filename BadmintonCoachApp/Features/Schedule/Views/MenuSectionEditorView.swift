import SwiftUI

/// 練習メニューの1セクション（タイトル+行）を編集する画面。
/// SessionEditViewのセクション一覧からNavigationLinkで開く。
struct MenuSectionEditorView: View {
    @Binding var section: MenuSectionDraft
    let availableCourts: [CourtTag]

    var body: some View {
        Form {
            Section("セクション名") {
                TextField("例: フットワーク(約20分)", text: $section.title)
            }

            Section {
                ForEach($section.items) { $item in
                    MenuSectionItemRow(item: $item, availableCourts: availableCourts)
                }
                .onDelete { offsets in
                    section.items.remove(atOffsets: offsets)
                }
                .onMove { source, destination in
                    section.items.move(fromOffsets: source, toOffset: destination)
                }
                Button {
                    section.items.append(MenuSectionItemDraft())
                } label: {
                    Label("行を追加", systemImage: "plus")
                }
            } header: {
                Text("項目")
            } footer: {
                Text("字下げでコート見出しの下の内訳などを表現できます。コートを割り当てると「1・2コート」のように複数選べます。")
            }
        }
        .navigationTitle(section.title.isEmpty ? "セクション" : section.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
    }
}

/// 練習メニューの1行を編集する行UI。MenuSectionEditorView・MenuTemplateEditorViewの両方で使う。
struct MenuSectionItemRow: View {
    @Binding var item: MenuSectionItemDraft
    let availableCourts: [CourtTag]
    @State private var isPresentingCourtPicker = false

    private var courtSummary: String {
        availableCourts
            .filter { item.courtIDs.contains($0.id) }
            .map(\.name)
            .joined(separator: "・")
    }

    private var shotsPerPersonBinding: Binding<Int> {
        Binding(
            get: { item.shotsPerPerson ?? 0 },
            set: { item.shotsPerPerson = $0 > 0 ? $0 : nil }
        )
    }

    private var setsBinding: Binding<Int> {
        Binding(
            get: { item.sets ?? 0 },
            set: { item.sets = $0 > 0 ? $0 : nil }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("内容", text: $item.text, axis: .vertical)

            HStack {
                Stepper(shotsPerPersonBinding.wrappedValue > 0 ? "\(shotsPerPersonBinding.wrappedValue)球" : "球数なし", value: shotsPerPersonBinding, in: 0...30)
                Spacer()
                Stepper(setsBinding.wrappedValue > 0 ? "\(setsBinding.wrappedValue)セット" : "セット数なし", value: setsBinding, in: 0...10)
            }
            .font(.caption)

            HStack {
                Stepper("字下げ: \(item.indentLevel)", value: $item.indentLevel, in: 0...2)
                    .fixedSize()
                Spacer()
                Toggle("強調", isOn: $item.isEmphasized)
                    .fixedSize()
            }
            .font(.caption)

            Button {
                isPresentingCourtPicker = true
            } label: {
                Label(courtSummary.isEmpty ? "コートを割り当て" : courtSummary, systemImage: "sportscourt")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $isPresentingCourtPicker) {
            CourtMultiPickerView(availableCourts: availableCourts, selectedIDs: $item.courtIDs)
        }
    }
}

struct CourtMultiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let availableCourts: [CourtTag]
    @Binding var selectedIDs: Set<UUID>

    var body: some View {
        NavigationStack {
            List(availableCourts) { court in
                Button {
                    toggle(court)
                } label: {
                    HStack {
                        Text(court.name)
                        Spacer()
                        if selectedIDs.contains(court.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            }
            .navigationTitle("コートを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }

    private func toggle(_ court: CourtTag) {
        if selectedIDs.contains(court.id) {
            selectedIDs.remove(court.id)
        } else {
            selectedIDs.insert(court.id)
        }
    }
}

#Preview {
    NavigationStack {
        MenuSectionEditorView(
            section: .constant(MenuSectionDraft(title: "ノック練", items: [MenuSectionItemDraft(text: "スマッシュ8球×2回")])),
            availableCourts: []
        )
    }
}

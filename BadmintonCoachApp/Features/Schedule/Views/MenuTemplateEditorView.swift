import SwiftUI
import SwiftData

/// 名前付きテンプレート（MenuTemplate）の新規作成・編集画面。
/// `MenuTemplatePickerView`から「新しいメニューを作成」で開かれた場合は、保存と同時に
/// `onSaved`経由で今回の練習メニューにも項目が適用される。設定タブのテンプレート管理からは
/// `onSaved`なしで、保存・編集専用として使う。
/// 行編集UI（MenuSectionItemRow・CourtMultiPickerView）はMenuSectionEditorViewと共有する。
struct MenuTemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let category: MenuCategoryTag
    let availableCourts: [CourtTag]
    let existingTemplate: MenuTemplate?
    var onSaved: (([MenuSectionItemDraft]) -> Void)?

    @State private var name: String
    @State private var items: [MenuSectionItemDraft]

    init(
        category: MenuCategoryTag,
        availableCourts: [CourtTag],
        existingTemplate: MenuTemplate? = nil,
        onSaved: (([MenuSectionItemDraft]) -> Void)? = nil
    ) {
        self.category = category
        self.availableCourts = availableCourts
        self.existingTemplate = existingTemplate
        self.onSaved = onSaved
        _name = State(initialValue: existingTemplate?.name ?? "")
        _items = State(initialValue: (existingTemplate?.sortedItems ?? []).map { item in
            MenuSectionItemDraft(
                text: item.text,
                shotsPerPerson: item.shotsPerPerson,
                sets: item.sets,
                indentLevel: item.indentLevel,
                isEmphasized: item.isEmphasized,
                courtIDs: Set(item.courts.map(\.id))
            )
        })
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("メニュー名") {
                TextField("例: 4隅フットワーク", text: $name)
            }

            Section {
                ForEach($items) { $item in
                    MenuSectionItemRow(item: $item, availableCourts: availableCourts)
                }
                .onDelete { offsets in
                    items.remove(atOffsets: offsets)
                }
                .onMove { source, destination in
                    items.move(fromOffsets: source, toOffset: destination)
                }
                Button {
                    items.append(MenuSectionItemDraft())
                } label: {
                    Label("行を追加", systemImage: "plus")
                }
            } header: {
                Text("項目")
            }
        }
        .navigationTitle(existingTemplate == nil ? "新しいメニュー" : "メニューを編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存", action: save)
                    .disabled(!isValid)
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let template = existingTemplate ?? MenuTemplate(category: category)
        if existingTemplate == nil {
            modelContext.insert(template)
        }
        template.name = trimmedName
        for item in template.items {
            modelContext.delete(item)
        }
        template.items.removeAll()
        for (index, draft) in items.enumerated() {
            let courts = availableCourts.filter { draft.courtIDs.contains($0.id) }
            let item = MenuTemplateItem(
                orderIndex: index,
                text: draft.text,
                shotsPerPerson: draft.shotsPerPerson,
                sets: draft.sets,
                indentLevel: draft.indentLevel,
                isEmphasized: draft.isEmphasized,
                template: template,
                courts: courts
            )
            modelContext.insert(item)
            template.items.append(item)
        }
        try? modelContext.save()
        onSaved?(items)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        MenuTemplateEditorView(
            category: MenuCategoryTag(name: "フットワーク", sortOrder: 0, supportsTemplateLibrary: true),
            availableCourts: []
        )
    }
    .modelContainer(AppModelContainer.preview)
}

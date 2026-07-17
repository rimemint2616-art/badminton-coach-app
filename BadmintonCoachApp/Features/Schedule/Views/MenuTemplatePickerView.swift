import SwiftUI
import SwiftData

/// テンプレート対応カテゴリ（フットワーク・ノック練・パターン練など）のボタンをタップした時に開くシート。
/// 保存済みテンプレートから選んで今回のメニューに追加するか、その場で新しいテンプレートを
/// 作成・保存するか、あるいは1項目だけ手早く追加するかを選べる。
struct MenuTemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let category: MenuCategoryTag
    let availableCourts: [CourtTag]
    let onApply: ([MenuSectionItemDraft]) -> Void

    @Query(sort: [SortDescriptor(\MenuTemplate.name)]) private var allTemplates: [MenuTemplate]
    @State private var isPresentingQuickAdd = false

    private var templates: [MenuTemplate] {
        allTemplates.filter { $0.category?.id == category.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if templates.isEmpty {
                        Text("保存済みのメニューはまだありません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(templates) { template in
                            Button {
                                apply(template)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(template.name)
                                            .foregroundStyle(.primary)
                                        Text("\(template.items.count)項目")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("保存済みのメニュー")
                } footer: {
                    Text("タップすると今回の練習メニューに追加されます。テンプレート自体は設定タブから管理できます。")
                }

                Section {
                    NavigationLink {
                        MenuTemplateEditorView(category: category, availableCourts: availableCourts) { items in
                            onApply(items)
                            dismiss()
                        }
                    } label: {
                        Label("新しいメニューを作成", systemImage: "plus.square.on.square")
                    }
                } footer: {
                    Text("名前を付けて保存すると、次回以降もここから呼び出せます。")
                }

                Section {
                    Button {
                        isPresentingQuickAdd = true
                    } label: {
                        Label("1項目だけ追加", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .sheet(isPresented: $isPresentingQuickAdd) {
                MenuQuickAddItemView(category: category, availableCourts: availableCourts) { itemDraft in
                    onApply([itemDraft])
                    dismiss()
                }
            }
        }
    }

    private func apply(_ template: MenuTemplate) {
        let drafts = template.sortedItems.map { item in
            MenuSectionItemDraft(
                text: item.text,
                shotsPerPerson: item.shotsPerPerson,
                sets: item.sets,
                indentLevel: item.indentLevel,
                isEmphasized: item.isEmphasized,
                courtIDs: Set(item.courts.map(\.id))
            )
        }
        onApply(drafts)
        dismiss()
    }
}

#Preview {
    MenuTemplatePickerView(
        category: MenuCategoryTag(name: "フットワーク", sortOrder: 0, supportsTemplateLibrary: true),
        availableCourts: [],
        onApply: { _ in }
    )
    .modelContainer(AppModelContainer.preview)
}

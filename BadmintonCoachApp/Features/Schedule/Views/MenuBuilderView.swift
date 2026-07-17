import SwiftUI
import SwiftData

/// 「メニューを作る」画面。設定タブで管理されたカテゴリボタンから、球数・セット数・コートを
/// 選んで手早く項目を追加できる。テンプレート機能が有効なカテゴリ（フットワーク・ノック練・
/// パターン練など）は、保存済みテンプレートの呼び出しや、その場での新規テンプレート作成もできる。
/// カテゴリに当てはまらない内容（休憩、ランク戦の対戦表など）は自由入力のセクションとして追加できる。
/// 字下げ・強調・並び替えなど細かい調整は、作成済みセクションをタップしてMenuSectionEditorViewで行う。
struct MenuBuilderView: View {
    @Binding var sectionDrafts: [MenuSectionDraft]
    let availableCourts: [CourtTag]
    let durationSummary: String

    @Query(sort: [SortDescriptor(\MenuCategoryTag.sortOrder)]) private var categoryTags: [MenuCategoryTag]

    @State private var quickAddCategory: MenuCategoryTag?
    @State private var templatePickerCategory: MenuCategoryTag?

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        Form {
            Section("練習時間") {
                Text(durationSummary)
                    .foregroundStyle(.secondary)
            }

            Section {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(categoryTags) { category in
                        categoryButton(category)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("カテゴリから追加")
            } footer: {
                Text("タップすると項目を追加できます。テンプレート対応のカテゴリは、保存済みのメニューから選んだり、その場で新しいメニューを作成・保存したりできます。カテゴリ自体の追加・削除は設定タブから行えます。")
            }

            if !sectionDrafts.isEmpty {
                Section("作成済みのセクション") {
                    ForEach($sectionDrafts) { $draft in
                        NavigationLink {
                            MenuSectionEditorView(section: $draft, availableCourts: availableCourts)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(draft.title.isEmpty ? "（無題のセクション）" : draft.title)
                                Text("\(draft.items.count)項目")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        sectionDrafts.remove(atOffsets: offsets)
                    }
                    .onMove { source, destination in
                        sectionDrafts.move(fromOffsets: source, toOffset: destination)
                    }
                }
            }

            Section {
                Button {
                    sectionDrafts.append(MenuSectionDraft())
                } label: {
                    Label("自由入力のセクションを追加", systemImage: "plus")
                }
            } footer: {
                Text("休憩やランク戦の対戦表など、カテゴリに当てはまらない内容はこちらから追加できます。")
            }
        }
        .navigationTitle("メニューを作る")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $quickAddCategory) { category in
            MenuQuickAddItemView(category: category, availableCourts: availableCourts) { itemDraft in
                addItem(itemDraft, to: category)
            }
        }
        .sheet(item: $templatePickerCategory) { category in
            MenuTemplatePickerView(category: category, availableCourts: availableCourts) { itemDrafts in
                applyItems(itemDrafts, to: category)
            }
        }
    }

    private func itemCount(for category: MenuCategoryTag) -> Int {
        sectionDrafts.first(where: { $0.categoryID == category.id })?.items.count ?? 0
    }

    private func categoryButton(_ category: MenuCategoryTag) -> some View {
        let count = itemCount(for: category)
        return Button {
            if category.supportsTemplateLibrary {
                templatePickerCategory = category
            } else {
                quickAddCategory = category
            }
        } label: {
            VStack(spacing: 6) {
                Text(category.name)
                    .font(.headline)
                Text(count > 0 ? "\(count)項目" : "追加する")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func addItem(_ itemDraft: MenuSectionItemDraft, to category: MenuCategoryTag) {
        applyItems([itemDraft], to: category)
    }

    private func applyItems(_ itemDrafts: [MenuSectionItemDraft], to category: MenuCategoryTag) {
        guard !itemDrafts.isEmpty else { return }
        if let index = sectionDrafts.firstIndex(where: { $0.categoryID == category.id }) {
            sectionDrafts[index].items.append(contentsOf: itemDrafts)
        } else {
            var newSection = MenuSectionDraft(title: category.name, categoryID: category.id)
            newSection.items.append(contentsOf: itemDrafts)
            sectionDrafts.append(newSection)
        }
    }
}

#Preview {
    NavigationStack {
        MenuBuilderView(sectionDrafts: .constant([]), availableCourts: [], durationSummary: "7月16日(木) 9:00〜11:00 (120分)")
    }
    .modelContainer(AppModelContainer.preview)
}

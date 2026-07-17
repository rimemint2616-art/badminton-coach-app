import SwiftUI
import SwiftData

/// 設定タブから開く、特定カテゴリの保存済みテンプレート一覧。作成・編集・削除ができる。
struct MenuTemplateManagementView: View {
    @Environment(\.modelContext) private var modelContext
    let category: MenuCategoryTag

    @Query(sort: [SortDescriptor(\CourtTag.sortOrder)]) private var courtTags: [CourtTag]
    @Query(sort: [SortDescriptor(\MenuTemplate.name)]) private var allTemplates: [MenuTemplate]
    @State private var isPresentingNew = false

    private var templates: [MenuTemplate] {
        allTemplates.filter { $0.category?.id == category.id }
    }

    var body: some View {
        List {
            if templates.isEmpty {
                ContentUnavailableView(
                    "テンプレートがありません",
                    systemImage: "list.bullet.clipboard",
                    description: Text("右上の＋から作成できます")
                )
            } else {
                ForEach(templates) { template in
                    NavigationLink {
                        MenuTemplateEditorView(category: category, availableCourts: courtTags, existingTemplate: template)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                            Text("\(template.items.count)項目")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteTemplates)
            }
        }
        .navigationTitle("\(category.name)のテンプレート")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isPresentingNew = true
                } label: {
                    Label("追加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNew) {
            NavigationStack {
                MenuTemplateEditorView(category: category, availableCourts: courtTags)
            }
        }
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(templates[index])
        }
    }
}

#Preview {
    NavigationStack {
        MenuTemplateManagementView(category: MenuCategoryTag(name: "フットワーク", sortOrder: 0, supportsTemplateLibrary: true))
    }
    .modelContainer(AppModelContainer.preview)
}

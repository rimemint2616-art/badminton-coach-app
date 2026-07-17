import SwiftUI
import SwiftData

/// 練習メニュー（小カテゴリ）のライブラリ管理。大カテゴリごとにセクション分けして表示する。
/// 設定タブから開く前提で、ナビゲーションは親のNavigationStackに委ねる。
struct MenuLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\PracticeMenu.name)]) private var allMenus: [PracticeMenu]

    @State private var searchText = ""
    @State private var isPresentingNewMenu = false

    private func menus(in category: MajorCategory) -> [PracticeMenu] {
        allMenus.filter { menu in
            menu.majorCategory == category &&
            (searchText.isEmpty || menu.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    private var hasAnyMatch: Bool {
        MajorCategory.allCases.contains { !menus(in: $0).isEmpty }
    }

    var body: some View {
        Group {
            if !hasAnyMatch {
                ContentUnavailableView(
                    "練習メニューがありません",
                    systemImage: "list.bullet.clipboard",
                    description: Text("右上の＋からメニューを追加してください")
                )
            } else {
                List {
                    ForEach(MajorCategory.allCases) { category in
                        let categoryMenus = menus(in: category)
                        if !categoryMenus.isEmpty {
                            Section(category.displayName) {
                                ForEach(categoryMenus) { menu in
                                    NavigationLink(value: menu) {
                                        MenuRow(menu: menu)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            duplicate(menu)
                                        } label: {
                                            Label("複製", systemImage: "plus.square.on.square")
                                        }
                                        .tint(.blue)
                                    }
                                }
                                .onDelete { deleteMenus(categoryMenus, at: $0) }
                            }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "メニュー名で検索")
        .navigationTitle("メニューライブラリ")
        .navigationDestination(for: PracticeMenu.self) { menu in
            MenuEditView(menu: menu)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isPresentingNewMenu = true
                } label: {
                    Label("メニューを追加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewMenu) {
            NavigationStack {
                MenuEditView(menu: nil)
            }
        }
    }

    private func duplicate(_ menu: PracticeMenu) {
        let copy = PracticeMenu(
            name: "\(menu.name) のコピー",
            descriptionText: menu.descriptionText,
            targetSkillTags: menu.targetSkillTags,
            durationMinutes: menu.durationMinutes,
            equipment: menu.equipment,
            difficultyLevel: menu.difficultyLevel,
            majorCategory: menu.majorCategory,
            middleCategory: menu.middleCategory
        )
        modelContext.insert(copy)
        try? modelContext.save()
    }

    private func deleteMenus(_ menus: [PracticeMenu], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(menus[index])
        }
        try? modelContext.save()
    }
}

private struct MenuRow: View {
    let menu: PracticeMenu

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(menu.name)
                .font(.headline)
            HStack {
                if let middle = menu.middleCategory {
                    Text(middle.displayName)
                }
                Text("\(menu.durationMinutes)分")
                Text(menu.difficultyLevel.displayName)
                if menu.isDefaultMenu {
                    Label("デフォルト", systemImage: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        MenuLibraryView()
    }
    .modelContainer(AppModelContainer.preview)
}

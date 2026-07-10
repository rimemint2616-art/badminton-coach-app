import SwiftUI
import SwiftData

struct MenuLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\PracticeMenu.name)]) private var allMenus: [PracticeMenu]

    @State private var searchText = ""
    @State private var selectedTag: String?
    @State private var isPresentingNewMenu = false

    private var allTags: [String] {
        Array(Set(allMenus.flatMap(\.targetSkillTags))).sorted()
    }

    private var filteredMenus: [PracticeMenu] {
        allMenus
            .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
            .filter { selectedTag == nil || $0.targetSkillTags.contains(selectedTag!) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !allTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            tagChip(label: "すべて", isSelected: selectedTag == nil) {
                                selectedTag = nil
                            }
                            ForEach(allTags, id: \.self) { tag in
                                tagChip(label: tag, isSelected: selectedTag == tag) {
                                    selectedTag = tag
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }

                if filteredMenus.isEmpty {
                    ContentUnavailableView(
                        "練習メニューがありません",
                        systemImage: "list.bullet.clipboard",
                        description: Text("右上の＋からメニューを追加してください")
                    )
                } else {
                    List {
                        ForEach(filteredMenus) { menu in
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
                        .onDelete(perform: deleteMenus)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "メニュー名で検索")
            .navigationTitle("練習メニュー")
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
    }

    private func tagChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }

    private func duplicate(_ menu: PracticeMenu) {
        let copy = PracticeMenu(
            name: "\(menu.name) のコピー",
            descriptionText: menu.descriptionText,
            targetSkillTags: menu.targetSkillTags,
            durationMinutes: menu.durationMinutes,
            equipment: menu.equipment,
            difficultyLevel: menu.difficultyLevel
        )
        modelContext.insert(copy)
        try? modelContext.save()
    }

    private func deleteMenus(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredMenus[index])
        }
    }
}

private struct MenuRow: View {
    let menu: PracticeMenu

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(menu.name)
                .font(.headline)
            HStack {
                Text("\(menu.durationMinutes)分")
                Text(menu.difficultyLevel.displayName)
                if !menu.targetSkillTags.isEmpty {
                    Text(menu.targetSkillTags.joined(separator: ", "))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    MenuLibraryView()
        .modelContainer(AppModelContainer.preview)
}

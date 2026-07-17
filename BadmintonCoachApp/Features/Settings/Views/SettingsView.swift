import SwiftUI
import SwiftData

/// 設定タブ。デフォルトメニュー（毎回の練習の最初に自動追加）や休憩の既定設定を管理する。
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\PracticeMenu.name)]) private var allMenus: [PracticeMenu]

    @AppStorage("defaultTargetMinutes") private var defaultTargetMinutes = 120
    @AppStorage("defaultBreakInterval") private var defaultBreakInterval = 30
    @AppStorage("defaultBreakDuration") private var defaultBreakDuration = 5

    @State private var isPresentingMenuPicker = false

    private var defaultMenus: [PracticeMenu] {
        allMenus.filter(\.isDefaultMenu).sorted { $0.defaultOrderIndex < $1.defaultOrderIndex }
    }
    private var nonDefaultMenus: [PracticeMenu] {
        allMenus.filter { !$0.isDefaultMenu }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if defaultMenus.isEmpty {
                        Text("設定されていません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(defaultMenus) { menu in
                            HStack {
                                Text(menu.name)
                                Spacer()
                                Text(menu.majorCategory.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onMove(perform: moveDefaultMenu)
                        .onDelete(perform: removeDefaultMenu)
                    }
                    Button {
                        isPresentingMenuPicker = true
                    } label: {
                        Label("デフォルトメニューを追加", systemImage: "plus")
                    }
                } header: {
                    Text("デフォルトメニュー")
                } footer: {
                    Text("毎回の練習の最初に自動追加されます（体操など）。並び替えできます。")
                }

                Section("既定の設定") {
                    Stepper("目標時間: \(defaultTargetMinutes)分", value: $defaultTargetMinutes, in: 10...360, step: 5)
                    Stepper("休憩の間隔: \(defaultBreakInterval)分ごと", value: $defaultBreakInterval, in: 5...120, step: 5)
                    Stepper("休憩の長さ: \(defaultBreakDuration)分", value: $defaultBreakDuration, in: 1...30)
                }

                Section("メニュー管理") {
                    NavigationLink {
                        MenuLibraryView()
                    } label: {
                        Label("メニューライブラリを管理", systemImage: "list.bullet.clipboard")
                    }
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $isPresentingMenuPicker) {
                defaultMenuPicker
            }
        }
    }

    private var defaultMenuPicker: some View {
        NavigationStack {
            List {
                if nonDefaultMenus.isEmpty {
                    Text("追加できるメニューがありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(nonDefaultMenus) { menu in
                        Button {
                            addDefaultMenu(menu)
                        } label: {
                            HStack {
                                Text(menu.name)
                                Spacer()
                                Text(menu.majorCategory.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("メニューを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { isPresentingMenuPicker = false }
                }
            }
        }
    }

    private func addDefaultMenu(_ menu: PracticeMenu) {
        menu.isDefaultMenu = true
        menu.defaultOrderIndex = (defaultMenus.map(\.defaultOrderIndex).max() ?? -1) + 1
        try? modelContext.save()
        isPresentingMenuPicker = false
    }

    private func moveDefaultMenu(from source: IndexSet, to destination: Int) {
        var reordered = defaultMenus
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, menu) in reordered.enumerated() {
            menu.defaultOrderIndex = index
        }
        try? modelContext.save()
    }

    private func removeDefaultMenu(at offsets: IndexSet) {
        let menus = defaultMenus
        for index in offsets {
            menus[index].isDefaultMenu = false
        }
        try? modelContext.save()
    }
}

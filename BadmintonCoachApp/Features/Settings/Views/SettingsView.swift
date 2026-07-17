import SwiftUI
import SwiftData

/// アプリ全体の表示設定（文字サイズなど）、学年タグの管理、バージョン情報を表示する設定タブ。
struct SettingsView: View {
    @AppStorage(AppTextSize.storageKey) private var appTextSizeRawValue: String = AppTextSize.large.rawValue

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("表示") {
                    Picker("文字サイズ", selection: $appTextSizeRawValue) {
                        ForEach(AppTextSize.allCases) { size in
                            Text(size.displayName).tag(size.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                GradeTagManagementSection()

                PointReasonTagManagementSection()

                CourtTagManagementSection()

                MenuCategoryManagementSection()

                RankChallengeGridColorSection()

                Section("このアプリについて") {
                    LabeledContent("バージョン", value: appVersion)
                }
            }
            .navigationTitle("設定")
            .toolbar {
                EditButton()
            }
        }
    }
}

/// 生徒の「学年」ピッカーに出す選択肢（GradeTag）を管理するセクション。
/// 表示/非表示の切り替え、色の変更、タグの追加・削除、既定タグへのリセットができる。
private struct GradeTagManagementSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\GradeTag.sortOrder)]) private var gradeTags: [GradeTag]

    @State private var newTagName = ""
    @State private var isPresentingResetConfirmation = false

    var body: some View {
        Section {
            ForEach(gradeTags) { tag in
                HStack(spacing: 12) {
                    ColorPicker(
                        "\(tag.name)の色",
                        selection: Binding(
                            get: { tag.color },
                            set: { tag.color = $0 }
                        )
                    )
                    .labelsHidden()

                    Text(tag.name)
                        .foregroundStyle(tag.isHidden ? .secondary : .primary)

                    Spacer()

                    Toggle(
                        "表示",
                        isOn: Binding(
                            get: { !tag.isHidden },
                            set: { tag.isHidden = !$0 }
                        )
                    )
                    .labelsHidden()
                }
            }
            .onDelete(perform: deleteTags)
            .onMove(perform: moveTags)

            HStack {
                TextField("新しいタグを追加", text: $newTagName)
                Button("追加", action: addTag)
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Button("デフォルトに戻す", role: .destructive) {
                isPresentingResetConfirmation = true
            }
        } header: {
            Text("学年タグ")
        } footer: {
            Text("スイッチで生徒の学年選択肢への表示/非表示を切り替えられます。左の丸をタップすると色を変更できます。左にスワイプするとタグを削除できます（設定済みの生徒からは学年が未設定に戻ります）。右上の「編集」でタグの並び替えができ、この順番が生徒一覧の「学年順」表示にそのまま使われます。")
        }
        .confirmationDialog(
            "学年タグをデフォルトに戻しますか？",
            isPresented: $isPresentingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("デフォルトに戻す", role: .destructive, action: resetToDefaults)
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("追加・変更したタグはすべて削除され、既定の学年タグ一式に戻ります。この操作は取り消せません。")
        }
    }

    private func addTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (gradeTags.map(\.sortOrder).max() ?? -1) + 1
        modelContext.insert(GradeTag(name: trimmed, sortOrder: nextOrder))
        newTagName = ""
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(gradeTags[index])
        }
    }

    private func moveTags(from source: IndexSet, to destination: Int) {
        var reordered = gradeTags
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, tag) in reordered.enumerated() {
            tag.sortOrder = index
        }
    }

    private func resetToDefaults() {
        gradeTags.forEach { modelContext.delete($0) }
        DefaultGradeTags.makeAll().forEach { modelContext.insert($0) }
    }
}

/// 「流れ」モードでポイント記録後に選ぶ理由候補（PointReasonTag）を管理するセクション。
/// タグの追加・削除・並び替え、既定タグへのリセットができる。GradeTagと同じ設計。
private struct PointReasonTagManagementSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\PointReasonTag.sortOrder)]) private var reasonTags: [PointReasonTag]

    @State private var newTagName = ""
    @State private var isPresentingResetConfirmation = false

    var body: some View {
        Section {
            ForEach(reasonTags) { tag in
                Text(tag.name)
            }
            .onDelete(perform: deleteTags)
            .onMove(perform: moveTags)

            HStack {
                TextField("新しい理由タグを追加", text: $newTagName)
                Button("追加", action: addTag)
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Button("デフォルトに戻す", role: .destructive) {
                isPresentingResetConfirmation = true
            }
        } header: {
            Text("ポイント理由タグ")
        } footer: {
            Text("「試合」タブの流れ記録で、ポイントを取った理由として表示される候補です。左にスワイプすると削除、右上の「編集」で並び替えができます。")
        }
        .confirmationDialog(
            "ポイント理由タグをデフォルトに戻しますか？",
            isPresented: $isPresentingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("デフォルトに戻す", role: .destructive, action: resetToDefaults)
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("追加・変更したタグはすべて削除され、既定の理由タグ一式に戻ります。この操作は取り消せません。")
        }
    }

    private func addTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (reasonTags.map(\.sortOrder).max() ?? -1) + 1
        modelContext.insert(PointReasonTag(name: trimmed, sortOrder: nextOrder))
        newTagName = ""
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(reasonTags[index])
        }
    }

    private func moveTags(from source: IndexSet, to destination: Int) {
        var reordered = reasonTags
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, tag) in reordered.enumerated() {
            tag.sortOrder = index
        }
    }

    private func resetToDefaults() {
        reasonTags.forEach { modelContext.delete($0) }
        DefaultPointReasonTags.makeAll().forEach { modelContext.insert($0) }
    }
}

/// 練習メニューで使う「コート」（数・呼び方）を管理するセクション。
/// タグの追加・削除・並び替え、既定タグへのリセットができる。GradeTag/PointReasonTagと同じ設計。
private struct CourtTagManagementSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\CourtTag.sortOrder)]) private var courtTags: [CourtTag]

    @State private var newTagName = ""
    @State private var isPresentingResetConfirmation = false

    var body: some View {
        Section {
            ForEach(courtTags) { tag in
                Text(tag.name)
            }
            .onDelete(perform: deleteTags)
            .onMove(perform: moveTags)

            HStack {
                TextField("新しいコートを追加", text: $newTagName)
                Button("追加", action: addTag)
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Button("デフォルトに戻す", role: .destructive) {
                isPresentingResetConfirmation = true
            }
        } header: {
            Text("コート")
        } footer: {
            Text("練習メニューの各行に割り当てられるコートの数・呼び方です。左にスワイプすると削除、右上の「編集」で並び替えができます。削除しても、そのコートが割り当てられていた練習メニューの行自体は消えず、コート表示だけが外れます。")
        }
        .confirmationDialog(
            "コートをデフォルトに戻しますか？",
            isPresented: $isPresentingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("デフォルトに戻す", role: .destructive, action: resetToDefaults)
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("追加・変更したコートはすべて削除され、既定のコート一式に戻ります。この操作は取り消せません。")
        }
    }

    private func addTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (courtTags.map(\.sortOrder).max() ?? -1) + 1
        modelContext.insert(CourtTag(name: trimmed, sortOrder: nextOrder))
        newTagName = ""
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(courtTags[index])
        }
    }

    private func moveTags(from source: IndexSet, to destination: Int) {
        var reordered = courtTags
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, tag) in reordered.enumerated() {
            tag.sortOrder = index
        }
    }

    private func resetToDefaults() {
        courtTags.forEach { modelContext.delete($0) }
        DefaultCourtTags.makeAll().forEach { modelContext.insert($0) }
    }
}

/// 練習メニューの「カテゴリ」（体操・フットワークなど）を管理するセクション。
/// カテゴリの追加・削除・並び替えに加え、「毎回追加」（新規メニュー作成時の自動セクション化+所要時間）
/// と「テンプレート機能」（カテゴリ別の保存済みメニュー呼び出し）をカテゴリごとに切り替えられる。
private struct MenuCategoryManagementSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\MenuCategoryTag.sortOrder)]) private var categoryTags: [MenuCategoryTag]

    @State private var newTagName = ""
    @State private var isPresentingResetConfirmation = false

    var body: some View {
        Section {
            ForEach(categoryTags) { tag in
                categoryRow(tag)
            }
            .onDelete(perform: deleteTags)
            .onMove(perform: moveTags)

            HStack {
                TextField("新しいカテゴリを追加", text: $newTagName)
                Button("追加", action: addTag)
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Button("デフォルトに戻す", role: .destructive) {
                isPresentingResetConfirmation = true
            }
        } header: {
            Text("練習メニューのカテゴリ")
        } footer: {
            Text("「メニューを作る」画面のカテゴリボタンです。「毎回追加」をオンにすると、新規メニュー作成時に自動でセクションが追加されます。「テンプレート機能」をオンにすると、そのカテゴリでよく使うメニューを名前を付けて保存・呼び出しできるようになります。左にスワイプすると削除、右上の「編集」で並び替えができます。")
        }
        .confirmationDialog(
            "カテゴリをデフォルトに戻しますか？",
            isPresented: $isPresentingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("デフォルトに戻す", role: .destructive, action: resetToDefaults)
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("追加・変更したカテゴリはすべて削除され、既定の5カテゴリに戻ります。保存済みのテンプレートも削除されます。この操作は取り消せません。")
        }
    }

    @ViewBuilder
    private func categoryRow(_ tag: MenuCategoryTag) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tag.name)

            Toggle(
                "毎回追加",
                isOn: Binding(
                    get: { tag.isStandardEveryPractice },
                    set: { tag.isStandardEveryPractice = $0 }
                )
            )
            .font(.caption)

            if tag.isStandardEveryPractice {
                Stepper(
                    "\(tag.standardDurationMinutes ?? 5)分",
                    value: Binding(
                        get: { tag.standardDurationMinutes ?? 5 },
                        set: { tag.standardDurationMinutes = $0 }
                    ),
                    in: 1...60
                )
                .font(.caption)
            }

            Toggle(
                "テンプレート機能",
                isOn: Binding(
                    get: { tag.supportsTemplateLibrary },
                    set: { tag.supportsTemplateLibrary = $0 }
                )
            )
            .font(.caption)

            if tag.supportsTemplateLibrary {
                NavigationLink {
                    MenuTemplateManagementView(category: tag)
                } label: {
                    Text("テンプレートを管理（\(tag.templates.count)件）")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func addTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (categoryTags.map(\.sortOrder).max() ?? -1) + 1
        modelContext.insert(MenuCategoryTag(name: trimmed, sortOrder: nextOrder))
        newTagName = ""
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categoryTags[index])
        }
    }

    private func moveTags(from source: IndexSet, to destination: Int) {
        var reordered = categoryTags
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, tag) in reordered.enumerated() {
            tag.sortOrder = index
        }
    }

    private func resetToDefaults() {
        categoryTags.forEach { modelContext.delete($0) }
        DefaultMenuCategoryTags.makeAll().forEach { modelContext.insert($0) }
    }
}

/// ランク戦の対戦表で、行の選手が勝った時・列の選手が勝った時のマスの背景色を変更するセクション。
private struct RankChallengeGridColorSection: View {
    @AppStorage(RankChallengeGridColors.rowWinnerKey) private var rowWinnerHex: String = RankChallengeGridColors.defaultRowWinnerHex
    @AppStorage(RankChallengeGridColors.columnWinnerKey) private var columnWinnerHex: String = RankChallengeGridColors.defaultColumnWinnerHex

    var body: some View {
        Section {
            ColorPicker(
                "行の選手が勝った時の色",
                selection: Binding(
                    get: { Color(hex: rowWinnerHex) },
                    set: { rowWinnerHex = $0.hexString }
                )
            )
            ColorPicker(
                "列の選手が勝った時の色",
                selection: Binding(
                    get: { Color(hex: columnWinnerHex) },
                    set: { columnWinnerHex = $0.hexString }
                )
            )
        } header: {
            Text("ランク戦の対戦表")
        } footer: {
            Text("対戦表のマスは、勝った選手が表の行と列のどちらにいるかで背景色が変わります。")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(AppModelContainer.preview)
}

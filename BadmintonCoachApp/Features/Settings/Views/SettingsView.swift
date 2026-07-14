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

#Preview {
    SettingsView()
        .modelContainer(AppModelContainer.preview)
}

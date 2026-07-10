import SwiftUI
import SwiftData

/// 練習メニュー（ドリル）の新規作成・編集フォーム。
/// `menu` が nil なら新規作成、値があれば既存インスタンスのプロパティを直接更新する。
struct MenuEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let menu: PracticeMenu?

    @State private var name: String
    @State private var descriptionText: String
    @State private var tagsText: String
    @State private var durationMinutes: Int
    @State private var equipment: String
    @State private var difficultyLevel: DifficultyLevel

    init(menu: PracticeMenu?) {
        self.menu = menu
        _name = State(initialValue: menu?.name ?? "")
        _descriptionText = State(initialValue: menu?.descriptionText ?? "")
        _tagsText = State(initialValue: menu?.targetSkillTags.joined(separator: ", ") ?? "")
        _durationMinutes = State(initialValue: menu?.durationMinutes ?? 10)
        _equipment = State(initialValue: menu?.equipment ?? "")
        _difficultyLevel = State(initialValue: menu?.difficultyLevel ?? .beginner)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("基本情報") {
                TextField("メニュー名", text: $name)
                TextEditor(text: $descriptionText)
                    .frame(minHeight: 100)
                TextField("対象スキルのタグ（カンマ区切り）", text: $tagsText)
            }

            Section("詳細") {
                Stepper("所要時間: \(durationMinutes)分", value: $durationMinutes, in: 1...120)
                TextField("使用器具", text: $equipment)
                Picker("難易度", selection: $difficultyLevel) {
                    ForEach(DifficultyLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
            }
        }
        .navigationTitle(menu == nil ? "メニューを追加" : "メニューを編集")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
                    .disabled(!isValid)
            }
        }
    }

    private func save() {
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let menu {
            menu.name = trimmedName
            menu.descriptionText = descriptionText
            menu.targetSkillTags = tags
            menu.durationMinutes = durationMinutes
            menu.equipment = equipment
            menu.difficultyLevel = difficultyLevel
        } else {
            let newMenu = PracticeMenu(
                name: trimmedName,
                descriptionText: descriptionText,
                targetSkillTags: tags,
                durationMinutes: durationMinutes,
                equipment: equipment,
                difficultyLevel: difficultyLevel
            )
            modelContext.insert(newMenu)
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview("新規作成") {
    NavigationStack {
        MenuEditView(menu: nil)
    }
    .modelContainer(AppModelContainer.preview)
}

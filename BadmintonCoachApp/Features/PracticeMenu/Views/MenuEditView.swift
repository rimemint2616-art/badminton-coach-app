import SwiftUI
import SwiftData

/// 練習メニュー（小カテゴリ）の新規作成・編集フォーム。
/// `menu` が nil なら新規作成、値があれば既存インスタンスのプロパティを直接更新する。
/// `presetMajor` / `presetMiddle` を渡すと、そのカテゴリを初期選択した状態で新規作成できる。
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
    @State private var majorCategory: MajorCategory
    @State private var middleCategory: MiddleCategory
    @State private var isDefaultMenu: Bool

    init(menu: PracticeMenu?, presetMajor: MajorCategory? = nil, presetMiddle: MiddleCategory? = nil) {
        self.menu = menu
        _name = State(initialValue: menu?.name ?? "")
        _descriptionText = State(initialValue: menu?.descriptionText ?? "")
        _tagsText = State(initialValue: menu?.targetSkillTags.joined(separator: ", ") ?? "")
        _durationMinutes = State(initialValue: menu?.durationMinutes ?? 10)
        _equipment = State(initialValue: menu?.equipment ?? "")
        _difficultyLevel = State(initialValue: menu?.difficultyLevel ?? .beginner)
        _majorCategory = State(initialValue: menu?.majorCategory ?? presetMajor ?? .footwork)
        _middleCategory = State(initialValue: menu?.middleCategory ?? presetMiddle ?? .singles)
        _isDefaultMenu = State(initialValue: menu?.isDefaultMenu ?? false)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section("カテゴリ") {
                Picker("大カテゴリ", selection: $majorCategory) {
                    ForEach(MajorCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                if majorCategory.hasMiddleCategory {
                    Picker("中カテゴリ", selection: $middleCategory) {
                        ForEach(MiddleCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                LabeledContent("測定方法", value: formatDescription)
            }

            Section("基本情報") {
                TextField("メニュー名", text: $name)
                TextEditor(text: $descriptionText)
                    .frame(minHeight: 100)
                TextField("対象スキルのタグ（カンマ区切り）", text: $tagsText)
            }

            Section("詳細") {
                Stepper("目安時間: \(durationMinutes)分", value: $durationMinutes, in: 1...120)
                TextField("使用器具", text: $equipment)
                Picker("難易度", selection: $difficultyLevel) {
                    ForEach(DifficultyLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
            }

            Section {
                Toggle("デフォルトメニューにする", isOn: $isDefaultMenu)
            } footer: {
                Text("オンにすると、毎回の練習メニュー作成時に最初へ自動追加されます。")
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

    private var formatDescription: String {
        switch majorCategory.format {
        case .simple: return "時間のみ"
        case .repsAndSets: return "回数/球数 × セット"
        case .minutes: return "分"
        case .pointMatch: return "点マッチ"
        }
    }

    private func save() {
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedMiddle: MiddleCategory? = majorCategory.hasMiddleCategory ? middleCategory : nil

        if let menu {
            menu.name = trimmedName
            menu.descriptionText = descriptionText
            menu.targetSkillTags = tags
            menu.durationMinutes = durationMinutes
            menu.equipment = equipment
            menu.difficultyLevel = difficultyLevel
            menu.majorCategory = majorCategory
            menu.middleCategory = resolvedMiddle
            menu.isDefaultMenu = isDefaultMenu
        } else {
            let newMenu = PracticeMenu(
                name: trimmedName,
                descriptionText: descriptionText,
                targetSkillTags: tags,
                durationMinutes: durationMinutes,
                equipment: equipment,
                difficultyLevel: difficultyLevel,
                majorCategory: majorCategory,
                middleCategory: resolvedMiddle,
                isDefaultMenu: isDefaultMenu
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

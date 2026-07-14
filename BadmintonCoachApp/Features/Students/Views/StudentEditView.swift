import SwiftUI
import SwiftData

/// 生徒の新規作成・編集フォーム。
/// `student` が nil なら新規作成、値があれば既存インスタンスのプロパティを直接更新する。
struct StudentEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\GradeTag.sortOrder)]) private var allGradeTags: [GradeTag]
    /// 直前に選んだ学年タグのID。新規追加フォームを開いたときの初期値として使い、
    /// 同じ学年の生徒を何人も続けて登録するときの手間を減らす。
    @AppStorage("lastUsedGradeTagID") private var lastUsedGradeTagIDRawValue = ""

    let student: Student?

    @State private var name: String
    @State private var nameKana: String
    @State private var dominantHand: DominantHand?
    @State private var gradeTag: GradeTag?
    @State private var rankText: String
    @State private var notes: String
    @State private var didJustAddAnother = false
    @FocusState private var isNameFieldFocused: Bool

    init(student: Student?) {
        self.student = student
        _name = State(initialValue: student?.name ?? "")
        _nameKana = State(initialValue: student?.nameKana ?? "")
        _dominantHand = State(initialValue: student?.dominantHand)
        _gradeTag = State(initialValue: student?.gradeTag)
        _rankText = State(initialValue: student?.rank.map(String.init) ?? "")
        _notes = State(initialValue: student?.notes ?? "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 非表示に設定されたタグはピッカーから外すが、既にその生徒に設定済みの場合は選択肢として残す
    /// （非表示にしただけで既存データが見えなくなるのを防ぐため）。
    private var availableGradeTags: [GradeTag] {
        allGradeTags.filter { !$0.isHidden || $0.id == gradeTag?.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                if didJustAddAnother {
                    Section {
                        Label("生徒を追加しました。続けて次の生徒を入力できます。", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section("基本情報") {
                    TextField("氏名", text: $name)
                        .focused($isNameFieldFocused)
                    TextField("フリガナ", text: $nameKana)
                    Picker("学年", selection: $gradeTag) {
                        Text("未設定").tag(GradeTag?.none)
                        ForEach(availableGradeTags) { tag in
                            Text(tag.name).tag(GradeTag?.some(tag))
                        }
                    }
                }

                Section("プレースタイル") {
                    Picker("利き手", selection: $dominantHand) {
                        Text("未設定").tag(DominantHand?.none)
                        ForEach(DominantHand.allCases) { hand in
                            Text(hand.displayName).tag(DominantHand?.some(hand))
                        }
                    }
                }

                Section {
                    TextField("ランク（数字が小さいほど上位）", text: $rankText)
                        .keyboardType(.numberPad)
                } header: {
                    Text("ランク")
                }

                Section("メモ") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                if student == nil {
                    Section {
                        Button {
                            saveAndAddAnother()
                        } label: {
                            Label("保存して続けて追加", systemImage: "person.badge.plus")
                        }
                        .disabled(!isValid)
                    } footer: {
                        Text("学年・利き手は次の生徒にも引き継がれるので、氏名だけ入力してすぐ次を登録できます。")
                    }
                }
            }
            .navigationTitle(student == nil ? "生徒を追加" : "生徒を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if student == nil && gradeTag == nil {
                    gradeTag = lastUsedGradeTag()
                }
            }
        }
    }

    private func lastUsedGradeTag() -> GradeTag? {
        guard let uuid = UUID(uuidString: lastUsedGradeTagIDRawValue) else { return nil }
        return allGradeTags.first { $0.id == uuid }
    }

    private func save() {
        persist()
        dismiss()
    }

    private func saveAndAddAnother() {
        persist()
        name = ""
        nameKana = ""
        rankText = ""
        notes = ""
        didJustAddAnother = true
        isNameFieldFocused = true
    }

    private func persist() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKana = nameKana.trimmingCharacters(in: .whitespacesAndNewlines)
        let rank = Int(rankText.trimmingCharacters(in: .whitespacesAndNewlines))

        if let student {
            student.name = trimmedName
            student.nameKana = trimmedKana.isEmpty ? nil : trimmedKana
            student.dominantHand = dominantHand
            student.gradeTag = gradeTag
            student.rank = rank
            student.notes = notes
        } else {
            let newStudent = Student(
                name: trimmedName,
                nameKana: trimmedKana.isEmpty ? nil : trimmedKana,
                dominantHand: dominantHand,
                gradeTag: gradeTag,
                rank: rank,
                notes: notes
            )
            modelContext.insert(newStudent)
        }
        try? modelContext.save()

        if let gradeTag {
            lastUsedGradeTagIDRawValue = gradeTag.id.uuidString
        }
    }
}

#Preview("新規作成") {
    StudentEditView(student: nil)
        .modelContainer(AppModelContainer.preview)
}

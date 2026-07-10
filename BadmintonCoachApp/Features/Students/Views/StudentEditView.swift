import SwiftUI
import SwiftData

/// 生徒の新規作成・編集フォーム。
/// `student` が nil なら新規作成、値があれば既存インスタンスのプロパティを直接更新する。
struct StudentEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let student: Student?

    @State private var name: String
    @State private var nameKana: String
    @State private var hasBirthdate: Bool
    @State private var birthdate: Date
    @State private var dominantHand: DominantHand?
    @State private var level: StudentLevel
    @State private var notes: String

    init(student: Student?) {
        self.student = student
        _name = State(initialValue: student?.name ?? "")
        _nameKana = State(initialValue: student?.nameKana ?? "")
        _hasBirthdate = State(initialValue: student?.birthdate != nil)
        _birthdate = State(initialValue: student?.birthdate ?? .now)
        _dominantHand = State(initialValue: student?.dominantHand)
        _level = State(initialValue: student?.level ?? .beginner)
        _notes = State(initialValue: student?.notes ?? "")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("氏名", text: $name)
                    TextField("フリガナ", text: $nameKana)
                    Toggle("生年月日を設定", isOn: $hasBirthdate)
                    if hasBirthdate {
                        DatePicker("生年月日", selection: $birthdate, displayedComponents: .date)
                    }
                }

                Section("プレースタイル") {
                    Picker("利き手", selection: $dominantHand) {
                        Text("未設定").tag(DominantHand?.none)
                        ForEach(DominantHand.allCases) { hand in
                            Text(hand.displayName).tag(DominantHand?.some(hand))
                        }
                    }
                    Picker("レベル", selection: $level) {
                        ForEach(StudentLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }

                Section("メモ") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
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
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKana = nameKana.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedBirthdate: Date? = hasBirthdate ? birthdate : nil

        if let student {
            student.name = trimmedName
            student.nameKana = trimmedKana.isEmpty ? nil : trimmedKana
            student.birthdate = resolvedBirthdate
            student.dominantHand = dominantHand
            student.level = level
            student.notes = notes
        } else {
            let newStudent = Student(
                name: trimmedName,
                nameKana: trimmedKana.isEmpty ? nil : trimmedKana,
                birthdate: resolvedBirthdate,
                dominantHand: dominantHand,
                level: level,
                notes: notes
            )
            modelContext.insert(newStudent)
        }
        dismiss()
    }
}

#Preview("新規作成") {
    StudentEditView(student: nil)
        .modelContainer(AppModelContainer.preview)
}

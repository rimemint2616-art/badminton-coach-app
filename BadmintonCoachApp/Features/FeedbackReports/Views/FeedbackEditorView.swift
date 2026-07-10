import SwiftUI
import SwiftData

/// フィードバックの新規作成フォーム。source は常に .manual（AI解析は将来のフェーズで追加予定）。
struct FeedbackEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let student: Student
    var match: Match?
    var session: PracticeSession?

    @State private var date: Date = .now
    @State private var category: FeedbackCategory?
    @State private var text: String = ""

    private var isValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("対象") {
                    LabeledContent("生徒", value: student.name)
                    if let match {
                        LabeledContent("紐づく試合", value: "\(match.player1?.name ?? "?") vs \(match.player2?.name ?? "?")")
                    }
                    if let session {
                        LabeledContent("紐づく練習", value: session.date.formatted(date: .abbreviated, time: .omitted))
                    }
                }

                Section("内容") {
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                    Picker("カテゴリー", selection: $category) {
                        Text("未設定").tag(FeedbackCategory?.none)
                        ForEach(FeedbackCategory.allCases) { category in
                            Text(category.displayName).tag(FeedbackCategory?.some(category))
                        }
                    }
                    TextEditor(text: $text)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("フィードバックを追加")
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
        let feedback = Feedback(
            date: date,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            source: .manual,
            student: student,
            session: session,
            match: match
        )
        modelContext.insert(feedback)
        student.feedbackEntries.append(feedback)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let container = AppModelContainer.preview
    let student = try! container.mainContext.fetch(FetchDescriptor<Student>()).first!
    return FeedbackEditorView(student: student)
        .modelContainer(container)
}

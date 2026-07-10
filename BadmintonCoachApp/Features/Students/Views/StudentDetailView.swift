import SwiftUI
import SwiftData

struct StudentDetailView: View {
    @Bindable var student: Student
    @State private var isPresentingEdit = false
    @State private var isPresentingFeedback = false

    private var allMatches: [Match] {
        (student.matchesAsPlayer1 + student.matchesAsPlayer2)
            .sorted { $0.date > $1.date }
    }

    private var sortedFeedback: [Feedback] {
        student.feedbackEntries.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section("プロフィール") {
                LabeledContent("氏名", value: student.name)
                if let kana = student.nameKana, !kana.isEmpty {
                    LabeledContent("フリガナ", value: kana)
                }
                LabeledContent("レベル", value: student.level.displayName)
                if let hand = student.dominantHand {
                    LabeledContent("利き手", value: hand.displayName)
                }
                LabeledContent("入会日", value: student.joinedDate.formatted(date: .abbreviated, time: .omitted))
                if student.isArchived {
                    Label("アーカイブ済み", systemImage: "archivebox.fill")
                        .foregroundStyle(.secondary)
                }
                if !student.notes.isEmpty {
                    Text(student.notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("試合履歴（\(allMatches.count)）") {
                if allMatches.isEmpty {
                    Text("記録された試合はまだありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(allMatches) { match in
                        NavigationLink(value: match) {
                            MatchSummaryRow(match: match, student: student)
                        }
                    }
                }
            }

            Section {
                if sortedFeedback.isEmpty {
                    Text("フィードバックはまだありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedFeedback) { feedback in
                        FeedbackRow(feedback: feedback)
                    }
                }
                Button {
                    isPresentingFeedback = true
                } label: {
                    Label("フィードバックを追加", systemImage: "plus.bubble")
                }
            } header: {
                Text("フィードバック（\(sortedFeedback.count)）")
            }

            Section {
                NavigationLink {
                    ReportGeneratorView(student: student)
                } label: {
                    Label("PDFレポートを作成", systemImage: "doc.richtext")
                }
            }
        }
        .navigationTitle(student.name)
        .navigationDestination(for: Match.self) { match in
            MatchDetailView(match: match)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") {
                    isPresentingEdit = true
                }
            }
        }
        .sheet(isPresented: $isPresentingEdit) {
            StudentEditView(student: student)
        }
        .sheet(isPresented: $isPresentingFeedback) {
            FeedbackEditorView(student: student)
        }
    }
}

private struct MatchSummaryRow: View {
    let match: Match
    let student: Student

    private var opponentName: String {
        if match.player1 === student {
            return match.player2?.name ?? "（不明）"
        } else {
            return match.player1?.name ?? "（不明）"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("vs \(opponentName)")
                .font(.subheadline)
            HStack {
                Text(match.date.formatted(date: .abbreviated, time: .shortened))
                Spacer()
                Text(match.status.displayName)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

private struct FeedbackRow: View {
    let feedback: Feedback

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let category = feedback.category {
                    Text(category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.15), in: Capsule())
                }
                Spacer()
                Text(feedback.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(feedback.text)
                .font(.body)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        let container = AppModelContainer.preview
        let student = try! container.mainContext.fetch(FetchDescriptor<Student>()).first!
        StudentDetailView(student: student)
    }
    .modelContainer(AppModelContainer.preview)
}

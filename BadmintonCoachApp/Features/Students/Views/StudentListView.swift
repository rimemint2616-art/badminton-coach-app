import SwiftUI
import SwiftData

struct StudentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Student.name)]) private var allStudents: [Student]

    @State private var searchText = ""
    @State private var showArchived = false
    @State private var isPresentingNewStudent = false

    private var filteredStudents: [Student] {
        allStudents
            .filter { showArchived || !$0.isArchived }
            .filter {
                searchText.isEmpty
                    || $0.name.localizedCaseInsensitiveContains(searchText)
                    || ($0.nameKana ?? "").localizedCaseInsensitiveContains(searchText)
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredStudents.isEmpty {
                    ContentUnavailableView(
                        "生徒がいません",
                        systemImage: "person.2.slash",
                        description: Text("右上の＋から生徒を追加してください")
                    )
                } else {
                    List {
                        ForEach(filteredStudents) { student in
                            NavigationLink(value: student) {
                                StudentRow(student: student)
                            }
                        }
                        .onDelete(perform: archiveStudents)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "生徒名で検索")
            .navigationTitle("生徒")
            .navigationDestination(for: Student.self) { student in
                StudentDetailView(student: student)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingNewStudent = true
                    } label: {
                        Label("生徒を追加", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Toggle("アーカイブ済みを表示", isOn: $showArchived)
                        .toggleStyle(.button)
                }
            }
            .sheet(isPresented: $isPresentingNewStudent) {
                StudentEditView(student: nil)
            }
        }
    }

    /// 試合・フィードバック履歴を持つ生徒はハード削除せず isArchived を立てるだけにする。
    /// 履歴が無い生徒はその場で完全に削除してよい。
    private func archiveStudents(at offsets: IndexSet) {
        for index in offsets {
            let student = filteredStudents[index]
            let hasHistory = !student.matchesAsPlayer1.isEmpty
                || !student.matchesAsPlayer2.isEmpty
                || !student.feedbackEntries.isEmpty
            if hasHistory {
                student.isArchived = true
            } else {
                modelContext.delete(student)
            }
        }
    }
}

private struct StudentRow: View {
    let student: Student

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(student.name)
                    .font(.headline)
                if let kana = student.nameKana, !kana.isEmpty {
                    Text(kana)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(student.level.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.15), in: Capsule())
            if student.isArchived {
                Image(systemName: "archivebox")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    StudentListView()
        .modelContainer(AppModelContainer.preview)
}

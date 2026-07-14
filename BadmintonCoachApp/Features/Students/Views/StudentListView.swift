import SwiftUI
import SwiftData

/// 生徒一覧の並び順。学年順は設定タブでの学年タグの並び順（GradeTag.sortOrder）に従う。
enum StudentSortMode: String, CaseIterable, Identifiable {
    case grade, rank

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .grade: return "学年順"
        case .rank: return "ランク順"
        }
    }
}

/// 学年順表示のときに使う、学年タグごとの生徒グループ。
private struct GradeGroup: Identifiable {
    let tag: GradeTag?
    let students: [Student]
    var id: String { tag?.id.uuidString ?? "none" }
}

struct StudentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Student.name)]) private var allStudents: [Student]

    @State private var searchText = ""
    @State private var showArchived = false
    @State private var isPresentingNewStudent = false
    @AppStorage("studentSortMode") private var sortModeRawValue = StudentSortMode.grade.rawValue

    private var sortMode: StudentSortMode {
        StudentSortMode(rawValue: sortModeRawValue) ?? .grade
    }

    private var filteredStudents: [Student] {
        let filtered = allStudents
            .filter { showArchived || !$0.isArchived }
            .filter {
                searchText.isEmpty
                    || $0.name.localizedCaseInsensitiveContains(searchText)
                    || ($0.nameKana ?? "").localizedCaseInsensitiveContains(searchText)
            }

        switch sortMode {
        case .grade:
            return filtered.sorted { lhs, rhs in
                let l = lhs.gradeTag?.sortOrder ?? Int.max
                let r = rhs.gradeTag?.sortOrder ?? Int.max
                if l != r { return l < r }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        case .rank:
            return filtered.sorted { lhs, rhs in
                let l = lhs.rank ?? Int.max
                let r = rhs.rank ?? Int.max
                if l != r { return l < r }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
    }

    /// 学年順のとき、既にソート済みのfilteredStudentsを学年タグ単位でグループ化する
    /// （隣り合う要素だけ見ればよいので、事前ソート済みという前提で軽量に計算できる）。
    private var groupedByGrade: [GradeGroup] {
        var groups: [GradeGroup] = []
        for student in filteredStudents {
            if let last = groups.last, last.tag?.id == student.gradeTag?.id {
                groups[groups.count - 1] = GradeGroup(tag: last.tag, students: last.students + [student])
            } else {
                groups.append(GradeGroup(tag: student.gradeTag, students: [student]))
            }
        }
        return groups
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sortModeSwitcher

                Group {
                    if filteredStudents.isEmpty {
                        ContentUnavailableView(
                            "生徒がいません",
                            systemImage: "person.2.slash",
                            description: Text("右上の＋から生徒を追加してください")
                        )
                    } else {
                        List {
                            switch sortMode {
                            case .grade:
                                ForEach(groupedByGrade) { group in
                                    Section {
                                        ForEach(group.students) { student in
                                            NavigationLink(value: student) {
                                                GradeGroupedStudentRow(student: student)
                                            }
                                            .listRowBackground(group.tag?.color.opacity(0.18))
                                        }
                                        .onDelete { offsets in
                                            archiveStudents(students: group.students, at: offsets)
                                        }
                                    } header: {
                                        Text(group.tag?.name ?? "学年未設定")
                                            .font(.title3.weight(.bold))
                                            .foregroundStyle(group.tag?.color ?? .secondary)
                                    }
                                }
                            case .rank:
                                ForEach(filteredStudents) { student in
                                    NavigationLink(value: student) {
                                        RankedStudentRow(student: student)
                                    }
                                    .listRowBackground(student.gradeTag?.color.opacity(0.18))
                                }
                                .onDelete { offsets in
                                    archiveStudents(students: filteredStudents, at: offsets)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "生徒名で検索")
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

    /// 学年順/ランク順を切り替える大きめのスイッチャー。iPadでタップしやすいよう、
    /// RootTabViewのタブバーと同じデザイン言語（大きい文字＋角丸ハイライト）にしている。
    private var sortModeSwitcher: some View {
        HStack(spacing: 8) {
            ForEach(StudentSortMode.allCases) { mode in
                Button {
                    sortModeRawValue = mode.rawValue
                } label: {
                    Text(mode.displayName)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(sortMode == mode ? Color.accentColor : Color.primary)
                        .background(
                            sortMode == mode ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    /// 試合・フィードバック履歴を持つ生徒はハード削除せず isArchived を立てるだけにする。
    /// 履歴が無い生徒はその場で完全に削除してよい。
    private func archiveStudents(students: [Student], at offsets: IndexSet) {
        for index in offsets {
            let student = students[index]
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

/// 学年順表示の行。学年名はセクションヘッダーに出すので、ここでは名前とランクだけ。
private struct GradeGroupedStudentRow: View {
    let student: Student

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(student.name)
                    .font(.title2.weight(.semibold))
                if let kana = student.nameKana, !kana.isEmpty {
                    Text(kana)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let rank = student.rank {
                Text("#\(rank)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            if student.isArchived {
                Image(systemName: "archivebox")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

/// ランク順表示の行。ランク番号を大きく前面に出し、順位が一目でわかるようにする。
private struct RankedStudentRow: View {
    let student: Student

    var body: some View {
        HStack(spacing: 16) {
            Text(student.rank.map { "#\($0)" } ?? "―")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(student.rank == nil ? Color.secondary : Color.accentColor)
                .frame(minWidth: 90, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(student.name)
                    .font(.title2.weight(.semibold))
                if let kana = student.nameKana, !kana.isEmpty {
                    Text(kana)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let gradeTag = student.gradeTag {
                    Text(gradeTag.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if student.isArchived {
                Image(systemName: "archivebox")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    StudentListView()
        .modelContainer(AppModelContainer.preview)
}

import SwiftUI
import SwiftData

/// ランク戦の参加者・ブロック分けを決めて組み合わせを自動生成する画面。
struct RankChallengeSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Student.name)]) private var allStudents: [Student]
    @Query(sort: [SortDescriptor(\GradeTag.sortOrder)]) private var gradeTags: [GradeTag]

    @State private var name: String
    @State private var selectedStudentIDs: Set<UUID> = []
    @State private var useBlocks = false
    @State private var blockCount = 2
    @State private var distributionMode: RankChallengePairingGenerator.DistributionMode = .byRank
    @State private var isPresentingSizeAdjustment = false
    @State private var proposedBlockSizes: [Int] = []

    init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        _name = State(initialValue: "\(formatter.string(from: .now))度 ランク戦")
    }

    private struct GradeGroup: Identifiable {
        let tag: GradeTag?
        let students: [Student]
        var id: String { tag?.id.uuidString ?? "ungraded" }
    }

    private var activeStudents: [Student] {
        allStudents.filter { !$0.isArchived }
    }

    private var selectedStudents: [Student] {
        activeStudents.filter { selectedStudentIDs.contains($0.id) }
    }

    /// 学年タグごとに参加者候補をまとめ、グループ単位で全選択できるようにする。
    private var gradeGroups: [GradeGroup] {
        let byTagID = Dictionary(grouping: activeStudents) { $0.gradeTag?.id }
        var result: [GradeGroup] = []
        for tag in gradeTags {
            if let students = byTagID[tag.id], !students.isEmpty {
                result.append(GradeGroup(tag: tag, students: students.sorted { ($0.rank ?? Int.max) < ($1.rank ?? Int.max) }))
            }
        }
        if let ungraded = byTagID[nil], !ungraded.isEmpty {
            result.append(GradeGroup(tag: nil, students: ungraded.sorted { $0.name < $1.name }))
        }
        return result
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedStudentIDs.count >= 2
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("大会名") {
                    TextField("大会名", text: $name)
                }

                ForEach(gradeGroups) { group in
                    Section {
                        ForEach(group.students) { student in
                            Button {
                                toggle(student)
                            } label: {
                                HStack {
                                    Text(student.name)
                                    Spacer()
                                    if selectedStudentIDs.contains(student.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.primary)
                        }
                    } header: {
                        HStack {
                            Text(group.tag?.name ?? "学年未設定")
                            Spacer()
                            Button(isGroupFullySelected(group) ? "全解除" : "全選択") {
                                toggleGroup(group)
                            }
                            .font(.caption)
                            .textCase(nil)
                        }
                    }
                }

                Section {
                    Toggle("ブロックに分ける", isOn: $useBlocks)
                    if useBlocks {
                        Stepper("ブロック数: \(blockCount)", value: $blockCount, in: 2...6)
                        Picker("組み合わせ順", selection: $distributionMode) {
                            Text("ランク順").tag(RankChallengePairingGenerator.DistributionMode.byRank)
                            Text("ランダム").tag(RankChallengePairingGenerator.DistributionMode.random)
                        }
                        .pickerStyle(.segmented)
                    }
                } header: {
                    Text("参加者（\(selectedStudentIDs.count)名選択中）")
                } footer: {
                    Text(useBlocks
                        ? (distributionMode == .byRank
                            ? "ランク順に1人ずつ各ブロックへ順番に配ります（例: 3ブロックなら1,4,7 / 2,5,8 / 3,6,9）。"
                            : "参加者をランダムに各ブロックへ振り分けます。")
                        : "参加者全員で総当たりの組み合わせを作ります。")
                }
            }
            .navigationTitle("ランク戦を作成")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("組み合わせを作成") { attemptCreateEvent() }
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $isPresentingSizeAdjustment) {
                RankChallengeBlockSizeAdjustmentSheet(
                    participantCount: selectedStudents.count,
                    sizes: proposedBlockSizes,
                    onConfirm: { sizes in createEvent(blockSizes: sizes) }
                )
            }
        }
    }

    private func isGroupFullySelected(_ group: GradeGroup) -> Bool {
        group.students.allSatisfy { selectedStudentIDs.contains($0.id) }
    }

    private func toggleGroup(_ group: GradeGroup) {
        if isGroupFullySelected(group) {
            group.students.forEach { selectedStudentIDs.remove($0.id) }
        } else {
            group.students.forEach { selectedStudentIDs.insert($0.id) }
        }
    }

    private func toggle(_ student: Student) {
        if selectedStudentIDs.contains(student.id) {
            selectedStudentIDs.remove(student.id)
        } else {
            selectedStudentIDs.insert(student.id)
        }
    }

    private func attemptCreateEvent() {
        guard isValid else { return }
        if useBlocks {
            let sizes = RankChallengePairingGenerator.evenBlockSizes(participantCount: selectedStudents.count, blockCount: blockCount)
            if Set(sizes).count > 1 {
                proposedBlockSizes = sizes
                isPresentingSizeAdjustment = true
                return
            }
        }
        createEvent(blockSizes: nil)
    }

    private func createEvent(blockSizes: [Int]?) {
        guard isValid else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let event = RankChallengeEvent(
            name: trimmedName,
            useBlocks: useBlocks,
            participants: selectedStudents
        )
        modelContext.insert(event)

        let generated = RankChallengePairingGenerator.generate(
            participants: selectedStudents,
            blockCount: useBlocks ? blockCount : 1,
            mode: distributionMode,
            blockSizes: blockSizes
        )
        for item in generated {
            let pairing = RankChallengePairing(
                blockName: item.blockName,
                matchNumber: item.matchNumber,
                player1: item.player1,
                player2: item.player2,
                event: event
            )
            modelContext.insert(pairing)
            event.pairings.append(pairing)
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    RankChallengeSetupView()
        .modelContainer(AppModelContainer.preview)
}

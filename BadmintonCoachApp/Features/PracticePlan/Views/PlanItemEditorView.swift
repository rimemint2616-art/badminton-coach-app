import SwiftUI
import SwiftData

/// 本日の練習メニュー1項目の詳細設定。測定方法（回数×セット/分/点マッチ）に応じて入力欄が変わる。
/// コートへの選手割り当てもここで行う。
struct PlanItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Student.name)]) private var allStudents: [Student]

    @Bindable var item: DraftItem

    private var activeStudents: [Student] {
        allStudents.filter { !$0.isArchived }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(item.kind == .rest ? "休憩" : "メニュー") {
                    TextField("名称", text: $item.title)
                    if item.kind == .drill, let major = item.majorCategory {
                        LabeledContent("カテゴリ") {
                            Text([major.displayName, item.middleCategory?.displayName].compactMap { $0 }.joined(separator: " › "))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if item.kind == .drill {
                    formatSection
                }

                Section(item.kind == .rest ? "休憩時間" : "目安時間") {
                    Stepper("\(item.estimatedMinutes)分", value: $item.estimatedMinutes, in: 1...240)
                }

                if item.kind == .drill {
                    courtSection
                }

                Section("メモ") {
                    TextEditor(text: $item.notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle(item.kind == .rest ? "休憩を編集" : "項目を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }

    // MARK: - 測定方法ごとの入力欄

    @ViewBuilder
    private var formatSection: some View {
        if let format = item.format {
            formatFields(format)
        }
    }

    @ViewBuilder
    private func formatFields(_ format: MeasurementFormat) -> some View {
        switch format {
        case .repsAndSets:
            Section("回数・セット") {
                Picker("単位", selection: bindingRepUnit) {
                    ForEach(RepUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                Stepper("1人 \(item.countPerPerson ?? 0)\(item.repUnit?.displayName ?? "回")",
                        value: intBinding(\.countPerPerson, default: 20), in: 1...200)
                Stepper("\(item.sets ?? 0) セット",
                        value: intBinding(\.sets, default: 3), in: 1...30)
            }
        case .minutes:
            Section("時間") {
                Stepper("\(item.minutes ?? item.estimatedMinutes)分",
                        value: intBinding(\.minutes, default: item.estimatedMinutes), in: 1...120)
                    .onChange(of: item.minutes) { _, newValue in
                        if let newValue { item.estimatedMinutes = newValue }
                    }
            }
        case .pointMatch:
            Section("マッチ設定") {
                Picker("何点マッチ", selection: intBinding(\.matchPoints, default: 21)) {
                    ForEach([7, 11, 15, 21], id: \.self) { pts in
                        Text("\(pts)点").tag(pts)
                    }
                }
                Stepper("\(item.matchCount ?? 1) マッチ",
                        value: intBinding(\.matchCount, default: 1), in: 1...20)
            }
        case .simple:
            EmptyView()
        }
    }

    // MARK: - コート割り当て

    private var courtSection: some View {
        Section("コート割り当て") {
            ForEach($item.courts) { $court in
                DisclosureGroup("コート\(court.courtNumber)（\(court.players.count)名）") {
                    ForEach(activeStudents) { student in
                        Button {
                            togglePlayer(student, inCourt: court.id)
                        } label: {
                            HStack {
                                Text(student.name)
                                Spacer()
                                if court.players.contains(where: { $0.id == student.id }) {
                                    Image(systemName: "checkmark").foregroundStyle(.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                    }
                }
            }
            .onDelete { offsets in
                item.courts.remove(atOffsets: offsets)
            }

            Button {
                let nextNumber = (item.courts.map(\.courtNumber).max() ?? 0) + 1
                item.courts.append(CourtAssignment(courtNumber: nextNumber))
            } label: {
                Label("コートを追加", systemImage: "plus")
            }
        }
    }

    private func togglePlayer(_ student: Student, inCourt courtID: UUID) {
        guard let index = item.courts.firstIndex(where: { $0.id == courtID }) else { return }
        if let playerIndex = item.courts[index].players.firstIndex(where: { $0.id == student.id }) {
            item.courts[index].players.remove(at: playerIndex)
        } else {
            item.courts[index].players.append(AssignedPlayer(id: student.id, name: student.name))
        }
    }

    // MARK: - Binding helpers

    private var bindingRepUnit: Binding<RepUnit> {
        Binding(
            get: { item.repUnit ?? .reps },
            set: { item.repUnit = $0 }
        )
    }

    private func intBinding(_ keyPath: ReferenceWritableKeyPath<DraftItem, Int?>, default def: Int) -> Binding<Int> {
        Binding(
            get: { item[keyPath: keyPath] ?? def },
            set: { item[keyPath: keyPath] = $0 }
        )
    }
}

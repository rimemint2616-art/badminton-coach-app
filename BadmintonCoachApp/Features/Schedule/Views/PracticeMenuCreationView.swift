import SwiftUI
import SwiftData

/// 「練習メニュー」タブの「メニューを作る」ボタンから開く画面。練習時間を設定してから、
/// カテゴリボタンでメニューを組み立て、新規の練習セッションとして保存する。
/// 出席者・場所など他の詳細は、保存後にスケジュールタブの編集画面から調整できる。
struct PracticeMenuCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CourtTag.sortOrder)]) private var courtTags: [CourtTag]
    @Query(sort: [SortDescriptor(\MenuCategoryTag.sortOrder)]) private var categoryTags: [MenuCategoryTag]

    @State private var date: Date = .now
    @State private var startTime: Date = .now
    @State private var endTime: Date = .now.addingTimeInterval(60 * 60)
    @State private var menuGoal: String = ""
    @State private var sectionDrafts: [MenuSectionDraft] = []

    private var durationSummaryText: String {
        let japanese = Locale(identifier: "ja_JP")
        let dateText = date.formatted(.dateTime.month().day().weekday(.abbreviated).locale(japanese))
        let timeText = "\(startTime.formatted(date: .omitted, time: .shortened))〜\(endTime.formatted(date: .omitted, time: .shortened))"
        let minutes = max(0, Int(endTime.timeIntervalSince(startTime) / 60))
        return "\(dateText) \(timeText) (\(minutes)分)"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("練習時間") {
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                    DatePicker("開始時刻", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("終了時刻", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section {
                    TextField("目標（任意）", text: $menuGoal)
                    NavigationLink {
                        MenuBuilderView(sectionDrafts: $sectionDrafts, availableCourts: courtTags, durationSummary: durationSummaryText)
                    } label: {
                        HStack {
                            Label("メニューを作る", systemImage: "square.and.pencil")
                            Spacer()
                            if !sectionDrafts.isEmpty {
                                Text("\(sectionDrafts.count)セクション")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("練習メニュー")
                } footer: {
                    Text("体操・フットワーク・ノック練などカテゴリごとに項目を追加できます。出席者や場所などの詳細は、保存後にスケジュールタブの編集画面から設定できます。")
                }
            }
            .navigationTitle("メニューを作る")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                }
            }
            .onAppear {
                // 「毎回追加」カテゴリ（体操など）のセクションを自動で差し込む。
                if sectionDrafts.isEmpty {
                    sectionDrafts = MenuSectionDraft.standardDrafts(from: categoryTags)
                }
            }
        }
    }

    private func save() {
        let session = PracticeSession(
            date: date,
            startTime: startTime,
            endTime: endTime,
            menuGoal: menuGoal
        )
        modelContext.insert(session)

        for (sectionIndex, sectionDraft) in sectionDrafts.enumerated() {
            let category = categoryTags.first { $0.id == sectionDraft.categoryID }
            let section = MenuSection(
                orderIndex: sectionIndex,
                title: sectionDraft.title,
                category: category,
                session: session
            )
            modelContext.insert(section)
            session.menuSections.append(section)
            for (itemIndex, itemDraft) in sectionDraft.items.enumerated() {
                let courts = courtTags.filter { itemDraft.courtIDs.contains($0.id) }
                let item = MenuSectionItem(
                    orderIndex: itemIndex,
                    text: itemDraft.text,
                    shotsPerPerson: itemDraft.shotsPerPerson,
                    sets: itemDraft.sets,
                    indentLevel: itemDraft.indentLevel,
                    isEmphasized: itemDraft.isEmphasized,
                    section: section,
                    courts: courts
                )
                modelContext.insert(item)
                section.items.append(item)
            }
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    PracticeMenuCreationView()
        .modelContainer(AppModelContainer.preview)
}

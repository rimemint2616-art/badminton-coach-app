import SwiftUI
import SwiftData

/// 練習セッションの新規作成・編集フォーム。
/// `session` が nil なら新規作成、値があれば既存インスタンスを直接更新する。
struct SessionEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Student.name)]) private var allStudents: [Student]
    @Query(sort: [SortDescriptor(\CourtTag.sortOrder)]) private var courtTags: [CourtTag]
    @Query(sort: [SortDescriptor(\MenuCategoryTag.sortOrder)]) private var categoryTags: [MenuCategoryTag]

    let session: PracticeSession?

    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var location: String
    @State private var sessionType: SessionType
    @State private var eventCategory: SessionEventCategory
    @State private var isAllDay: Bool
    @State private var title: String
    @State private var notes: String
    @State private var selectedAttendeeIDs: Set<UUID>
    @State private var menuGoal: String
    @State private var sectionDrafts: [MenuSectionDraft]

    init(session: PracticeSession?) {
        self.session = session
        _date = State(initialValue: session?.date ?? .now)
        _startTime = State(initialValue: session?.startTime ?? .now)
        _endTime = State(initialValue: session?.endTime ?? .now.addingTimeInterval(60 * 60))
        _location = State(initialValue: session?.location ?? "")
        _sessionType = State(initialValue: session?.sessionType ?? .group)
        _eventCategory = State(initialValue: session?.eventCategory ?? .practice)
        _isAllDay = State(initialValue: session?.isAllDay ?? false)
        _title = State(initialValue: session?.title ?? "")
        _notes = State(initialValue: session?.notes ?? "")
        _selectedAttendeeIDs = State(initialValue: Set(session?.attendees.map(\.id) ?? []))
        _menuGoal = State(initialValue: session?.menuGoal ?? "")
        _sectionDrafts = State(initialValue: (session?.sortedMenuSections ?? []).map { section in
            MenuSectionDraft(
                title: section.title,
                categoryID: section.category?.id,
                items: section.sortedItems.map { item in
                    MenuSectionItemDraft(
                        text: item.text,
                        shotsPerPerson: item.shotsPerPerson,
                        sets: item.sets,
                        indentLevel: item.indentLevel,
                        isEmphasized: item.isEmphasized,
                        courtIDs: Set(item.courts.map(\.id))
                    )
                }
            )
        })
    }

    private var activeStudents: [Student] {
        allStudents.filter { !$0.isArchived }
    }

    /// 「メニューを作る」画面の上部に表示する、練習時間の参考表示。
    private var durationSummaryText: String {
        let japanese = Locale(identifier: "ja_JP")
        let dateText = date.formatted(.dateTime.month().day().weekday(.abbreviated).locale(japanese))
        if isAllDay {
            return "\(dateText) 終日"
        }
        let timeText = "\(startTime.formatted(date: .omitted, time: .shortened))〜\(endTime.formatted(date: .omitted, time: .shortened))"
        let minutes = max(0, Int(endTime.timeIntervalSince(startTime) / 60))
        return "\(dateText) \(timeText) (\(minutes)分)"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("日時") {
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                    Toggle("終日", isOn: $isAllDay)
                    if !isAllDay {
                        DatePicker("開始時刻", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("終了時刻", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("種別") {
                    Picker("練習・大会・練習試合", selection: $eventCategory) {
                        ForEach(SessionEventCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    TextField("タイトル（任意）", text: $title)
                }

                Section("詳細") {
                    TextField("場所", text: $location)
                    Picker("個人・グループ", selection: $sessionType) {
                        ForEach(SessionType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                Section("出席者") {
                    ForEach(activeStudents) { student in
                        Button {
                            toggleAttendee(student)
                        } label: {
                            HStack {
                                Text(student.name)
                                Spacer()
                                if selectedAttendeeIDs.contains(student.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                    }
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
                    Text("「メニューを作る」から、体操・フットワーク・ノック練などカテゴリごとに項目を追加できます。")
                }
            }
            .navigationTitle(session == nil ? "練習を追加" : "練習を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .onAppear {
                // 新規作成時は全員参加をデフォルトにする（欠席者だけ後から外す運用の方が早いため）。
                if session == nil && selectedAttendeeIDs.isEmpty {
                    selectedAttendeeIDs = Set(activeStudents.map(\.id))
                }
                // 新規作成時は「毎回追加」カテゴリ（体操など）のセクションを自動で差し込む。
                if session == nil && sectionDrafts.isEmpty {
                    sectionDrafts = MenuSectionDraft.standardDrafts(from: categoryTags)
                }
            }
        }
    }

    private func toggleAttendee(_ student: Student) {
        if selectedAttendeeIDs.contains(student.id) {
            selectedAttendeeIDs.remove(student.id)
        } else {
            selectedAttendeeIDs.insert(student.id)
        }
    }

    private func save() {
        let attendees = activeStudents.filter { selectedAttendeeIDs.contains($0.id) }
        let targetSession: PracticeSession

        if let session {
            session.date = date
            session.startTime = startTime
            session.endTime = endTime
            session.location = location
            session.sessionType = sessionType
            session.eventCategory = eventCategory
            session.isAllDay = isAllDay
            session.title = title
            session.notes = notes
            session.menuGoal = menuGoal
            targetSession = session
            for section in session.menuSections {
                modelContext.delete(section)
            }
            session.menuSections.removeAll()
        } else {
            let newSession = PracticeSession(
                date: date, startTime: startTime, endTime: endTime,
                location: location, sessionType: sessionType,
                eventCategory: eventCategory, isAllDay: isAllDay, title: title, notes: notes,
                menuGoal: menuGoal
            )
            modelContext.insert(newSession)
            targetSession = newSession
        }

        targetSession.attendees = attendees

        for (sectionIndex, sectionDraft) in sectionDrafts.enumerated() {
            let category = categoryTags.first { $0.id == sectionDraft.categoryID }
            let section = MenuSection(
                orderIndex: sectionIndex,
                title: sectionDraft.title,
                category: category,
                session: targetSession
            )
            modelContext.insert(section)
            targetSession.menuSections.append(section)
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
    SessionEditView(session: nil)
        .modelContainer(AppModelContainer.preview)
}

import SwiftUI
import SwiftData

/// 練習セッションの新規作成・編集フォーム。
/// `session` が nil なら新規作成、値があれば既存インスタンスを直接更新する。
struct SessionEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Student.name)]) private var allStudents: [Student]

    let session: PracticeSession?

    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var location: String
    @State private var sessionType: SessionType
    @State private var notes: String
    @State private var selectedAttendeeIDs: Set<UUID>
    @State private var drillSelections: [PracticeMenu]
    @State private var isPresentingMenuPicker = false

    init(session: PracticeSession?) {
        self.session = session
        _date = State(initialValue: session?.date ?? .now)
        _startTime = State(initialValue: session?.startTime ?? .now)
        _endTime = State(initialValue: session?.endTime ?? .now.addingTimeInterval(60 * 60))
        _location = State(initialValue: session?.location ?? "")
        _sessionType = State(initialValue: session?.sessionType ?? .group)
        _notes = State(initialValue: session?.notes ?? "")
        _selectedAttendeeIDs = State(initialValue: Set(session?.attendees.map(\.id) ?? []))
        _drillSelections = State(initialValue: (session?.drillItems.sorted { $0.orderIndex < $1.orderIndex } ?? []).compactMap(\.menu))
    }

    private var activeStudents: [Student] {
        allStudents.filter { !$0.isArchived }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("日時") {
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                    DatePicker("開始時刻", selection: $startTime, displayedComponents: .hourAndMinute)
                    DatePicker("終了時刻", selection: $endTime, displayedComponents: .hourAndMinute)
                }

                Section("詳細") {
                    TextField("場所", text: $location)
                    Picker("種別", selection: $sessionType) {
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
                                        .foregroundStyle(.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                    }
                }

                Section("練習メニュー") {
                    ForEach(drillSelections) { menu in
                        Text(menu.name)
                    }
                    .onDelete { offsets in
                        drillSelections.remove(atOffsets: offsets)
                    }
                    .onMove { source, destination in
                        drillSelections.move(fromOffsets: source, toOffset: destination)
                    }
                    Button {
                        isPresentingMenuPicker = true
                    } label: {
                        Label("メニューを追加", systemImage: "plus")
                    }
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
            .sheet(isPresented: $isPresentingMenuPicker) {
                MenuPickerView(alreadySelected: drillSelections) { menu in
                    drillSelections.append(menu)
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
            session.notes = notes
            targetSession = session
            for item in session.drillItems {
                modelContext.delete(item)
            }
            session.drillItems.removeAll()
        } else {
            let newSession = PracticeSession(
                date: date, startTime: startTime, endTime: endTime,
                location: location, sessionType: sessionType, notes: notes
            )
            modelContext.insert(newSession)
            targetSession = newSession
        }

        targetSession.attendees = attendees

        for (index, menu) in drillSelections.enumerated() {
            let item = SessionDrillItem(orderIndex: index, session: targetSession, menu: menu)
            modelContext.insert(item)
            targetSession.drillItems.append(item)
            menu.sessionItems.append(item)
        }

        try? modelContext.save()
        dismiss()
    }
}

private struct MenuPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\PracticeMenu.name)]) private var allMenus: [PracticeMenu]
    let alreadySelected: [PracticeMenu]
    let onSelect: (PracticeMenu) -> Void

    var body: some View {
        NavigationStack {
            List(allMenus) { menu in
                Button {
                    onSelect(menu)
                    dismiss()
                } label: {
                    HStack {
                        Text(menu.name)
                        Spacer()
                        if alreadySelected.contains(where: { $0.id == menu.id }) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("メニューを選択")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SessionEditView(session: nil)
        .modelContainer(AppModelContainer.preview)
}

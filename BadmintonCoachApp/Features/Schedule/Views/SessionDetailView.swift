import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Bindable var session: PracticeSession
    @State private var isPresentingEdit = false
    @State private var isPresentingMatchSetup = false
    @State private var feedbackTarget: Student?

    private var sortedDrillItems: [SessionDrillItem] {
        session.drillItems.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        List {
            Section("練習情報") {
                LabeledContent("日付", value: session.date.formatted(date: .complete, time: .omitted))
                LabeledContent("時間", value: "\(session.startTime.formatted(date: .omitted, time: .shortened)) - \(session.endTime.formatted(date: .omitted, time: .shortened))")
                if !session.location.isEmpty {
                    LabeledContent("場所", value: session.location)
                }
                LabeledContent("種別", value: session.sessionType.displayName)
                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("出席者（\(session.attendees.count)）") {
                if session.attendees.isEmpty {
                    Text("出席者が設定されていません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(session.attendees.sorted { $0.name < $1.name }) { student in
                        HStack {
                            Text(student.name)
                            Spacer()
                            Button {
                                feedbackTarget = student
                            } label: {
                                Label("フィードバック", systemImage: "plus.bubble")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            Section("練習メニュー（\(sortedDrillItems.count)）") {
                if sortedDrillItems.isEmpty {
                    Text("練習メニューが設定されていません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedDrillItems) { item in
                        VStack(alignment: .leading) {
                            Text(item.menu?.name ?? "（削除済みメニュー）")
                                .font(.subheadline)
                            Text("\(item.plannedDurationOverride ?? item.menu?.durationMinutes ?? 0)分")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button {
                    isPresentingMatchSetup = true
                } label: {
                    Label("この出席者で試合記録を開始", systemImage: "sportscourt")
                }
                .disabled(session.attendees.count < 2)
            }
        }
        .navigationTitle("練習詳細")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") { isPresentingEdit = true }
            }
        }
        .sheet(isPresented: $isPresentingEdit) {
            SessionEditView(session: session)
        }
        .sheet(isPresented: $isPresentingMatchSetup) {
            MatchSetupView(presetSession: session)
        }
        .sheet(item: $feedbackTarget) { student in
            FeedbackEditorView(student: student, session: session)
        }
    }
}

#Preview {
    NavigationStack {
        let container = AppModelContainer.preview
        let session = try! container.mainContext.fetch(FetchDescriptor<PracticeSession>()).first!
        SessionDetailView(session: session)
    }
    .modelContainer(AppModelContainer.preview)
}

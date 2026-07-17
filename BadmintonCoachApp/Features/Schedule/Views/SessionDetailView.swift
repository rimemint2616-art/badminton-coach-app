import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Bindable var session: PracticeSession
    @State private var isPresentingEdit = false
    @State private var isPresentingMatchSetup = false
    @State private var feedbackTarget: Student?

    /// 出欠セグメントピッカー用のBinding。trueが「欠席」、falseが「出席」を表す。
    private func attendanceBinding(for student: Student) -> Binding<Bool> {
        Binding(
            get: { session.isAbsent(student) },
            set: { session.setAttendance(present: !$0, for: student) }
        )
    }

    var body: some View {
        List {
            Section("練習情報") {
                if !session.title.isEmpty {
                    LabeledContent("タイトル", value: session.title)
                }
                LabeledContent("日付", value: session.date.formatted(Date.FormatStyle(date: .complete, time: .omitted).locale(Locale(identifier: "ja_JP"))))
                LabeledContent("時間", value: session.isAllDay ? "終日" : "\(session.startTime.formatted(date: .omitted, time: .shortened)) - \(session.endTime.formatted(date: .omitted, time: .shortened))")
                if !session.location.isEmpty {
                    LabeledContent("場所", value: session.location)
                }
                LabeledContent {
                    Text(session.eventCategory.displayName)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(session.eventCategory.color.opacity(0.2), in: Capsule())
                        .foregroundStyle(session.eventCategory.color)
                } label: {
                    Text("種別")
                }
                LabeledContent("形式", value: session.sessionType.displayName)
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
                            Picker("出欠", selection: attendanceBinding(for: student)) {
                                Text("出席").tag(false)
                                Text("欠席").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .fixedSize()
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

            Section("練習メニュー") {
                if !session.menuGoal.isEmpty {
                    Text("目標「\(session.menuGoal)」")
                        .font(.subheadline.bold())
                }
                if session.sortedMenuSections.isEmpty {
                    Text("練習メニューが設定されていません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(session.sortedMenuSections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.title)
                                .font(.headline)
                            ForEach(section.sortedItems) { item in
                                MenuSectionItemLineView(item: item)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !session.sortedMenuSections.isEmpty {
                Section {
                    NavigationLink {
                        PracticeMenuPDFExportView(session: session)
                    } label: {
                        Label("PDFを書き出す", systemImage: "doc.richtext")
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
        .fullScreenCover(isPresented: $isPresentingMatchSetup) {
            MatchSetupView(presetSession: session)
        }
        .sheet(item: $feedbackTarget) { student in
            FeedbackEditorView(student: student, session: session)
        }
    }
}

/// 練習メニューの1行の読み取り表示。字下げ・強調・割り当てコートを紙のメニューと同じ見た目で表す。
private struct MenuSectionItemLineView: View {
    let item: MenuSectionItem

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(item.indentLevel > 0 ? "→" : "・")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayText)
                    .fontWeight(item.isEmphasized ? .bold : .regular)
                    .foregroundStyle(item.isEmphasized ? Color(hex: "#E03131") : Color.primary)
                if !item.courts.isEmpty {
                    Text(item.courts.sorted { $0.sortOrder < $1.sortOrder }.map(\.name).joined(separator: "・"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.leading, CGFloat(item.indentLevel) * 20)
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

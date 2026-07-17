import SwiftUI
import SwiftData

/// 「本日の練習メニュー」作成・編集画面。
/// 全画面を左右2分割し、左でカテゴリからメニューを選び、右で作成中のメニューを随時確認・編集する。
struct PlanBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draft: PlanDraft
    @State private var editingItem: DraftItem?
    @State private var showingUnderTimeConfirm = false
    @State private var pdfPreview: PDFPreviewItem?

    init(draft: PlanDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                CategoryBrowserView { menu in
                    draft.add(.from(menu: menu))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                planPane
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("本日の練習メニュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        exportPDF()
                    } label: {
                        Label("PDF", systemImage: "arrow.up.doc")
                    }
                    .disabled(draft.items.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { attemptSave() }
                }
            }
            .sheet(item: $editingItem) { item in
                PlanItemEditorView(item: item)
            }
            .sheet(item: $pdfPreview) { preview in
                pdfShareSheet(url: preview.url)
            }
            .alert("目標時間に不足しています", isPresented: $showingUnderTimeConfirm) {
                Button("このまま保存", role: .destructive) { performSave() }
                Button("編集を続ける", role: .cancel) {}
            } message: {
                Text("合計 \(draft.contentMinutes)分 / 目標 \(draft.targetDurationMinutes)分（\(draft.underByMinutes)分 不足）。このまま保存しますか？")
            }
        }
    }

    // MARK: - 右ペイン（作成中の本日の練習メニュー）

    private var planPane: some View {
        VStack(spacing: 0) {
            planHeader
            Divider()
            if draft.items.isEmpty {
                ContentUnavailableView(
                    "メニュー未追加",
                    systemImage: "list.bullet.rectangle",
                    description: Text("左のカテゴリからメニューをタップして追加してください")
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(draft.items.enumerated()), id: \.element.id) { index, item in
                        Button {
                            editingItem = item
                        } label: {
                            PlanItemRow(index: index + 1, item: item)
                        }
                        .buttonStyle(.plain)
                    }
                    .onMove { draft.move(from: $0, to: $1) }
                    .onDelete { draft.remove(at: $0) }
                }
                .listStyle(.plain)
            }
            Divider()
            footerButtons
        }
        .background(Color(.systemGroupedBackground))
    }

    private var planHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("タイトル（例: 6/20 火曜練習）", text: $draft.title)
                .font(.headline)
            HStack {
                DatePicker("", selection: $draft.date, displayedComponents: .date)
                    .labelsHidden()
                Spacer()
                Stepper("目標 \(draft.targetDurationMinutes)分", value: $draft.targetDurationMinutes, in: 10...360, step: 5)
                    .fixedSize()
            }
            timeBar
        }
        .padding()
    }

    private var timeBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("合計 \(draft.contentMinutes)分 / 目標 \(draft.targetDurationMinutes)分")
                    .font(.subheadline.bold())
                Spacer()
                if draft.isOverTime {
                    Label("\(draft.overByMinutes)分 時間超過中", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                } else if draft.isUnderTime {
                    Text("あと \(draft.underByMinutes)分")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Label("ちょうど", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
            }
            GeometryReader { geo in
                let ratio = draft.targetDurationMinutes > 0
                    ? min(1.5, Double(draft.contentMinutes) / Double(draft.targetDurationMinutes))
                    : 0
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemGray5))
                    Capsule()
                        .fill(draft.isOverTime ? Color.red : Color.accentColor)
                        .frame(width: geo.size.width * min(1.0, ratio))
                }
            }
            .frame(height: 8)
        }
    }

    private var footerButtons: some View {
        HStack {
            Button {
                draft.addRest()
            } label: {
                Label("休憩を追加", systemImage: "cup.and.saucer")
            }
            Spacer()
            Button {
                draft.autoInsertBreaks()
            } label: {
                Label("休憩を自動挿入", systemImage: "wand.and.stars")
            }
            .disabled(draft.items.filter { $0.kind == .drill }.isEmpty)
            Spacer()
            EditButton()
        }
        .padding()
    }

    // MARK: - 保存 / PDF

    private func attemptSave() {
        if draft.isUnderTime && draft.contentMinutes > 0 {
            showingUnderTimeConfirm = true
        } else {
            performSave()
        }
    }

    private func performSave() {
        draft.save(into: modelContext)
        dismiss()
    }

    private func exportPDF() {
        let data = PlanPDFGenerator.generate(draft: draft)
        let fileName = "practice-\(Int(draft.date.timeIntervalSince1970)).pdf"
        if let (url, _) = try? ShareService.saveReport(pdfData: data, fileName: fileName) {
            pdfPreview = PDFPreviewItem(url: url)
        }
    }

    private func pdfShareSheet(url: URL) -> some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 60))
                    .foregroundStyle(.accent)
                Text("PDFを作成しました")
                    .font(.headline)
                ShareLink(item: url) {
                    Label("共有・保存", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("PDF出力")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { pdfPreview = nil }
                }
            }
        }
    }
}

private struct PDFPreviewItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// 本日の練習メニュー1項目の行表示。
private struct PlanItemRow: View {
    let index: Int
    let item: DraftItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if item.kind == .rest {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(.orange)
                    .frame(width: 24)
            } else {
                Text("\(index)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title.isEmpty ? (item.kind == .rest ? "休憩" : "（無題）") : item.title)
                    .font(.headline)
                HStack(spacing: 8) {
                    if let major = item.majorCategory {
                        Text([major.displayName, item.middleCategory?.displayName].compactMap { $0 }.joined(separator: "・"))
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                    }
                    if !item.parameterSummary.isEmpty {
                        Text(item.parameterSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if !item.courts.isEmpty {
                    Text(courtSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(item.estimatedMinutes)分")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var courtSummary: String {
        item.courts
            .sorted { $0.courtNumber < $1.courtNumber }
            .map { "コート\($0.courtNumber): " + $0.players.map(\.name).joined(separator: "・") }
            .joined(separator: " / ")
    }
}

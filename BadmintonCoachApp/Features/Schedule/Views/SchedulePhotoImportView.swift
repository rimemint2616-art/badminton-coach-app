import SwiftUI
import SwiftData
import PhotosUI

/// 紙の予定表を撮影・選択した写真から自動で読み取り、練習・大会の候補を一覧登録する。
/// OCRの精度は写真次第のため、登録前に必ず内容を確認・修正できるようにしている。
struct SchedulePhotoImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var pickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var isProcessing = false
    @State private var parsedEntries: [ParsedScheduleEntry] = []
    @State private var targetYear = Calendar.current.component(.year, from: .now)
    @State private var targetMonth = Calendar.current.component(.month, from: .now)
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker("写真を選択", selection: $pickerItem, matching: .images)
                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    }
                } header: {
                    Text("予定表の写真")
                } footer: {
                    Text("ベータ機能です。表のレイアウトや写り方によって読み取り精度が変わるため、登録前に必ず内容を確認・修正してください。")
                }

                Section("対象の年月") {
                    Stepper("\(targetYear)年", value: $targetYear, in: 2020...2100)
                    Stepper("\(targetMonth)月", value: $targetMonth, in: 1...12)
                }

                if isProcessing {
                    Section {
                        HStack {
                            ProgressView()
                            Text("読み取り中…")
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                if !parsedEntries.isEmpty {
                    Section("読み取り結果（\(parsedEntries.count)件）") {
                        ForEach($parsedEntries) { $entry in
                            ParsedEntryRow(entry: $entry)
                        }
                        .onDelete { offsets in
                            parsedEntries.remove(atOffsets: offsets)
                        }
                    }
                }
            }
            .navigationTitle("写真から予定を取り込む")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") { commit() }
                        .disabled(parsedEntries.isEmpty)
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                Task { await loadAndRecognize(newItem) }
            }
        }
    }

    private func loadAndRecognize(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        errorMessage = nil
        isProcessing = true

        guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
            isProcessing = false
            errorMessage = "画像の読み込みに失敗しました"
            return
        }
        previewImage = image

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            ScheduleOCRParser.recognizeLines(in: image) { lines in
                let entries = ScheduleOCRParser.parseEntries(fromLines: lines)
                Task { @MainActor in
                    isProcessing = false
                    parsedEntries = entries
                    if entries.isEmpty {
                        errorMessage = "予定を読み取れませんでした。写真の向きや明るさを変えて試すか、手動で追加してください。"
                    }
                    continuation.resume()
                }
            }
        }
    }

    private func commit() {
        let calendar = Calendar(identifier: .gregorian)

        for entry in parsedEntries {
            var dateComponents = DateComponents(year: targetYear, month: targetMonth, day: entry.day)
            let dayDate = calendar.date(from: dateComponents) ?? .now

            let startTime: Date
            let endTime: Date
            if entry.isAllDay {
                startTime = dayDate
                endTime = dayDate
            } else {
                dateComponents.hour = entry.startHour
                dateComponents.minute = entry.startMinute
                startTime = calendar.date(from: dateComponents) ?? dayDate

                dateComponents.hour = entry.endHour
                dateComponents.minute = entry.endMinute
                endTime = calendar.date(from: dateComponents) ?? dayDate
            }

            let session = PracticeSession(
                date: dayDate,
                startTime: startTime,
                endTime: endTime,
                location: "",
                sessionType: .group,
                eventCategory: entry.category,
                isAllDay: entry.isAllDay,
                title: "",
                notes: ""
            )
            modelContext.insert(session)
        }

        try? modelContext.save()
        dismiss()
    }
}

/// 読み取り結果1件を確認・修正するための行。
private struct ParsedEntryRow: View {
    @Binding var entry: ParsedScheduleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Stepper("\(entry.day)日", value: $entry.day, in: 1...31)
                Spacer()
                Picker("種別", selection: $entry.category) {
                    ForEach(SessionEventCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.menu)
            }

            Toggle("終日", isOn: $entry.isAllDay)

            if !entry.isAllDay {
                HStack {
                    Stepper(String(format: "開始 %02d:%02d", entry.startHour, entry.startMinute), onIncrement: { adjustStart(by: 10) }, onDecrement: { adjustStart(by: -10) })
                }
                HStack {
                    Stepper(String(format: "終了 %02d:%02d", entry.endHour, entry.endMinute), onIncrement: { adjustEnd(by: 10) }, onDecrement: { adjustEnd(by: -10) })
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func adjustStart(by minutes: Int) {
        let total = (entry.startHour * 60 + entry.startMinute + minutes + 24 * 60) % (24 * 60)
        entry.startHour = total / 60
        entry.startMinute = total % 60
    }

    private func adjustEnd(by minutes: Int) {
        let total = (entry.endHour * 60 + entry.endMinute + minutes + 24 * 60) % (24 * 60)
        entry.endHour = total / 60
        entry.endMinute = total % 60
    }
}

#Preview {
    SchedulePhotoImportView()
        .modelContainer(AppModelContainer.preview)
}

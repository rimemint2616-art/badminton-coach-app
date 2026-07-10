import SwiftUI
import SwiftData

struct ReportGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    let student: Student

    @State private var rangeStart: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var rangeEnd: Date = .now
    @State private var generatedFileURL: URL?
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private var pastReports: [ReportRecord] {
        student.reportRecords.sorted { $0.generatedAt > $1.generatedAt }
    }

    var body: some View {
        Form {
            Section("対象期間") {
                DatePicker("開始日", selection: $rangeStart, displayedComponents: .date)
                DatePicker("終了日", selection: $rangeEnd, displayedComponents: .date)
            }

            Section {
                Button {
                    generate()
                } label: {
                    if isGenerating {
                        ProgressView()
                    } else {
                        Text("PDFレポートを生成")
                    }
                }
                .disabled(isGenerating || rangeStart > rangeEnd)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                if let generatedFileURL {
                    ShareLink(item: generatedFileURL) {
                        Label("生成したPDFを共有", systemImage: "square.and.arrow.up")
                    }
                }
            }

            if !pastReports.isEmpty {
                Section("過去に生成したレポート") {
                    ForEach(pastReports) { record in
                        if let url = ShareService.resolvedURL(forRelativePath: record.relativeFilePath) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(record.dateRangeStart.formatted(date: .abbreviated, time: .omitted)) 〜 \(record.dateRangeEnd.formatted(date: .abbreviated, time: .omitted))")
                                    Text("生成日: \(record.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                ShareLink(item: url) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("PDFレポート")
    }

    private func generate() {
        isGenerating = true
        errorMessage = nil

        let matches = (student.matchesAsPlayer1 + student.matchesAsPlayer2)
            .filter { $0.date >= rangeStart && $0.date <= rangeEnd }
            .sorted { $0.date < $1.date }
        let feedback = student.feedbackEntries
            .filter { $0.date >= rangeStart && $0.date <= rangeEnd }

        let reportData = StatsAggregationService.reportData(
            for: student,
            matches: matches,
            feedback: feedback,
            dateRangeStart: rangeStart,
            dateRangeEnd: rangeEnd
        )

        let pdfData = PDFReportGenerator.generate(data: reportData)
        let fileName = "\(student.name)_\(Int(Date().timeIntervalSince1970)).pdf"

        do {
            let (fileURL, relativePath) = try ShareService.saveReport(pdfData: pdfData, fileName: fileName)
            let record = ReportRecord(
                dateRangeStart: rangeStart,
                dateRangeEnd: rangeEnd,
                relativeFilePath: relativePath,
                student: student
            )
            modelContext.insert(record)
            student.reportRecords.append(record)
            try? modelContext.save()
            generatedFileURL = fileURL
        } catch {
            errorMessage = "PDFの保存に失敗しました: \(error.localizedDescription)"
        }

        isGenerating = false
    }
}

#Preview {
    NavigationStack {
        let container = AppModelContainer.preview
        let student = try! container.mainContext.fetch(FetchDescriptor<Student>()).first!
        ReportGeneratorView(student: student)
    }
    .modelContainer(AppModelContainer.preview)
}

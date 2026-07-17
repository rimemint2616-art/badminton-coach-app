import SwiftUI
import SwiftData

/// 練習メニューをPDFに書き出して共有する画面。ReportGeneratorViewの生成/共有UXを踏襲するが、
/// 練習メニューは1回作ったその場限りの出力として扱うため、期間指定や過去の生成履歴は持たない。
struct PracticeMenuPDFExportView: View {
    let session: PracticeSession

    @State private var generatedFileURL: URL?
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Button {
                    generate()
                } label: {
                    if isGenerating {
                        ProgressView()
                    } else {
                        Text("PDFを生成")
                    }
                }
                .disabled(isGenerating)

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
        }
        .navigationTitle("練習メニューPDF")
    }

    private func generate() {
        isGenerating = true
        errorMessage = nil

        let pdfData = PracticeMenuPDFGenerator.generate(session: session)
        let fileName = "練習メニュー_\(Int(Date().timeIntervalSince1970)).pdf"

        do {
            let (fileURL, _) = try ShareService.saveReport(pdfData: pdfData, fileName: fileName)
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
        let session = try! container.mainContext.fetch(FetchDescriptor<PracticeSession>()).first!
        PracticeMenuPDFExportView(session: session)
    }
    .modelContainer(AppModelContainer.preview)
}

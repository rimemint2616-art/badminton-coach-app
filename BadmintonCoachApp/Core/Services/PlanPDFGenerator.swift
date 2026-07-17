import SwiftUI
import UIKit

/// 本日の練習メニュー（作成中ドラフト）をPDF化する。
/// PDFReportGeneratorと同じく、SwiftUIビューをページごとにCGContextへ直接描画する。
enum PlanPDFGenerator {
    static let pageSize = CGSize(width: 595, height: 842) // A4, 72dpi
    private static let rowsPerFirstPage = 9
    private static let rowsPerPage = 13

    @MainActor
    static func generate(draft: PlanDraft) -> Data {
        // 練習項目のみ連番を採番しつつ、(番号, 項目) の並びを作る
        var numbered: [(number: Int, item: DraftItem)] = []
        var counter = 0
        for item in draft.items {
            if item.kind == .drill {
                counter += 1
                numbered.append((number: counter, item: item))
            } else {
                numbered.append((number: 0, item: item))
            }
        }

        // ページごとに分割
        var pages: [[(number: Int, item: DraftItem)]] = []
        var remaining = numbered
        let firstCount = min(rowsPerFirstPage, remaining.count)
        pages.append(Array(remaining.prefix(firstCount)))
        remaining.removeFirst(firstCount)
        while !remaining.isEmpty {
            let count = min(rowsPerPage, remaining.count)
            pages.append(Array(remaining.prefix(count)))
            remaining.removeFirst(count)
        }
        if pages.isEmpty { pages = [[]] }

        let total = draft.contentMinutes
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        return renderer.pdfData { context in
            for (index, rows) in pages.enumerated() {
                renderPage(context: context) {
                    PlanPDFPage(
                        title: draft.title,
                        date: draft.date,
                        targetMinutes: draft.targetDurationMinutes,
                        totalMinutes: total,
                        rows: rows,
                        pageIndex: index,
                        pageCount: pages.count
                    )
                }
            }
        }
    }

    @MainActor
    private static func renderPage<V: View>(
        context: UIGraphicsPDFRendererContext,
        @ViewBuilder content: () -> V
    ) {
        context.beginPage()
        let page = content().frame(width: pageSize.width, height: pageSize.height)
        let imageRenderer = ImageRenderer(content: page)
        imageRenderer.render { _, renderInContext in
            renderInContext(context.cgContext)
        }
    }
}

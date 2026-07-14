import SwiftUI
import UIKit

/// SwiftUI Viewをページごとに直接CGContextへ描画してPDFを組み立てる。
/// ImageRenderer.uiImageで一度ビットマップ化してから埋め込む方式より、
/// 文字がシャープでファイルサイズも小さくなる。
enum PDFReportGenerator {
    static let pageSize = CGSize(width: 595, height: 842) // A4, 72dpi

    @MainActor
    static func generate(data: StudentReportData) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        return renderer.pdfData { context in
            renderPage(context: context) { CoverPage(data: data) }
            renderPage(context: context) { SummaryStatsPage(data: data) }
            for match in data.matches {
                renderPage(context: context) { MatchDetailPage(match: match) }
            }
            if !data.feedbackEntries.isEmpty {
                renderPage(context: context) { FeedbackPage(entries: data.feedbackEntries) }
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
        let cgContext = context.cgContext
        imageRenderer.render { _, renderInContext in
            // UIGraphicsPDFRendererContextのCGContextは既にUIKit座標系（原点が左上）に
            // 変換済みだが、ImageRenderer.renderのクロージャはPDFネイティブ座標系（原点が左下）を
            // 前提にしているため、そのまま渡すと文字が上下反転して描画される。
            // ここで一度上下反転させて座標系を合わせる。
            cgContext.saveGState()
            cgContext.translateBy(x: 0, y: pageSize.height)
            cgContext.scaleBy(x: 1, y: -1)
            renderInContext(cgContext)
            cgContext.restoreGState()
        }
    }
}

import SwiftUI
import UIKit

/// 練習メニュー(PracticeSession)をPDFに書き出す。長さが不定の1本の文書として
/// 実際の高さを測ってからページ数を決める（決め打ちの行高ヒューリスティックは使わない）。
/// SwiftUI ViewをCGContextへ直接描画する方式はPDFReportGeneratorと同じ
/// （文字がシャープでファイルサイズも小さくなるため）。
enum PracticeMenuPDFGenerator {
    static let pageSize = PracticeMenuPDFPage.pageSize

    @MainActor
    static func generate(session: PracticeSession) -> Data {
        let content = PracticeMenuPDFContent(session: session)
        let measuredHeight = ImageRenderer(content: content).uiImage?.size.height ?? PracticeMenuPDFPage.windowHeight
        let windowHeight = PracticeMenuPDFPage.windowHeight
        let pageCount = max(1, Int((measuredHeight / windowHeight).rounded(.up)))

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        return renderer.pdfData { context in
            for pageIndex in 0..<pageCount {
                renderPage(context: context) {
                    PracticeMenuPDFPage(content: content, pageIndex: pageIndex, pageCount: pageCount)
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

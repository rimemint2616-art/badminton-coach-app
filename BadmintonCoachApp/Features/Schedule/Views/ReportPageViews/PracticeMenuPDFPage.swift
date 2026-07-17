import SwiftUI

/// 練習メニュー全体（PracticeMenuPDFContent）のうち、1ページ分だけを切り出して表示する「窓」。
/// 同じcontentをページごとに上へずらして(.offset)から、ページ1枚分の高さでクリップする。
struct PracticeMenuPDFPage: View {
    let content: PracticeMenuPDFContent
    let pageIndex: Int
    let pageCount: Int

    static let pageSize = CGSize(width: 595, height: 842) // A4、72dpi
    static let margin: CGFloat = 40
    static var windowHeight: CGFloat { pageSize.height - margin * 2 }

    var body: some View {
        VStack(spacing: 8) {
            content
                .offset(y: -CGFloat(pageIndex) * Self.windowHeight)
                .frame(height: Self.windowHeight, alignment: .top)
                .clipped()

            if pageCount > 1 {
                Text("\(pageIndex + 1) / \(pageCount)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(.top, Self.margin)
        .padding(.bottom, Self.margin)
        .frame(width: Self.pageSize.width, height: Self.pageSize.height, alignment: .top)
        .background(.white)
    }
}

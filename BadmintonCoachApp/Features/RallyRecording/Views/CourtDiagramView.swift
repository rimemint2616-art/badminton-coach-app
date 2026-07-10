import SwiftUI

/// コート上の1点（0...1に正規化した座標）に置くマーカー。
/// ライブタギング中の「現在ラリーのショット」表示と、PDFレポートの着地ヒートマップの両方で使う。
struct CourtShotMarker: Identifiable {
    let id: UUID
    var position: CGPoint
    var color: Color
    var label: String?

    init(id: UUID = UUID(), position: CGPoint, color: Color, label: String? = nil) {
        self.id = id
        self.position = position
        self.color = color
        self.label = label
    }
}

/// バドミントンコートを縦（奥のベースライン〜手前のベースライン）に描画するView。
/// タップで正規化座標(0...1)をコールバックする。
struct CourtDiagramView: View {
    var markers: [CourtShotMarker] = []
    var onTap: ((CGPoint) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                Canvas { context, canvasSize in
                    drawCourt(context: context, size: canvasSize)
                }
                ForEach(markers) { marker in
                    Circle()
                        .fill(marker.color)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                        .position(
                            x: marker.position.x * size.width,
                            y: marker.position.y * size.height
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                guard let onTap else { return }
                let normalized = CGPoint(
                    x: min(max(location.x / size.width, 0), 1),
                    y: min(max(location.y / size.height, 0), 1)
                )
                onTap(normalized)
            }
        }
        .aspectRatio(CourtDimensions.aspectRatio, contentMode: .fit)
        .background(Color.green.opacity(0.15))
    }

    private func drawCourt(context: GraphicsContext, size: CGSize) {
        let width = size.width
        let height = size.height
        let inset = CourtDimensions.singlesSideInsetRatio * width
        let shortServiceOffset = CourtDimensions.shortServiceLineOffsetRatio * height
        let doublesLongServiceOffset = CourtDimensions.doublesLongServiceLineOffsetRatio * height

        let mainLine = GraphicsContext.Shading.color(.white)
        let dashedStyle = StrokeStyle(lineWidth: 1, dash: [4, 4])

        // ダブルス外枠（補助表示）
        var outer = Path()
        outer.addRect(CGRect(x: 0, y: 0, width: width, height: height))
        context.stroke(outer, with: .color(.white.opacity(0.5)), style: dashedStyle)

        // シングルスサイドライン（主要ライン）
        var singlesLines = Path()
        singlesLines.move(to: CGPoint(x: inset, y: 0))
        singlesLines.addLine(to: CGPoint(x: inset, y: height))
        singlesLines.move(to: CGPoint(x: width - inset, y: 0))
        singlesLines.addLine(to: CGPoint(x: width - inset, y: height))
        context.stroke(singlesLines, with: mainLine, lineWidth: 2)

        // ネット
        var net = Path()
        net.move(to: CGPoint(x: 0, y: height / 2))
        net.addLine(to: CGPoint(x: width, y: height / 2))
        context.stroke(net, with: .color(.white), lineWidth: 3)

        // ショートサービスライン（上下）
        var shortServiceLines = Path()
        shortServiceLines.move(to: CGPoint(x: 0, y: height / 2 - shortServiceOffset))
        shortServiceLines.addLine(to: CGPoint(x: width, y: height / 2 - shortServiceOffset))
        shortServiceLines.move(to: CGPoint(x: 0, y: height / 2 + shortServiceOffset))
        shortServiceLines.addLine(to: CGPoint(x: width, y: height / 2 + shortServiceOffset))
        context.stroke(shortServiceLines, with: mainLine, lineWidth: 2)

        // ダブルスロングサービスライン（点線、補助表示）
        var longServiceLines = Path()
        longServiceLines.move(to: CGPoint(x: 0, y: doublesLongServiceOffset))
        longServiceLines.addLine(to: CGPoint(x: width, y: doublesLongServiceOffset))
        longServiceLines.move(to: CGPoint(x: 0, y: height - doublesLongServiceOffset))
        longServiceLines.addLine(to: CGPoint(x: width, y: height - doublesLongServiceOffset))
        context.stroke(longServiceLines, with: .color(.white.opacity(0.5)), style: dashedStyle)

        // センターライン（サービスコートを左右に分割、ショートサービスラインから外枠まで）
        var centerLine = Path()
        centerLine.move(to: CGPoint(x: width / 2, y: 0))
        centerLine.addLine(to: CGPoint(x: width / 2, y: height / 2 - shortServiceOffset))
        centerLine.move(to: CGPoint(x: width / 2, y: height / 2 + shortServiceOffset))
        centerLine.addLine(to: CGPoint(x: width / 2, y: height))
        context.stroke(centerLine, with: mainLine, lineWidth: 2)
    }
}

#Preview {
    CourtDiagramView(markers: [
        CourtShotMarker(position: CGPoint(x: 0.3, y: 0.2), color: .red),
        CourtShotMarker(position: CGPoint(x: 0.7, y: 0.8), color: .blue)
    ])
    .padding()
}

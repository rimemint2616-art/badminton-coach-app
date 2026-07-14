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

/// ラリー中のショットを線で繋いで表示するための軌跡。
/// showDots が false のときは線のみ（点は描かない）で、過去のラリーを控えめに表示するのに使う。
struct CourtRallyTrail: Identifiable {
    struct Point {
        var position: CGPoint
        var color: Color
    }

    let id: UUID
    var points: [Point]
    var lineColor: Color
    var showDots: Bool

    init(id: UUID = UUID(), points: [Point], lineColor: Color, showDots: Bool) {
        self.id = id
        self.points = points
        self.lineColor = lineColor
        self.showDots = showDots
    }
}

/// バドミントンコートを縦（奥のベースライン〜手前のベースライン）に描画するView。
/// タップで正規化座標(0...1)をコールバックする。
struct CourtDiagramView: View {
    var markers: [CourtShotMarker] = []
    var trails: [CourtRallyTrail] = []
    var onTap: ((CGPoint) -> Void)?

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack {
                Canvas { context, canvasSize in
                    drawCourt(context: context, size: canvasSize)
                    drawTrails(context: context, size: canvasSize)
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

    /// ラリーごとのショットを線で繋いで描画する。showDots が true のラリーだけ点も重ねて描く。
    private func drawTrails(context: GraphicsContext, size: CGSize) {
        for trail in trails {
            let resolvedPoints = trail.points.map {
                CGPoint(x: $0.position.x * size.width, y: $0.position.y * size.height)
            }
            guard !resolvedPoints.isEmpty else { continue }

            if resolvedPoints.count > 1 {
                var path = Path()
                path.move(to: resolvedPoints[0])
                for point in resolvedPoints.dropFirst() {
                    path.addLine(to: point)
                }
                context.stroke(
                    path,
                    with: .color(trail.lineColor),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }

            guard trail.showDots else { continue }
            for (index, point) in resolvedPoints.enumerated() {
                let rect = CGRect(x: point.x - 7, y: point.y - 7, width: 14, height: 14)
                context.fill(Path(ellipseIn: rect), with: .color(trail.points[index].color))
                context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: 1.5)
            }
        }
    }
}

#Preview {
    CourtDiagramView(markers: [
        CourtShotMarker(position: CGPoint(x: 0.3, y: 0.2), color: .red),
        CourtShotMarker(position: CGPoint(x: 0.7, y: 0.8), color: .blue)
    ])
    .padding()
}

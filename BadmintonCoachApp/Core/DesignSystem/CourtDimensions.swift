import CoreGraphics

/// バドミントンコートの寸法（メートル）。CourtDiagramViewの描画と、
/// PDFレポートのショット着地ヒートマップの両方から参照する共通定数。
/// 描画フレームはダブルスコート全体（最大の外枠）を基準にし、
/// シングルスライン・サービスラインはその中の比率として計算する。
enum CourtDimensions {
    static let singlesWidthMeters: Double = 5.18
    static let doublesWidthMeters: Double = 6.10
    static let lengthMeters: Double = 13.40
    static let shortServiceLineFromNetMeters: Double = 1.98
    static let doublesLongServiceLineFromBackMeters: Double = 0.76

    /// 描画フレームの width:height 比率（ダブルスコート全体を基準）
    static var aspectRatio: CGFloat {
        CGFloat(doublesWidthMeters / lengthMeters)
    }

    /// シングルスサイドラインの、ダブルスコート幅に対する片側インセット比率
    static var singlesSideInsetRatio: CGFloat {
        CGFloat((doublesWidthMeters - singlesWidthMeters) / 2 / doublesWidthMeters)
    }

    /// ネットからショートサービスラインまでの、コート全長に対する比率
    static var shortServiceLineOffsetRatio: CGFloat {
        CGFloat(shortServiceLineFromNetMeters / lengthMeters)
    }

    /// ベースラインからダブルスロングサービスラインまでの、コート全長に対する比率
    static var doublesLongServiceLineOffsetRatio: CGFloat {
        CGFloat(doublesLongServiceLineFromBackMeters / lengthMeters)
    }
}

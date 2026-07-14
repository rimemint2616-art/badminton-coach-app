import SwiftUI

extension Color {
    /// "#RRGGBB" 形式の文字列からColorを作る。パースに失敗した場合はグレーにフォールバックする。
    init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString.removeAll { $0 == "#" }
        var value: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8) / 255
        let b = Double(value & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// "#RRGGBB" 形式の文字列に変換する。
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

/// 学年タグの既定色パレット。ユーザーがColorPickerで自由に変更できるので、
/// ここでは新規タグ作成時の初期値として使うだけ。
enum GradeTagPalette {
    static let hexColors: [String] = [
        "#FF6B6B", "#FF922B", "#FCC419", "#51CF66",
        "#20C997", "#4DABF7", "#748FFC", "#DA77F2"
    ]

    static func hex(for index: Int) -> String {
        hexColors[((index % hexColors.count) + hexColors.count) % hexColors.count]
    }
}

extension GradeTag {
    var color: Color {
        get { Color(hex: colorHex) }
        set { colorHex = newValue.hexString }
    }
}

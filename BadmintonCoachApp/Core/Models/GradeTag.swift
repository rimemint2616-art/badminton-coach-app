import Foundation
import SwiftData

/// 生徒の「学年」に使うタグ。固定enumではなく可変データにしてあるのは、
/// 設定タブから表示/非表示の切り替えやタグの追加・削除をできるようにするため。
@Model
final class GradeTag {
    var id: UUID
    var name: String
    var sortOrder: Int
    var isHidden: Bool
    var isDefault: Bool
    /// "#RRGGBB" 形式。生徒一覧のバッジ背景色などに使う。Color変換は Color+Hex.swift 側で行う。
    var colorHex: String

    /// このタグが設定されている生徒。タグ削除時もStudentは消さない（.nullify）。
    @Relationship(deleteRule: .nullify, inverse: \Student.gradeTag)
    var students: [Student] = []

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int,
        isHidden: Bool = false,
        isDefault: Bool = false,
        colorHex: String? = nil
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.isHidden = isHidden
        self.isDefault = isDefault
        self.colorHex = colorHex ?? GradeTagPalette.hex(for: sortOrder)
    }
}

/// 初回起動時、および設定タブの「デフォルトに戻す」で使う既定の学年タグ一式。
enum DefaultGradeTags {
    static let names: [String] = [
        "中学1年生", "中学2年生", "中学3年生",
        "高校1年生", "高校2年生", "高校3年生"
    ]

    static func makeAll() -> [GradeTag] {
        names.enumerated().map { index, name in
            GradeTag(name: name, sortOrder: index, isDefault: true)
        }
    }
}

extension GradeTag {
    /// GradeTagが1件も無ければ既定タグを流し込む。既にデータがあれば何もしない。
    static func seedDefaultsIfNeeded(in context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<GradeTag>())) ?? 0
        guard count == 0 else { return }
        DefaultGradeTags.makeAll().forEach { context.insert($0) }
    }
}

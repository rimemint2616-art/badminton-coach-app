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
/// 学年が高い方が先に来る順（中学3年生→...→高校1年生）で表示する。
enum DefaultGradeTags {
    static let names: [String] = [
        "中学3年生", "中学2年生", "中学1年生",
        "高校3年生", "高校2年生", "高校1年生"
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

    /// 学年の並び順を「中1→中2→中3→高1→高2→高3」から「中3→中2→中1→高3→高2→高1」に
    /// 変更した際、既にシード済みの既存インストールにも反映するための一度きりの再整列。
    /// 名前が完全一致するデフォルトタグだけを動かすので、ユーザーが追加した独自タグや
    /// 手動での並び替えには影響しない。
    static func realignDefaultOrderIfNeeded(in context: ModelContext) {
        let flagKey = "gradeTagOrderRealignedV2"
        guard !UserDefaults.standard.bool(forKey: flagKey) else { return }
        let existing = (try? context.fetch(FetchDescriptor<GradeTag>())) ?? []
        for (index, name) in DefaultGradeTags.names.enumerated() {
            existing.first(where: { $0.name == name })?.sortOrder = index
        }
        UserDefaults.standard.set(true, forKey: flagKey)
    }
}

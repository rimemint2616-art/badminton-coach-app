import Foundation
import SwiftData

/// 「流れ」モードでポイントの理由として選べるタグ。固定enumではなく可変データにしてあるのは、
/// 設定タブからコーチが自由に追加・削除・並び替えできるようにするため（GradeTagと同じ設計）。
@Model
final class PointReasonTag {
    var id: UUID
    var name: String
    var sortOrder: Int
    var isDefault: Bool

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.isDefault = isDefault
    }
}

/// 初回起動時、および設定タブの「デフォルトに戻す」で使う既定のポイント理由タグ一式。
enum DefaultPointReasonTags {
    static let names: [String] = [
        "相手のサーブミス", "スマッシュ決まった", "プッシュ決めた", "相手のミス"
    ]

    static func makeAll() -> [PointReasonTag] {
        names.enumerated().map { index, name in
            PointReasonTag(name: name, sortOrder: index, isDefault: true)
        }
    }
}

extension PointReasonTag {
    /// PointReasonTagが1件も無ければ既定タグを流し込む。既にデータがあれば何もしない。
    static func seedDefaultsIfNeeded(in context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<PointReasonTag>())) ?? 0
        guard count == 0 else { return }
        DefaultPointReasonTags.makeAll().forEach { context.insert($0) }
    }
}

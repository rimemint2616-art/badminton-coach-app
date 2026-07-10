import Foundation
import SwiftData

/// PracticeSessionとPracticeMenuの中間テーブル。
/// 並び順・上書き時間・完了フラグなど、単純な多対多では持てない付加情報を保持するために
/// 明示的なエンティティとして用意している。
@Model
final class SessionDrillItem {
    var id: UUID
    var orderIndex: Int
    /// PracticeMenuのdurationMinutesを上書きしたい場合のみ設定
    var plannedDurationOverride: Int?
    var completed: Bool
    var sessionNotes: String

    /// 親のセッション。削除では消えない（PracticeSession.drillItemsの.cascadeが唯一の削除経路）。
    var session: PracticeSession?
    /// 参照先のメニュー。削除では消えない（PracticeMenu.sessionItemsの.cascadeが唯一の削除経路）。
    var menu: PracticeMenu?

    init(
        id: UUID = UUID(),
        orderIndex: Int = 0,
        plannedDurationOverride: Int? = nil,
        completed: Bool = false,
        sessionNotes: String = "",
        session: PracticeSession? = nil,
        menu: PracticeMenu? = nil
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.plannedDurationOverride = plannedDurationOverride
        self.completed = completed
        self.sessionNotes = sessionNotes
        self.session = session
        self.menu = menu
    }
}

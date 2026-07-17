import Foundation
import SwiftData

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case individual, group

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .individual: return "個人"
        case .group: return "グループ"
        }
    }
}

/// 練習・大会・練習試合の別。スケジュール一覧での色分け表示にも使う。
enum SessionEventCategory: String, Codable, CaseIterable, Identifiable {
    case practice, tournament, practiceMatch

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .practice: return "練習"
        case .tournament: return "大会"
        case .practiceMatch: return "練習試合"
        }
    }
}

/// 練習スケジュールの1コマ。
@Model
final class PracticeSession {
    var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var location: String
    var sessionType: SessionType
    var eventCategory: SessionEventCategory
    /// 終日予定（開始・終了時刻を指定しない、大会日程未定の日など）かどうか。
    var isAllDay: Bool
    /// 種別タグとは別の、自由記述のタイトル（例:「地区大会」「対〇〇中 練習試合」「暫定メニュー案」）。
    var title: String
    var notes: String
    /// 練習メニューの目標（例:「けがをせず、羽を打つ感覚を取り戻す」）。空なら非表示。
    var menuGoal: String

    /// 出席予定の生徒（多対多）。デフォルトは全員参加。
    @Relationship(inverse: \Student.sessions)
    var attendees: [Student] = []

    /// attendeesのうち欠席の生徒のID一覧。フィードバックを書く際に参照する出欠記録。
    var absentStudentIDs: [UUID] = []

    /// このセッションに紐づく練習メニュー項目。セッション削除でまとめて削除（.cascade）。
    /// 旧来のカタログ選択方式（メニューライブラリタブ用）。新しい構造化メニュー編集では使わない。
    @Relationship(deleteRule: .cascade, inverse: \SessionDrillItem.session)
    var drillItems: [SessionDrillItem] = []

    /// 構造化された練習メニュー（セクション単位）。セッション削除でまとめて削除（.cascade）。
    @Relationship(deleteRule: .cascade, inverse: \MenuSection.session)
    var menuSections: [MenuSection] = []

    /// このセッション中に記録された試合。セッション削除でも試合記録は残す（.nullify）。
    @Relationship(deleteRule: .nullify, inverse: \Match.session)
    var matches: [Match] = []

    init(
        id: UUID = UUID(),
        date: Date = .now,
        startTime: Date = .now,
        endTime: Date = .now,
        location: String = "",
        sessionType: SessionType = .group,
        eventCategory: SessionEventCategory = .practice,
        isAllDay: Bool = false,
        title: String = "",
        notes: String = "",
        menuGoal: String = ""
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.sessionType = sessionType
        self.eventCategory = eventCategory
        self.isAllDay = isAllDay
        self.title = title
        self.notes = notes
        self.menuGoal = menuGoal
    }

    func isAbsent(_ student: Student) -> Bool {
        absentStudentIDs.contains(student.id)
    }

    func setAttendance(present: Bool, for student: Student) {
        if present {
            absentStudentIDs.removeAll { $0 == student.id }
        } else if !absentStudentIDs.contains(student.id) {
            absentStudentIDs.append(student.id)
        }
    }

    var sortedMenuSections: [MenuSection] {
        menuSections.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// 「7月5日(土) 9:00〜11:00 (120分)」のような、練習メニューの見出しに使う文字列。
    /// 画面表示とPDF出力の両方でこれを使い回し、表記がずれないようにする。
    var menuHeaderText: String {
        let japanese = Locale(identifier: "ja_JP")
        let dateText = date.formatted(.dateTime.month().day().weekday(.abbreviated).locale(japanese))
        if isAllDay {
            return "\(dateText) 終日"
        }
        let timeText = "\(startTime.formatted(date: .omitted, time: .shortened))〜\(endTime.formatted(date: .omitted, time: .shortened))"
        let minutes = max(0, Int(endTime.timeIntervalSince(startTime) / 60))
        return "\(dateText) \(timeText) (\(minutes)分)"
    }
}

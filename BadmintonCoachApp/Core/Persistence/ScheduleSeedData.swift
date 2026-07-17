import Foundation
import SwiftData

/// 洛西陵明小中バドミントン部の実際の予定表（2026年7月分）を初回起動時に流し込むための
/// シードデータ。ビルドし直すたびに手入力する手間を省くためのもの。既にスケジュールが
/// 1件でも存在すれば何もしない。
enum ScheduleSeedData {
    private struct TimedEntry {
        let day: Int
        let startHour: Int
        let startMinute: Int
        let endHour: Int
        let endMinute: Int
    }

    /// 練習日（時間あり）。場所・メモは記録しない。
    private static let practiceEntries: [TimedEntry] = [
        TimedEntry(day: 1, startHour: 15, startMinute: 40, endHour: 16, endMinute: 40),
        TimedEntry(day: 3, startHour: 15, startMinute: 40, endHour: 16, endMinute: 40),
        TimedEntry(day: 4, startHour: 9, startMinute: 0, endHour: 12, endMinute: 0),
        TimedEntry(day: 6, startHour: 15, startMinute: 40, endHour: 16, endMinute: 40),
        TimedEntry(day: 8, startHour: 15, startMinute: 40, endHour: 16, endMinute: 40),
        TimedEntry(day: 10, startHour: 15, startMinute: 40, endHour: 16, endMinute: 40),
        TimedEntry(day: 11, startHour: 9, startMinute: 0, endHour: 12, endMinute: 0),
        TimedEntry(day: 13, startHour: 13, startMinute: 30, endHour: 15, endMinute: 30),
        TimedEntry(day: 14, startHour: 13, startMinute: 30, endHour: 15, endMinute: 30),
        TimedEntry(day: 15, startHour: 13, startMinute: 30, endHour: 15, endMinute: 30),
        TimedEntry(day: 17, startHour: 13, startMinute: 30, endHour: 15, endMinute: 30),
        TimedEntry(day: 21, startHour: 13, startMinute: 30, endHour: 15, endMinute: 30),
        TimedEntry(day: 23, startHour: 9, startMinute: 0, endHour: 11, endMinute: 0),
        TimedEntry(day: 27, startHour: 9, startMinute: 0, endHour: 11, endMinute: 0),
        TimedEntry(day: 28, startHour: 9, startMinute: 0, endHour: 11, endMinute: 0),
        TimedEntry(day: 30, startHour: 9, startMinute: 0, endHour: 11, endMinute: 0),
        TimedEntry(day: 31, startHour: 9, startMinute: 0, endHour: 11, endMinute: 0)
    ]

    /// 大会（夏季大会ブロック予選・全市）。日程未定のため終日扱い。
    private static let tournamentDays: [Int] = [18, 19, 20, 24, 25]

    static func seedJuly2026IfNeeded(in context: ModelContext) {
        let existingCount = (try? context.fetchCount(FetchDescriptor<PracticeSession>())) ?? 0
        guard existingCount == 0 else { return }

        let calendar = Calendar(identifier: .gregorian)
        func date(day: Int, hour: Int = 0, minute: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 7, day: day, hour: hour, minute: minute)) ?? .now
        }

        for entry in practiceEntries {
            let session = PracticeSession(
                date: date(day: entry.day),
                startTime: date(day: entry.day, hour: entry.startHour, minute: entry.startMinute),
                endTime: date(day: entry.day, hour: entry.endHour, minute: entry.endMinute),
                location: "",
                sessionType: .group,
                eventCategory: .practice,
                isAllDay: false,
                notes: ""
            )
            context.insert(session)
        }

        for day in tournamentDays {
            let session = PracticeSession(
                date: date(day: day),
                startTime: date(day: day),
                endTime: date(day: day),
                location: "",
                sessionType: .group,
                eventCategory: .tournament,
                isAllDay: true,
                notes: ""
            )
            context.insert(session)
        }
    }
}

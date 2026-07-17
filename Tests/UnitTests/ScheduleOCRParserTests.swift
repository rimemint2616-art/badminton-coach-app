import XCTest
@testable import BadmintonCoachApp

final class ScheduleOCRParserTests: XCTestCase {
    func testSkipsOffDays() {
        let lines = ["2 木 OFF", "5 日 OFF"]
        XCTAssertTrue(ScheduleOCRParser.parseEntries(fromLines: lines).isEmpty)
    }

    func testParsesPracticeWithTimes() {
        let lines = ["1 水 練習 15:40 ~ 16:40 体育館I"]
        let entries = ScheduleOCRParser.parseEntries(fromLines: lines)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.day, 1)
        XCTAssertEqual(entries.first?.category, .practice)
        XCTAssertEqual(entries.first?.isAllDay, false)
        XCTAssertEqual(entries.first?.startHour, 15)
        XCTAssertEqual(entries.first?.startMinute, 40)
        XCTAssertEqual(entries.first?.endHour, 16)
        XCTAssertEqual(entries.first?.endMinute, 40)
    }

    func testParsesTournamentAsAllDay() {
        let lines = ["18 土 未定 夏季大会ブロック予選 予定日"]
        let entries = ScheduleOCRParser.parseEntries(fromLines: lines)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.day, 18)
        XCTAssertEqual(entries.first?.category, .tournament)
        XCTAssertEqual(entries.first?.isAllDay, true)
    }

    func testIgnoresLinesWithoutLeadingDayNumber() {
        let lines = ["令和8年 7月 洛西陵明小中 バドミントン部 予定表", "日 曜日 内容 時間 場所 メモ"]
        XCTAssertTrue(ScheduleOCRParser.parseEntries(fromLines: lines).isEmpty)
    }

    func testParsesFullMonthSample() {
        let lines = [
            "1 水 練習 15:40 ~ 16:40 体育館I",
            "2 木 OFF",
            "4 土 練習 9:00 ~ 12:00 体育館I",
            "18 土 未定 夏季大会ブロック予選 予定日",
            "24 金 未定 夏季大会全市 個人戦予定日"
        ]
        let entries = ScheduleOCRParser.parseEntries(fromLines: lines)
        XCTAssertEqual(entries.count, 4)
        XCTAssertEqual(entries.filter { $0.category == .tournament }.count, 2)
        XCTAssertEqual(entries.filter { $0.category == .practice }.count, 2)
    }
}

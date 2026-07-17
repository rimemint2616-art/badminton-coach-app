import Foundation
import SwiftData

/// 実際の部員名簿を初回起動時に流し込むための一時的なシードデータ。
/// ビルドし直すたびに手入力する手間を省くためのもの。既に生徒が1人でも
/// 登録されていれば何もしない。
enum StudentSeedData {
    private struct Entry {
        let rank: Int
        let name: String
    }

    /// 名簿の並び順（先頭の番号がそのままランク）。
    private static let entries: [Entry] = [
        Entry(rank: 1, name: "甲斐"),
        Entry(rank: 2, name: "石塚"),
        Entry(rank: 3, name: "山本"),
        Entry(rank: 4, name: "松木"),
        Entry(rank: 5, name: "高"),
        Entry(rank: 6, name: "羽生田"),
        Entry(rank: 7, name: "山下"),
        Entry(rank: 8, name: "川越"),
        Entry(rank: 9, name: "西村"),
        Entry(rank: 10, name: "生田"),
        Entry(rank: 11, name: "大橋"),
        Entry(rank: 12, name: "鶴田"),
        Entry(rank: 13, name: "金"),
        Entry(rank: 14, name: "山口"),
        Entry(rank: 15, name: "門間")
    ]

    /// 中学3年生であることが分かっている名前。それ以外は全員中学2年生として登録する。
    private static let thirdYearNames: Set<String> = ["石塚", "松木", "高"]

    static func seedIfNeeded(in context: ModelContext) {
        let existingCount = (try? context.fetchCount(FetchDescriptor<Student>())) ?? 0
        guard existingCount == 0 else { return }

        let gradeTags = (try? context.fetch(FetchDescriptor<GradeTag>())) ?? []
        let thirdYearTag = gradeTags.first { $0.name == "中学3年生" }
        let secondYearTag = gradeTags.first { $0.name == "中学2年生" }

        for entry in entries {
            let tag = thirdYearNames.contains(entry.name) ? thirdYearTag : secondYearTag
            let student = Student(name: entry.name, gradeTag: tag, rank: entry.rank)
            context.insert(student)
        }
    }
}

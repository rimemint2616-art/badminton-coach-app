import Foundation
import SwiftData

/// SwiftUI PreviewやUIテストで使うサンプルデータ。本番データには一切影響しない。
enum SampleData {
    static func seed(into context: ModelContext) {
        GradeTag.seedDefaultsIfNeeded(in: context)
        let gradeTags = (try? context.fetch(FetchDescriptor<GradeTag>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        func gradeTag(named name: String) -> GradeTag? {
            gradeTags.first { $0.name == name }
        }

        let taro = Student(name: "山田 太郎", nameKana: "ヤマダ タロウ", dominantHand: .right, gradeTag: gradeTag(named: "中学2年生"), rank: 1)
        let hanako = Student(name: "佐藤 花子", nameKana: "サトウ ハナコ", dominantHand: .left, gradeTag: gradeTag(named: "高校1年生"), rank: 2)
        let jiro = Student(name: "鈴木 次郎", nameKana: "スズキ ジロウ", dominantHand: .right, gradeTag: gradeTag(named: "中学1年生"), rank: 3)

        [taro, hanako, jiro].forEach { context.insert($0) }

        let smashMenu = PracticeMenu(
            name: "スマッシュ連続打ち",
            descriptionText: "ノック方式でスマッシュを連続で打ち込む基礎練習",
            targetSkillTags: ["smash", "power"],
            durationMinutes: 15,
            difficultyLevel: .intermediate
        )
        let footworkMenu = PracticeMenu(
            name: "4隅フットワーク",
            descriptionText: "コート4隅への移動を反復するフットワーク練習",
            targetSkillTags: ["footwork"],
            durationMinutes: 10,
            difficultyLevel: .beginner
        )
        [smashMenu, footworkMenu].forEach { context.insert($0) }

        let session = PracticeSession(
            date: .now,
            startTime: .now,
            endTime: .now.addingTimeInterval(2 * 60 * 60),
            location: "第一体育館",
            sessionType: .group,
            notes: "通常練習"
        )
        session.attendees = [taro, hanako, jiro]
        context.insert(session)

        let feedback = Feedback(
            text: "バックハンドのクリアが安定してきた。次回はスマッシュ後のリカバリーを意識させる。",
            category: .technique,
            source: .manual,
            student: taro,
            session: session
        )
        context.insert(feedback)
    }
}

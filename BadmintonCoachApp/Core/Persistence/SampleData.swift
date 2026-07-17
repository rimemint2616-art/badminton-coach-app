import Foundation
import SwiftData

/// SwiftUI PreviewやUIテストで使うサンプルデータ。本番データには一切影響しない。
enum SampleData {
    static func seed(into context: ModelContext) {
        GradeTag.seedDefaultsIfNeeded(in: context)
        PointReasonTag.seedDefaultsIfNeeded(in: context)
        CourtTag.seedDefaultsIfNeeded(in: context)
        MenuCategoryTag.seedDefaultsIfNeeded(in: context)
        let gradeTags = (try? context.fetch(FetchDescriptor<GradeTag>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        func gradeTag(named name: String) -> GradeTag? {
            gradeTags.first { $0.name == name }
        }
        let courtTags = (try? context.fetch(FetchDescriptor<CourtTag>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        func courtTag(named name: String) -> CourtTag? {
            courtTags.first { $0.name == name }
        }
        let categoryTags = (try? context.fetch(FetchDescriptor<MenuCategoryTag>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
        func categoryTag(named name: String) -> MenuCategoryTag? {
            categoryTags.first { $0.name == name }
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
            eventCategory: .practice,
            notes: "通常練習",
            menuGoal: "けがをせず、羽を打つ感覚を取り戻す"
        )
        session.attendees = [taro, hanako, jiro]
        context.insert(session)

        let warmupSection = MenuSection(orderIndex: 0, title: "体操 5分", category: categoryTag(named: "体操"), session: session)
        context.insert(warmupSection)
        session.menuSections.append(warmupSection)

        let footworkSection = MenuSection(orderIndex: 1, title: "フットワーク(約20分)", category: categoryTag(named: "フットワーク"), session: session)
        context.insert(footworkSection)
        session.menuSections.append(footworkSection)
        let footworkItem1 = MenuSectionItem(
            orderIndex: 0,
            text: "3コート使ったステップ(ランジ、ツーステップ、サイドステップ、クロスステップ、ダッシュ)×1周",
            section: footworkSection
        )
        let footworkItem2 = MenuSectionItem(
            orderIndex: 1,
            text: "→最後のダッシュ以外は急がなくていいので、ゆっくり大きくを意識すること",
            indentLevel: 1,
            section: footworkSection
        )
        [footworkItem1, footworkItem2].forEach {
            context.insert($0)
            footworkSection.items.append($0)
        }

        let knockSection = MenuSection(orderIndex: 2, title: "ノック練", category: categoryTag(named: "ノック練"), session: session)
        context.insert(knockSection)
        session.menuSections.append(knockSection)
        let knockCourts = [courtTag(named: "1コート"), courtTag(named: "2コート")].compactMap { $0 }
        let knockItem = MenuSectionItem(
            orderIndex: 0,
            text: "山田 太郎、佐藤 花子、鈴木 次郎",
            shotsPerPerson: 8,
            isEmphasized: true,
            section: knockSection,
            courts: knockCourts
        )
        context.insert(knockItem)
        knockSection.items.append(knockItem)

        let tournament = PracticeSession(
            date: .now.addingTimeInterval(3 * 24 * 60 * 60),
            startTime: .now.addingTimeInterval(3 * 24 * 60 * 60),
            endTime: .now.addingTimeInterval(3 * 24 * 60 * 60 + 6 * 60 * 60),
            location: "市民体育館",
            sessionType: .group,
            eventCategory: .tournament,
            notes: "地区大会"
        )
        tournament.attendees = [taro, hanako]
        context.insert(tournament)

        let practiceMatch = PracticeSession(
            date: .now.addingTimeInterval(24 * 60 * 60),
            startTime: .now.addingTimeInterval(24 * 60 * 60),
            endTime: .now.addingTimeInterval(24 * 60 * 60 + 90 * 60),
            location: "第二体育館",
            sessionType: .individual,
            eventCategory: .practiceMatch,
            notes: "他校との練習試合"
        )
        practiceMatch.attendees = [jiro]
        context.insert(practiceMatch)

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

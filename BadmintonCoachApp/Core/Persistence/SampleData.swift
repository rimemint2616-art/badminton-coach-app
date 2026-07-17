import Foundation
import SwiftData

/// SwiftUI PreviewやUIテストで使うサンプルデータ。本番データには一切影響しない。
enum SampleData {
    static func seed(into context: ModelContext) {
        let taro = Student(name: "山田 太郎", nameKana: "ヤマダ タロウ", dominantHand: .right, level: .intermediate)
        let hanako = Student(name: "佐藤 花子", nameKana: "サトウ ハナコ", dominantHand: .left, level: .advanced)
        let jiro = Student(name: "鈴木 次郎", nameKana: "スズキ ジロウ", dominantHand: .right, level: .beginner)

        [taro, hanako, jiro].forEach { context.insert($0) }

        // 体操（デフォルトメニュー: 毎回の練習の最初に自動追加）
        let stretchMenu = PracticeMenu(
            name: "ストレッチ・体操",
            descriptionText: "全身のストレッチと準備運動",
            durationMinutes: 10,
            difficultyLevel: .beginner,
            majorCategory: .warmup,
            isDefaultMenu: true,
            defaultOrderIndex: 0
        )
        // フットワーク
        let footworkMenu = PracticeMenu(
            name: "4隅フットワーク",
            descriptionText: "コート4隅への移動を反復するフットワーク練習",
            targetSkillTags: ["footwork"],
            durationMinutes: 10,
            difficultyLevel: .beginner,
            majorCategory: .footwork
        )
        // ノック練
        let smashMenu = PracticeMenu(
            name: "スマッシュ連続打ち",
            descriptionText: "ノック方式でスマッシュを連続で打ち込む基礎練習",
            targetSkillTags: ["smash", "power"],
            durationMinutes: 15,
            difficultyLevel: .intermediate,
            majorCategory: .knock,
            middleCategory: .singles
        )
        // パターン練
        let patternMenu = PracticeMenu(
            name: "全面フリー（半面攻撃）",
            descriptionText: "決められた配球パターンで攻守を反復する",
            durationMinutes: 15,
            difficultyLevel: .advanced,
            majorCategory: .pattern,
            middleCategory: .doubles
        )
        // ゲーム練
        let gameMenu = PracticeMenu(
            name: "ダブルス実戦ゲーム",
            descriptionText: "試合形式でのゲーム練習",
            durationMinutes: 20,
            difficultyLevel: .intermediate,
            majorCategory: .game,
            middleCategory: .doubles
        )
        [stretchMenu, footworkMenu, smashMenu, patternMenu, gameMenu].forEach { context.insert($0) }

        // サンプルの本日の練習メニュー
        let plan = PracticePlan(
            title: "サンプル練習メニュー",
            date: .now,
            targetDurationMinutes: 90
        )
        context.insert(plan)
        let planItem1 = PlanItem(
            orderIndex: 0, kind: .drill, title: stretchMenu.name, menuID: stretchMenu.id,
            majorCategory: .warmup, estimatedMinutes: 10, plan: plan
        )
        let planItem2 = PlanItem(
            orderIndex: 1, kind: .drill, title: footworkMenu.name, menuID: footworkMenu.id,
            majorCategory: .footwork, repUnit: .reps, countPerPerson: 20, sets: 3,
            estimatedMinutes: 15, plan: plan
        )
        [planItem1, planItem2].forEach { context.insert($0); plan.items.append($0) }

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

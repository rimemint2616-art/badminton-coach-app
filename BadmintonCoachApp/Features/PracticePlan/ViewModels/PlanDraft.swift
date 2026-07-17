import Foundation
import SwiftData
import SwiftUI

/// 作成中の「本日の練習メニュー」1項目。
/// SwiftDataに保存せず、ビルダー画面で編集し、保存時にPlanItemへ変換する。
@Observable
final class DraftItem: Identifiable {
    let id: UUID
    var kind: PlanItemKind
    var menuID: UUID?
    var title: String
    var majorCategory: MajorCategory?
    var middleCategory: MiddleCategory?
    var repUnit: RepUnit?
    var countPerPerson: Int?
    var sets: Int?
    var minutes: Int?
    var matchPoints: Int?
    var matchCount: Int?
    var estimatedMinutes: Int
    var notes: String
    var courts: [CourtAssignment]

    init(
        id: UUID = UUID(),
        kind: PlanItemKind = .drill,
        menuID: UUID? = nil,
        title: String = "",
        majorCategory: MajorCategory? = nil,
        middleCategory: MiddleCategory? = nil,
        repUnit: RepUnit? = nil,
        countPerPerson: Int? = nil,
        sets: Int? = nil,
        minutes: Int? = nil,
        matchPoints: Int? = nil,
        matchCount: Int? = nil,
        estimatedMinutes: Int = 10,
        notes: String = "",
        courts: [CourtAssignment] = []
    ) {
        self.id = id
        self.kind = kind
        self.menuID = menuID
        self.title = title
        self.majorCategory = majorCategory
        self.middleCategory = middleCategory
        self.repUnit = repUnit
        self.countPerPerson = countPerPerson
        self.sets = sets
        self.minutes = minutes
        self.matchPoints = matchPoints
        self.matchCount = matchCount
        self.estimatedMinutes = estimatedMinutes
        self.notes = notes
        self.courts = courts
    }

    var format: MeasurementFormat? { majorCategory?.format }

    /// カテゴリの測定方法から、メニューを追加した際の初期値を設定して生成する。
    static func from(menu: PracticeMenu) -> DraftItem {
        let item = DraftItem(
            kind: .drill,
            menuID: menu.id,
            title: menu.name,
            majorCategory: menu.majorCategory,
            middleCategory: menu.middleCategory,
            estimatedMinutes: menu.durationMinutes
        )
        switch menu.format {
        case .simple:
            break
        case .repsAndSets:
            item.repUnit = (menu.majorCategory == .knock) ? .shuttles : .reps
            item.countPerPerson = 20
            item.sets = 3
        case .minutes:
            item.minutes = menu.durationMinutes
        case .pointMatch:
            item.matchPoints = 21
            item.matchCount = 1
        }
        return item
    }

    static func rest(minutes: Int) -> DraftItem {
        DraftItem(kind: .rest, title: "休憩", estimatedMinutes: minutes)
    }

    /// 行に表示するパラメータの要約。
    var parameterSummary: String {
        if kind == .rest { return "休憩" }
        guard let format else { return "" }
        switch format {
        case .simple:
            return ""
        case .repsAndSets:
            let unit = repUnit?.displayName ?? "回"
            let count = countPerPerson ?? 0
            let s = sets ?? 0
            return "1人 \(count)\(unit) × \(s)セット"
        case .minutes:
            return "\(minutes ?? estimatedMinutes)分"
        case .pointMatch:
            let pts = matchPoints ?? 21
            let cnt = matchCount ?? 1
            return "\(pts)点マッチ × \(cnt)"
        }
    }
}

/// 作成中の「本日の練習メニュー」全体。
@Observable
final class PlanDraft: Identifiable {
    /// 画面提示（fullScreenCover等）用の安定ID。
    let id = UUID()
    var existingPlanID: UUID?
    var title: String
    var date: Date
    var targetDurationMinutes: Int
    var breakIntervalMinutes: Int
    var breakDurationMinutes: Int
    var notes: String
    var items: [DraftItem]

    init(
        existingPlanID: UUID? = nil,
        title: String = "",
        date: Date = .now,
        targetDurationMinutes: Int = 120,
        breakIntervalMinutes: Int = 30,
        breakDurationMinutes: Int = 5,
        notes: String = "",
        items: [DraftItem] = []
    ) {
        self.existingPlanID = existingPlanID
        self.title = title
        self.date = date
        self.targetDurationMinutes = targetDurationMinutes
        self.breakIntervalMinutes = breakIntervalMinutes
        self.breakDurationMinutes = breakDurationMinutes
        self.notes = notes
        self.items = items
    }

    var contentMinutes: Int {
        items.reduce(0) { $0 + $1.estimatedMinutes }
    }
    var isOverTime: Bool { contentMinutes > targetDurationMinutes }
    var overByMinutes: Int { max(0, contentMinutes - targetDurationMinutes) }
    var underByMinutes: Int { max(0, targetDurationMinutes - contentMinutes) }
    var isUnderTime: Bool { contentMinutes < targetDurationMinutes }

    // MARK: - 編集操作

    func add(_ item: DraftItem) {
        items.append(item)
    }

    func addRest() {
        items.append(.rest(minutes: breakDurationMinutes))
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    /// メニューの間に休憩を自動挿入する。既存の休憩はいったん除去してから入れ直す。
    func autoInsertBreaks() {
        let drills = items.filter { $0.kind == .drill }
        guard breakIntervalMinutes > 0, !drills.isEmpty else {
            items = drills
            return
        }
        var rebuilt: [DraftItem] = []
        var sinceLastBreak = 0
        for (index, drill) in drills.enumerated() {
            rebuilt.append(drill)
            sinceLastBreak += drill.estimatedMinutes
            let isLast = index == drills.count - 1
            if !isLast && sinceLastBreak >= breakIntervalMinutes {
                rebuilt.append(.rest(minutes: breakDurationMinutes))
                sinceLastBreak = 0
            }
        }
        items = rebuilt
    }

    // MARK: - 読み込み / 保存

    /// 既存のPracticePlanからドラフトを復元する。
    static func load(from plan: PracticePlan) -> PlanDraft {
        let draft = PlanDraft(
            existingPlanID: plan.id,
            title: plan.title,
            date: plan.date,
            targetDurationMinutes: plan.targetDurationMinutes,
            breakIntervalMinutes: plan.breakIntervalMinutes,
            breakDurationMinutes: plan.breakDurationMinutes,
            notes: plan.notes,
            items: plan.sortedItems.map { item in
                DraftItem(
                    id: item.id,
                    kind: item.kind,
                    menuID: item.menuID,
                    title: item.title,
                    majorCategory: item.majorCategory,
                    middleCategory: item.middleCategory,
                    repUnit: item.repUnit,
                    countPerPerson: item.countPerPerson,
                    sets: item.sets,
                    minutes: item.minutes,
                    matchPoints: item.matchPoints,
                    matchCount: item.matchCount,
                    estimatedMinutes: item.estimatedMinutes,
                    notes: item.notes,
                    courts: item.courts
                )
            }
        )
        return draft
    }

    /// 新規作成用ドラフト。デフォルトメニューを先頭に自動追加する。
    static func newPlan(defaultMenus: [PracticeMenu], breakInterval: Int, breakDuration: Int, target: Int) -> PlanDraft {
        let draft = PlanDraft(
            targetDurationMinutes: target,
            breakIntervalMinutes: breakInterval,
            breakDurationMinutes: breakDuration
        )
        for menu in defaultMenus.sorted(by: { $0.defaultOrderIndex < $1.defaultOrderIndex }) {
            draft.items.append(.from(menu: menu))
        }
        return draft
    }

    /// ドラフトをSwiftDataへ保存する（既存なら上書き、なければ新規作成）。保存したPracticePlanを返す。
    @discardableResult
    func save(into context: ModelContext) -> PracticePlan {
        let plan: PracticePlan
        if let existingPlanID,
           let existing = try? context.fetch(
               FetchDescriptor<PracticePlan>(predicate: #Predicate<PracticePlan> { $0.id == existingPlanID })
           ).first {
            plan = existing
            plan.title = title
            plan.date = date
            plan.targetDurationMinutes = targetDurationMinutes
            plan.breakIntervalMinutes = breakIntervalMinutes
            plan.breakDurationMinutes = breakDurationMinutes
            plan.notes = notes
            for old in plan.items {
                context.delete(old)
            }
            plan.items.removeAll()
        } else {
            plan = PracticePlan(
                title: title,
                date: date,
                targetDurationMinutes: targetDurationMinutes,
                breakIntervalMinutes: breakIntervalMinutes,
                breakDurationMinutes: breakDurationMinutes,
                notes: notes
            )
            context.insert(plan)
            existingPlanID = plan.id
        }

        for (index, draftItem) in items.enumerated() {
            let planItem = PlanItem(
                id: draftItem.id,
                orderIndex: index,
                kind: draftItem.kind,
                title: draftItem.title,
                menuID: draftItem.menuID,
                majorCategory: draftItem.majorCategory,
                middleCategory: draftItem.middleCategory,
                repUnit: draftItem.repUnit,
                countPerPerson: draftItem.countPerPerson,
                sets: draftItem.sets,
                minutes: draftItem.minutes,
                matchPoints: draftItem.matchPoints,
                matchCount: draftItem.matchCount,
                estimatedMinutes: draftItem.estimatedMinutes,
                notes: draftItem.notes,
                courts: draftItem.courts,
                plan: plan
            )
            context.insert(planItem)
            plan.items.append(planItem)
        }

        try? context.save()
        return plan
    }
}

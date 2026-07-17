import XCTest
import SwiftData
@testable import BadmintonCoachApp

final class MenuCategoryTagTests: XCTestCase {
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: Schema(SchemaV1.models), isStoredInMemoryOnly: true)
        return try ModelContainer(for: Schema(SchemaV1.models), configurations: [configuration])
    }

    @MainActor
    func testStandardDraftsOnlyIncludesStandardEveryPracticeCategoriesInSortOrder() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let warmup = MenuCategoryTag(name: "体操", sortOrder: 0, isStandardEveryPractice: true, standardDurationMinutes: 5)
        let footwork = MenuCategoryTag(name: "フットワーク", sortOrder: 1, isStandardEveryPractice: false)
        let stretch = MenuCategoryTag(name: "ストレッチ", sortOrder: 2, isStandardEveryPractice: true, standardDurationMinutes: nil)
        [warmup, footwork, stretch].forEach { context.insert($0) }
        try context.save()

        let drafts = MenuSectionDraft.standardDrafts(from: [footwork, stretch, warmup])

        XCTAssertEqual(drafts.map(\.title), ["体操 5分", "ストレッチ"])
        XCTAssertEqual(drafts.map(\.categoryID), [warmup.id, stretch.id])
    }

    @MainActor
    func testSeedDefaultsIfNeededOnlySeedsOnce() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        MenuCategoryTag.seedDefaultsIfNeeded(in: context)
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MenuCategoryTag>()), DefaultMenuCategoryTags.definitions.count)

        context.insert(MenuCategoryTag(name: "サーブ練", sortOrder: 99))
        try context.save()
        MenuCategoryTag.seedDefaultsIfNeeded(in: context)
        try context.save()

        // 既にデータがあるので、2回目のseedDefaultsIfNeededは何もしない
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MenuCategoryTag>()), DefaultMenuCategoryTags.definitions.count + 1)
    }

    @MainActor
    func testDeletingCategoryTagNullifiesSectionCategoryWithoutDeletingSection() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = PracticeSession()
        context.insert(session)
        let category = MenuCategoryTag(name: "ノック練", sortOrder: 0, supportsTemplateLibrary: true)
        context.insert(category)
        let section = MenuSection(orderIndex: 0, title: "ノック練", category: category, session: session)
        context.insert(section)
        session.menuSections.append(section)
        try context.save()

        context.delete(category)
        try context.save()

        XCTAssertNil(section.category)
        XCTAssertNotNil(try context.fetch(FetchDescriptor<MenuSection>()).first)
    }

    @MainActor
    func testTemplateItemsCascadeDeleteWithTemplate() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let category = MenuCategoryTag(name: "フットワーク", sortOrder: 0, supportsTemplateLibrary: true)
        context.insert(category)
        let template = MenuTemplate(name: "4隅フットワーク", category: category)
        context.insert(template)
        let item = MenuTemplateItem(orderIndex: 0, text: "サイドステップ", template: template)
        context.insert(item)
        template.items.append(item)
        try context.save()

        context.delete(template)
        try context.save()

        XCTAssertTrue(try context.fetch(FetchDescriptor<MenuTemplateItem>()).isEmpty)
    }
}

import XCTest
import SwiftData
@testable import BadmintonCoachApp

final class MenuSectionModelTests: XCTestCase {
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: Schema(SchemaV1.models), isStoredInMemoryOnly: true)
        return try ModelContainer(for: Schema(SchemaV1.models), configurations: [configuration])
    }

    @MainActor
    func testSessionMenuSectionsCascadeDeleteWithSession() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = PracticeSession(menuGoal: "けがをせず打つ")
        context.insert(session)
        let section = MenuSection(orderIndex: 0, title: "体操", session: session)
        context.insert(section)
        session.menuSections.append(section)
        let item = MenuSectionItem(orderIndex: 0, text: "ラジオ体操", section: section)
        context.insert(item)
        section.items.append(item)
        try context.save()

        context.delete(session)
        try context.save()

        XCTAssertTrue(try context.fetch(FetchDescriptor<MenuSection>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<MenuSectionItem>()).isEmpty)
    }

    @MainActor
    func testDeletingCourtTagRemovesItFromItemWithoutDeletingItem() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = PracticeSession()
        context.insert(session)
        let section = MenuSection(orderIndex: 0, title: "ノック練", session: session)
        context.insert(section)
        session.menuSections.append(section)

        let court1 = CourtTag(name: "1コート", sortOrder: 0)
        let court2 = CourtTag(name: "2コート", sortOrder: 1)
        context.insert(court1)
        context.insert(court2)

        let item = MenuSectionItem(orderIndex: 0, text: "スマッシュ", section: section, courts: [court1, court2])
        context.insert(item)
        section.items.append(item)
        try context.save()

        context.delete(court1)
        try context.save()

        XCTAssertEqual(item.courts.map(\.name), ["2コート"])
        XCTAssertNotNil(try context.fetch(FetchDescriptor<MenuSectionItem>()).first)
    }

    @MainActor
    func testSortedItemsAndSectionsRespectOrderIndex() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = PracticeSession()
        context.insert(session)

        let sectionB = MenuSection(orderIndex: 1, title: "B", session: session)
        let sectionA = MenuSection(orderIndex: 0, title: "A", session: session)
        [sectionB, sectionA].forEach {
            context.insert($0)
            session.menuSections.append($0)
        }

        let itemB = MenuSectionItem(orderIndex: 1, text: "b", section: sectionA)
        let itemA = MenuSectionItem(orderIndex: 0, text: "a", section: sectionA)
        [itemB, itemA].forEach {
            context.insert($0)
            sectionA.items.append($0)
        }
        try context.save()

        XCTAssertEqual(session.sortedMenuSections.map(\.title), ["A", "B"])
        XCTAssertEqual(sectionA.sortedItems.map(\.text), ["a", "b"])
    }

    @MainActor
    func testCategoryAndRepsAreStoredAndComposeDisplayText() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = PracticeSession()
        context.insert(session)
        let category = MenuCategoryTag(name: "ノック練", sortOrder: 0)
        context.insert(category)
        let section = MenuSection(orderIndex: 0, title: "ノック練", category: category, session: session)
        context.insert(section)
        session.menuSections.append(section)

        let bothItem = MenuSectionItem(orderIndex: 0, text: "スマッシュ", shotsPerPerson: 8, sets: 2, section: section)
        let shotsOnlyItem = MenuSectionItem(orderIndex: 1, text: "クリア", shotsPerPerson: 10, section: section)
        let neitherItem = MenuSectionItem(orderIndex: 2, text: "ヘアピン", section: section)
        [bothItem, shotsOnlyItem, neitherItem].forEach {
            context.insert($0)
            section.items.append($0)
        }
        try context.save()

        XCTAssertEqual(section.category?.name, "ノック練")
        XCTAssertEqual(bothItem.repsSuffix, "8球×2セット")
        XCTAssertEqual(bothItem.displayText, "スマッシュ 8球×2セット")
        XCTAssertEqual(shotsOnlyItem.repsSuffix, "10球")
        XCTAssertNil(neitherItem.repsSuffix)
        XCTAssertEqual(neitherItem.displayText, "ヘアピン")
    }

    @MainActor
    func testCourtTagSeedDefaultsIfNeededOnlySeedsOnce() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        CourtTag.seedDefaultsIfNeeded(in: context)
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CourtTag>()), DefaultCourtTags.names.count)

        context.insert(CourtTag(name: "特設コート", sortOrder: 99))
        try context.save()
        CourtTag.seedDefaultsIfNeeded(in: context)
        try context.save()

        // 既にデータがあるので、2回目のseedDefaultsIfNeededは何もしない
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CourtTag>()), DefaultCourtTags.names.count + 1)
    }
}

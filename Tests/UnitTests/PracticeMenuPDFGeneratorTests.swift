import XCTest
import SwiftData
import CoreGraphics
@testable import BadmintonCoachApp

final class PracticeMenuPDFGeneratorTests: XCTestCase {
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: Schema(SchemaV1.models), isStoredInMemoryOnly: true)
        return try ModelContainer(for: Schema(SchemaV1.models), configurations: [configuration])
    }

    @MainActor
    private func pageCount(of data: Data) -> Int {
        guard let provider = CGDataProvider(data: data as CFData),
              let document = CGPDFDocument(provider) else { return 0 }
        return document.numberOfPages
    }

    @MainActor
    func testGenerateProducesSinglePageForShortMenu() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = PracticeSession(
            startTime: .now, endTime: .now.addingTimeInterval(60 * 60),
            menuGoal: "羽を打つ感覚を取り戻す"
        )
        context.insert(session)
        let section = MenuSection(orderIndex: 0, title: "体操 5分", session: session)
        context.insert(section)
        session.menuSections.append(section)
        try context.save()

        let data = PracticeMenuPDFGenerator.generate(session: session)
        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(pageCount(of: data), 1)
    }

    @MainActor
    func testGenerateProducesMultiplePagesForLongMenu() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = PracticeSession(startTime: .now, endTime: .now.addingTimeInterval(2 * 60 * 60))
        context.insert(session)

        // 十分長い内容を作り、1ページに収まらないようにする。
        for sectionIndex in 0..<20 {
            let section = MenuSection(orderIndex: sectionIndex, title: "セクション\(sectionIndex)", session: session)
            context.insert(section)
            session.menuSections.append(section)
            for itemIndex in 0..<5 {
                let item = MenuSectionItem(
                    orderIndex: itemIndex,
                    text: "とても長い練習内容の説明文です。反復回数や注意点をたくさん書いています。\(sectionIndex)-\(itemIndex)",
                    section: section
                )
                context.insert(item)
                section.items.append(item)
            }
        }
        try context.save()

        let data = PracticeMenuPDFGenerator.generate(session: session)
        XCTAssertFalse(data.isEmpty)
        XCTAssertGreaterThan(pageCount(of: data), 1)
    }
}

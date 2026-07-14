import XCTest
import SwiftData
@testable import BadmintonCoachApp

@MainActor
final class ModelPersistenceTests: XCTestCase {
    private func makeInMemoryContext() throws -> ModelContext {
        let configuration = ModelConfiguration(schema: Schema(SchemaV1.models), isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Schema(SchemaV1.models),
            migrationPlan: AppMigrationPlan.self,
            configurations: [configuration]
        )
        // container.mainContext は @MainActor 隔離されており、XCTestの同期テストメソッドから
        // 呼ぶとメインスレッド外で実行されてクラッシュすることがあるため、
        // 隔離されていない ModelContext(container:) を使う。
        return ModelContext(container)
    }

    func testStudentInsertAndFetch() throws {
        let context = try makeInMemoryContext()
        let student = Student(name: "テスト太郎")
        context.insert(student)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Student>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "テスト太郎")
    }

    func testDeletingMatchCascadesToRalliesAndShots() throws {
        let context = try makeInMemoryContext()
        let player1 = Student(name: "選手1")
        let player2 = Student(name: "選手2")
        context.insert(player1)
        context.insert(player2)

        let match = Match(player1: player1, player2: player2)
        context.insert(match)

        let rally = Rally(orderIndex: 0, serverPlayer: player1, match: match)
        context.insert(rally)
        match.rallies.append(rally)

        let shot = Shot(orderIndex: 0, player: player1, shotType: .serve, courtX: 0.5, courtY: 0.1, rally: rally)
        context.insert(shot)
        rally.shots.append(shot)

        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<Rally>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Shot>()).count, 1)

        context.delete(match)
        try context.save()

        XCTAssertEqual(try context.fetch(FetchDescriptor<Rally>()).count, 0, "Matchを消したらRallyもcascade削除されるべき")
        XCTAssertEqual(try context.fetch(FetchDescriptor<Shot>()).count, 0, "Matchを消したらShotもcascade削除されるべき")
        // 選手自体は残る
        XCTAssertEqual(try context.fetch(FetchDescriptor<Student>()).count, 2)
    }

    func testDeletingStudentDoesNotCascadeIntoFeedback() throws {
        let context = try makeInMemoryContext()
        let student = Student(name: "生徒A")
        context.insert(student)

        let feedback = Feedback(text: "よく頑張りました", student: student)
        context.insert(feedback)
        student.feedbackEntries.append(feedback)
        try context.save()

        context.delete(student)
        try context.save()

        let remainingFeedback = try context.fetch(FetchDescriptor<Feedback>())
        XCTAssertEqual(remainingFeedback.count, 1, "Studentを削除してもFeedbackは残るべき（.nullify）")
        XCTAssertNil(remainingFeedback.first?.student)
    }
}

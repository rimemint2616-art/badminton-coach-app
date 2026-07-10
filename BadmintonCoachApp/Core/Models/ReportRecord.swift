import Foundation
import SwiftData

/// 生成済みPDFレポートのシステムオブレコード。
/// PDF実体はDocuments/Reports/に保存し、DBにはメタデータとファイルURLのみ持たせる
/// （SwiftDataに大きなバイナリを直接ブロブとして持たせない方針）。
@Model
final class ReportRecord {
    var id: UUID
    var dateRangeStart: Date
    var dateRangeEnd: Date
    var generatedAt: Date
    /// Documentsディレクトリからの相対パス
    var relativeFilePath: String

    var student: Student?

    init(
        id: UUID = UUID(),
        dateRangeStart: Date,
        dateRangeEnd: Date,
        generatedAt: Date = .now,
        relativeFilePath: String,
        student: Student? = nil
    ) {
        self.id = id
        self.dateRangeStart = dateRangeStart
        self.dateRangeEnd = dateRangeEnd
        self.generatedAt = generatedAt
        self.relativeFilePath = relativeFilePath
        self.student = student
    }
}

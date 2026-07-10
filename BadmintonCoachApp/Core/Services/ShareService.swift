import Foundation

enum ShareServiceError: Error {
    case documentsDirectoryUnavailable
}

/// 生成したPDFをDocuments/Reports/へ保存する。DB(ReportRecord)にはこのURLを記録するだけにし、
/// バイナリ本体をSwiftDataへ直接持たせない。
enum ShareService {
    static func saveReport(pdfData: Data, fileName: String) throws -> (fileURL: URL, relativePath: String) {
        let documentsURL = try FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let reportsURL = documentsURL.appendingPathComponent("Reports", isDirectory: true)
        if !FileManager.default.fileExists(atPath: reportsURL.path) {
            try FileManager.default.createDirectory(at: reportsURL, withIntermediateDirectories: true)
        }
        let fileURL = reportsURL.appendingPathComponent(fileName)
        try pdfData.write(to: fileURL, options: .atomic)
        return (fileURL, "Reports/\(fileName)")
    }

    static func resolvedURL(forRelativePath relativePath: String) -> URL? {
        guard let documentsURL = try? FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
        ) else { return nil }
        return documentsURL.appendingPathComponent(relativePath)
    }
}

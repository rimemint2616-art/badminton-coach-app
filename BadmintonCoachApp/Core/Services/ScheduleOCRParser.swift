import Foundation
import UIKit
import Vision

/// 予定表の写真から読み取った1件分の候補。ユーザーが確認・修正してから登録する前提。
struct ParsedScheduleEntry: Identifiable {
    let id = UUID()
    var day: Int
    var category: SessionEventCategory
    var isAllDay: Bool
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
}

/// 「令和8年 7月」のような紙の予定表をカメラロールの写真から読み取り、
/// 練習・大会の候補を抽出するベータ的な機能。表のレイアウトや手書き文字など
/// 認識精度は写真依存のため、読み取り結果は必ずユーザーが確認・修正する前提で設計する。
enum ScheduleOCRParser {
    /// 画像からテキスト行を抽出する。行の分割はVisionのバウンディングボックスのY座標で近いものをまとめる簡易実装。
    static func recognizeLines(in image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }

        let request = VNRecognizeTextRequest { request, _ in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion([])
                return
            }
            let items: [(String, CGRect)] = observations.compactMap { observation in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                return (candidate.string, observation.boundingBox)
            }
            completion(groupIntoRows(items).map { row in row.map(\.0).joined(separator: " ") })
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ja-JP", "en-US"]
        request.usesLanguageCorrection = false

        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    /// Visionは原点が左下・0〜1正規化座標。Y中心が近いものは同じ表の行とみなしてまとめ、
    /// 行内はX座標順（左→右）に並べ直す。
    private static func groupIntoRows(_ items: [(String, CGRect)]) -> [[(String, CGRect)]] {
        let sorted = items.sorted { $0.1.midY > $1.1.midY }
        var rows: [[(String, CGRect)]] = []
        let rowThreshold: CGFloat = 0.015

        for item in sorted {
            if let lastIndex = rows.indices.last,
               let firstOfRow = rows[lastIndex].first,
               abs(firstOfRow.1.midY - item.1.midY) < rowThreshold {
                rows[lastIndex].append(item)
            } else {
                rows.append([item])
            }
        }
        return rows.map { $0.sorted { $0.1.minX < $1.1.minX } }
    }

    /// 行テキストの配列から、日付・種別・時間を推定してエントリ候補を作る。
    /// 「OFF」を含む行はスキップ。時刻が2つ以上見つかれば練習として時間付きで、
    /// 「大会」「未定」を含めば終日の大会として登録する。
    static func parseEntries(fromLines lines: [String]) -> [ParsedScheduleEntry] {
        let timePattern = try! NSRegularExpression(pattern: "([0-9]{1,2})[:：]([0-9]{2})")
        let dayPattern = try! NSRegularExpression(pattern: "^\\s*([0-9]{1,2})\\b")

        var entries: [ParsedScheduleEntry] = []

        for line in lines {
            if line.uppercased().contains("OFF") { continue }

            guard let dayMatch = dayPattern.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                  let dayRange = Range(dayMatch.range(at: 1), in: line),
                  let day = Int(line[dayRange]), (1...31).contains(day) else { continue }

            let times = timePattern.matches(in: line, range: NSRange(line.startIndex..., in: line)).compactMap { match -> (Int, Int)? in
                guard let hRange = Range(match.range(at: 1), in: line),
                      let mRange = Range(match.range(at: 2), in: line),
                      let h = Int(line[hRange]), let m = Int(line[mRange]),
                      (0...23).contains(h), (0...59).contains(m) else { return nil }
                return (h, m)
            }

            let isTournament = line.contains("大会") || line.contains("未定")

            if isTournament {
                entries.append(ParsedScheduleEntry(day: day, category: .tournament, isAllDay: true, startHour: 0, startMinute: 0, endHour: 0, endMinute: 0))
            } else if times.count >= 2 {
                entries.append(ParsedScheduleEntry(day: day, category: .practice, isAllDay: false, startHour: times[0].0, startMinute: times[0].1, endHour: times[1].0, endMinute: times[1].1))
            }
        }
        return entries
    }
}

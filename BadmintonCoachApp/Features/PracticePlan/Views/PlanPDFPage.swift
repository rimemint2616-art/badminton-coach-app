import Foundation
import SwiftUI

/// 本日の練習メニューをPDF化する際の1ページ分のレイアウト。
struct PlanPDFPage: View {
    let title: String
    let date: Date
    let targetMinutes: Int
    let totalMinutes: Int
    /// (連番, 項目) の配列。連番は練習項目のみ採番（休憩は0）。
    let rows: [(number: Int, item: DraftItem)]
    let pageIndex: Int
    let pageCount: Int

    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateStyle = .long
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if pageIndex == 0 {
                header
            }
            ForEach(rows.indices, id: \.self) { i in
                rowView(number: rows[i].number, item: rows[i].item)
                Divider()
            }
            Spacer()
            HStack {
                Spacer()
                Text("\(pageIndex + 1) / \(pageCount)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(40)
        .frame(width: 595, height: 842, alignment: .top)
        .background(Color.white)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.isEmpty ? "本日の練習メニュー" : title)
                .font(.system(size: 26, weight: .bold))
            Text(dateText)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Text("合計 \(totalMinutes)分")
                Text("目標 \(targetMinutes)分")
                if totalMinutes > targetMinutes {
                    Text("（\(totalMinutes - targetMinutes)分 超過）").foregroundStyle(.red)
                } else if totalMinutes < targetMinutes {
                    Text("（\(targetMinutes - totalMinutes)分 不足）").foregroundStyle(.orange)
                }
            }
            .font(.system(size: 14, weight: .medium))
            Divider().padding(.vertical, 8)
        }
        .padding(.bottom, 8)
    }

    private func rowView(number: Int, item: DraftItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if item.kind == .rest {
                Text("休憩")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.orange)
                    .frame(width: 36, alignment: .leading)
            } else {
                Text("\(number).")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 36, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.isEmpty ? "（無題）" : item.title)
                    .font(.system(size: 15, weight: .semibold))
                let meta = [categoryText(item), item.parameterSummary].filter { !$0.isEmpty }.joined(separator: "  ｜  ")
                if !meta.isEmpty {
                    Text(meta)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                if !item.courts.isEmpty {
                    Text(courtText(item))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(item.estimatedMinutes)分")
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.vertical, 6)
    }

    private func categoryText(_ item: DraftItem) -> String {
        guard let major = item.majorCategory else { return "" }
        return [major.displayName, item.middleCategory?.displayName].compactMap { $0 }.joined(separator: "・")
    }

    private func courtText(_ item: DraftItem) -> String {
        "コート — " + item.courts
            .sorted { $0.courtNumber < $1.courtNumber }
            .map { "\($0.courtNumber): " + $0.players.map(\.name).joined(separator: "・") }
            .joined(separator: "  /  ")
    }
}

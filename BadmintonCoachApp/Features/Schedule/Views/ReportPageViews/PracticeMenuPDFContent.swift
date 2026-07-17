import SwiftUI
import SwiftData

/// 練習メニュー全体を1つの連続したViewとしてまとめる。高さは内容次第で不定
/// （`.fixedSize(vertical: true)`で実測できるようにしてある）。
/// PracticeMenuPDFGeneratorがこの実測高さをもとにページ数・各ページの窓を決める。
struct PracticeMenuPDFContent: View {
    let session: PracticeSession

    static let pageWidth: CGFloat = 595 // A4幅、72dpi

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(session.menuHeaderText)
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .center)

            if !session.title.isEmpty {
                Text(session.title)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if !session.menuGoal.isEmpty {
                Text("目標「\(session.menuGoal)」")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            ForEach(session.sortedMenuSections) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.title)
                        .font(.system(size: 15, weight: .bold))
                    ForEach(section.sortedItems) { item in
                        PracticeMenuPDFLineView(item: item)
                    }
                }
            }
        }
        .padding(.horizontal, 40)
        .frame(width: Self.pageWidth, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
        .background(.white)
    }
}

private struct PracticeMenuPDFLineView: View {
    let item: MenuSectionItem

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(item.indentLevel > 0 ? "→" : "・")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayText)
                    .font(.system(size: item.isEmphasized ? 13 : 11, weight: item.isEmphasized ? .bold : .regular))
                    .foregroundStyle(item.isEmphasized ? Color(hex: "#E03131") : Color.black)
                if !item.courts.isEmpty {
                    Text(item.courts.sorted { $0.sortOrder < $1.sortOrder }.map(\.name).joined(separator: "・"))
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.leading, CGFloat(item.indentLevel) * 16)
    }
}

#Preview {
    let container = AppModelContainer.preview
    let session = try! container.mainContext.fetch(FetchDescriptor<PracticeSession>()).first!
    return ScrollView { PracticeMenuPDFContent(session: session) }
}

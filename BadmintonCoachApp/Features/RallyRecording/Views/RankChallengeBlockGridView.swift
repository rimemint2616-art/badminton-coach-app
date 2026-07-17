import SwiftUI

/// ブロック内の対戦表を、紙の対戦表と同じ「行×列のマス目」の見た目で表示する。
/// 上三角のマスに対戦コード（例:「A5」）またはスコアを表示し、タップで試合記録を開始する。
struct RankChallengeBlockGridView: View {
    let blockLabel: String
    let participants: [Student]
    let pairings: [RankChallengePairing]
    let onTapPairing: (RankChallengePairing) -> Void

    @AppStorage(RankChallengeGridColors.rowWinnerKey) private var rowWinnerHex: String = RankChallengeGridColors.defaultRowWinnerHex
    @AppStorage(RankChallengeGridColors.columnWinnerKey) private var columnWinnerHex: String = RankChallengeGridColors.defaultColumnWinnerHex

    static let cellHeight: CGFloat = 64
    private let cellWidth: CGFloat = 104
    private let cellHeight: CGFloat = Self.cellHeight

    private var lookup: [Set<UUID>: RankChallengePairing] {
        var dict: [Set<UUID>: RankChallengePairing] = [:]
        for pairing in pairings {
            guard let p1 = pairing.player1, let p2 = pairing.player2 else { continue }
            dict[Set([p1.id, p2.id])] = pairing
        }
        return dict
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                GridRow {
                    frameCell { Text(blockLabel).font(.title2.weight(.bold)) }
                        .background(Color.secondary.opacity(0.2))
                    ForEach(participants) { student in
                        frameCell { headerLabel(student.name) }
                            .background(Color.secondary.opacity(0.12))
                    }
                }
                ForEach(Array(participants.enumerated()), id: \.element.id) { rowIndex, rowStudent in
                    GridRow {
                        frameCell { headerLabel(rowStudent.name) }
                            .background(Color.secondary.opacity(0.12))
                        ForEach(Array(participants.enumerated()), id: \.element.id) { colIndex, colStudent in
                            if colIndex > rowIndex, let pairing = lookup[Set([rowStudent.id, colStudent.id])] {
                                matchCell(pairing, rowStudent: rowStudent, colStudent: colStudent)
                            } else {
                                frameCell { Color.clear }
                            }
                        }
                    }
                }
            }
        }
    }

    private func headerLabel(_ name: String) -> some View {
        Text(name)
            .font(.title3.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func frameCell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(width: cellWidth, height: cellHeight)
            .overlay(Rectangle().stroke(Color.secondary.opacity(0.3), lineWidth: 0.5))
    }

    private func matchCell(_ pairing: RankChallengePairing, rowStudent: Student, colStudent: Student) -> some View {
        Button {
            onTapPairing(pairing)
        } label: {
            frameCell {
                if pairing.isCompleted, let s1 = pairing.currentPlayer1Score, let s2 = pairing.currentPlayer2Score {
                    VStack(spacing: 2) {
                        Text("\(s1)-\(s2)")
                            .font(.title3.weight(.bold))
                        if let winner = pairing.winner {
                            Text(winner.name)
                                .font(.caption)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                } else {
                    Text(pairing.matchCode)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .background(cellBackground(pairing, rowStudent: rowStudent, colStudent: colStudent))
        }
        .buttonStyle(.plain)
    }

    private func cellBackground(_ pairing: RankChallengePairing, rowStudent: Student, colStudent: Student) -> Color {
        guard let winner = pairing.winner else {
            return pairing.isCompleted ? Color.green.opacity(0.15) : Color.accentColor.opacity(0.08)
        }
        if winner.id == rowStudent.id {
            return Color(hex: rowWinnerHex).opacity(0.35)
        } else if winner.id == colStudent.id {
            return Color(hex: columnWinnerHex).opacity(0.35)
        }
        return Color.green.opacity(0.15)
    }
}

#Preview {
    let s1 = Student(name: "森田", rank: 1)
    let s2 = Student(name: "齋藤", rank: 2)
    let s3 = Student(name: "高", rank: 3)
    let s4 = Student(name: "吉川", rank: 4)
    let pairings = [
        RankChallengePairing(blockName: "Aブロック", matchNumber: 1, player1: s1, player2: s4),
        RankChallengePairing(blockName: "Aブロック", matchNumber: 2, player1: s2, player2: s3),
        RankChallengePairing(blockName: "Aブロック", matchNumber: 3, player1: s1, player2: s3, player1Score: 2, player2Score: 0),
        RankChallengePairing(blockName: "Aブロック", matchNumber: 4, player1: s2, player2: s4),
        RankChallengePairing(blockName: "Aブロック", matchNumber: 5, player1: s1, player2: s2),
        RankChallengePairing(blockName: "Aブロック", matchNumber: 6, player1: s3, player2: s4)
    ]
    return RankChallengeBlockGridView(
        blockLabel: "A",
        participants: [s1, s2, s3, s4],
        pairings: pairings,
        onTapPairing: { _ in }
    )
    .padding()
}

import SwiftUI

/// 「生徒A 2-1 生徒B」のように対戦結果を表示し、勝った側の名前を太字で強調する。
/// 試合一覧・試合詳細の両方から使い回す。
struct MatchResultSummaryView: View {
    let player1Name: String
    let player2Name: String
    let gamesWonByPlayer1: Int
    let gamesWonByPlayer2: Int

    private var player1Wins: Bool { gamesWonByPlayer1 > gamesWonByPlayer2 }
    private var player2Wins: Bool { gamesWonByPlayer2 > gamesWonByPlayer1 }

    var body: some View {
        HStack(spacing: 6) {
            Text(player1Name)
                .fontWeight(player1Wins ? .bold : .regular)
                .foregroundStyle(player1Wins ? Color.primary : .secondary)
                .lineLimit(1)
            Text("\(gamesWonByPlayer1)-\(gamesWonByPlayer2)")
                .foregroundStyle(.secondary)
            Text(player2Name)
                .fontWeight(player2Wins ? .bold : .regular)
                .foregroundStyle(player2Wins ? Color.primary : .secondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    MatchResultSummaryView(player1Name: "甲斐", player2Name: "石塚", gamesWonByPlayer1: 2, gamesWonByPlayer2: 1)
        .font(.headline)
}

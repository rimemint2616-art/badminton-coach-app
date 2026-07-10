import SwiftUI

struct ScoreboardView: View {
    let player1Name: String
    let player2Name: String
    let player1Score: Int
    let player2Score: Int
    let gamesWonByPlayer1: Int
    let gamesWonByPlayer2: Int
    let currentGameNumber: Int
    let currentServer: MatchSide

    var body: some View {
        HStack(spacing: 24) {
            playerColumn(name: player1Name, score: player1Score, gamesWon: gamesWonByPlayer1, side: .player1)
            VStack {
                Text("ゲーム \(currentGameNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(":")
                    .font(.largeTitle.bold())
            }
            playerColumn(name: player2Name, score: player2Score, gamesWon: gamesWonByPlayer2, side: .player2)
        }
        .padding()
        .cardStyle()
    }

    private func playerColumn(name: String, score: Int, gamesWon: Int, side: MatchSide) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                if currentServer == side {
                    Image(systemName: "tennis.racket")
                        .font(.caption)
                }
                Text(name)
                    .font(.headline)
            }
            Text("\(score)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
            Text("獲得ゲーム: \(gamesWon)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ScoreboardView(
        player1Name: "山田 太郎",
        player2Name: "佐藤 花子",
        player1Score: 15,
        player2Score: 12,
        gamesWonByPlayer1: 1,
        gamesWonByPlayer2: 0,
        currentGameNumber: 2,
        currentServer: .player1
    )
}

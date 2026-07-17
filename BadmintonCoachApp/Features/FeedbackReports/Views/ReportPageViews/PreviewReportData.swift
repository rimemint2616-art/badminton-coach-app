import Foundation

/// レポートページのSwiftUI PreviewをSwiftData無しで確認するためのサンプルデータ。
enum PreviewReportData {
    static let sample = StudentReportData(
        studentName: "山田 太郎",
        dateRangeStart: Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now,
        dateRangeEnd: .now,
        matches: [sampleMatch],
        feedbackEntries: [
            FeedbackSnapshot(id: UUID(), date: .now, category: "技術", text: "バックハンドのクリアが安定してきた。次回はスマッシュ後のリカバリーを意識させる。")
        ],
        aggregateShotTypeDistribution: [
            ShotTypeCount(shotType: .clear, count: 20),
            ShotTypeCount(shotType: .smash, count: 12),
            ShotTypeCount(shotType: .drop, count: 8),
            ShotTypeCount(shotType: .net, count: 6)
        ],
        totalMatches: 1,
        wins: 1,
        losses: 0
    )

    static let sampleMatch = MatchStats(
        id: UUID(),
        date: .now,
        player1Name: "山田 太郎",
        player2Name: "佐藤 花子",
        finalScoreSummary: [
            GameScoreSnapshot(gameNumber: 1, player1Score: 21, player2Score: 18),
            GameScoreSnapshot(gameNumber: 2, player1Score: 21, player2Score: 15)
        ],
        winnerName: "山田 太郎",
        totalRallies: 42,
        averageRallyLength: 5.4,
        longestRallyLength: 18,
        shotTypeDistribution: [
            ShotTypeCount(shotType: .clear, count: 20),
            ShotTypeCount(shotType: .smash, count: 12),
            ShotTypeCount(shotType: .drop, count: 8)
        ],
        winnerShotCounts: ["山田 太郎": 10, "佐藤 花子": 6],
        errorShotCounts: ["山田 太郎": 5, "佐藤 花子": 9],
        shotMarkers: [
            ShotMarkerSnapshot(courtX: 0.3, courtY: 0.2, result: .winner, playerName: "山田 太郎"),
            ShotMarkerSnapshot(courtX: 0.7, courtY: 0.8, result: .unforcedError, playerName: "佐藤 花子")
        ],
        pointsWonByPlayer1: 42,
        pointsWonByPlayer2: 33,
        pointReasonBreakdownPlayer1: [
            PointReasonBreakdownEntry(reason: "スマッシュ決まった", count: 18, percentage: 42.9),
            PointReasonBreakdownEntry(reason: "相手のサーブミス", count: 12, percentage: 28.6)
        ],
        pointReasonBreakdownPlayer2: [
            PointReasonBreakdownEntry(reason: "相手のミス", count: 15, percentage: 45.5),
            PointReasonBreakdownEntry(reason: "プッシュ決めた", count: 10, percentage: 30.3)
        ]
    )
}

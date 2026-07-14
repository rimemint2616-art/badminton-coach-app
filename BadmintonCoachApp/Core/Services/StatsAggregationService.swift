import Foundation

/// SwiftDataモデルに依存しない、PDF生成・プレビュー両方で使い回せる素のCodable構造体群。
/// これによりレポートのView層をSwiftDataから切り離し、プレビュー・テストを容易にする。

struct ShotTypeCount: Codable, Identifiable, Hashable {
    var id: String { shotType.rawValue }
    let shotType: ShotType
    let count: Int
}

struct GameScoreSnapshot: Codable, Hashable {
    let gameNumber: Int
    let player1Score: Int
    let player2Score: Int
}

struct ShotMarkerSnapshot: Codable, Hashable {
    let courtX: Double
    let courtY: Double
    let result: ShotResult
    let playerName: String
}

struct MatchStats: Codable, Identifiable {
    let id: UUID
    let date: Date
    let player1Name: String
    let player2Name: String
    let finalScoreSummary: [GameScoreSnapshot]
    let winnerName: String?
    let totalRallies: Int
    let averageRallyLength: Double
    let longestRallyLength: Int
    let shotTypeDistribution: [ShotTypeCount]
    let winnerShotCounts: [String: Int]
    let errorShotCounts: [String: Int]
    let shotMarkers: [ShotMarkerSnapshot]
}

struct FeedbackSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    let category: String?
    let text: String
}

struct StudentReportData: Codable {
    let studentName: String
    let dateRangeStart: Date
    let dateRangeEnd: Date
    let matches: [MatchStats]
    let feedbackEntries: [FeedbackSnapshot]
    let aggregateShotTypeDistribution: [ShotTypeCount]
    let totalMatches: Int
    let wins: Int
    let losses: Int
}

enum StatsAggregationService {
    static func stats(for match: Match) -> MatchStats {
        let player1Name = match.player1DisplayName
        let player2Name = match.player2DisplayName

        let allShots = match.rallies.flatMap(\.shots)

        var typeCounts: [ShotType: Int] = [:]
        var winnerCounts: [String: Int] = [:]
        var errorCounts: [String: Int] = [:]
        var markers: [ShotMarkerSnapshot] = []

        for shot in allShots {
            typeCounts[shot.shotType, default: 0] += 1
            let playerName = (shot.player === match.player1) ? player1Name : player2Name
            if shot.result == .winner {
                winnerCounts[playerName, default: 0] += 1
            } else if shot.result == .unforcedError || shot.result == .forcedError {
                errorCounts[playerName, default: 0] += 1
            }
            markers.append(ShotMarkerSnapshot(courtX: shot.courtX, courtY: shot.courtY, result: shot.result, playerName: playerName))
        }

        let rallyLengths = match.rallies.map { rally -> Int in
            rally.manualShotCount ?? rally.shots.count
        }
        let averageLength = rallyLengths.isEmpty ? 0 : Double(rallyLengths.reduce(0, +)) / Double(rallyLengths.count)

        let gamesWonByPlayer1 = match.finalScoreSummary.filter { $0.player1Score > $0.player2Score }.count
        let gamesWonByPlayer2 = match.finalScoreSummary.filter { $0.player2Score > $0.player1Score }.count
        let winnerName: String?
        if match.status == .completed {
            winnerName = gamesWonByPlayer1 > gamesWonByPlayer2 ? player1Name
                : (gamesWonByPlayer2 > gamesWonByPlayer1 ? player2Name : nil)
        } else {
            winnerName = nil
        }

        return MatchStats(
            id: match.id,
            date: match.date,
            player1Name: player1Name,
            player2Name: player2Name,
            finalScoreSummary: match.finalScoreSummary.map {
                GameScoreSnapshot(gameNumber: $0.gameNumber, player1Score: $0.player1Score, player2Score: $0.player2Score)
            },
            winnerName: winnerName,
            totalRallies: match.rallies.count,
            averageRallyLength: averageLength,
            longestRallyLength: rallyLengths.max() ?? 0,
            shotTypeDistribution: typeCounts.map { ShotTypeCount(shotType: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count },
            winnerShotCounts: winnerCounts,
            errorShotCounts: errorCounts,
            shotMarkers: markers
        )
    }

    static func reportData(for student: Student, matches: [Match], feedback: [Feedback], dateRangeStart: Date, dateRangeEnd: Date) -> StudentReportData {
        let matchStats = matches.map(stats(for:))

        var aggregateTypeCounts: [ShotType: Int] = [:]
        for stat in matchStats {
            for entry in stat.shotTypeDistribution {
                aggregateTypeCounts[entry.shotType, default: 0] += entry.count
            }
        }

        let wins = matchStats.filter { $0.winnerName == student.name }.count
        let losses = matchStats.filter { $0.winnerName != nil && $0.winnerName != student.name }.count

        return StudentReportData(
            studentName: student.name,
            dateRangeStart: dateRangeStart,
            dateRangeEnd: dateRangeEnd,
            matches: matchStats,
            feedbackEntries: feedback.map {
                FeedbackSnapshot(id: $0.id, date: $0.date, category: $0.category?.displayName, text: $0.text)
            }.sorted { $0.date > $1.date },
            aggregateShotTypeDistribution: aggregateTypeCounts.map { ShotTypeCount(shotType: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count },
            totalMatches: matchStats.count,
            wins: wins,
            losses: losses
        )
    }
}

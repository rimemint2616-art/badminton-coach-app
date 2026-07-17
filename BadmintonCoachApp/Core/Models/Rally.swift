import Foundation
import SwiftData

@Model
final class Rally {
    var id: UUID
    /// 試合内の通し番号（0始まり）
    var orderIndex: Int
    /// 何ゲーム目か（1,2,3）
    var gameNumber: Int
    /// このラリーのサーバー
    var serverPlayer: Student?
    /// ラリー終了直後のスコア（プレイヤー1, プレイヤー2）。再計算せず直接保持する。
    var player1ScoreAfterRally: Int
    var player2ScoreAfterRally: Int
    /// ポイントが決まった理由（設定タブで管理するPointReasonTagの名前をそのまま保存する）。
    /// タグを後から改名・削除しても過去の記録は変わらないよう、関係ではなく文字列で持つ。
    var endReason: String?
    /// 簡易モードで記録した際の手動打数。詳細モードでは常にnil（shots.countが正）。
    var manualShotCount: Int?

    /// 親の試合。Rally削除では消えない（Match.ralliesの.cascadeが唯一の削除経路）。
    var match: Match?

    /// このラリーのショット記録。Rally削除時にまとめて削除（.cascade）。
    @Relationship(deleteRule: .cascade, inverse: \Shot.rally)
    var shots: [Shot] = []

    init(
        id: UUID = UUID(),
        orderIndex: Int,
        gameNumber: Int = 1,
        serverPlayer: Student? = nil,
        player1ScoreAfterRally: Int = 0,
        player2ScoreAfterRally: Int = 0,
        endReason: String? = nil,
        manualShotCount: Int? = nil,
        match: Match? = nil
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.gameNumber = gameNumber
        self.serverPlayer = serverPlayer
        self.player1ScoreAfterRally = player1ScoreAfterRally
        self.player2ScoreAfterRally = player2ScoreAfterRally
        self.endReason = endReason
        self.manualShotCount = manualShotCount
        self.match = match
    }
}

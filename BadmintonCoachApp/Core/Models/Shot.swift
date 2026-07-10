import Foundation
import SwiftData

/// ショットの種類。将来のAI解析が構造化データとして読めるよう、
/// 自由記述テキストではなく厳格なenumで管理する。
enum ShotType: String, Codable, CaseIterable, Identifiable {
    case serve
    case clear
    case drop
    case smash
    case drive
    case net
    case lift
    case push
    case block
    case roundTheHead
    case flick
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .serve: return "サーブ"
        case .clear: return "クリア"
        case .drop: return "ドロップ"
        case .smash: return "スマッシュ"
        case .drive: return "ドライブ"
        case .net: return "ネット"
        case .lift: return "ロビング"
        case .push: return "プッシュ"
        case .block: return "ブロック"
        case .roundTheHead: return "ラウンドザヘッド"
        case .flick: return "フリック"
        case .other: return "その他"
        }
    }
}

enum ShotResult: String, Codable, CaseIterable, Identifiable {
    case inPlay
    case winner
    case unforcedError
    case forcedError

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inPlay: return "継続中"
        case .winner: return "ウィナー"
        case .unforcedError: return "アンフォーストエラー"
        case .forcedError: return "フォーストエラー"
        }
    }
}

enum ShotErrorType: String, Codable, CaseIterable, Identifiable {
    case net
    case outLong
    case outWide
    case footFault
    case serviceFault
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .net: return "ネット"
        case .outLong: return "アウト（縦）"
        case .outWide: return "アウト（横）"
        case .footFault: return "フットフォルト"
        case .serviceFault: return "サービスフォルト"
        case .other: return "その他"
        }
    }
}

@Model
final class Shot {
    var id: UUID
    /// ラリー内の通し番号（0始まり）
    var orderIndex: Int
    var player: Student?
    var shotType: ShotType
    /// コート上の落下位置（シングルスコート基準、0...1に正規化した座標）
    var courtX: Double
    var courtY: Double
    var result: ShotResult
    var errorType: ShotErrorType?
    var timestamp: Date?

    /// 親のラリー。Shot削除では消えない（Rally.shotsの.cascadeが唯一の削除経路）。
    var rally: Rally?

    init(
        id: UUID = UUID(),
        orderIndex: Int,
        player: Student? = nil,
        shotType: ShotType,
        courtX: Double,
        courtY: Double,
        result: ShotResult = .inPlay,
        errorType: ShotErrorType? = nil,
        timestamp: Date? = nil,
        rally: Rally? = nil
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.player = player
        self.shotType = shotType
        self.courtX = courtX
        self.courtY = courtY
        self.result = result
        self.errorType = errorType
        self.timestamp = timestamp
        self.rally = rally
    }
}

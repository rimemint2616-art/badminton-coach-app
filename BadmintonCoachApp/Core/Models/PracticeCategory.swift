import Foundation

/// 練習メニューの大カテゴリ。アプリ内蔵の固定セット。
/// 各カテゴリは測定方法（`format`）と、中カテゴリ（シングルス/ダブルス）を持つかどうかが決まっている。
enum MajorCategory: String, Codable, CaseIterable, Identifiable {
    case warmup     // 体操・ウォームアップ
    case footwork   // フットワーク
    case knock      // ノック練
    case pattern    // パターン練
    case game       // ゲーム練

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .warmup: return "体操"
        case .footwork: return "フットワーク"
        case .knock: return "ノック練"
        case .pattern: return "パターン練"
        case .game: return "ゲーム練"
        }
    }

    var systemImage: String {
        switch self {
        case .warmup: return "figure.cooldown"
        case .footwork: return "figure.run"
        case .knock: return "arrow.up.forward.circle"
        case .pattern: return "point.topleft.down.to.point.bottomright.curvepath"
        case .game: return "trophy"
        }
    }

    /// このカテゴリの測定方法。
    var format: MeasurementFormat {
        switch self {
        case .warmup: return .simple
        case .footwork, .knock: return .repsAndSets
        case .pattern: return .minutes
        case .game: return .pointMatch
        }
    }

    /// シングルス/ダブルスの中カテゴリを持つか。
    var hasMiddleCategory: Bool {
        switch self {
        case .knock, .pattern, .game: return true
        case .warmup, .footwork: return false
        }
    }
}

/// 中カテゴリ。ノック練・パターン練・ゲーム練で使う。
enum MiddleCategory: String, Codable, CaseIterable, Identifiable {
    case singles    // シングルス
    case doubles    // ダブルス

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .singles: return "シングルス"
        case .doubles: return "ダブルス"
        }
    }
}

/// メニュー1件の測定方法（本日の練習メニューに追加したときに設定できる数値項目が変わる）。
enum MeasurementFormat: String, Codable {
    case simple         // 数値なし（時間のみ）: 体操
    case repsAndSets    // 何球/何回 × セット数: フットワーク・ノック練
    case minutes        // 何分: パターン練
    case pointMatch     // 何点マッチ: ゲーム練
}

/// フットワーク・ノック練で「何球」か「何回」かを選べるようにする単位。
enum RepUnit: String, Codable, CaseIterable, Identifiable {
    case shuttles   // 球
    case reps       // 回

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shuttles: return "球"
        case .reps: return "回"
        }
    }
}

/// 本日の練習メニューに並ぶ項目の種類。
enum PlanItemKind: String, Codable, CaseIterable, Identifiable {
    case drill  // 練習メニュー
    case rest   // 休憩

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .drill: return "練習"
        case .rest: return "休憩"
        }
    }
}

/// コートへの選手割り当て（1コート分）。PlanItemにCodableの値として保存する。
struct CourtAssignment: Codable, Hashable, Identifiable {
    var id: UUID
    var courtNumber: Int
    var players: [AssignedPlayer]

    init(id: UUID = UUID(), courtNumber: Int, players: [AssignedPlayer] = []) {
        self.id = id
        self.courtNumber = courtNumber
        self.players = players
    }
}

/// コートに割り当てられた選手。生徒への参照は壊れないようにIDと名前のスナップショットで保持する。
struct AssignedPlayer: Codable, Hashable, Identifiable {
    var id: UUID        // Student.id
    var name: String    // 割り当て時点の名前スナップショット
}

import Foundation

/// ライブタギング中に「どちらのプレイヤーか」を扱うための軽量な値。
/// 実際のStudentへの解決はViewModel/View側でMatch.player1/player2を参照して行う。
enum MatchSide: String, Codable, Hashable {
    case player1
    case player2

    var opposite: MatchSide {
        self == .player1 ? .player2 : .player1
    }
}

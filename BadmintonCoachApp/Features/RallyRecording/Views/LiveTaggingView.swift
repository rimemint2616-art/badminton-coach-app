import SwiftUI
import SwiftData

struct LiveTaggingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: LiveTaggingViewModel

    init(match: Match, modelContext: ModelContext, firstServer: MatchSide = .player1) {
        _viewModel = State(initialValue: LiveTaggingViewModel(match: match, modelContext: modelContext, firstServer: firstServer))
    }

    init(viewModel: LiveTaggingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    /// 現在のゲームで確定済みのラリー（記録順）。
    private var currentGameRallies: [Rally] {
        viewModel.match.rallies
            .filter { $0.gameNumber == viewModel.currentGameNumber }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    /// コートに表示するショットの軌跡。
    /// 直近1ラリー（＋記録中のラリー）は点+線、それより前のラリーは線のみにして
    /// ラリーが増えても点だらけで見づらくならないようにする。
    private var trails: [CourtRallyTrail] {
        var result: [CourtRallyTrail] = []
        let rallies = currentGameRallies
        let recentCount = 1
        let olderRallies = rallies.count > recentCount ? rallies.prefix(rallies.count - recentCount) : []
        let recentRallies = rallies.suffix(recentCount)

        for rally in olderRallies {
            let points = rally.shots
                .sorted { $0.orderIndex < $1.orderIndex }
                .map { CourtRallyTrail.Point(position: CGPoint(x: $0.courtX, y: $0.courtY), color: .gray) }
            guard points.count > 1 else { continue }
            result.append(CourtRallyTrail(points: points, lineColor: .gray.opacity(0.4), showDots: false))
        }

        for rally in recentRallies {
            let points = rally.shots
                .sorted { $0.orderIndex < $1.orderIndex }
                .map {
                    CourtRallyTrail.Point(
                        position: CGPoint(x: $0.courtX, y: $0.courtY),
                        color: $0.player === viewModel.match.player1 ? .red : .blue
                    )
                }
            guard !points.isEmpty else { continue }
            result.append(CourtRallyTrail(points: points, lineColor: .white.opacity(0.8), showDots: true))
        }

        if !viewModel.pendingShots.isEmpty {
            let points = viewModel.pendingShots.map {
                CourtRallyTrail.Point(
                    position: CGPoint(x: $0.courtX, y: $0.courtY),
                    color: $0.side == .player1 ? .red : .blue
                )
            }
            result.append(CourtRallyTrail(points: points, lineColor: .yellow, showDots: true))
        }

        return result
    }

    var body: some View {
        VStack(spacing: 12) {
            ScoreboardView(
                player1Name: viewModel.player1Name,
                player2Name: viewModel.player2Name,
                player1Score: viewModel.player1Score,
                player2Score: viewModel.player2Score,
                gamesWonByPlayer1: viewModel.gamesWonByPlayer1,
                gamesWonByPlayer2: viewModel.gamesWonByPlayer2,
                currentGameNumber: viewModel.currentGameNumber,
                currentServer: viewModel.currentServer
            )

            Picker("記録モード", selection: $viewModel.recordingMode) {
                ForEach(RecordingMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)

            HStack(alignment: .top, spacing: 16) {
                CourtDiagramView(trails: trails) { point in
                    viewModel.selectCourtPosition(point)
                }
                .layoutPriority(1)
                .overlay(alignment: .topLeading) {
                    if viewModel.pendingTapPoint != nil {
                        Text("ショット種類を選択してください")
                            .font(.caption)
                            .padding(6)
                            .background(.thinMaterial, in: Capsule())
                            .padding(8)
                    }
                }

                ShotPaletteView(isEnabled: viewModel.pendingTapPoint != nil) { shotType in
                    viewModel.selectShotType(shotType)
                }
                .frame(width: 160)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if viewModel.recordingMode == .quick && viewModel.canEndRally {
                Stepper(
                    "打数（目安）: \(viewModel.quickModeShotCount)",
                    value: $viewModel.quickModeShotCount,
                    in: 1...50
                )
                .frame(maxWidth: 320)
            }

            HStack {
                Button {
                    viewModel.undoLastPendingShot()
                } label: {
                    Label("ショットを取り消し", systemImage: "arrow.uturn.backward")
                }
                .disabled(viewModel.pendingShots.isEmpty)

                Button {
                    viewModel.undoLastRally()
                } label: {
                    Label("ラリーを取り消し", systemImage: "arrow.uturn.backward.circle")
                }
                .disabled(viewModel.match.rallies.isEmpty)

                Spacer()

                Button(role: .destructive) {
                    viewModel.endRally(kind: .error)
                } label: {
                    Label("Error", systemImage: "xmark.circle.fill")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canEndRally)

                Button {
                    viewModel.endRally(kind: .winner)
                } label: {
                    Label("Winner", systemImage: "checkmark.circle.fill")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canEndRally)
            }
        }
        .padding()
        .navigationTitle("ラリー記録")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Label("中断して保存", systemImage: "pause.circle")
                }
                .disabled(!viewModel.pendingShots.isEmpty)
            }
        }
        .alert("ゲーム終了", isPresented: $viewModel.isGameOver) {
            Button("\(viewModel.player1Name) が先にサーブ") {
                viewModel.startNextGame(firstServer: .player1)
            }
            Button("\(viewModel.player2Name) が先にサーブ") {
                viewModel.startNextGame(firstServer: .player2)
            }
        } message: {
            Text("次のゲームの最初のサーバーを選んでください")
        }
        .alert("試合終了", isPresented: $viewModel.isMatchOver) {
            Button("完了") { dismiss() }
        } message: {
            Text("試合結果が保存されました")
        }
    }
}

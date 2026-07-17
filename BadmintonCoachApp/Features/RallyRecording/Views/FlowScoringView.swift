import SwiftUI
import SwiftData

/// 「流れ」モードの記録画面。ショットのタグ付けは行わず、ポイントを取った側を
/// ボタンでその場で記録していくだけのシンプルなライブスコアラー。
/// ポイントボタンをタップすると即座に記録し、その直後に理由候補（設定タブで管理）を
/// 表示して、タップ1回で後付けのタグ付けもできるようにする。
struct FlowScoringView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\PointReasonTag.sortOrder)]) private var reasonTags: [PointReasonTag]
    @State private var viewModel: FlowScoringViewModel
    @State private var reasonPickerSide: MatchSide?

    init(match: Match, modelContext: ModelContext, firstServer: MatchSide = .player1) {
        _viewModel = State(initialValue: FlowScoringViewModel(match: match, modelContext: modelContext, firstServer: firstServer))
    }

    init(viewModel: FlowScoringViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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

                HStack(spacing: 16) {
                    pointButton(name: viewModel.player1Name, side: .player1)
                    pointButton(name: viewModel.player2Name, side: .player2)
                }

                if let side = reasonPickerSide {
                    reasonPickerSection(side: side)
                }

                Button {
                    viewModel.undoLastPoint()
                    reasonPickerSide = nil
                } label: {
                    Label("1ポイント取り消し", systemImage: "arrow.uturn.backward")
                }
                .disabled(viewModel.match.rallies.isEmpty)
            }
            .padding()
        }
        .navigationTitle("試合の流れを記録")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Label("中断して保存", systemImage: "pause.circle")
                }
            }
        }
        .alert("ゲーム終了", isPresented: $viewModel.isGameOver) {
            Button("次のゲームへ") {
                viewModel.startNextGame()
                reasonPickerSide = nil
            }
        } message: {
            Text("次のゲームは前のゲームの勝者が先にサーブします")
        }
        .alert("試合終了", isPresented: $viewModel.isMatchOver) {
            Button("完了") { dismiss() }
        } message: {
            Text("試合結果が保存されました")
        }
    }

    private func pointButton(name: String, side: MatchSide) -> some View {
        Button {
            viewModel.awardPoint(to: side)
            reasonPickerSide = side
        } label: {
            VStack(spacing: 6) {
                Text(name)
                    .font(.system(size: 44, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("ポイント")
                    .font(.title2.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(side == .player1 ? .red : .blue)
    }

    @ViewBuilder
    private func reasonPickerSection(side: MatchSide) -> some View {
        let name = side == .player1 ? viewModel.player1Name : viewModel.player2Name
        VStack(spacing: 18) {
            Text("\(name)のポイント — 理由は？")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(reasonTags) { tag in
                    Button {
                        viewModel.tagLastPoint(reason: tag.name)
                        reasonPickerSide = nil
                    } label: {
                        Text(tag.name)
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 22)
                    }
                    .buttonStyle(.bordered)
                    .tint(side == .player1 ? .red : .blue)
                }
            }

            Button("スキップ") {
                reasonPickerSide = nil
            }
            .font(.body)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        let container = AppModelContainer.preview
        let match = Match(recordingStyle: .flow)
        container.mainContext.insert(match)
        return FlowScoringView(match: match, modelContext: container.mainContext)
    }
    .modelContainer(AppModelContainer.preview)
}

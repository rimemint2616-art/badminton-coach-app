import SwiftUI
import SwiftData

/// 試合記録中の画面。match.recordingStyleに応じて「流れ」/「結果のみ」の
/// 記録UIを切り替えて表示し、記録の途中でもツールバーから方式を切り替えられるようにする。
struct MatchRecordingView: View {
    private let modelContext: ModelContext
    @Bindable var match: Match
    @State private var flowViewModel: FlowScoringViewModel

    init(match: Match, modelContext: ModelContext, firstServer: MatchSide = .player1) {
        self.match = match
        self.modelContext = modelContext
        _flowViewModel = State(
            initialValue: Self.makeFlowViewModel(match: match, modelContext: modelContext, firstServer: firstServer)
        )
    }

    var body: some View {
        Group {
            switch match.recordingStyle {
            case .flow:
                FlowScoringView(viewModel: flowViewModel)
            case .resultOnly:
                let draft = (flowViewModel.player1Score, flowViewModel.player2Score)
                SimpleResultEntryView(
                    match: match,
                    currentGameDraftScore: draft == (0, 0) ? nil : draft
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Button {
                        switchToResultOnly()
                    } label: {
                        Label("結果のみの入力に切り替え", systemImage: "number")
                    }
                    .disabled(match.recordingStyle == .resultOnly)

                    Button {
                        switchToFlow()
                    } label: {
                        Label("流れの記録に切り替え", systemImage: "bolt")
                    }
                    .disabled(match.recordingStyle == .flow)
                } label: {
                    Label("記録方法を切り替え", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
    }

    private static func makeFlowViewModel(match: Match, modelContext: ModelContext, firstServer: MatchSide) -> FlowScoringViewModel {
        if match.rallies.isEmpty {
            return FlowScoringViewModel(match: match, modelContext: modelContext, firstServer: firstServer)
        }
        return FlowScoringViewModel.resuming(match: match, modelContext: modelContext)
    }

    private func switchToResultOnly() {
        match.recordingStyle = .resultOnly
        try? modelContext.save()
    }

    private func switchToFlow() {
        match.recordingStyle = .flow
        flowViewModel = Self.makeFlowViewModel(match: match, modelContext: modelContext, firstServer: .player1)
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        let container = AppModelContainer.preview
        let match = Match(recordingStyle: .flow)
        container.mainContext.insert(match)
        return MatchRecordingView(match: match, modelContext: container.mainContext)
    }
    .modelContainer(AppModelContainer.preview)
}

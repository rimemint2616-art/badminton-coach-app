import SwiftUI

/// ショット種類を選ぶ常時表示パレット。主要8種類＋「もっと見る」で残りを表示する。
struct ShotPaletteView: View {
    var isEnabled: Bool
    var onSelect: (ShotType) -> Void

    @State private var showingMore = false

    private let primaryTypes: [ShotType] = [
        .serve, .clear, .drop, .smash, .drive, .net, .lift, .push
    ]
    private let moreTypes: [ShotType] = [
        .block, .roundTheHead, .flick, .other
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(primaryTypes) { type in
                paletteButton(type)
            }

            Button {
                showingMore = true
            } label: {
                Label("もっと見る", systemImage: "ellipsis.circle")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .disabled(!isEnabled)
        }
        .popover(isPresented: $showingMore) {
            VStack(spacing: 8) {
                ForEach(moreTypes) { type in
                    paletteButton(type)
                }
            }
            .padding()
            .frame(minWidth: 200)
        }
    }

    private func paletteButton(_ type: ShotType) -> some View {
        Button {
            showingMore = false
            onSelect(type)
        } label: {
            Text(type.displayName)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isEnabled)
    }
}

#Preview {
    ShotPaletteView(isEnabled: true) { _ in }
        .padding()
        .frame(width: 220)
}

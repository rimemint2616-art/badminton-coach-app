import SwiftUI

/// ブロック分けの人数が均等にならない場合に、コーチが各ブロックの人数を確認・調整してから
/// 組み合わせを作成できるようにするシート。
struct RankChallengeBlockSizeAdjustmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    let participantCount: Int
    @State var sizes: [Int]
    let onConfirm: ([Int]) -> Void

    private var total: Int { sizes.reduce(0, +) }
    private var isValid: Bool { total == participantCount && sizes.allSatisfy { $0 >= 2 || $0 == 0 } }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(sizes.indices, id: \.self) { index in
                        Stepper(
                            "\(blockLabel(index)): \(sizes[index])名",
                            value: Binding(
                                get: { sizes[index] },
                                set: { sizes[index] = max(0, $0) }
                            ),
                            in: 0...participantCount
                        )
                    }
                } header: {
                    Text("ブロックごとの人数")
                } footer: {
                    Text(isValid
                        ? "合計 \(total)名（参加者 \(participantCount)名と一致）"
                        : "合計 \(total)名 — 参加者\(participantCount)名と一致するよう調整してください（各ブロック0名か2名以上）")
                        .foregroundStyle(isValid ? Color.secondary : Color.red)
                }
            }
            .navigationTitle("ブロックの人数を調整")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("この人数で作成") {
                        onConfirm(sizes)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func blockLabel(_ index: Int) -> String {
        index < RankChallengePairingGenerator.blockLabels.count
            ? "\(RankChallengePairingGenerator.blockLabels[index])ブロック"
            : "第\(index + 1)ブロック"
    }
}

#Preview {
    RankChallengeBlockSizeAdjustmentSheet(participantCount: 11, sizes: [4, 4, 3], onConfirm: { _ in })
}

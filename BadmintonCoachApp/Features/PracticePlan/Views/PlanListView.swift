import SwiftUI
import SwiftData

/// 保存した「本日の練習メニュー」の一覧。ここから新規作成・呼び出し編集を行う。
struct PlanListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\PracticePlan.date, order: .reverse)]) private var plans: [PracticePlan]
    @Query(filter: #Predicate<PracticeMenu> { $0.isDefaultMenu }) private var defaultMenus: [PracticeMenu]

    @AppStorage("defaultTargetMinutes") private var defaultTargetMinutes = 120
    @AppStorage("defaultBreakInterval") private var defaultBreakInterval = 30
    @AppStorage("defaultBreakDuration") private var defaultBreakDuration = 5

    @State private var activeDraft: PlanDraft?

    var body: some View {
        NavigationStack {
            Group {
                if plans.isEmpty {
                    ContentUnavailableView(
                        "本日の練習メニューがありません",
                        systemImage: "list.bullet.clipboard",
                        description: Text("右上の＋から作成してください")
                    )
                } else {
                    List {
                        ForEach(plans) { plan in
                            Button {
                                activeDraft = PlanDraft.load(from: plan)
                            } label: {
                                PlanSummaryRow(plan: plan)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deletePlans)
                    }
                }
            }
            .navigationTitle("本日の練習メニュー")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        activeDraft = PlanDraft.newPlan(
                            defaultMenus: defaultMenus,
                            breakInterval: defaultBreakInterval,
                            breakDuration: defaultBreakDuration,
                            target: defaultTargetMinutes
                        )
                    } label: {
                        Label("新規作成", systemImage: "plus")
                    }
                }
            }
            .fullScreenCover(item: $activeDraft) { draft in
                PlanBuilderView(draft: draft)
            }
        }
    }

    private func deletePlans(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(plans[index])
        }
        try? modelContext.save()
    }
}

private struct PlanSummaryRow: View {
    let plan: PracticePlan

    private var dateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateStyle = .medium
        return f.string(from: plan.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(plan.title.isEmpty ? "（無題の練習メニュー）" : plan.title)
                .font(.headline)
            HStack(spacing: 12) {
                Text(dateText)
                Text("合計 \(plan.totalMinutes)分 / 目標 \(plan.targetDurationMinutes)分")
                Text("\(plan.items.count)項目")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

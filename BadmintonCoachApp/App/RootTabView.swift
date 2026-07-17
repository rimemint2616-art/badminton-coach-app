import SwiftUI

/// アプリのトップレベルナビゲーション。5つの機能領域すべてを配線する。
struct RootTabView: View {
    var body: some View {
        TabView {
            StudentListView()
                .tabItem {
                    Label("生徒", systemImage: "person.2.fill")
                }

            ScheduleAgendaView()
                .tabItem {
                    Label("スケジュール", systemImage: "calendar")
                }

            MatchListView()
                .tabItem {
                    Label("ラリー記録", systemImage: "sportscourt.fill")
                }

            PlanListView()
                .tabItem {
                    Label("練習メニュー", systemImage: "list.bullet.clipboard.fill")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(AppModelContainer.preview)
}

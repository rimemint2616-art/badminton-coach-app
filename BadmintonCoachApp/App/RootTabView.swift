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

            MenuLibraryView()
                .tabItem {
                    Label("練習メニュー", systemImage: "list.bullet.clipboard.fill")
                }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(AppModelContainer.preview)
}

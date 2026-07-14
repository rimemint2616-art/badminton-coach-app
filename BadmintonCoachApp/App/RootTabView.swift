import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case students, schedule, rally, menu, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .students: return "生徒"
        case .schedule: return "スケジュール"
        case .rally: return "ラリー記録"
        case .menu: return "練習メニュー"
        case .settings: return "設定"
        }
    }

    var systemImage: String {
        switch self {
        case .students: return "person.2.fill"
        case .schedule: return "calendar"
        case .rally: return "sportscourt.fill"
        case .menu: return "list.bullet.clipboard.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

/// アプリのトップレベルナビゲーション。5つの機能領域すべてを配線する。
/// タブを押しやすくするため、標準の（小さい）TabViewの見た目ではなく、
/// アイコン＋ラベルを大きく表示するカスタムタブバーを使う。
struct RootTabView: View {
    @AppStorage(AppTextSize.storageKey) private var appTextSizeRawValue: String = AppTextSize.large.rawValue
    @State private var selectedTab: AppTab = .students

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            content
        }
        .dynamicTypeSize((AppTextSize(rawValue: appTextSizeRawValue) ?? .large).dynamicTypeSize)
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.systemImage)
                            .font(.title2)
                        Text(tab.title)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.primary)
                    .background(
                        selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear,
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    /// 各タブのViewはZStack+opacityで常時保持し、タブ切り替えのたびにNavigationStackの
    /// 位置やスクロール位置が失われないようにする（switch文で作り直すと状態が毎回リセットされる）。
    private var content: some View {
        ZStack {
            StudentListView()
                .opacity(selectedTab == .students ? 1 : 0)
                .allowsHitTesting(selectedTab == .students)
            ScheduleAgendaView()
                .opacity(selectedTab == .schedule ? 1 : 0)
                .allowsHitTesting(selectedTab == .schedule)
            MatchListView()
                .opacity(selectedTab == .rally ? 1 : 0)
                .allowsHitTesting(selectedTab == .rally)
            MenuLibraryView()
                .opacity(selectedTab == .menu ? 1 : 0)
                .allowsHitTesting(selectedTab == .menu)
            SettingsView()
                .opacity(selectedTab == .settings ? 1 : 0)
                .allowsHitTesting(selectedTab == .settings)
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(AppModelContainer.preview)
}

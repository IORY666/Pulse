import SwiftUI

/// 主视图 - TabView根容器
struct ContentView: View {
    @Environment(HabitViewModel.self) private var viewModel
    @Environment(StoreManager.self) private var storeManager
    @State private var selectedTab: Tab = .today
    @State private var showPaywall = false
    @State private var showAddHabit = false

    enum Tab: String, CaseIterable {
        case today = "今日"
        case habits = "习惯"
        case settings = "设置"

        var iconName: String {
            switch self {
            case .today: return "checkmark.circle.fill"
            case .habits: return "list.bullet.rectangle.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 今日打卡页
            NavigationStack {
                TodayView(showAddHabit: $showAddHabit)
            }
            .tabItem {
                Label(Tab.today.rawValue, systemImage: Tab.today.iconName)
            }
            .tag(Tab.today)

            // 习惯管理页
            NavigationStack {
                HabitListView(showAddHabit: $showAddHabit)
            }
            .tabItem {
                Label(Tab.habits.rawValue, systemImage: Tab.habits.iconName)
            }
            .tag(Tab.habits)

            // 设置页
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(Tab.settings.rawValue, systemImage: Tab.settings.iconName)
            }
            .tag(Tab.settings)
        }
        .tint(viewModel.todayCompletionRate > 0 ? .green : .blue)
        .sheet(isPresented: $showAddHabit) {
            AddHabitView()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .showPaywall)
        ) { _ in
            showPaywall = true
        }
    }
}

// MARK: - 通知名称扩展

extension Notification.Name {
    /// 显示付费墙的通知
    static let showPaywall = Notification.Name("showPaywall")
}

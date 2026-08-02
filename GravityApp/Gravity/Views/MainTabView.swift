import SwiftUI
import Combine

/// 主界面 — 底部 TabBar（仪表盘 / 终端 / 设置）
struct MainTabView: View {
    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var terminalVM = TerminalViewModel()
    @StateObject private var settingsVM = SettingsViewModel()

    /// 当前使用 Mock 还是真实连接
    @State private var useMock = true
    @State private var webSocketService = WebSocketService()
    @State private var mockService = MockAgentService()

    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard = "仪表盘"
        case terminal = "终端"
        case settings = "设置"

        var icon: String {
            switch self {
            case .dashboard: return "gauge.with.dots.needle.33percent"
            case .terminal: return "terminal"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 仪表盘
            DashboardView(
                viewModel: dashboardVM,
                onSessionTap: { sessionId in
                    terminalVM.selectTab(sessionId)
                },
                onSwitchToTerminal: {
                    selectedTab = .terminal
                }
            )
            .tabItem {
                Label(Tab.dashboard.rawValue, systemImage: Tab.dashboard.icon)
            }
            .tag(Tab.dashboard)

            // 终端
            TerminalView(
                viewModel: terminalVM,
                onSelectSession: { sessionId in
                    terminalVM.selectTab(sessionId)
                }
            )
            .tabItem {
                Label(Tab.terminal.rawValue, systemImage: Tab.terminal.icon)
            }
            .tag(Tab.terminal)

            // 设置
            SettingsView(
                viewModel: settingsVM,
                onConnect: { host, port, token in
                    connectToAgent(host: host, port: port, token: token)
                },
                onDisconnect: {
                    disconnect()
                }
            )
            .tabItem {
                Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
            }
            .tag(Tab.settings)
        }
        .tint(GravityColors.brand)
        .preferredColorScheme(.dark)
        .onAppear {
            setupServices()
        }
    }

    // MARK: - 服务初始化

    private func setupServices() {
        settingsVM.loadSettings()

        // 默认使用 Mock 模式
        useMock = true
        mockService.connect()

        // 绑定 ViewModel
        dashboardVM.bind(mock: mockService)
        terminalVM.bind(mock: mockService)
        settingsVM.bindConnectionState(from: mockService.$connectionState.eraseToAnyPublisher())

        // 创建默认终端会话
        _ = mockService.createSession(name: "终端 #1")

        // 加载快捷指令到终端
        terminalVM.reloadQuickCommands()
    }

    // MARK: - 连接/断开

    private func connectToAgent(host: String, port: Int, token: String) {
        useMock = false
        mockService.disconnect()

        webSocketService.connect(host: host, port: port, token: token)

        dashboardVM.bind(webSocket: webSocketService)
        terminalVM.bind(webSocket: webSocketService)
        settingsVM.bindConnectionState(from: webSocketService.$connectionState.eraseToAnyPublisher())

        // 等 WebSocket 连上后再创建会话（避免消息被丢弃）
        var cancellable: AnyCancellable?
        cancellable = webSocketService.$connectionState
            .filter { $0 == .connected }
            .first()
            .sink { _ in
                _ = self.webSocketService.createSession(name: "终端 #1")
                cancellable?.cancel()
            }
    }

    private func disconnect() {
        if useMock {
            mockService.disconnect()
        } else {
            webSocketService.disconnect()
        }
    }
}

#Preview {
    MainTabView()
}

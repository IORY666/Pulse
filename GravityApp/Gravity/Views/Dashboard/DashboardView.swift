import SwiftUI

/// 仪表盘主页面
struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    var onSessionTap: (String) -> Void
    var onSwitchToTerminal: () -> Void

    @State private var selectedDetailCard: String?
    @State private var showingDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // 连接状态
                    connectionBar

                    // 系统状态卡片网格
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        StatusCard(
                            title: "CPU",
                            icon: "cpu",
                            value: viewModel.cpuColor == GravityColors.success
                                ? String(format: "%.0f%%", viewModel.systemInfo.cpu)
                                : String(format: "%.0f%%", viewModel.systemInfo.cpu),
                            subtitle: viewModel.systemInfo.cpuTemperature.map { String(format: "%.0f°C", $0) } ?? "—",
                            color: viewModel.cpuColor,
                            trendData: viewModel.cpuHistory.suffix(30)
                        ) { showDetail("CPU") }

                        StatusCard(
                            title: "内存",
                            icon: "memorychip",
                            value: viewModel.memoryColor == GravityColors.success
                                ? formatMemory(viewModel.systemInfo.memoryUsed)
                                : formatMemory(viewModel.systemInfo.memoryUsed),
                            subtitle: "已用 / \(formatMemory(viewModel.systemInfo.memoryTotal))",
                            color: viewModel.memoryColor,
                            trendData: viewModel.memoryHistory.suffix(30)
                        ) { showDetail("内存") }

                        StatusCard(
                            title: "磁盘",
                            icon: "internaldrive",
                            value: viewModel.diskColor == GravityColors.success
                                ? formatBytes(viewModel.systemInfo.diskFree)
                                : formatBytes(viewModel.systemInfo.diskFree),
                            subtitle: "可用 / \(formatBytes(viewModel.systemInfo.diskTotal))",
                            color: viewModel.diskColor,
                            trendData: [Double(viewModel.systemInfo.diskPercent)] // 磁盘变化慢
                        ) { showDetail("磁盘") }

                        StatusCard(
                            title: "进程",
                            icon: "list.bullet.rectangle",
                            value: "\(viewModel.systemInfo.processCount)",
                            subtitle: "个进程运行中",
                            color: GravityColors.info,
                            trendData: []
                        ) { showDetail("进程") }

                        StatusCard(
                            title: "网络",
                            icon: "network",
                            value: formatSpeed(viewModel.systemInfo.networkDown),
                            subtitle: "↓下行 / ↑\(formatSpeed(viewModel.systemInfo.networkUp))",
                            color: GravityColors.brand,
                            trendData: viewModel.networkHistory.suffix(30)
                        ) { showDetail("网络") }

                        StatusCard(
                            title: "运行时长",
                            icon: "clock",
                            value: formatUptimeShort(viewModel.systemInfo.uptime),
                            subtitle: "持续运行",
                            color: GravityColors.warning,
                            trendData: []
                        ) { showDetail("运行时长") }
                    }

                    // 活跃终端区域
                    ActiveSessionsList(
                        sessions: viewModel.activeSessions.map { session in
                            (id: session.id,
                             name: session.name,
                             isRunning: session.isRunning,
                             lastOutput: session.lastOutputDescription,
                             lineCount: session.outputLines.count)
                        },
                        onTap: { sessionId in
                            onSessionTap(sessionId)
                            onSwitchToTerminal()
                        }
                    )
                }
                .padding(14)
            }
            .background(GravityColors.background)
            .navigationTitle("Gravity")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                // 下拉刷新 — 由 WebSocket 心跳自动覆盖，这里给个触觉反馈
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
            .sheet(isPresented: $showingDetail) {
                if let card = selectedDetailCard {
                    StatusCardDetailView(
                        title: card,
                        icon: iconForCard(card),
                        color: colorForCard(card),
                        systemInfo: viewModel.systemInfo
                    )
                }
            }
        }
    }

    // MARK: - 连接状态栏

    private var connectionBar: some View {
        HStack {
            ConnectionStatusBadge(
                state: viewModel.connectionState,
                deviceName: viewModel.deviceName
            )
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }

    // MARK: - 辅助

    private func showDetail(_ card: String) {
        selectedDetailCard = card
        showingDetail = true
    }

    private func iconForCard(_ card: String) -> String {
        switch card {
        case "CPU": return "cpu"
        case "内存": return "memorychip"
        case "磁盘": return "internaldrive"
        case "进程": return "list.bullet.rectangle"
        case "网络": return "network"
        case "运行时长": return "clock"
        default: return "questionmark"
        }
    }

    private func colorForCard(_ card: String) -> Color {
        switch card {
        case "CPU": return viewModel.cpuColor
        case "内存": return viewModel.memoryColor
        case "磁盘": return viewModel.diskColor
        case "进程": return GravityColors.info
        case "网络": return GravityColors.brand
        case "运行时长": return GravityColors.warning
        default: return GravityColors.textSecondary
        }
    }

    private func formatMemory(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824.0
        if gb >= 1 { return String(format: "%.1fG", gb) }
        return String(format: "%.0fM", Double(bytes) / 1_048_576.0)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824.0
        if gb >= 1 { return String(format: "%.0fGB", gb) }
        return String(format: "%.0fMB", Double(bytes) / 1_048_576.0)
    }

    private func formatSpeed(_ bytesPerSec: UInt64) -> String {
        let mbps = Double(bytesPerSec) / 131_072.0
        if mbps >= 1 { return String(format: "%.1fM", mbps) }
        return String(format: "%.0fK", Double(bytesPerSec) / 128.0)
    }

    private func formatUptimeShort(_ seconds: Int64) -> String {
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        if days > 0 { return "\(days)天\(hours)时" }
        let mins = (seconds % 3600) / 60
        return "\(hours)时\(mins)分"
    }
}

#Preview {
    let vm = DashboardViewModel()
    DashboardView(viewModel: vm, onSessionTap: { _ in }, onSwitchToTerminal: {})
        .preferredColorScheme(.dark)
}

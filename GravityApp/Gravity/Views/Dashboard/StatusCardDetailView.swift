import SwiftUI

/// 状态卡片详情页（点击卡片展开）
struct StatusCardDetailView: View {
    let title: String
    let icon: String
    let color: Color
    let systemInfo: SystemInfo

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    switch title {
                    case "CPU":
                        cpuDetail
                    case "内存":
                        memoryDetail
                    case "磁盘":
                        diskDetail
                    case "进程":
                        processDetail
                    case "网络":
                        networkDetail
                    case "运行时长":
                        uptimeDetail
                    default:
                        Text("无详情")
                    }
                }
                .padding()
            }
            .background(GravityColors.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundColor(GravityColors.brand)
                }
            }
        }
    }

    // MARK: - CPU 详情

    private var cpuDetail: some View {
        VStack(spacing: 16) {
            // 总体使用率大环
            ZStack {
                Circle()
                    .stroke(GravityColors.border, lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(systemInfo.cpu / 100))
                    .stroke(cpuColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: systemInfo.cpu)

                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", systemInfo.cpu))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(GravityColors.textPrimary)
                    Text(systemInfo.cpuStatus)
                        .font(.caption)
                        .foregroundColor(cpuColor)
                }
            }

            if let temp = systemInfo.cpuTemperature {
                DetailRow(label: "温度", value: String(format: "%.1f°C", temp))
            }

            // 各核心占用
            if let perCore = systemInfo.cpuPerCore {
                VStack(alignment: .leading, spacing: 8) {
                    Text("各核心占用")
                        .font(.headline)
                        .foregroundColor(GravityColors.textPrimary)

                    ForEach(Array(perCore.enumerated()), id: \.offset) { idx, usage in
                        HStack {
                            Text("Core \(idx)")
                                .font(.caption)
                                .foregroundColor(GravityColors.textSecondary)
                                .frame(width: 50, alignment: .leading)

                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(usage > 80 ? GravityColors.error : GravityColors.brand)
                                    .frame(width: geo.size.width * CGFloat(usage / 100))
                            }
                            .frame(height: 8)
                            .background(GravityColors.border.opacity(0.3))
                            .cornerRadius(3)

                            Text(String(format: "%.0f%%", usage))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(GravityColors.textSecondary)
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 内存详情

    private var memoryDetail: some View {
        VStack(spacing: 16) {
            // 内存使用环形图
            ZStack {
                Circle()
                    .stroke(GravityColors.border, lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(systemInfo.memoryPercent / 100))
                    .stroke(memoryColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: systemInfo.memoryPercent)

                VStack(spacing: 2) {
                    Text(String(format: "%.0f%%", systemInfo.memoryPercent))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(GravityColors.textPrimary)
                    Text(systemInfo.memoryStatus)
                        .font(.caption)
                        .foregroundColor(memoryColor)
                }
            }

            DetailRow(label: "已用", value: formatBytes(systemInfo.memoryUsed))
            DetailRow(label: "总量", value: formatBytes(systemInfo.memoryTotal))
            DetailRow(label: "可用", value: formatBytes(systemInfo.memoryTotal - systemInfo.memoryUsed))

            // 内存条
            VStack(alignment: .leading, spacing: 4) {
                Text("内存占用")
                    .font(.caption)
                    .foregroundColor(GravityColors.textSecondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(GravityColors.border)
                            .frame(height: 20)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(memoryColor)
                            .frame(width: geo.size.width * CGFloat(systemInfo.memoryPercent / 100), height: 20)
                    }
                }
                .frame(height: 20)
            }
        }
    }

    // MARK: - 磁盘详情

    private var diskDetail: some View {
        VStack(spacing: 16) {
            DetailRow(label: "可用空间", value: formatBytes(systemInfo.diskFree))
            DetailRow(label: "总容量", value: formatBytes(systemInfo.diskTotal))
            DetailRow(label: "已用", value: formatBytes(systemInfo.diskTotal - systemInfo.diskFree))

            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "已用 %.0f%%", systemInfo.diskPercent))
                    .font(.caption)
                    .foregroundColor(GravityColors.textSecondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(GravityColors.border)
                            .frame(height: 20)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(diskColor)
                            .frame(width: geo.size.width * CGFloat(systemInfo.diskPercent / 100), height: 20)
                    }
                }
                .frame(height: 20)
            }
        }
    }

    // MARK: - 进程详情

    private var processDetail: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(systemInfo.processCount)")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(GravityColors.textPrimary)
                    Text("运行中进程")
                        .font(.caption)
                        .foregroundColor(GravityColors.textSecondary)
                }
                Spacer()
            }

            Text("CPU 占用 TOP 3")
                .font(.headline)
                .foregroundColor(GravityColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(systemInfo.topProcesses) { proc in
                HStack {
                    Text(proc.name)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(GravityColors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(String(format: "%.1f%%", proc.cpuPercent))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(proc.cpuPercent > 50 ? GravityColors.error : GravityColors.success)

                    Text(String(format: "%.0fMB", proc.memoryMB))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(GravityColors.textSecondary)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(GravityColors.cardBackground)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - 网络详情

    private var networkDetail: some View {
        VStack(spacing: 16) {
            DetailRow(label: "上行速率", value: formatSpeed(systemInfo.networkUp))
            DetailRow(label: "下行速率", value: formatSpeed(systemInfo.networkDown))
            DetailRow(label: "上行总计", value: "—")   // Agent 需额外提供累计数据
            DetailRow(label: "下行总计", value: "—")
        }
    }

    // MARK: - 运行时长

    private var uptimeDetail: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(formatUptime(systemInfo.uptime))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(GravityColors.textPrimary)
                    Text("持续运行")
                        .font(.caption)
                        .foregroundColor(GravityColors.textSecondary)
                }
                Spacer()
            }
        }
    }

    // MARK: - 辅助

    private var cpuColor: Color {
        if systemInfo.cpu >= 95 { return GravityColors.error }
        if systemInfo.cpu >= 80 { return GravityColors.warning }
        return GravityColors.success
    }

    private var memoryColor: Color {
        let pct = systemInfo.memoryPercent
        if pct >= 95 { return GravityColors.error }
        if pct >= 80 { return GravityColors.warning }
        return GravityColors.success
    }

    private var diskColor: Color {
        let pct = systemInfo.diskPercent
        if pct >= 90 { return GravityColors.error }
        if pct >= 75 { return GravityColors.warning }
        return GravityColors.success
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824.0
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        let mb = Double(bytes) / 1_048_576.0
        return String(format: "%.0f MB", mb)
    }

    private func formatSpeed(_ bytesPerSec: UInt64) -> String {
        let mbps = Double(bytesPerSec) / 131_072.0 // bytes/s → Mbps
        if mbps >= 1 { return String(format: "%.2f Mbps", mbps) }
        let kbps = Double(bytesPerSec) / 128.0
        return String(format: "%.0f Kbps", kbps)
    }

    private func formatUptime(_ seconds: Int64) -> String {
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        if days > 0 {
            return "\(days)天 \(hours)小时 \(minutes)分"
        }
        return "\(hours)小时 \(minutes)分"
    }
}

/// 详情行组件
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(GravityColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(GravityColors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(GravityColors.cardBackground)
        .cornerRadius(8)
    }
}

#Preview {
    StatusCardDetailView(
        title: "CPU", icon: "cpu", color: GravityColors.success,
        systemInfo: .mock()
    )
    .preferredColorScheme(.dark)
}

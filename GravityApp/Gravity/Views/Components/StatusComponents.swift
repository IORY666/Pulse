import SwiftUI

/// 连接状态指示器 — 绿点呼吸/红点常亮/灰点
struct ConnectionStatusBadge: View {
    let state: ConnectionState
    let deviceName: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .scaleEffect(isBreathing ? 1.3 : 1.0)
                .opacity(isBreathing ? 0.5 : 1.0)
                .animation(
                    isBreathing ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default,
                    value: isBreathing
                )

            Text(statusText)
                .font(.caption)
                .foregroundColor(statusColor)

            if !deviceName.isEmpty && state.isConnected {
                Text("·")
                    .foregroundColor(GravityColors.textSecondary)
                Text(deviceName)
                    .font(.caption)
                    .foregroundColor(GravityColors.textSecondary)
            }
        }
    }

    private var statusColor: Color {
        switch state {
        case .connected: return GravityColors.success
        case .connecting, .reconnecting: return GravityColors.warning
        case .disconnected: return GravityColors.textSecondary
        case .error: return GravityColors.error
        }
    }

    private var statusText: String {
        state.displayText
    }

    private var isBreathing: Bool {
        if case .connected = state { return true }
        return false
    }
}

/// 迷你趋势线 — 用于仪表盘卡片底部
struct MiniTrendLine: View {
    let data: [Double]
    var color: Color = GravityColors.brand
    var height: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            if data.count >= 2 {
                Path { path in
                    let stepX = geo.size.width / CGFloat(data.count - 1)
                    let maxVal = data.max() ?? 1
                    let minVal = data.min() ?? 0
                    let range = max(maxVal - minVal, 1)

                    for (i, value) in data.enumerated() {
                        let x = CGFloat(i) * stepX
                        let y = geo.size.height * (1 - CGFloat((value - minVal) / range))
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

                // 渐变填充
                Path { path in
                    let stepX = geo.size.width / CGFloat(data.count - 1)
                    let maxVal = data.max() ?? 1
                    let minVal = data.min() ?? 0
                    let range = max(maxVal - minVal, 1)

                    for (i, value) in data.enumerated() {
                        let x = CGFloat(i) * stepX
                        let y = geo.size.height * (1 - CGFloat((value - minVal) / range))
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.15), color.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(height: height)
    }
}

/// 错误关键词高亮行标记
struct ErrorMarker: View {
    var body: some View {
        Rectangle()
            .fill(GravityColors.error)
            .frame(width: 3)
    }
}

// MARK: - 预览

#Preview {
    VStack(spacing: 20) {
        ConnectionStatusBadge(state: .connected, deviceName: "DELL-XPS")
        ConnectionStatusBadge(state: .connecting, deviceName: "")
        ConnectionStatusBadge(state: .disconnected, deviceName: "")
        ConnectionStatusBadge(state: .error("超时"), deviceName: "")

        MiniTrendLine(
            data: [45, 52, 48, 60, 55, 62, 58, 65, 70, 68],
            color: GravityColors.success
        )
        .frame(width: 120)
    }
    .padding()
    .background(GravityColors.background)
    .preferredColorScheme(.dark)
}

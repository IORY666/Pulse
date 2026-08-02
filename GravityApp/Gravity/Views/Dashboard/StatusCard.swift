import SwiftUI

/// 仪表盘状态卡片组件
struct StatusCard: View {
    let title: String
    let icon: String
    let value: String
    let subtitle: String
    let color: Color
    let trendData: [Double]
    var onClick: (() -> Void)?

    @State private var isPressed = false

    var body: some View {
        Button(action: { onClick?() }) {
            VStack(alignment: .leading, spacing: 8) {
                // 顶部：图标 + 标题
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(color)

                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(GravityColors.textSecondary)

                    Spacer()
                }

                // 中部：主数据
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(GravityColors.textPrimary)

                // 底部：副标题
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(GravityColors.textSecondary)
                    .lineLimit(1)

                // 趋势线
                MiniTrendLine(data: trendData, color: color)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(GravityColors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(GravityColors.border, lineWidth: 0.5)
            )
        }
        .buttonStyle(CardButtonStyle())
    }
}

/// 卡片点击缩放效果
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - 预览

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
        StatusCard(
            title: "CPU",
            icon: "cpu",
            value: "47%",
            subtitle: "温度 58°C",
            color: GravityColors.success,
            trendData: [35, 42, 38, 55, 47, 52, 48, 47]
        )
        StatusCard(
            title: "内存",
            icon: "memorychip",
            value: "6.2G",
            subtitle: "已用 / 16G 总量",
            color: GravityColors.info,
            trendData: [5.8, 6.0, 5.9, 6.1, 6.3, 6.2, 6.4, 6.2]
        )
    }
    .padding()
    .background(GravityColors.background)
    .preferredColorScheme(.dark)
}

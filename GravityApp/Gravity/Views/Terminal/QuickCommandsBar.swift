import SwiftUI

/// 快捷指令栏 — 横滚预设命令按钮
struct QuickCommandsBar: View {
    let commands: [QuickCommand]
    var onSend: (QuickCommand) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(commands) { cmd in
                    QuickCommandButton(command: cmd, onSend: { onSend(cmd) })
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .background(GravityColors.cardBackground)
        .overlay(
            Rectangle()
                .fill(GravityColors.border)
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

/// 单个快捷指令按钮
struct QuickCommandButton: View {
    let command: QuickCommand
    let onSend: () -> Void

    @State private var isFlashing = false

    var body: some View {
        Button(action: {
            isFlashing = true
            onSend()
            // 脉冲闪光效果
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFlashing = false
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: command.icon)
                    .font(.system(size: 11))
                Text(command.title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(command.colorValue())
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            // 脉冲闪光
            .overlay(
                isFlashing
                    ? RoundedRectangle(cornerRadius: 16)
                        .stroke(GravityColors.brand.opacity(0.8), lineWidth: 2)
                        .scaleEffect(1.15)
                        .opacity(isFlashing ? 0 : 1)
                    : nil
            )
            .animation(.easeOut(duration: 0.3), value: isFlashing)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickCommandsBar(commands: QuickCommand.defaults, onSend: { _ in })
        .preferredColorScheme(.dark)
}

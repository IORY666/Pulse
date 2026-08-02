import SwiftUI

/// 终端输入栏 — 底部命令输入 + 发送按钮
struct TerminalInputBar: View {
    @Binding var inputText: String
    var onSend: () -> Void
    var isConnected: Bool
    var isRunning: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            // 输入框
            HStack(spacing: 4) {
                Text("$")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(isConnected ? GravityColors.success : GravityColors.textSecondary)

                TextField("输入命令...", text: $inputText)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(GravityColors.terminalText)
                    .focused($isFocused)
                    .disabled(!isConnected)
                    .onSubmit {
                        if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSend()
                        }
                    }
                    .submitLabel(.send)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(GravityColors.background)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(GravityColors.border, lineWidth: 0.5)
            )

            // 发送按钮
            Button(action: onSend) {
                Image(systemName: isRunning ? "stop.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? GravityColors.textSecondary
                            : GravityColors.brand
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isConnected)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(GravityColors.cardBackground)
        .overlay(
            Rectangle()
                .fill(GravityColors.border)
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

#Preview {
    VStack {
        Spacer()
        TerminalInputBar(
            inputText: .constant("git status"),
            onSend: {},
            isConnected: true,
            isRunning: false
        )
    }
    .preferredColorScheme(.dark)
}

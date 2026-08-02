import SwiftUI

/// 终端输出渲染视图 — ANSI 颜色支持、错误高亮、JSON 折叠、自动滚动
struct TerminalOutputView: View {
    let outputLines: [OutputLine]
    @Binding var autoScroll: Bool
    var fontSize: CGFloat = 13

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    if outputLines.isEmpty {
                        emptyState
                    } else {
                        ForEach(outputLines) { line in
                            OutputLineView(line: line, fontSize: fontSize)
                                .id(line.id)
                        }
                    }
                }
                .padding(8)
            }
            .onChange(of: outputLines.count) { _ in
                if autoScroll, let lastLine = outputLines.last {
                    withAnimation {
                        proxy.scrollTo(lastLine.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                if let lastLine = outputLines.last {
                    proxy.scrollTo(lastLine.id, anchor: .bottom)
                }
            }
            // 用户手动滚动 → 暂停自动滚动
            .simultaneousGesture(
                DragGesture().onChanged { _ in
                    autoScroll = false
                }
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            Image(systemName: "terminal")
                .font(.system(size: 40))
                .foregroundColor(GravityColors.textSecondary.opacity(0.4))
            Text("等待命令...")
                .font(.system(size: 14))
                .foregroundColor(GravityColors.textSecondary)
            Text("在下方输入命令或点击快捷指令开始")
                .font(.system(size: 12))
                .foregroundColor(GravityColors.textSecondary.opacity(0.6))
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 单行输出渲染
struct OutputLineView: View {
    let line: OutputLine
    var fontSize: CGFloat = 13

    @State private var jsonExpanded = false
    @State private var longTextExpanded = false

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            // 错误行左侧标记
            if line.isErrorLine {
                Rectangle()
                    .fill(GravityColors.error)
                    .frame(width: 3)
            }

            VStack(alignment: .leading, spacing: 0) {
                if let attributed = line.attributedText {
                    // 使用 ANSI 解析后的 AttributedString
                    Text(attributed)
                        .font(.system(size: fontSize, design: .monospaced))
                        .textSelection(.enabled)
                } else {
                    // 纯文本渲染
                    Text(line.rawText)
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(line.isStderr ? GravityColors.error : GravityColors.terminalText)
                        .textSelection(.enabled)
                }

                // JSON 折叠按钮
                if line.containsJSON && line.rawText.count > 200 {
                    Button(action: { jsonExpanded.toggle() }) {
                        Text(jsonExpanded ? "收起 JSON ▲" : "展开 JSON ▼")
                            .font(.system(size: 10))
                            .foregroundColor(GravityColors.info)
                    }
                    .padding(.top, 2)

                    if jsonExpanded {
                        Text(tryPrettyJSON(line.rawText))
                            .font(.system(size: fontSize - 1, design: .monospaced))
                            .foregroundColor(GravityColors.terminalText.opacity(0.8))
                            .textSelection(.enabled)
                            .padding(.leading, 12)
                    }
                }
            }
            .padding(.vertical, 1)
            .padding(.leading, line.isErrorLine ? 6 : 0)

            Spacer(minLength: 0)
        }
        // 错误行背景高亮
        .background(
            line.isErrorLine
                ? GravityColors.error.opacity(0.08)
                : Color.clear
        )
        .cornerRadius(2)
    }

    /// 尝试格式化 JSON
    private func tryPrettyJSON(_ raw: String) -> String {
        guard let data = raw.data(using: .utf8) else { return raw }
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            let pretty = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
            return String(data: pretty, encoding: .utf8) ?? raw
        } catch {
            return raw
        }
    }
}

/// 滚动到底部按钮
struct ScrollToBottomButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(GravityColors.textPrimary)
                .padding(8)
                .background(GravityColors.brand.opacity(0.8))
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
}

#Preview {
    let lines = [
        OutputLine(rawText: "\u{001B}[32m✓\u{001B}[0m 构建成功"),
        OutputLine(rawText: "npm WARN deprecated old-package@1.0.0"),
        OutputLine(rawText: "error: 找不到模块 './utils'"),
        OutputLine(rawText: "{\"status\":\"ok\",\"count\":42,\"items\":[1,2,3]}"),
        OutputLine(rawText: "\u{001B}[1m\u{001B}[36m══════════\u{001B}[0m"),
    ]
    TerminalOutputView(outputLines: lines, autoScroll: .constant(true))
        .background(GravityColors.background)
        .preferredColorScheme(.dark)
}

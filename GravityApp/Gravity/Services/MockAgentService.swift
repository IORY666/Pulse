import Foundation
import Combine

/// Mock Agent 服务 — 在无真实 Agent 时模拟连接和交互
/// 用于开发调试和 UI 演示
@MainActor
final class MockAgentService: ObservableObject {

    // MARK: - 发布属性

    @Published var connectionState: ConnectionState = .disconnected
    @Published var deviceName: String = "DELL-XPS (Mock)"
    @Published var systemInfo: SystemInfo = .mock()
    @Published var sessions: [TerminalSession] = []

    /// 终端输出流
    let outputPublisher = PassthroughSubject<(sessionId: String, outputLine: OutputLine), Never>()

    /// 系统信息流
    let sysinfoPublisher = PassthroughSubject<SystemInfo, Never>()

    // MARK: - 内部

    private var sysinfoTimer: AnyCancellable?
    private var outputTimers: [String: AnyCancellable] = [:]

    private let mockCommands: [String: String] = [
        "git status": """
        On branch main
        Your branch is up to date with 'origin/main'.

        nothing to commit, working tree clean
        """,
        "git log --oneline -5": """
        a1b2c3d feat: 添加用户认证模块
        e4f5g6h fix: 修复终端 ANSI 渲染问题
        i7j8k9l refactor: 重构 WebSocket 连接管理
        m0n1o2p chore: 更新依赖版本
        q3r4s5t docs: 更新 README
        """,
        "dir": """
         驱动器 C 中的卷是 Windows
         卷的序列号是 A1B2-C3D4

         C:\\Users\\SwaggyP\\Projects 的目录

        2026/08/02  10:30    <DIR>          .
        2026/08/02  10:30    <DIR>          ..
        2026/08/01  15:22    <DIR>          pulse-miniapp
        2026/07/30  09:15    <DIR>          gravity-agent
        2026/08/02  10:28             1,234 README.md
                       1 个文件          1,234 字节
                       4 个目录  156,789,012,480 可用字节
        """,
        "systeminfo | findstr /B /C:\"OS\" /C:\"System\" /C:\"Memory\"": """
        OS Name:       Microsoft Windows 11 Home China
        OS Version:    10.0.26200 N/A Build 26200
        System Model:  XPS 15 9520
        System Type:   x64-based PC
        Total Physical Memory:     16,384 MB
        Available Physical Memory: 8,192 MB
        """,
    ]

    /// 模拟终端输出的连续内容
    private let mockLongOutput: [String] = [
        "\u{001B}[32m✓\u{001B}[0m 正在安装依赖...",
        "\u{001B}[36m→\u{001B}[0m npm install --legacy-peer-deps",
        "\u{001B}[90mnpm WARN deprecated package@1.0.0: Use new-package instead\u{001B}[0m",
        "\u{001B}[32m✓\u{001B}[0m 依赖安装完成 (3.2s)",
        "",
        "\u{001B}[36m→\u{001B}[0m 运行单元测试...",
        "\u{001B}[33m⚠\u{001B}[0m 1 个测试跳过 (快照未更新)",
        "\u{001B}[32m✓\u{001B}[0m 12/12 测试通过",
        "",
        "\u{001B}[36m→\u{001B}[0m 构建项目中...",
        "\u{001B}[90m[1/3] Compiling TypeScript...\u{001B}[0m",
        "\u{001B}[90m[2/3] Bundling with esbuild...\u{001B}[0m",
        "\u{001B}[90m[3/3] Minifying...\u{001B}[0m",
        "\u{001B}[32m✓\u{001B}[0m 构建完成 (8.7s)",
        "",
        "\u{001B}[1m\u{001B}[32m══════════════════════════════════\u{001B}[0m",
        "\u{001B}[1m\u{001B}[32m  部署完成！✅\u{001B}[0m",
        "\u{001B}[1m\u{001B}[32m══════════════════════════════════\u{001B}[0m",
    ]

    // MARK: - 公共接口

    /// 启动 Mock 连接
    func connect() {
        connectionState = .connecting
        deviceName = "DELL-XPS (Mock)"

        // 模拟 1 秒连接延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.connectionState = .connected
            self.startMockDataStream()
        }
    }

    /// 断开连接
    func disconnect() {
        connectionState = .disconnected
        sysinfoTimer?.cancel()
        outputTimers.values.forEach { $0.cancel() }
        outputTimers.removeAll()
    }

    /// 创建模拟终端会话
    func createSession(name: String = "终端") -> String {
        let session = TerminalSession(name: name)
        sessions.append(session)
        return session.id
    }

    /// 关闭会话
    func closeSession(_ sessionId: String) {
        sessions.removeAll { $0.id == sessionId }
        outputTimers[sessionId]?.cancel()
        outputTimers.removeValue(forKey: sessionId)
    }

    /// 发送命令到模拟会话
    func sendCommand(_ command: String, sessionId: String) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }

        sessions[index].isRunning = true
        sessions[index].lastOutputAt = Date()

        // 回显命令
        let echoLine = OutputLine(
            rawText: "\u{001B}[35m$\u{001B}[0m \(command)",
            isStderr: false
        )
        outputPublisher.send((sessionId: sessionId, outputLine: echoLine))

        // 查找预定义响应
        if let response = mockCommands[command] {
            // 有匹配的响应，逐行输出
            let lines = response.components(separatedBy: "\n")
            for (offset, line) in lines.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(offset + 1)) { [weak self] in
                    guard let self else { return }
                    let outputLine = OutputLine(rawText: line)
                    self.outputPublisher.send((sessionId: sessionId, outputLine: outputLine))
                    if let idx = self.sessions.firstIndex(where: { $0.id == sessionId }) {
                        self.sessions[idx].lastOutputAt = Date()
                    }
                    if offset == lines.count - 1 {
                        self.finishCommand(sessionId: sessionId)
                    }
                }
            }
        } else if command == "\u{0003}" {
            // Ctrl+C
            let outputLine = OutputLine(rawText: "^C", isStderr: false)
            outputPublisher.send((sessionId: sessionId, outputLine: outputLine))
            sessions[index].isRunning = false
            sessions[index].command = nil
        } else if command == "cls" || command == "clear" {
            // 清屏
            let outputLine = OutputLine(rawText: "\u{001B}[2J\u{001B}[H")
            outputPublisher.send((sessionId: sessionId, outputLine: outputLine))
            sessions[index].isRunning = false
            sessions[index].command = nil
        } else {
            // 通用响应
            let genericResponse = generateGenericResponse(for: command)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self else { return }
                let outputLine = OutputLine(rawText: genericResponse)
                self.outputPublisher.send((sessionId: sessionId, outputLine: outputLine))
                self.finishCommand(sessionId: sessionId)
            }
        }
    }

    // MARK: - Mock 数据流

    private func startMockDataStream() {
        // 每 2 秒更新系统信息
        sysinfoTimer = Timer.publish(every: 2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, case .connected = self.connectionState else { return }
                self.systemInfo = self.systemInfo.nextTick()
                self.sysinfoPublisher.send(self.systemInfo)
            }
    }

    private func finishCommand(sessionId: String) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        sessions[index].isRunning = false
        sessions[index].command = nil
        sessions[index].lastOutputAt = Date()
    }

    /// 生成通用命令响应
    private func generateGenericResponse(for command: String) -> String {
        if command.lowercased().contains("npm") || command.lowercased().contains("node") {
            return "v20.11.0\nnpm v10.2.4"
        }
        if command.lowercased().contains("python") {
            return "Python 3.12.1"
        }
        if command.lowercased().contains("whoami") {
            return "swaggyp"
        }
        if command.lowercased().contains("hostname") {
            return "DELL-XPS"
        }
        if command.lowercased().contains("pwd") || command.lowercased().contains("cd") {
            return "C:\\Users\\SwaggyP\\Projects\\gravity-agent"
        }
        if command.lowercased().contains("echo") {
            return command.replacingOccurrences(of: "echo ", with: "", options: .caseInsensitive)
        }
        // 模拟一条 LLM/构建相关输出
        return "\u{001B}[90m[\(command.components(separatedBy: " ").first ?? "cmd")]\u{001B}[0m 执行完成 ✓"
    }
}

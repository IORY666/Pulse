import Foundation
import Combine
import SwiftUI

/// 终端 ViewModel — 多标签页管理、输出缓冲、命令发送、断线重连恢复
@MainActor
final class TerminalViewModel: ObservableObject {

    // MARK: - 发布属性

    /// 所有终端会话
    @Published var sessions: [TerminalSession] = []
    /// 当前选中的会话 ID
    @Published var selectedSessionId: String?
    /// 当前输入的文本
    @Published var inputText: String = ""
    /// 是否自动滚动到底部
    @Published var autoScroll: Bool = true
    /// 连接状态
    @Published var connectionState: ConnectionState = .disconnected
    /// 快捷指令列表
    @Published var quickCommands: [QuickCommand] = QuickCommand.defaults
    /// 等待确认的指令（需要二次确认时）
    @Published var pendingConfirmation: QuickCommand?

    // MARK: - 计算属性

    /// 当前选中的会话
    var selectedSession: TerminalSession? {
        sessions.first { $0.id == selectedSessionId }
    }

    /// 当前会话的输出行
    var currentOutputLines: [OutputLine] {
        selectedSession?.outputLines ?? []
    }

    /// 当前会话的输出行数
    var outputLineCount: Int {
        selectedSession?.outputLines.count ?? 0
    }

    /// 各标签页摘要信息
    var sessionSummaries: [(id: String, name: String, isRunning: Bool, lastOutput: String, lineCount: Int)] {
        sessions.map { session in
            (id: session.id,
             name: session.name,
             isRunning: session.isRunning,
             lastOutput: session.lastOutputDescription,
             lineCount: session.outputLines.count)
        }
    }

    // MARK: - 内部

    private var cancellables = Set<AnyCancellable>()
    private var webSocketService: WebSocketService?
    private var mockService: MockAgentService?

    // MARK: - 公共方法

    /// 绑定 WebSocket 服务
    func bind(webSocket: WebSocketService) {
        self.webSocketService = webSocket
        self.mockService = nil
        cancellables.removeAll()

        webSocket.$connectionState
            .assign(to: \.connectionState, on: self)
            .store(in: &cancellables)

        webSocket.outputPublisher
            .sink { [weak self] sessionId, outputLine in
                self?.appendOutput(sessionId: sessionId, line: outputLine)
            }
            .store(in: &cancellables)

        webSocket.messagePublisher
            .sink { [weak self] msg in
                switch msg.payload {
                case .sessionCreated(let sessionId):
                    self?.addSession(TerminalSession(id: sessionId, name: "终端 #\(self?.sessions.count ?? 0 + 1)", isRunning: true, createdAt: Date()))
                case .sessionClosed(let sessionId):
                    self?.removeSession(sessionId)
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    /// 绑定 Mock 服务
    func bind(mock: MockAgentService) {
        self.mockService = mock
        self.webSocketService = nil
        cancellables.removeAll()

        mock.$connectionState
            .assign(to: \.connectionState, on: self)
            .store(in: &cancellables)

        mock.outputPublisher
            .sink { [weak self] sessionId, outputLine in
                self?.appendOutput(sessionId: sessionId, line: outputLine)
            }
            .store(in: &cancellables)

        // 从 Mock 同步会话列表
        mock.$sessions
            .sink { [weak self] sessions in
                self?.sessions = sessions
                if self?.selectedSessionId == nil, let first = sessions.first {
                    self?.selectedSessionId = first.id
                }
            }
            .store(in: &cancellables)
    }

    /// 创建新标签页
    func createTab(name: String? = nil) {
        let sessionName = name ?? "终端 #\(sessions.count + 1)"
        if let ws = webSocketService {
            let sessionId = ws.createSession(name: sessionName)
            selectedSessionId = sessionId
            // 不手动 addSession — 等 Agent 的 session_created 回调来添加
        } else if let mock = mockService {
            let sessionId = mock.createSession(name: sessionName)
            selectedSessionId = sessionId
            // Mock 的 $sessions publisher 会自动同步
        }
    }

    /// 关闭标签页
    func closeTab(_ sessionId: String) {
        webSocketService?.closeSession(sessionId)
        mockService?.closeSession(sessionId)
        removeSession(sessionId)

        // 切换到相邻标签页
        if selectedSessionId == sessionId {
            if let first = sessions.first {
                selectedSessionId = first.id
            }
        }
    }

    /// 选中标签页
    func selectTab(_ sessionId: String) {
        selectedSessionId = sessionId
    }

    /// 发送命令
    func sendCommand() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        // 如果没有会话，自动创建一个
        if selectedSessionId == nil || sessions.isEmpty {
            createTab(name: "终端 #1")
        }
        guard let sessionId = selectedSessionId else { return }
        inputText = ""

        if let ws = webSocketService {
            ws.sendCommand(text, sessionId: sessionId)
        } else if let mock = mockService {
            mock.sendCommand(text, sessionId: sessionId)
        }

        // 更新会话状态
        if let index = sessions.firstIndex(where: { $0.id == sessionId }) {
            sessions[index].isRunning = true
            sessions[index].command = text
            sessions[index].lastOutputAt = Date()
        }
    }

    /// 发送快捷指令
    func sendQuickCommand(_ command: QuickCommand) {
        if command.requiresConfirmation {
            pendingConfirmation = command
        } else {
            executeQuickCommand(command)
        }
    }

    /// 确认执行待确认的指令
    func confirmPendingCommand() {
        guard let cmd = pendingConfirmation else { return }
        executeQuickCommand(cmd)
        pendingConfirmation = nil
    }

    /// 取消待确认的指令
    func cancelPendingCommand() {
        pendingConfirmation = nil
    }

    /// 刷新快捷指令列表（从持久化存储加载）
    func reloadQuickCommands() {
        let stored = DataStore.shared.loadQuickCommands()
        quickCommands = stored
    }

    // MARK: - 内部方法

    private func executeQuickCommand(_ command: QuickCommand) {
        guard let sessionId = selectedSessionId else { return }
        if let ws = webSocketService {
            ws.sendCommand(command.command, sessionId: sessionId)
        } else if let mock = mockService {
            mock.sendCommand(command.command, sessionId: sessionId)
        }
    }

    private func addSession(_ session: TerminalSession) {
        // 防止重复添加
        guard !sessions.contains(where: { $0.id == session.id }) else { return }
        sessions.append(session)
        if selectedSessionId == nil {
            selectedSessionId = session.id
        }
    }

    private func removeSession(_ sessionId: String) {
        sessions.removeAll { $0.id == sessionId }
    }

    private func appendOutput(sessionId: String, line: OutputLine) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        var outputLine = line

        // 预解析 ANSI
        if ANSIParser.containsANSI(line.rawText) {
            outputLine.attributedText = ANSIParser.parse(line.rawText)
        }

        sessions[index].outputLines.append(outputLine)
        sessions[index].lastOutputAt = Date()

        // 限制缓冲区大小（保留最近 5000 行）
        if sessions[index].outputLines.count > 5000 {
            sessions[index].outputLines.removeFirst(1000)
        }
    }
}

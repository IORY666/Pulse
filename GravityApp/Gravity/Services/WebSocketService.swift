import Foundation
import Combine

/// WebSocket 连接状态
enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int, maxAttempts: Int)
    case error(String)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var displayText: String {
        switch self {
        case .disconnected: return "未连接"
        case .connecting: return "连接中..."
        case .connected: return "已连接"
        case .reconnecting(let n, let max): return "重连中(\(n)/\(max))"
        case .error(let msg): return "错误: \(msg)"
        }
    }
}

/// WebSocket 通信服务
/// 负责与 Windows Agent 的 WebSocket 连接、消息收发、自动重连
@MainActor
final class WebSocketService: ObservableObject {

    // MARK: - 发布属性

    @Published var connectionState: ConnectionState = .disconnected
    @Published var deviceName: String = ""

    /// 接收到的消息流（非输出类消息）
    let messagePublisher = PassthroughSubject<GravityMessage, Never>()

    /// 终端输出流（按会话分发）
    let outputPublisher = PassthroughSubject<(sessionId: String, outputLine: OutputLine), Never>()

    /// 系统信息流
    let sysinfoPublisher = PassthroughSubject<SystemInfo, Never>()

    // MARK: - 配置

    private var host: String = ""
    private var port: Int = 9527
    private var token: String = ""
    private var useTLS: Bool = false

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession!
    private var heartbeatTimer: AnyCancellable?
    private var reconnectTimer: AnyCancellable?
    private var heartbeatSeq: Int = 0

    private let maxReconnectAttempts = 10
    private var reconnectAttempt = 0
    private let initialReconnectDelay: TimeInterval = 1.0
    private let maxReconnectDelay: TimeInterval = 30.0

    /// 是否应该保持连接（手动断开时为 false）
    private var shouldStayConnected = false

    // MARK: - 公共接口

    /// 连接到 Agent
    func connect(host: String, port: Int = 9527, token: String = "", useTLS: Bool = false) {
        self.host = host
        self.port = port
        self.token = token
        self.useTLS = useTLS
        self.shouldStayConnected = true
        self.reconnectAttempt = 0

        performConnect()
    }

    /// 断开连接
    func disconnect() {
        shouldStayConnected = false
        reconnectTimer?.cancel()
        reconnectTimer = nil
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
    }

    /// 发送消息
    func send(_ message: GravityMessage) {
        guard let ws = webSocketTask, case .connected = connectionState else {
            print("[WS] 未连接，无法发送消息")
            return
        }

        do {
            let data = try JSONEncoder().encode(message)
            ws.send(.data(data)) { [weak self] error in
                if let error {
                    Task { @MainActor in
                        print("[WS] 发送失败: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            print("[WS] 消息编码失败: \(error)")
        }
    }

    /// 发送终端命令
    func sendCommand(_ command: String, sessionId: String) {
        // 特殊处理：Ctrl+C
        if command == "\u{0003}" {
            send(GravityMessage(
                type: .signal,
                session: sessionId,
                payload: .signal(name: "SIGINT")
            ))
        } else {
            send(GravityMessage(
                type: .exec,
                session: sessionId,
                payload: .exec(command: command)
            ))
        }
    }

    /// 发送终端输入
    func sendInput(_ text: String, sessionId: String) {
        send(GravityMessage(
            type: .input,
            session: sessionId,
            payload: .input(text: text)
        ))
    }

    /// 创建新终端会话
    func createSession(name: String = "终端") -> String {
        let sessionId = UUID().uuidString
        send(GravityMessage(
            type: .createSession,
            session: sessionId,
            payload: .empty
        ))
        return sessionId
    }

    /// 关闭终端会话
    func closeSession(_ sessionId: String) {
        send(GravityMessage(
            type: .closeSession,
            session: sessionId,
            payload: .empty
        ))
    }

    // MARK: - 连接管理

    private func performConnect() {
        connectionState = .connecting

        let scheme = useTLS ? "wss" : "ws"
        let urlString = "\(scheme)://\(host):\(port)/ws"
        guard let url = URL(string: urlString) else {
            connectionState = .error("无效的 URL")
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        // Bearer Token 认证
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("gravity-ios/1.0", forHTTPHeaderField: "X-Gravity-Client")

        session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        startHeartbeat()
        receiveNext()
    }

    /// 接收消息循环
    private func receiveNext() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let message):
                    // 首次收到消息 → 连接成功
                    if case .connecting = self.connectionState {
                        self.connectionState = .connected
                        self.reconnectAttempt = 0
                    }

                    switch message {
                    case .data(let data):
                        self.handleMessage(data)
                    case .string(let text):
                        if let data = text.data(using: .utf8) {
                            self.handleMessage(data)
                        }
                    @unknown default:
                        break
                    }
                    // 继续监听下一条
                    self.receiveNext()

                case .failure(let error):
                    self.handleDisconnect(error)
                }
            }
        }
    }

    /// 处理收到的消息
    private func handleMessage(_ data: Data) {
        do {
            let msg = try JSONDecoder().decode(GravityMessage.self, from: data)
            switch msg.payload {
            case .output(let text, let isStderr):
                let outputLine = OutputLine(rawText: text, isStderr: isStderr)
                outputPublisher.send((sessionId: msg.session ?? "default", outputLine: outputLine))
            case .sysinfo(let sysinfo):
                sysinfoPublisher.send(sysinfo)
            case .sessionCreated(let sessionId):
                messagePublisher.send(msg)
            case .sessionClosed(let sessionId):
                messagePublisher.send(msg)
            case .notification(let event, let detail):
                messagePublisher.send(msg)
            case .heartbeatAck:
                break // 心跳响应，无需额外处理
            case .error(let code, let message):
                print("[WS] Agent 错误: [\(code)] \(message)")
                messagePublisher.send(msg)
            default:
                messagePublisher.send(msg)
            }
        } catch {
            print("[WS] 消息解码失败: \(error)")
        }
    }

    /// 处理断开连接
    private func handleDisconnect(_ error: Error) {
        let nsError = error as NSError
        if nsError.domain == NSPOSIXErrorDomain && nsError.code == 57 {
            // 正常关闭，不重连
            connectionState = .disconnected
            return
        }

        print("[WS] 连接断开: \(error.localizedDescription)")

        if shouldStayConnected && reconnectAttempt < maxReconnectAttempts {
            attemptReconnect()
        } else {
            connectionState = .error("连接失败，已达最大重试次数")
            shouldStayConnected = false
        }
    }

    /// 指数退避重连
    private func attemptReconnect() {
        reconnectAttempt += 1
        connectionState = .reconnecting(attempt: reconnectAttempt, maxAttempts: maxReconnectAttempts)

        let delay = min(initialReconnectDelay * pow(2.0, Double(reconnectAttempt - 1)), maxReconnectDelay)
        print("[WS] \(delay)秒后第\(reconnectAttempt)次重连...")

        reconnectTimer?.cancel()
        reconnectTimer = Timer.publish(every: delay, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.performConnect()
                }
            }
    }

    /// 心跳（每30秒）
    private func startHeartbeat() {
        heartbeatTimer?.cancel()
        heartbeatTimer = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self, case .connected = self.connectionState else { return }
                    self.heartbeatSeq += 1
                    self.send(GravityMessage(
                        type: .heartbeat,
                        payload: .heartbeat(seq: self.heartbeatSeq)
                    ))
                    // 请求系统信息
                    self.send(GravityMessage(type: .sysinfo, payload: .empty))
                }
            }
    }
}

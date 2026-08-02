import Foundation

/// Gravity 通信协议消息（基于 WebSocket JSON）
struct GravityMessage: Codable, Identifiable {
    let id: String
    let type: MessageType
    let session: String?
    let payload: Payload?
    let ts: Int64?

    init(id: String = UUID().uuidString,
         type: MessageType,
         session: String? = nil,
         payload: Payload? = nil,
         ts: Int64? = nil) {
        self.id = id
        self.type = type
        self.session = session
        self.payload = payload
        self.ts = ts
    }
}

enum MessageType: String, Codable {
    // 客户端 → Agent
    case exec       // 执行命令
    case input      // 向运行中的进程发送输入
    case signal     // 发送信号 (Ctrl+C 等)
    case heartbeat  // 心跳
    case sysinfo    // 请求系统信息
    case createSession = "create_session"
    case closeSession = "close_session"

    // Agent → 客户端
    case output         // 终端输出
    case sysinfoResp    = "sysinfo_resp"
    case error          // 错误
    case heartbeatAck   = "heartbeat_ack"
    case sessionCreated = "session_created"
    case sessionClosed  = "session_closed"
    case notification   // 推送通知事件
}

/// 消息载荷
enum Payload: Codable {
    case exec(command: String)
    case input(text: String)
    case signal(name: String)      // "SIGINT", "SIGTERM"
    case output(text: String, isStderr: Bool)
    case sysinfo(data: SystemInfo)
    case error(code: Int, message: String)
    case sessionCreated(sessionId: String)
    case sessionClosed(sessionId: String)
    case notification(event: String, detail: String)
    case heartbeat(seq: Int)
    case heartbeatAck(seq: Int)
    case empty

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case type
        case command, text, name, isStderr, data, code, message
        case sessionId, event, detail, seq
    }

    private enum PayloadType: String, Codable {
        case exec, input, signal, output, sysinfo, error
        case sessionCreated, sessionClosed, notification
        case heartbeat, heartbeatAck, empty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeStr = try container.decode(String.self, forKey: .type)
        switch typeStr {
        case "exec":
            let cmd = try container.decode(String.self, forKey: .command)
            self = .exec(command: cmd)
        case "input":
            let txt = try container.decode(String.self, forKey: .text)
            self = .input(text: txt)
        case "signal":
            let n = try container.decode(String.self, forKey: .name)
            self = .signal(name: n)
        case "output":
            let txt = try container.decode(String.self, forKey: .text)
            let stderr = try container.decodeIfPresent(Bool.self, forKey: .isStderr) ?? false
            self = .output(text: txt, isStderr: stderr)
        case "sysinfo_resp":
            let d = try container.decode(SystemInfo.self, forKey: .data)
            self = .sysinfo(data: d)
        case "error":
            let code = try container.decode(Int.self, forKey: .code)
            let msg = try container.decode(String.self, forKey: .message)
            self = .error(code: code, message: msg)
        case "session_created":
            let sid = try container.decode(String.self, forKey: .sessionId)
            self = .sessionCreated(sessionId: sid)
        case "session_closed":
            let sid = try container.decode(String.self, forKey: .sessionId)
            self = .sessionClosed(sessionId: sid)
        case "notification":
            let evt = try container.decode(String.self, forKey: .event)
            let det = try container.decode(String.self, forKey: .detail)
            self = .notification(event: evt, detail: det)
        case "heartbeat":
            let seq = try container.decode(Int.self, forKey: .seq)
            self = .heartbeat(seq: seq)
        case "heartbeat_ack":
            let seq = try container.decode(Int.self, forKey: .seq)
            self = .heartbeatAck(seq: seq)
        default:
            self = .empty
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .exec(let command):
            try container.encode("exec", forKey: .type)
            try container.encode(command, forKey: .command)
        case .input(let text):
            try container.encode("input", forKey: .type)
            try container.encode(text, forKey: .text)
        case .signal(let name):
            try container.encode("signal", forKey: .type)
            try container.encode(name, forKey: .name)
        case .output(let text, let isStderr):
            try container.encode("output", forKey: .type)
            try container.encode(text, forKey: .text)
            try container.encode(isStderr, forKey: .isStderr)
        case .sysinfo(let data):
            try container.encode("sysinfo_resp", forKey: .type)
            try container.encode(data, forKey: .data)
        case .error(let code, let message):
            try container.encode("error", forKey: .type)
            try container.encode(code, forKey: .code)
            try container.encode(message, forKey: .message)
        case .sessionCreated(let sessionId):
            try container.encode("session_created", forKey: .type)
            try container.encode(sessionId, forKey: .sessionId)
        case .sessionClosed(let sessionId):
            try container.encode("session_closed", forKey: .type)
            try container.encode(sessionId, forKey: .sessionId)
        case .notification(let event, let detail):
            try container.encode("notification", forKey: .type)
            try container.encode(event, forKey: .event)
            try container.encode(detail, forKey: .detail)
        case .heartbeat(let seq):
            try container.encode("heartbeat", forKey: .type)
            try container.encode(seq, forKey: .seq)
        case .heartbeatAck(let seq):
            try container.encode("heartbeat_ack", forKey: .type)
            try container.encode(seq, forKey: .seq)
        case .empty:
            try container.encode("empty", forKey: .type)
        }
    }
}

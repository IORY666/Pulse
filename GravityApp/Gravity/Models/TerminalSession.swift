import Foundation
import SwiftUI

/// 终端会话（对应 Agent 端一个 PTY 进程）
struct TerminalSession: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var command: String?        // 正在运行的命令
    var isRunning: Bool
    var lastOutputAt: Date?
    var createdAt: Date

    /// 输出行缓存（本地存储，不入协议）
    var outputLines: [OutputLine] = []

    init(id: String = UUID().uuidString,
         name: String = "终端",
         command: String? = nil,
         isRunning: Bool = false,
         lastOutputAt: Date? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.command = command
        self.isRunning = isRunning
        self.lastOutputAt = lastOutputAt
        self.createdAt = createdAt
    }

    /// 上次输出距今的描述
    var lastOutputDescription: String {
        guard let lastOutputAt else { return "无输出" }
        let interval = Int(Date().timeIntervalSince(lastOutputAt))
        if interval < 60 { return "\(interval)秒前" }
        if interval < 3600 { return "\(interval / 60)分钟前" }
        return "\(interval / 3600)小时前"
    }
}

/// 单行终端输出
struct OutputLine: Identifiable, Codable, Equatable {
    let id: String
    let rawText: String
    let isStderr: Bool
    let timestamp: Date

    /// ANSI 解析后的 AttributedString（缓存，不入库）
    var attributedText: AttributedString?

    init(id: String = UUID().uuidString,
         rawText: String,
         isStderr: Bool = false,
         timestamp: Date = Date()) {
        self.id = id
        self.rawText = rawText
        self.isStderr = isStderr
        self.timestamp = timestamp
    }

    /// 是否包含错误关键词
    var isErrorLine: Bool {
        let lowercased = rawText.lowercased()
        let keywords = ["error", "fail", "panic", "fatal", "exception", "errno", "cannot", "拒绝", "错误"]
        return keywords.contains { lowercased.contains($0) }
    }

    /// 是否包含 JSON
    var containsJSON: Bool {
        let trimmed = rawText.trimmingCharacters(in: .whitespaces)
        return (trimmed.hasPrefix("{") && trimmed.hasSuffix("}"))
            || (trimmed.hasPrefix("[") && trimmed.hasSuffix("]"))
    }
}

/// 快捷指令
struct QuickCommand: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var command: String
    var icon: String       // SF Symbol 名称
    var color: String      // 十六进制色值
    var requiresConfirmation: Bool
    var sortOrder: Int

    init(id: String = UUID().uuidString,
         title: String,
         command: String,
         icon: String = "terminal",
         color: String = "#7C3AED",
         requiresConfirmation: Bool = false,
         sortOrder: Int = 0) {
        self.id = id
        self.title = title
        self.command = command
        self.icon = icon
        self.color = color
        self.requiresConfirmation = requiresConfirmation
        self.sortOrder = sortOrder
    }

    /// 默认快捷指令集
    static let defaults: [QuickCommand] = [
        QuickCommand(title: "中断任务", command: "\u{0003}", icon: "stop.circle.fill", color: "#F85149", sortOrder: 0),
        QuickCommand(title: "Git 状态", command: "git status", icon: "arrow.triangle.branch", color: "#3FB950", sortOrder: 1),
        QuickCommand(title: "Git 日志", command: "git log --oneline -5", icon: "clock.arrow.circlepath", color: "#8B949E", sortOrder: 2),
        QuickCommand(title: "进程列表", command: "tasklist | head -10", icon: "list.bullet.rectangle", color: "#58A6FF", sortOrder: 3),
        QuickCommand(title: "系统概况", command: "systeminfo | findstr /B /C:\"OS\" /C:\"System\" /C:\"Memory\"", icon: "pc", color: "#D29922", sortOrder: 4),
        QuickCommand(title: "磁盘空间", command: "wmic logicaldisk get size,freespace,caption", icon: "internaldrive", color: "#7C3AED", sortOrder: 5),
    ]

    func colorValue() -> Color {
        Color(hex: color) ?? .purple
    }
}

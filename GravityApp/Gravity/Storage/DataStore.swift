import Foundation
import SwiftData
import SwiftUI

/// SwiftData 持久化存储管理
/// 负责快捷指令、会话历史、设置等数据的本地持久化

// MARK: - 持久化模型

/// 快捷指令持久化模型
@Model
final class QuickCommandModel {
    var id: String
    var title: String
    var command: String
    var icon: String
    var color: String
    var requiresConfirmation: Bool
    var sortOrder: Int

    init(from cmd: QuickCommand) {
        self.id = cmd.id
        self.title = cmd.title
        self.command = cmd.command
        self.icon = cmd.icon
        self.color = cmd.color
        self.requiresConfirmation = cmd.requiresConfirmation
        self.sortOrder = cmd.sortOrder
    }

    func toQuickCommand() -> QuickCommand {
        QuickCommand(
            id: id, title: title, command: command,
            icon: icon, color: color,
            requiresConfirmation: requiresConfirmation,
            sortOrder: sortOrder
        )
    }
}

/// 连接配置持久化模型
@Model
final class ConnectionConfigModel {
    var host: String
    var port: Int
    var token: String
    var deviceName: String
    var lastConnectedAt: Date?

    init(host: String = "", port: Int = 9527, token: String = "", deviceName: String = "") {
        self.host = host
        self.port = port
        self.token = token
        self.deviceName = deviceName
    }
}

// MARK: - 数据仓库

@MainActor
final class DataStore {
    static let shared = DataStore()

    var modelContext: ModelContext?

    private init() {}

    // MARK: - 快捷指令

    func loadQuickCommands() -> [QuickCommand] {
        guard let ctx = modelContext else { return QuickCommand.defaults }
        let descriptor = FetchDescriptor<QuickCommandModel>(sortBy: [SortDescriptor(\.sortOrder)])
        do {
            let models = try ctx.fetch(descriptor)
            if models.isEmpty {
                // 首次启动，写入默认值
                for cmd in QuickCommand.defaults {
                    ctx.insert(QuickCommandModel(from: cmd))
                }
                try ctx.save()
                return QuickCommand.defaults
            }
            return models.map { $0.toQuickCommand() }
        } catch {
            print("[DataStore] 加载快捷指令失败: \(error)")
            return QuickCommand.defaults
        }
    }

    func saveQuickCommands(_ commands: [QuickCommand]) {
        guard let ctx = modelContext else { return }
        // 全量替换：先删后插
        let descriptor = FetchDescriptor<QuickCommandModel>()
        if let existing = try? ctx.fetch(descriptor) {
            for model in existing { ctx.delete(model) }
        }
        for (idx, cmd) in commands.enumerated() {
            var updated = cmd
            updated.sortOrder = idx
            ctx.insert(QuickCommandModel(from: updated))
        }
        try? ctx.save()
    }

    // MARK: - 连接配置

    func loadConnectionConfig() -> ConnectionConfigModel {
        guard let ctx = modelContext else { return ConnectionConfigModel() }
        let descriptor = FetchDescriptor<ConnectionConfigModel>()
        if let config = try? ctx.fetch(descriptor).first {
            return config
        }
        let config = ConnectionConfigModel()
        ctx.insert(config)
        try? ctx.save()
        return config
    }

    func saveConnectionConfig(host: String, port: Int, token: String, deviceName: String) {
        guard let ctx = modelContext else { return }
        let config = loadConnectionConfig()
        config.host = host
        config.port = port
        config.token = token
        config.deviceName = deviceName
        config.lastConnectedAt = Date()
        try? ctx.save()
    }
}

// MARK: - Color 扩展：十六进制解析

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r, g, b: Double
        switch hexSanitized.count {
        case 6:
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
        case 8:
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
        default:
            return nil
        }
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - 设计系统色彩常量

enum GravityColors {
    static let background = Color(hex: "#0D1117")!
    static let cardBackground = Color(hex: "#161B22")!
    static let border = Color(hex: "#30363D")!
    static let textPrimary = Color(hex: "#E6EDF3")!
    static let textSecondary = Color(hex: "#8B949E")!
    static let terminalText = Color(hex: "#C9D1D9")!
    static let terminalCursor = Color(hex: "#58A6FF")!
    static let success = Color(hex: "#3FB950")!
    static let warning = Color(hex: "#D29922")!
    static let error = Color(hex: "#F85149")!
    static let brand = Color(hex: "#7C3AED")!
    static let info = Color(hex: "#58A6FF")!
}

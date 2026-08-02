import Foundation
import Combine
import SwiftUI

/// 设置 ViewModel — 连接配置、通知设置、外观设置
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - 连接设置

    @Published var host: String = ""
    @Published var port: String = "9527"
    @Published var token: String = ""
    @Published var deviceName: String = ""
    @Published var connectionState: ConnectionState = .disconnected

    // MARK: - 通知设置

    @Published var notifyOnErrorKeyword: Bool = true
    @Published var notifyOnTaskComplete: Bool = true
    @Published var notifyOnResourceAlert: Bool = true
    @Published var notifyOnLongIdle: Bool = false
    @Published var notifyOnAgentOffline: Bool = true
    @Published var errorKeywords: String = "error,fail,panic,exception,fatal"
    @Published var idleMinutesThreshold: Int = 10
    @Published var webhookURL: String = ""

    // MARK: - 外观设置

    @Published var terminalFontSize: CGFloat = 13
    @Published var terminalFontName: String = "JetBrains Mono"
    @Published var useSystemMonospacedFont: Bool = true

    // MARK: - 快捷指令

    @Published var quickCommands: [QuickCommand] = []

    // MARK: - 内部

    private var cancellables = Set<AnyCancellable>()

    /// 加载所有设置
    func loadSettings() {
        let config = DataStore.shared.loadConnectionConfig()
        host = config.host
        port = String(config.port)
        token = config.token
        deviceName = config.deviceName

        quickCommands = DataStore.shared.loadQuickCommands()

        // 从 UserDefaults 加载通知和外观设置
        let defaults = UserDefaults.standard
        notifyOnErrorKeyword = defaults.object(forKey: "notify_error_keyword") as? Bool ?? true
        notifyOnTaskComplete = defaults.object(forKey: "notify_task_complete") as? Bool ?? true
        notifyOnResourceAlert = defaults.object(forKey: "notify_resource_alert") as? Bool ?? true
        notifyOnLongIdle = defaults.object(forKey: "notify_long_idle") as? Bool ?? false
        notifyOnAgentOffline = defaults.object(forKey: "notify_agent_offline") as? Bool ?? true
        errorKeywords = defaults.string(forKey: "error_keywords") ?? "error,fail,panic,exception,fatal"
        idleMinutesThreshold = defaults.integer(forKey: "idle_minutes_threshold")
        if idleMinutesThreshold == 0 { idleMinutesThreshold = 10 }
        webhookURL = defaults.string(forKey: "webhook_url") ?? ""

        let savedFontSize = defaults.double(forKey: "terminal_font_size")
        if savedFontSize > 0 { terminalFontSize = savedFontSize }
        terminalFontName = defaults.string(forKey: "terminal_font_name") ?? "JetBrains Mono"
        useSystemMonospacedFont = defaults.object(forKey: "use_system_monospaced") as? Bool ?? true
    }

    /// 保存连接配置
    func saveConnection() {
        guard let portInt = Int(port) else { return }
        DataStore.shared.saveConnectionConfig(
            host: host, port: portInt, token: token, deviceName: deviceName
        )
    }

    /// 保存通知设置
    func saveNotificationSettings() {
        let defaults = UserDefaults.standard
        defaults.set(notifyOnErrorKeyword, forKey: "notify_error_keyword")
        defaults.set(notifyOnTaskComplete, forKey: "notify_task_complete")
        defaults.set(notifyOnResourceAlert, forKey: "notify_resource_alert")
        defaults.set(notifyOnLongIdle, forKey: "notify_long_idle")
        defaults.set(notifyOnAgentOffline, forKey: "notify_agent_offline")
        defaults.set(errorKeywords, forKey: "error_keywords")
        defaults.set(idleMinutesThreshold, forKey: "idle_minutes_threshold")
        defaults.set(webhookURL, forKey: "webhook_url")
    }

    /// 保存外观设置
    func saveAppearanceSettings() {
        let defaults = UserDefaults.standard
        defaults.set(terminalFontSize, forKey: "terminal_font_size")
        defaults.set(terminalFontName, forKey: "terminal_font_name")
        defaults.set(useSystemMonospacedFont, forKey: "use_system_monospaced")
    }

    /// 保存快捷指令
    func saveQuickCommands() {
        DataStore.shared.saveQuickCommands(quickCommands)
    }

    /// 绑定连接状态
    func bindConnectionState(from service: AnyPublisher<ConnectionState, Never>) {
        service
            .assign(to: \.connectionState, on: self)
            .store(in: &cancellables)
    }
}

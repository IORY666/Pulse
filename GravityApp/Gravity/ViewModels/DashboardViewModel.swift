import Foundation
import Combine
import SwiftUI

/// 仪表盘 ViewModel — 管理系统信息展示、趋势数据、异常检测
@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: - 发布属性

    /// 当前系统信息
    @Published var systemInfo: SystemInfo = .mock()
    /// 连接状态
    @Published var connectionState: ConnectionState = .disconnected
    @Published var deviceName: String = ""
    /// 活跃终端会话
    @Published var activeSessions: [TerminalSession] = []
    /// 最近 5 分钟 CPU 趋势（约 150 个数据点）
    @Published var cpuHistory: [Double] = []
    /// 最近 5 分钟内存趋势
    @Published var memoryHistory: [Double] = []
    /// 最近 5 分钟网络趋势
    @Published var networkHistory: [Double] = []

    // MARK: - 计算属性

    /// CPU 颜色
    var cpuColor: Color {
        if systemInfo.cpu >= 95 { return GravityColors.error }
        if systemInfo.cpu >= 80 { return GravityColors.warning }
        return GravityColors.success
    }

    /// 内存颜色
    var memoryColor: Color {
        let pct = systemInfo.memoryPercent
        if pct >= 95 { return GravityColors.error }
        if pct >= 80 { return GravityColors.warning }
        return GravityColors.success
    }

    /// 磁盘颜色
    var diskColor: Color {
        let pct = systemInfo.diskPercent
        if pct >= 90 { return GravityColors.error }
        if pct >= 75 { return GravityColors.warning }
        return GravityColors.success
    }

    // MARK: - 内部

    private var cancellables = Set<AnyCancellable>()
    private let maxHistoryPoints = 150 // 5分钟 * 60秒 / 2秒

    /// 绑定 WebSocket 服务
    func bind(webSocket: WebSocketService) {
        cancellables.removeAll()

        webSocket.$connectionState
            .assign(to: \.connectionState, on: self)
            .store(in: &cancellables)

        webSocket.$deviceName
            .assign(to: \.deviceName, on: self)
            .store(in: &cancellables)

        webSocket.sysinfoPublisher
            .sink { [weak self] info in
                self?.updateSystemInfo(info)
            }
            .store(in: &cancellables)

        webSocket.messagePublisher
            .sink { [weak self] msg in
                switch msg.payload {
                case .sessionCreated(let sessionId):
                    self?.activeSessions.append(
                        TerminalSession(id: sessionId, name: "终端", isRunning: true, createdAt: Date())
                    )
                case .sessionClosed(let sessionId):
                    self?.activeSessions.removeAll { $0.id == sessionId }
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    /// 绑定 Mock 服务
    func bind(mock: MockAgentService) {
        cancellables.removeAll()

        mock.$connectionState
            .assign(to: \.connectionState, on: self)
            .store(in: &cancellables)

        mock.$deviceName
            .assign(to: \.deviceName, on: self)
            .store(in: &cancellables)

        mock.sysinfoPublisher
            .sink { [weak self] info in
                self?.updateSystemInfo(info)
            }
            .store(in: &cancellables)

        mock.$sessions
            .assign(to: \.activeSessions, on: self)
            .store(in: &cancellables)
    }

    private func updateSystemInfo(_ info: SystemInfo) {
        systemInfo = info

        cpuHistory.append(info.cpu)
        memoryHistory.append(info.memoryPercent)
        let netTotal = Double(info.networkUp + info.networkDown) / 1024.0 / 1024.0 // MB/s
        networkHistory.append(netTotal)

        // 限制历史数据点数
        if cpuHistory.count > maxHistoryPoints {
            cpuHistory.removeFirst(cpuHistory.count - maxHistoryPoints)
        }
        if memoryHistory.count > maxHistoryPoints {
            memoryHistory.removeFirst(memoryHistory.count - maxHistoryPoints)
        }
        if networkHistory.count > maxHistoryPoints {
            networkHistory.removeFirst(networkHistory.count - maxHistoryPoints)
        }
    }
}

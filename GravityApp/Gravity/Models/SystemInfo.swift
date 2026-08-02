import Foundation

/// 系统信息数据模型（Agent 定期推送）
struct SystemInfo: Codable, Equatable {
    /// CPU 使用率 0-100
    var cpu: Double
    /// CPU 温度（摄氏度，可能不可用）
    var cpuTemperature: Double?
    /// 各核心占用率
    var cpuPerCore: [Double]?
    /// 内存已用（字节）
    var memoryUsed: UInt64
    /// 内存总量（字节）
    var memoryTotal: UInt64
    /// 磁盘可用（字节）
    var diskFree: UInt64
    /// 磁盘总量（字节）
    var diskTotal: UInt64
    /// 进程数
    var processCount: Int
    /// CPU 占用 TOP3 进程
    var topProcesses: [ProcessInfo]
    /// 网络上行速率（字节/秒）
    var networkUp: UInt64
    /// 网络下行速率（字节/秒）
    var networkDown: UInt64
    /// 系统运行时长（秒）
    var uptime: Int64

    // MARK: - 计算属性

    /// 内存使用率 0-100
    var memoryPercent: Double {
        guard memoryTotal > 0 else { return 0 }
        return Double(memoryUsed) / Double(memoryTotal) * 100
    }

    /// 磁盘使用率 0-100
    var diskPercent: Double {
        guard diskTotal > 0 else { return 0 }
        return Double(diskTotal - diskFree) / Double(diskTotal) * 100
    }

    /// CPU 状态文字
    var cpuStatus: String {
        if cpu >= 95 { return "严重" }
        if cpu >= 80 { return "偏高" }
        if cpu >= 50 { return "正常" }
        return "空闲"
    }

    /// 内存状态文字
    var memoryStatus: String {
        if memoryPercent >= 95 { return "严重" }
        if memoryPercent >= 80 { return "偏高" }
        return "正常"
    }
}

/// 进程信息
struct ProcessInfo: Codable, Equatable, Identifiable {
    var id: String { name }
    var name: String
    var pid: Int32
    var cpuPercent: Double
    var memoryMB: Double
}

// MARK: - Mock 数据

extension SystemInfo {
    static func mock() -> SystemInfo {
        SystemInfo(
            cpu: Double.random(in: 15...65),
            cpuTemperature: Double.random(in: 45...75),
            cpuPerCore: (0..<8).map { _ in Double.random(in: 10...80) },
            memoryUsed: UInt64.random(in: 4_000_000_000...12_000_000_000),
            memoryTotal: 16_000_000_000,
            diskFree: UInt64.random(in: 100_000_000_000...200_000_000_000),
            diskTotal: 512_000_000_000,
            processCount: Int.random(in: 70...120),
            topProcesses: [
                ProcessInfo(name: "claude-code.exe", pid: 12345, cpuPercent: 35.2, memoryMB: 890),
                ProcessInfo(name: "node.exe", pid: 6789, cpuPercent: 18.7, memoryMB: 420),
                ProcessInfo(name: "WindowsTerminal.exe", pid: 2345, cpuPercent: 5.3, memoryMB: 150),
            ],
            networkUp: UInt64.random(in: 10_000...500_000),
            networkDown: UInt64.random(in: 50_000...2_000_000),
            uptime: Int64.random(in: 100_000...300_000)
        )
    }

    /// 在上一次数据基础上微调，模拟连续变化
    func nextTick() -> SystemInfo {
        let jitter = { (val: Double, range: ClosedRange<Double>) -> Double in
            let delta = Double.random(in: -5...5)
            return min(max(val + delta, range.lowerBound), range.upperBound)
        }
        return SystemInfo(
            cpu: jitter(cpu, 5...90),
            cpuTemperature: cpuTemperature.map { jitter($0, 40...85) },
            cpuPerCore: cpuPerCore?.map { jitter($0, 5...95) },
            memoryUsed: max(0, UInt64(Double(memoryUsed) + Double.random(in: -100_000_000...100_000_000))),
            memoryTotal: memoryTotal,
            diskFree: max(0, UInt64(Double(diskFree) + Double.random(in: -50_000_000...0))),
            diskTotal: diskTotal,
            processCount: max(0, processCount + Int.random(in: -2...2)),
            topProcesses: topProcesses,
            networkUp: UInt64(max(0, Double(networkUp) + Double.random(in: -50_000...50_000))),
            networkDown: UInt64(max(0, Double(networkDown) + Double.random(in: -100_000...100_000))),
            uptime: uptime + 2
        )
    }
}

import Foundation
import SwiftData

/// 习惯数据模型 - 核心实体
@Model
final class Habit {
    /// 习惯名称
    var name: String = ""
    /// SF Symbol图标名称
    var iconName: String = "star.fill"
    /// 颜色（存储为十六进制字符串）
    var colorHex: String = "#4A90D9"
    /// 频率类型：daily(每天) / weekly(每周特定几天)
    var frequencyType: String = "daily"
    /// 每周哪几天需要打卡（仅 weekly 模式使用，存储 weekday 索引 1=周日...7=周六）
    var activeWeekdays: [Int] = []
    /// 每日提醒时间（可选，nil 表示不提醒）
    var reminderTime: Date?
    /// 创建时间
    var createdAt: Date = Date()
    /// 排序权重（用于自定义排序）
    var sortOrder: Int = 0
    /// 是否已归档
    var isArchived: Bool = false
    /// 目标次数（每天/每周需要完成几次）
    var targetCount: Int = 1

    /// 关联的打卡记录
    @Relationship(deleteRule: .cascade) var records: [HabitRecord] = []

    /// 今天的打卡记录（计算属性，不入库）
    @Transient
    var todayRecord: HabitRecord? {
        records.first { Calendar.current.isDateInToday($0.date) }
    }

    /// 今天是否已完成
    @Transient
    var isCompletedToday: Bool {
        todayRecord?.isCompleted ?? false
    }

    /// 连续打卡天数
    @Transient
    var currentStreak: Int {
        calculateStreak()
    }

    /// 最长连续天数
    @Transient
    var longestStreak: Int {
        calculateLongestStreak()
    }

    /// 今日完成次数
    @Transient
    var todayCompletedCount: Int {
        guard let record = todayRecord else { return 0 }
        return record.isCompleted ? record.count : 0
    }

    init(
        name: String = "",
        iconName: String = "star.fill",
        colorHex: String = "#4A90D9",
        frequencyType: String = "daily",
        activeWeekdays: [Int] = [],
        reminderTime: Date? = nil,
        targetCount: Int = 1
    ) {
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.frequencyType = frequencyType
        self.activeWeekdays = activeWeekdays
        self.reminderTime = reminderTime
        self.targetCount = targetCount
        self.createdAt = Date()
    }

    /// 判断某一天是否需要打卡
    func isActive(on date: Date) -> Bool {
        let calendar = Calendar.current
        switch frequencyType {
        case "daily":
            return true
        case "weekly":
            let weekday = calendar.component(.weekday, from: date)
            return activeWeekdays.contains(weekday)
        default:
            return true
        }
    }

    /// 计算当前连续打卡天数
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        let completedRecords = records.filter { $0.isCompleted }
        let completedDates = Set(completedRecords.map { calendar.startOfDay(for: $0.date) })
        let today = calendar.startOfDay(for: Date())

        // 检查今天是否完成
        guard completedDates.contains(today) else {
            // 检查昨天是否完成（今天未完成但昨天完成了，算昨天的连续）
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if completedDates.contains(yesterday) {
                var streak = 1
                var checkDate = calendar.date(byAdding: .day, value: -2, to: today)!
                while completedDates.contains(checkDate) {
                    streak += 1
                    guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prev
                }
                return streak
            }
            return 0
        }

        // 从今天往前数
        var streak = 1
        var checkDate = calendar.date(byAdding: .day, value: -1, to: today)!
        while completedDates.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    /// 计算历史最长连续打卡天数
    private func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        let completedRecords = records.filter { $0.isCompleted }
        guard !completedRecords.isEmpty else { return 0 }

        let sortedDates = Array(Set(completedRecords.map { calendar.startOfDay(for: $0.date) })).sorted()
        var maxStreak = 1
        var currentRun = 1

        for i in 1..<sortedDates.count {
            let prev = sortedDates[i - 1]
            let curr = sortedDates[i]
            if let diff = calendar.dateComponents([.day], from: prev, to: curr).day, diff == 1 {
                currentRun += 1
                maxStreak = max(maxStreak, currentRun)
            } else {
                currentRun = 1
            }
        }
        return maxStreak
    }

    /// 获取最近N天的完成率
    func completionRate(days: Int) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var activeDays = 0
        var completedDays = 0

        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            guard isActive(on: date) else { continue }
            activeDays += 1
            if let record = records.first(where: { calendar.isDate($0.date, inSameDayAs: date) }), record.isCompleted {
                completedDays += 1
            }
        }

        return activeDays > 0 ? Double(completedDays) / Double(activeDays) : 0
    }

    /// 获取指定日期的打卡记录
    func record(for date: Date) -> HabitRecord? {
        let calendar = Calendar.current
        return records.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
}

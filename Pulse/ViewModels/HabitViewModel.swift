import Foundation
import SwiftData
import SwiftUI
import UserNotifications

/// 习惯管理的主业务逻辑层
@MainActor
@Observable
final class HabitViewModel {
    /// 所有习惯（未归档）
    var habits: [Habit] = []
    /// 已归档习惯
    var archivedHabits: [Habit] = []
    /// 是否正在加载
    var isLoading = false

    /// 模型上下文（用于SwiftData操作）
    private var modelContext: ModelContext?

    /// 通知中心
    private let notificationCenter = UNUserNotificationCenter.current()

    /// 当前筛选模式
    var filterMode: FilterMode = .all

    enum FilterMode: String, CaseIterable {
        case all = "全部"
        case today = "今日待办"
        case completed = "已完成"

        var iconName: String {
            switch self {
            case .all: return "list.bullet"
            case .today: return "calendar.badge.checkmark"
            case .completed: return "checkmark.circle.fill"
            }
        }
    }

    /// 初始化上下文
    func configure(with context: ModelContext) {
        self.modelContext = context
        fetchHabits()
    }

    // MARK: - 数据获取

    /// 获取所有习惯
    func fetchHabits() {
        guard let context = modelContext else { return }

        let allHabitsDescriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )

        do {
            let all = try context.fetch(allHabitsDescriptor)
            habits = all.filter { !$0.isArchived }
            archivedHabits = all.filter { $0.isArchived }
        } catch {
            print("获取习惯数据失败: \(error)")
        }
    }

    /// 根据筛选模式返回习惯列表
    var filteredHabits: [Habit] {
        switch filterMode {
        case .all:
            return habits
        case .today:
            return habits.filter { $0.isActive(on: Date()) }
        case .completed:
            return habits.filter { $0.isCompletedToday }
        }
    }

    /// 今日需要打卡的习惯数量
    var todayActiveCount: Int {
        habits.filter { $0.isActive(on: Date()) }.count
    }

    /// 今日已完成习惯数量
    var todayCompletedCount: Int {
        habits.filter { $0.isActive(on: Date()) && $0.isCompletedToday }.count
    }

    /// 今日完成率（百分比文本）
    var todayCompletionText: String {
        let active = todayActiveCount
        guard active > 0 else { return "--" }
        let completed = todayCompletedCount
        return "\(Int(Double(completed) / Double(active) * 100))%"
    }

    /// 今日完成率（0-1范围）
    var todayCompletionRate: Double {
        let active = todayActiveCount
        guard active > 0 else { return 0 }
        return Double(todayCompletedCount) / Double(active)
    }

    // MARK: - CRUD操作

    /// 添加新习惯
    func addHabit(_ habit: Habit) {
        guard let context = modelContext else { return }
        context.insert(habit)
        saveContext()
        fetchHabits()
        scheduleReminder(for: habit)
    }

    /// 更新习惯
    func updateHabit(_ habit: Habit) {
        saveContext()
        fetchHabits()
        // 重新调度提醒
        removeReminder(for: habit)
        scheduleReminder(for: habit)
    }

    /// 删除习惯
    func deleteHabit(_ habit: Habit) {
        guard let context = modelContext else { return }
        removeReminder(for: habit)
        context.delete(habit)
        saveContext()
        fetchHabits()
    }

    /// 归档习惯
    func archiveHabit(_ habit: Habit) {
        habit.isArchived = true
        saveContext()
        fetchHabits()
    }

    /// 恢复归档习惯
    func unarchiveHabit(_ habit: Habit) {
        habit.isArchived = false
        saveContext()
        fetchHabits()
    }

    // MARK: - 打卡操作

    /// 打卡/取消打卡今天
    func toggleToday(for habit: Habit) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let record = habit.record(for: today) {
            if record.isCompleted {
                record.unmark()
            } else {
                record.markCompleted()
                // 触觉反馈由视图层处理
            }
        } else {
            // 创建新记录
            let record = HabitRecord(date: today, isCompleted: true, count: 1, completedAt: Date(), note: "")
            record.habit = habit
            habit.records.append(record)
        }

        saveContext()
        fetchHabits()
    }

    /// 快速打卡（直接标记完成）
    func quickComplete(_ habit: Habit) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let record = habit.record(for: today) {
            if !record.isCompleted {
                record.markCompleted()
            }
        } else {
            let record = HabitRecord(date: today, isCompleted: true, count: 1, completedAt: Date(), note: "")
            record.habit = habit
            habit.records.append(record)
        }

        saveContext()
        fetchHabits()
    }

    /// 给习惯添加备注
    func addNote(_ note: String, to habit: Habit, date: Date = Date()) {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)

        if let record = habit.record(for: targetDate) {
            record.note = note
        } else {
            let record = HabitRecord(date: targetDate, isCompleted: false, count: 0, note: note)
            record.habit = habit
            habit.records.append(record)
        }

        saveContext()
        fetchHabits()
    }

    /// 获取今天的打卡记录
    func todayRecord(for habit: Habit) -> HabitRecord? {
        return habit.record(for: Date())
    }

    // MARK: - 通知管理

    /// 请求通知权限
    func requestNotificationPermission() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// 调度打卡提醒
    private func scheduleReminder(for habit: Habit) {
        guard let reminderTime = habit.reminderTime else { return }

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)

        let content = UNMutableNotificationContent()
        content.title = "⏰ 该打卡了！"
        content.body = "别忘了「\(habit.name)」哦，坚持就是胜利 💪"
        content.sound = .default
        content.badge = 1

        switch habit.frequencyType {
        case "daily":
            // 每天提醒
            let trigger = UNCalendarNotificationTrigger(dateMatching: timeComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "habit-\(habit.persistentModelID)-daily",
                content: content,
                trigger: trigger
            )
            notificationCenter.add(request)

        case "weekly":
            // 每周特定几天提醒
            for weekday in habit.activeWeekdays {
                var components = timeComponents
                components.weekday = weekday
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "habit-\(habit.persistentModelID)-weekday-\(weekday)",
                    content: content,
                    trigger: trigger
                )
                notificationCenter.add(request)
            }

        default:
            break
        }
    }

    /// 移除习惯的提醒
    private func removeReminder(for habit: Habit) {
        var identifiers: [String] = []
        identifiers.append("habit-\(habit.persistentModelID)-daily")
        for weekday in 1...7 {
            identifiers.append("habit-\(habit.persistentModelID)-weekday-\(weekday)")
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - 数据导出

    /// 导出习惯数据为CSV字符串
    func exportCSV() -> String {
        var csv = "习惯名称,日期,是否完成,完成次数,备注\n"

        for habit in habits {
            let sortedRecords = habit.records.sorted { $0.date > $1.date }
            for record in sortedRecords {
                let dateStr = record.date.formatted(date: .numeric, time: .omitted)
                let completed = record.isCompleted ? "是" : "否"
                let escapedNote = record.note.replacingOccurrences(of: "\"", with: "\"\"")
                csv += "\"\(habit.name)\",\(dateStr),\(completed),\(record.count),\"\(escapedNote)\"\n"
            }
        }

        return csv
    }

    // MARK: - 私有辅助

    /// 保存上下文
    private func saveContext() {
        guard let context = modelContext else { return }
        do {
            try context.save()
        } catch {
            print("保存数据失败: \(error)")
        }
    }
}

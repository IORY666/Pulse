import Foundation
import SwiftData

/// 每日打卡记录模型
@Model
final class HabitRecord {
    /// 打卡日期
    var date: Date = Date()
    /// 是否已完成打卡
    var isCompleted: Bool = false
    /// 完成次数（支持每日多次打卡的场景）
    var count: Int = 0
    /// 完成时间戳
    var completedAt: Date?
    /// 备注
    var note: String = ""

    /// 反向关联到习惯
    var habit: Habit?

    init(
        date: Date = Date(),
        isCompleted: Bool = false,
        count: Int = 0,
        completedAt: Date? = nil,
        note: String = "",
        habit: Habit? = nil
    ) {
        self.date = date
        self.isCompleted = isCompleted
        self.count = count
        self.completedAt = completedAt
        self.note = note
        self.habit = habit
    }

    /// 标记为完成
    func markCompleted() {
        self.isCompleted = true
        self.count += 1
        self.completedAt = Date()
    }

    /// 取消打卡
    func unmark() {
        self.isCompleted = false
        self.count = max(0, count - 1)
        self.completedAt = nil
    }
}

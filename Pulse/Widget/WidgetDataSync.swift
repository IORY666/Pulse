import Foundation
import SwiftData

/// Widget数据同步器 — 将主App数据写入共享UserDefaults供Widget读取
/// 在主App的合适位置（如ContentView.onAppear或scenePhase变化时）调用 sync()
@MainActor
struct WidgetDataSync {
    /// 从SwiftData加载习惯数据并同步到Widget共享容器
    static func sync(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )

        guard let habits = try? modelContext.fetch(descriptor) else { return }

        let widgetHabits: [WidgetHabit] = habits.map { habit in
            WidgetHabit(
                id: habit.persistentModelID.description,
                name: habit.name,
                iconName: habit.iconName,
                colorHex: habit.colorHex,
                currentStreak: habit.currentStreak,
                isCompletedToday: habit.isCompletedToday
            )
        }

        // 写入App Group共享UserDefaults
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.pulse.habittracker") else {
            print("⚠️ 无法访问App Group共享容器，请检查 entitlements 配置")
            return
        }

        if let data = try? JSONEncoder().encode(widgetHabits) {
            sharedDefaults.set(data, forKey: "widget_habits")
            sharedDefaults.synchronize()
        }
    }
}

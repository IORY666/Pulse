import WidgetKit
import SwiftUI
import SwiftData

/// Pulse小组件入口 — 支持小号和中号Widget
@main
struct PulseWidget: Widget {
    let kind: String = "PulseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PulseWidgetProvider()) { entry in
            PulseWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("今日打卡")
        .description("快速查看今天的习惯打卡进度")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget时间线提供者

struct PulseWidgetProvider: TimelineProvider {
    /// 占位数据
    func placeholder(in context: Context) -> PulseWidgetEntry {
        PulseWidgetEntry(
            date: Date(),
            habits: placeholderHabits,
            completedCount: 2,
            totalCount: 4,
            topStreak: 7
        )
    }

    /// 快照数据
    func getSnapshot(in context: Context, completion: @escaping (PulseWidgetEntry) -> Void) {
        let entry = loadCurrentEntry()
        completion(entry)
    }

    /// 时间线
    func getTimeline(in context: Context, completion: @escaping (Timeline<PulseWidgetEntry>) -> Void) {
        let entry = loadCurrentEntry()
        // 每15分钟刷新一次（WidgetKit会自动优化刷新频率）
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    /// 从SwiftData加载当前数据
    private func loadCurrentEntry() -> PulseWidgetEntry {
        let habits = loadHabitsFromStore()
        let todayHabits = habits.filter { $0.isActive(on: Date()) }
        let completed = todayHabits.filter { $0.isCompletedToday }.count
        let topStreak = habits.map { $0.currentStreak }.max() ?? 0

        return PulseWidgetEntry(
            date: Date(),
            habits: todayHabits,
            completedCount: completed,
            totalCount: todayHabits.count,
            topStreak: topStreak
        )
    }

    /// 从App Group共享容器读取数据
    private func loadHabitsFromStore() -> [WidgetHabit] {
        // Widget Extension需要App Group共享数据
        // 这里使用UserDefaults共享作为轻量方案
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.pulse.habittracker"),
              let data = sharedDefaults.data(forKey: "widget_habits"),
              let habits = try? JSONDecoder().decode([WidgetHabit].self, from: data) else {
            return []
        }
        return habits
    }

    /// 占位数据
    private var placeholderHabits: [WidgetHabit] {
        [
            WidgetHabit(name: "晨跑", iconName: "figure.run", colorHex: "#34C759", currentStreak: 7, isCompletedToday: true),
            WidgetHabit(name: "阅读", iconName: "book.fill", colorHex: "#4A90D9", currentStreak: 5, isCompletedToday: true),
            WidgetHabit(name: "冥想", iconName: "brain.head.profile", colorHex: "#AF52DE", currentStreak: 3, isCompletedToday: false),
            WidgetHabit(name: "喝水", iconName: "drop.fill", colorHex: "#5AC8FA", currentStreak: 12, isCompletedToday: false),
        ]
    }
}

// MARK: - Widget数据模型（可编码，用于App Group共享）

struct WidgetHabit: Codable, Identifiable {
    let id: String
    let name: String
    let iconName: String
    let colorHex: String
    let currentStreak: Int
    let isCompletedToday: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        iconName: String,
        colorHex: String,
        currentStreak: Int,
        isCompletedToday: Bool
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.currentStreak = currentStreak
        self.isCompletedToday = isCompletedToday
    }
}

// MARK: - Widget条目

struct PulseWidgetEntry: TimelineEntry {
    let date: Date
    let habits: [WidgetHabit]
    let completedCount: Int
    let totalCount: Int
    let topStreak: Int
}

// MARK: - Widget视图

struct PulseWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: PulseWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - 小号Widget

struct SmallWidgetView: View {
    let entry: PulseWidgetEntry
    private let gradientColors: [Color] = [.blue, .green]

    var body: some View {
        VStack(spacing: 4) {
            // 进度环
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 6)
                    .frame(width: 56, height: 56)

                let rate = entry.totalCount > 0
                    ? Double(entry.completedCount) / Double(entry.totalCount)
                    : 0

                Circle()
                    .trim(from: 0, to: rate)
                    .stroke(
                        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(entry.completedCount)/\(entry.totalCount)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text("完成")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }

            // 火焰连击
            if entry.topStreak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                    Text("\(entry.topStreak)天")
                        .font(.system(size: 10, weight: .medium))
                }
            }

            Text("Pulse")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - 中号Widget

struct MediumWidgetView: View {
    let entry: PulseWidgetEntry

    var body: some View {
        VStack(spacing: 10) {
            // 头部
            HStack {
                Text("今日打卡")
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                HStack(spacing: 4) {
                    Text("\(entry.completedCount)/\(entry.totalCount)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text("完成")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            // 习惯列表（最多显示4个）
            if entry.habits.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("打开App添加习惯")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ForEach(entry.habits.prefix(4)) { habit in
                    HStack(spacing: 8) {
                        Image(systemName: habit.iconName)
                            .font(.system(size: 12))
                            .foregroundStyle(habit.isCompletedToday ? .green : Color(hex: habit.colorHex) ?? .blue)

                        Text(habit.name)
                            .font(.system(size: 12))
                            .foregroundStyle(habit.isCompletedToday ? .secondary : .primary)
                            .lineLimit(1)

                        Spacer()

                        if habit.isCompletedToday {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.green)
                        } else {
                            Circle()
                                .stroke(.secondary.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 14, height: 14)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 预览

#Preview(as: .systemSmall) {
    PulseWidget()
} timeline: {
    PulseWidgetEntry(
        date: Date(),
        habits: [
            WidgetHabit(name: "晨跑", iconName: "figure.run", colorHex: "#34C759", currentStreak: 7, isCompletedToday: true),
            WidgetHabit(name: "阅读", iconName: "book.fill", colorHex: "#4A90D9", currentStreak: 5, isCompletedToday: false),
        ],
        completedCount: 1,
        totalCount: 2,
        topStreak: 7
    )
}

#Preview(as: .systemMedium) {
    PulseWidget()
} timeline: {
    PulseWidgetEntry(
        date: Date(),
        habits: [
            WidgetHabit(name: "晨跑", iconName: "figure.run", colorHex: "#34C759", currentStreak: 7, isCompletedToday: true),
            WidgetHabit(name: "阅读", iconName: "book.fill", colorHex: "#4A90D9", currentStreak: 5, isCompletedToday: true),
            WidgetHabit(name: "冥想", iconName: "brain.head.profile", colorHex: "#AF52DE", currentStreak: 3, isCompletedToday: false),
            WidgetHabit(name: "喝水", iconName: "drop.fill", colorHex: "#5AC8FA", currentStreak: 12, isCompletedToday: false),
        ],
        completedCount: 2,
        totalCount: 4,
        topStreak: 12
    )
}

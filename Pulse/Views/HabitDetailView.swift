import SwiftUI
import Charts

/// 习惯详情与统计视图
struct HabitDetailView: View {
    let habit: Habit
    @Environment(HabitViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var selectedTimeRange: TimeRange = .week

    private var habitColor: Color {
        Color(hex: habit.colorHex) ?? .blue
    }

    enum TimeRange: String, CaseIterable {
        case week = "7天"
        case month = "30天"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 头部卡片
                headerCard
                    .padding(.horizontal, 20)

                // 连续打卡
                streakCard
                    .padding(.horizontal, 20)

                // 完成率图表
                chartCard
                    .padding(.horizontal, 20)

                // 最近记录
                recentRecords
                    .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddHabitView(editHabit: habit)
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                viewModel.deleteHabit(habit)
                dismiss()
            }
        } message: {
            Text("删除「\(habit.name)」后，所有打卡记录也将被删除，此操作不可撤销。")
        }
    }

    // MARK: - 头部卡片

    private var headerCard: some View {
        VStack(spacing: 12) {
            // 大图标
            Image(systemName: habit.iconName)
                .font(.system(size: 48))
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(habitColor.gradient)
                )

            Text(habit.name)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 4) {
                Image(systemName: habit.frequencyType == "daily" ? "repeat" : "calendar")
                    .font(.caption)
                Text(habit.frequencyType == "daily" ? "每天" : "每周")
                    .font(.caption)
                Text("·")
                Text("目标 \(habit.targetCount)次")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            // 今日状态
            Button {
                viewModel.toggleToday(for: habit)
            } label: {
                Label(
                    habit.isCompletedToday ? "✓ 今日已完成" : "点击打卡",
                    systemImage: habit.isCompletedToday ? "checkmark.circle.fill" : "circle"
                )
                .font(.headline)
                .foregroundStyle(habit.isCompletedToday ? .green : habitColor)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(habit.isCompletedToday ? Color.green.opacity(0.1) : habitColor.opacity(0.1))
                )
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        )
    }

    // MARK: - 连续打卡卡片

    private var streakCard: some View {
        HStack(spacing: 0) {
            streakItem(
                value: "\(habit.currentStreak)",
                label: "当前连续",
                icon: "flame.fill",
                color: .orange
            )
            Divider().frame(height: 48)
            streakItem(
                value: "\(habit.longestStreak)",
                label: "最长连续",
                icon: "trophy.fill",
                color: .yellow
            )
            Divider().frame(height: 48)
            streakItem(
                value: String(format: "%.0f%%", habit.completionRate(days: 30) * 100),
                label: "30天完成率",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
        )
    }

    private func streakItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 完成率图表

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("完成趋势")
                    .font(.headline)
                Spacer()
                Picker("时间范围", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            // 柱状图
            Chart {
                ForEach(chartData, id: \.date) { item in
                    BarMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("完成", item.completed ? 1 : 0)
                    )
                    .foregroundStyle(
                        item.completed
                            ? habitColor.gradient
                            : Color(.systemGray5).gradient
                    )
                    .cornerRadius(4)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .font(.caption2)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 140)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
        )
    }

    /// 图表数据
    private var chartData: [ChartItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = selectedTimeRange == .week ? 7 : 30

        return (0..<days).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return nil
            }
            let completed = habit.record(for: date)?.isCompleted ?? false
            return ChartItem(date: date, completed: completed)
        }
    }

    struct ChartItem: Identifiable {
        let id = UUID()
        let date: Date
        let completed: Bool
    }

    // MARK: - 最近记录

    private var recentRecords: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近记录")
                .font(.headline)
                .padding(.bottom, 4)

            let sortedRecords = habit.records.sorted { $0.date > $1.date }.prefix(20)

            if sortedRecords.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("还没有打卡记录")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
            } else {
                ForEach(sortedRecords) { record in
                    HStack {
                        Image(systemName: record.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(record.isCompleted ? .green : .secondary.opacity(0.3))

                        Text(record.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(record.isCompleted ? .primary : .secondary)

                        if record.isCompleted, let completedAt = record.completedAt {
                            Spacer()
                            Text(completedAt.formatted(date: .omitted, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if !record.note.isEmpty {
                            Spacer()
                            Text(record.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                    )
                }
            }
        }
    }
}

// MARK: - 预览

#Preview {
    NavigationStack {
        HabitDetailView(habit: Habit(name: "晨跑", iconName: "figure.run", colorHex: "#34C759"))
            .environment(HabitViewModel())
    }
}

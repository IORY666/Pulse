import SwiftUI

/// 今日打卡主视图
struct TodayView: View {
    @Environment(HabitViewModel.self) private var viewModel
    @Environment(StoreManager.self) private var storeManager
    @Binding var showAddHabit: Bool
    @State private var completedHabits: Set<String> = []
    @State private var animateProgress = false

    /// 今天活跃的习惯
    private var todayHabits: [Habit] {
        viewModel.habits.filter { $0.isActive(on: Date()) }
    }

    /// 需要显示付费墙（超过3个习惯且未付费且正在添加第4个）
    private var shouldShowPaywallHint: Bool {
        viewModel.habits.count >= 3 && !storeManager.isProUnlocked
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 头部进度卡
                headerCard
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // 习惯列表
                habitsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                // 空状态
                if todayHabits.isEmpty {
                    emptyState
                        .padding(.top, 60)
                }

                // 付费墙提示
                if shouldShowPaywallHint {
                    proBanner
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("今日打卡")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if viewModel.habits.count >= 3 && !storeManager.isProUnlocked {
                        NotificationCenter.default.post(name: .showPaywall, object: nil)
                    } else {
                        showAddHabit = true
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
        }
        .onAppear {
            viewModel.fetchHabits()
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                animateProgress = true
            }
        }
    }

    // MARK: - 头部进度卡片

    private var headerCard: some View {
        VStack(spacing: 16) {
            // 圆形进度环
            ZStack {
                // 背景环
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 120, height: 120)

                // 进度环
                Circle()
                    .trim(from: 0, to: animateProgress ? viewModel.todayCompletionRate : 0)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: animateProgress)

                // 中心文字
                VStack(spacing: 2) {
                    Text(viewModel.todayCompletionText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text("今日")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 统计行
            HStack(spacing: 32) {
                statItem(value: "\(viewModel.todayCompletedCount)", label: "已完成")
                Divider().frame(height: 32)
                statItem(value: "\(todayHabits.count)", label: "总任务")
                Divider().frame(height: 32)
                statItem(value: "\(todayHabits.map { $0.currentStreak }.max() ?? 0)", label: "最长连续")
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        )
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 习惯列表

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !todayHabits.isEmpty {
                HStack {
                    Text("待完成")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if viewModel.todayCompletionRate >= 1.0 && !todayHabits.isEmpty {
                        Label("全部完成！🎉", systemImage: "sparkles")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
            }

            ForEach(todayHabits) { habit in
                TodayHabitCard(habit: habit)
            }
        }
    }

    // MARK: - 空状态

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.blue.gradient)

            Text("今天还没有习惯")
                .font(.title3)
                .fontWeight(.medium)

            Text("点击右上角 + 添加你的第一个习惯吧")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddHabit = true
            } label: {
                Label("添加习惯", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue.gradient, in: Capsule())
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Pro升级提示

    private var proBanner: some View {
        Button {
            NotificationCenter.default.post(name: .showPaywall, object: nil)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("解锁 Pulse Pro")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("无限习惯 · 精美主题 · iCloud同步")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("¥36")
                    .font(.headline)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.1), in: Capsule())

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.orange.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 今日习惯卡片

struct TodayHabitCard: View {
    let habit: Habit
    @Environment(HabitViewModel.self) private var viewModel
    @State private var isCompleted: Bool = false
    @State private var showCheckmark = false
    @State private var scale: CGFloat = 1.0

    private var habitColor: Color {
        Color(hex: habit.colorHex) ?? .blue
    }

    var body: some View {
        Button {
            completeHabit()
        } label: {
            HStack(spacing: 14) {
                // 图标
                Image(systemName: habit.iconName)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isCompleted ? Color.green.gradient : habitColor.gradient)
                    )

                // 信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(isCompleted ? .secondary : .primary)
                        .strikethrough(isCompleted)

                    HStack(spacing: 6) {
                        if habit.currentStreak > 0 {
                            Label("\(habit.currentStreak)天", systemImage: "flame.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        if let time = habit.reminderTime {
                            Label(time.formatted(date: .omitted, time: .shortened), systemImage: "bell.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // 打卡按钮
                ZStack {
                    Circle()
                        .stroke(isCompleted ? Color.green : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 32, height: 32)

                    if showCheckmark {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(scale)
        .onAppear {
            isCompleted = habit.isCompletedToday
            showCheckmark = isCompleted
        }
    }

    private func completeHabit() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 0.92
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }

        // 切换打卡状态
        viewModel.toggleToday(for: habit)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            isCompleted.toggle()
            showCheckmark = isCompleted
        }
    }
}

// MARK: - 预览

#Preview {
    TodayView(showAddHabit: .constant(false))
        .environment(HabitViewModel())
        .environment(StoreManager.shared)
}

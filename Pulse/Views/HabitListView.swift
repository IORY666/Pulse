import SwiftUI

/// 习惯列表管理视图
struct HabitListView: View {
    @Environment(HabitViewModel.self) private var viewModel
    @Environment(StoreManager.self) private var storeManager
    @Binding var showAddHabit: Bool
    @State private var showDeleteAlert = false
    @State private var habitToDelete: Habit?
    @State private var selectedFilter: HabitViewModel.FilterMode = .all

    var body: some View {
        List {
            // 筛选器
            Section {
                Picker("筛选", selection: $selectedFilter) {
                    ForEach(HabitViewModel.FilterMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.iconName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 4)
                .onChange(of: selectedFilter) { _, newValue in
                    viewModel.filterMode = newValue
                }
            }

            // 活跃习惯
            Section {
                if viewModel.filteredHabits.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text(viewModel.filterMode == .all ? "还没有习惯" : "没有符合条件的习惯")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ForEach(viewModel.filteredHabits) { habit in
                        NavigationLink {
                            HabitDetailView(habit: habit)
                        } label: {
                            HabitRow(habit: habit)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                habitToDelete = habit
                                showDeleteAlert = true
                            } label: {
                                Label("删除", systemImage: "trash")
                            }

                            Button {
                                viewModel.archiveHabit(habit)
                            } label: {
                                Label("归档", systemImage: "archivebox")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                viewModel.quickComplete(habit)
                            } label: {
                                Label("打卡", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                    }
                }
            } header: {
                Text("我的习惯")
            } footer: {
                if !storeManager.isProUnlocked && viewModel.habits.count >= 3 {
                    Text("免费版最多添加3个习惯。升级Pro解锁无限习惯。")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            // 已归档
            if !viewModel.archivedHabits.isEmpty {
                Section("已归档") {
                    ForEach(viewModel.archivedHabits) { habit in
                        HStack {
                            Image(systemName: habit.iconName)
                                .foregroundStyle(.secondary)
                            Text(habit.name)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("恢复") {
                                viewModel.unarchiveHabit(habit)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
        .navigationTitle("习惯")
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
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let habit = habitToDelete {
                    withAnimation {
                        viewModel.deleteHabit(habit)
                    }
                }
            }
        } message: {
            Text("删除「\(habitToDelete?.name ?? "")」后，所有打卡记录也将被删除，此操作不可撤销。")
        }
    }
}

// MARK: - 习惯列表行

struct HabitRow: View {
    let habit: Habit

    private var habitColor: Color {
        Color(hex: habit.colorHex) ?? .blue
    }

    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: habit.iconName)
                .font(.body)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(habitColor.gradient)
                )

            // 信息
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    if habit.currentStreak > 0 {
                        Label("\(habit.currentStreak)天连续", systemImage: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(habit.frequencyType == "daily" ? "每天" : "每周")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 状态
            if habit.isCompletedToday {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary.opacity(0.4))
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 预览

#Preview {
    NavigationStack {
        HabitListView(showAddHabit: .constant(false))
            .environment(HabitViewModel())
            .environment(StoreManager.shared)
    }
}

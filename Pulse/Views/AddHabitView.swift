import SwiftUI

/// 新增/编辑习惯视图
struct AddHabitView: View {
    @Environment(HabitViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    /// 编辑模式下的现有习惯（nil 表示新建）
    var editHabit: Habit? = nil

    // 表单字段
    @State private var name: String = ""
    @State private var selectedIcon: String = "star.fill"
    @State private var selectedColorHex: String = "#4A90D9"
    @State private var frequencyType: String = "daily"
    @State private var activeWeekdays: [Int] = []
    @State private var hasReminder: Bool = false
    @State private var reminderTime: Date = Date()
    @State private var targetCount: Int = 1

    // 常用的SF Symbols图标列表
    private let iconOptions: [[String]] = [
        // 健康与运动
        ["heart.fill", "lungs.fill", "brain.head.profile", "figure.walk", "figure.run", "bicycle"],
        // 学习与工作
        ["book.fill", "pencil", "graduationcap.fill", "briefcase.fill", "laptopcomputer", "lightbulb.fill"],
        // 生活与习惯
        ["drop.fill", "leaf.fill", "sun.max.fill", "moon.stars.fill", "bed.double.fill", "alarm.fill"],
        // 情绪与社交
        ["face.smiling.fill", "hand.thumbsup.fill", "message.fill", "phone.fill", "envelope.fill", "person.2.fill"],
        // 爱好与财务
        ["music.note", "paintpalette.fill", "camera.fill", "gamecontroller.fill", "dollarsign.circle.fill", "cart.fill"],
        // 其他
        ["star.fill", "flame.fill", "sparkles", "crown.fill", "checkmark.seal.fill", "target"],
    ]

    // 图标分类名
    private let iconCategories = ["健康运动", "学习工作", "生活作息", "情绪社交", "爱好财务", "其他"]

    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                Section("习惯信息") {
                    TextField("习惯名称", text: $name)
                        .font(.body)

                    HStack {
                        Text("频率")
                        Spacer()
                        Picker("频率", selection: $frequencyType) {
                            Text("每天").tag("daily")
                            Text("每周特定几天").tag("weekly")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }

                    if frequencyType == "weekly" {
                        WeekdayPicker(selectedDays: $activeWeekdays)
                    }
                }

                // 图标选择
                Section("图标") {
                    ForEach(Array(zip(iconCategories, iconOptions)), id: \.0) { category, icons in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                                ForEach(icons, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.body)
                                            .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                            .frame(width: 40, height: 40)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(
                                                        selectedIcon == icon
                                                            ? Color(hex: selectedColorHex)?.gradient ?? Color.blue.gradient
                                                            : Color(.systemGray6).gradient
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // 颜色选择
                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                        ForEach(HabitColors.options, id: \.hex) { option in
                            Button {
                                selectedColorHex = option.hex
                            } label: {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hex: option.hex) ?? .blue)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            selectedColorHex == option.hex
                                                ? Image(systemName: "checkmark")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                                : nil
                                        )
                                    Text(option.name)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // 提醒设置
                Section {
                    Toggle("每日提醒", isOn: $hasReminder)

                    if hasReminder {
                        DatePicker("提醒时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                    }
                } header: {
                    Text("提醒")
                } footer: {
                    Text("开启后将在设定时间发送通知提醒你打卡")
                }

                // 确认按钮
                Section {
                    Button {
                        saveHabit()
                    } label: {
                        HStack {
                            Spacer()
                            Text(editHabit == nil ? "添加习惯" : "保存修改")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .listRowBackground(
                        name.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color(.systemGray4)
                            : Color(hex: selectedColorHex) ?? .blue
                    )
                    .foregroundStyle(.white)
                }
            }
            .navigationTitle(editHabit == nil ? "新建习惯" : "编辑习惯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadEditData()
            }
        }
    }

    // MARK: - 辅助方法

    private func loadEditData() {
        guard let habit = editHabit else {
            // 默认为明天早上8点
            var components = DateComponents()
            components.hour = 8
            components.minute = 0
            reminderTime = Calendar.current.date(from: components) ?? Date()
            return
        }

        name = habit.name
        selectedIcon = habit.iconName
        selectedColorHex = habit.colorHex
        frequencyType = habit.frequencyType
        activeWeekdays = habit.activeWeekdays
        targetCount = habit.targetCount

        if let time = habit.reminderTime {
            hasReminder = true
            reminderTime = time
        }
    }

    private func saveHabit() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let existing = editHabit {
            // 更新现有习惯
            existing.name = trimmedName
            existing.iconName = selectedIcon
            existing.colorHex = selectedColorHex
            existing.frequencyType = frequencyType
            existing.activeWeekdays = activeWeekdays
            existing.reminderTime = hasReminder ? reminderTime : nil
            existing.targetCount = targetCount
            viewModel.updateHabit(existing)
        } else {
            // 创建新习惯
            let habit = Habit(
                name: trimmedName,
                iconName: selectedIcon,
                colorHex: selectedColorHex,
                frequencyType: frequencyType,
                activeWeekdays: activeWeekdays,
                reminderTime: hasReminder ? reminderTime : nil,
                targetCount: targetCount
            )
            viewModel.addHabit(habit)
        }

        dismiss()
    }
}

// MARK: - 星期选择器

struct WeekdayPicker: View {
    @Binding var selectedDays: [Int]

    private let weekdays: [(Int, String)] = [
        (2, "一"), (3, "二"), (4, "三"), (5, "四"), (6, "五"), (7, "六"), (1, "日"),
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(weekdays, id: \.0) { index, label in
                Button {
                    toggleDay(index)
                } label: {
                    Text(label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(selectedDays.contains(index) ? .white : .primary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(selectedDays.contains(index) ? Color.blue.gradient : Color(.systemGray6))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggleDay(_ day: Int) {
        if let idx = selectedDays.firstIndex(of: day) {
            selectedDays.remove(at: idx)
        } else {
            selectedDays.append(day)
            selectedDays.sort()
        }
    }
}

// MARK: - 预览

#Preview {
    AddHabitView()
        .environment(HabitViewModel())
}

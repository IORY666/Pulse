import SwiftUI
import StoreKit

/// 设置与账户管理视图
struct SettingsView: View {
    @Environment(HabitViewModel.self) private var viewModel
    @Environment(StoreManager.self) private var storeManager
    @Environment(ThemeManager.self) private var themeManager
    @State private var showPaywall = false
    @State private var showExportSheet = false
    @State private var exportedCSV: String?
    @State private var showResetAlert = false
    @State private var notificationEnabled = false

    var body: some View {
        List {
            // Pro状态
            Section {
                HStack {
                    Image(systemName: storeManager.isProUnlocked ? "crown.fill" : "crown")
                        .font(.title2)
                        .foregroundStyle(storeManager.isProUnlocked ? .orange : .secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(storeManager.isProUnlocked ? "Pulse Pro" : "升级到 Pro")
                            .font(.headline)
                        Text(storeManager.isProUnlocked
                             ? "已解锁全部功能 · 感谢支持 🙏"
                             : "无限习惯 · 精美主题 · iCloud同步")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !storeManager.isProUnlocked {
                        Button {
                            showPaywall = true
                        } label: {
                            Text("¥36")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.orange.gradient, in: Capsule())
                        }
                    }
                }
            }

            // 外观设置
            Section("外观") {
                Picker(selection: Binding(
                    get: { themeManager.colorScheme },
                    set: { newValue in
                        themeManager.colorScheme = newValue
                        themeManager.save()
                    }
                )) {
                    ForEach(ThemeManager.ColorSchemeType.allCases, id: \.self) { scheme in
                        Label(scheme.rawValue, systemImage: scheme.iconName).tag(scheme)
                    }
                } label: {
                    Label("主题模式", systemImage: "circle.lefthalf.filled")
                }

                if storeManager.isProUnlocked {
                    NavigationLink {
                        ThemeCustomizationView()
                    } label: {
                        Label("主题强调色", systemImage: "paintpalette.fill")
                    }
                } else {
                    HStack {
                        Label("主题强调色", systemImage: "paintpalette.fill")
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // 通知设置
            Section("通知") {
                Toggle(isOn: $notificationEnabled) {
                    Label("打卡提醒", systemImage: "bell.fill")
                }
                .onChange(of: notificationEnabled) { _, newValue in
                    if newValue {
                        Task {
                            let granted = await viewModel.requestNotificationPermission()
                            if !granted {
                                notificationEnabled = false
                            }
                        }
                    }
                }
            }

            // 数据管理
            Section("数据") {
                if storeManager.isProUnlocked {
                    Button {
                        exportData()
                    } label: {
                        Label("导出为 CSV", systemImage: "square.and.arrow.up")
                    }
                } else {
                    HStack {
                        Label("导出为 CSV", systemImage: "square.and.arrow.up")
                        Spacer()
                        Text("Pro")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.1), in: Capsule())
                    }
                }

                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Label("重置所有数据", systemImage: "trash")
                        .foregroundStyle(.red)
                }
            }

            // 关于
            Section("关于") {
                HStack {
                    Label("版本", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                Link(destination: URL(string: "https://pulseapp.github.io/privacy")!) {
                    Label("隐私政策", systemImage: "hand.raised.fill")
                }

                Link(destination: URL(string: "https://pulseapp.github.io/terms")!) {
                    Label("使用条款", systemImage: "doc.text.fill")
                }

                if storeManager.isProUnlocked {
                    Button {
                        Task {
                            await storeManager.restorePurchases()
                        }
                    } label: {
                        Label("恢复购买", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
        .navigationTitle("设置")
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showExportSheet) {
            if let csv = exportedCSV {
                ExportSheetView(csvContent: csv)
            }
        }
        .alert("重置所有数据", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) {}
            Button("确认重置", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("这将删除所有习惯和打卡记录，包括iCloud中的数据。此操作不可撤销！")
        }
        .onAppear {
            checkNotificationStatus()
        }
    }

    // MARK: - 辅助方法

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    private func exportData() {
        exportedCSV = viewModel.exportCSV()
        showExportSheet = true
    }

    private func resetAllData() {
        // 删除所有习惯
        for habit in viewModel.habits {
            viewModel.deleteHabit(habit)
        }
        for habit in viewModel.archivedHabits {
            viewModel.deleteHabit(habit)
        }
    }
}

// MARK: - 主题自定义视图（Pro功能）

struct ThemeCustomizationView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedHex: String = ""

    var body: some View {
        List {
            Section("选择强调色") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 16) {
                    ForEach(HabitColors.options, id: \.hex) { option in
                        Button {
                            selectedHex = option.hex
                            themeManager.accentColorHex = option.hex
                            themeManager.save()
                        } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: option.hex) ?? .blue)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        themeManager.accentColorHex == option.hex
                                            ? Image(systemName: "checkmark")
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
                .padding(.vertical, 8)
            }

            Section {
                // 预览
                HStack(spacing: 12) {
                    Circle().fill(themeManager.accentColor).frame(width: 24, height: 24)
                    Text("当前强调色")
                    Spacer()
                    Text(themeManager.accentColorHex)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospaced()
                }
            }
        }
        .navigationTitle("主题强调色")
        .onAppear {
            selectedHex = themeManager.accentColorHex
        }
    }
}

// MARK: - 导出分享视图

struct ExportSheetView: View {
    let csvContent: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(csvContent)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("导出 CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: csvContent) {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

// MARK: - 预览

#Preview {
    NavigationStack {
        SettingsView()
            .environment(HabitViewModel())
            .environment(StoreManager.shared)
            .environment(ThemeManager.shared)
    }
}

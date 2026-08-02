import SwiftUI

/// 设置主页面
struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    var onConnect: (String, Int, String) -> Void
    var onDisconnect: () -> Void

    @State private var showCommandEditor = false
    @State private var editingCommand: QuickCommand?

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 连接
                connectionSection

                // MARK: - 快捷指令
                quickCommandsSection

                // MARK: - 通知
                notificationSection

                // MARK: - 外观
                appearanceSection

                // MARK: - 关于
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(GravityColors.background)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 连接设置

    private var connectionSection: some View {
        Section {
            HStack {
                ConnectionStatusBadge(
                    state: viewModel.connectionState,
                    deviceName: viewModel.deviceName
                )
            }

            HStack {
                Text("主机地址")
                    .foregroundColor(GravityColors.textSecondary)
                Spacer()
                TextField("192.168.x.x", text: $viewModel.host)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(GravityColors.textPrimary)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 14, design: .monospaced))
            }

            HStack {
                Text("端口")
                    .foregroundColor(GravityColors.textSecondary)
                Spacer()
                TextField("9527", text: $viewModel.port)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(GravityColors.textPrimary)
                    .keyboardType(.numberPad)
                    .font(.system(size: 14, design: .monospaced))
            }

            HStack {
                Text("Token")
                    .foregroundColor(GravityColors.textSecondary)
                Spacer()
                SecureField("可选", text: $viewModel.token)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(GravityColors.textPrimary)
                    .font(.system(size: 14, design: .monospaced))
            }

            // 连接/断开按钮
            if viewModel.connectionState.isConnected {
                Button(action: {
                    onDisconnect()
                }) {
                    HStack {
                        Spacer()
                        Label("断开连接", systemImage: "link.slash")
                            .foregroundColor(GravityColors.error)
                        Spacer()
                    }
                }
            } else {
                Button(action: {
                    viewModel.saveConnection()
                    onConnect(
                        viewModel.host,
                        Int(viewModel.port) ?? 9527,
                        viewModel.token
                    )
                }) {
                    HStack {
                        Spacer()
                        Label("连接", systemImage: "link")
                            .foregroundColor(GravityColors.success)
                        Spacer()
                    }
                }
                .disabled(viewModel.host.isEmpty)
            }
        } header: {
            Text("连接")
                .foregroundColor(GravityColors.textSecondary)
        }
        .listRowBackground(GravityColors.cardBackground)
    }

    // MARK: - 快捷指令

    private var quickCommandsSection: some View {
        Section {
            ForEach(viewModel.quickCommands) { cmd in
                HStack {
                    Image(systemName: cmd.icon)
                        .foregroundColor(cmd.colorValue())
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(cmd.title)
                            .font(.system(size: 14))
                            .foregroundColor(GravityColors.textPrimary)
                        Text(cmd.command)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(GravityColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editingCommand = cmd
                    showCommandEditor = true
                }
            }
            .onDelete { indexSet in
                viewModel.quickCommands.remove(atOffsets: indexSet)
                viewModel.saveQuickCommands()
            }
            .onMove { from, to in
                viewModel.quickCommands.move(fromOffsets: from, toOffset: to)
                viewModel.saveQuickCommands()
            }

            Button(action: {
                editingCommand = nil
                showCommandEditor = true
            }) {
                HStack {
                    Spacer()
                    Label("添加快捷指令", systemImage: "plus.circle")
                        .font(.system(size: 14))
                        .foregroundColor(GravityColors.brand)
                    Spacer()
                }
            }
        } header: {
            Text("快捷指令")
                .foregroundColor(GravityColors.textSecondary)
        }
        .listRowBackground(GravityColors.cardBackground)
        .sheet(isPresented: $showCommandEditor) {
            QuickCommandEditorView(
                command: editingCommand,
                onSave: { cmd in
                    if let existing = editingCommand,
                       let index = viewModel.quickCommands.firstIndex(where: { $0.id == existing.id }) {
                        viewModel.quickCommands[index] = cmd
                    } else {
                        viewModel.quickCommands.append(cmd)
                    }
                    viewModel.saveQuickCommands()
                    showCommandEditor = false
                },
                onDelete: {
                    if let existing = editingCommand {
                        viewModel.quickCommands.removeAll { $0.id == existing.id }
                        viewModel.saveQuickCommands()
                    }
                    showCommandEditor = false
                }
            )
        }
    }

    // MARK: - 通知设置

    private var notificationSection: some View {
        Section {
            ToggleRow(title: "错误关键词通知", subtitle: "终端输出匹配 error/fail 等", isOn: $viewModel.notifyOnErrorKeyword)
            ToggleRow(title: "任务完成通知", subtitle: "进程退出时推送", isOn: $viewModel.notifyOnTaskComplete)
            ToggleRow(title: "资源告警", subtitle: "CPU/内存/磁盘超阈值", isOn: $viewModel.notifyOnResourceAlert)
            ToggleRow(title: "长时间无输出", subtitle: "终端可能卡死时提醒", isOn: $viewModel.notifyOnLongIdle)
            ToggleRow(title: "Agent 离线", subtitle: "心跳超时通知", isOn: $viewModel.notifyOnAgentOffline)

            HStack {
                Text("Webhook URL")
                    .foregroundColor(GravityColors.textSecondary)
                Spacer()
                TextField("Bark/自定义", text: $viewModel.webhookURL)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(GravityColors.textPrimary)
                    .font(.system(size: 13, design: .monospaced))
            }
        } header: {
            Text("通知")
                .foregroundColor(GravityColors.textSecondary)
        }
        .listRowBackground(GravityColors.cardBackground)
    }

    // MARK: - 外观设置

    private var appearanceSection: some View {
        Section {
            HStack {
                Text("终端字号")
                    .foregroundColor(GravityColors.textSecondary)
                Spacer()
                Stepper("\(Int(viewModel.terminalFontSize))pt",
                        value: $viewModel.terminalFontSize,
                        in: 11...17,
                        step: 1)
                    .foregroundColor(GravityColors.textPrimary)
            }

            HStack {
                Text("终端字体")
                    .foregroundColor(GravityColors.textSecondary)
                Spacer()
                Text(viewModel.useSystemMonospacedFont ? "系统等宽" : viewModel.terminalFontName)
                    .foregroundColor(GravityColors.textPrimary)
                    .font(.system(size: 14))
            }
        } header: {
            Text("外观")
                .foregroundColor(GravityColors.textSecondary)
        }
        .listRowBackground(GravityColors.cardBackground)
    }

    // MARK: - 关于

    private var aboutSection: some View {
        Section {
            HStack {
                Text("版本")
                    .foregroundColor(GravityColors.textSecondary)
                Spacer()
                Text("1.0.0")
                    .foregroundColor(GravityColors.textPrimary)
                    .font(.system(size: 14, design: .monospaced))
            }

            HStack {
                Text("最低 iOS")
                    .foregroundColor(GravityColors.textSecondary)
                Spacer()
                Text("17.0")
                    .foregroundColor(GravityColors.textPrimary)
                    .font(.system(size: 14, design: .monospaced))
            }

            HStack {
                Text("协议")
                    .foregroundColor(GravityColors.textSecondary)
                Spacer()
                Text("Gravity Protocol v1")
                    .foregroundColor(GravityColors.textPrimary)
                    .font(.system(size: 14, design: .monospaced))
            }
        } header: {
            Text("关于")
                .foregroundColor(GravityColors.textSecondary)
        }
        .listRowBackground(GravityColors.cardBackground)
    }
}

/// 设置开关行
struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(GravityColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(GravityColors.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(GravityColors.brand)
                .labelsHidden()
        }
    }
}

#Preview {
    let vm = SettingsViewModel()
    vm.loadSettings()
    SettingsView(viewModel: vm, onConnect: { _, _, _ in }, onDisconnect: {})
        .preferredColorScheme(.dark)
}

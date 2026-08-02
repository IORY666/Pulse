import SwiftUI

/// 终端主页面 — 标签页切换 + 输出区域 + 快捷指令 + 输入栏
struct TerminalView: View {
    @ObservedObject var viewModel: TerminalViewModel
    var onSelectSession: (String) -> Void

    @State private var showAddSheet = false
    @State private var newSessionName = ""
    @State private var showScrollButton = false

    var body: some View {
        VStack(spacing: 0) {
            // 标签页栏
            terminalTabBar

            // 连接状态行
            connectionInfoBar

            // 终端输出区域
            ZStack(alignment: .bottomTrailing) {
                TerminalOutputView(
                    outputLines: viewModel.currentOutputLines,
                    autoScroll: $viewModel.autoScroll
                )
                .background(GravityColors.background)

                // 滚动到底部按钮
                if !viewModel.autoScroll && !viewModel.currentOutputLines.isEmpty {
                    ScrollToBottomButton {
                        viewModel.autoScroll = true
                    }
                    .padding(.trailing, 12)
                    .padding(.bottom, 8)
                    .transition(.opacity)
                }
            }

            // 快捷指令栏
            QuickCommandsBar(
                commands: viewModel.quickCommands,
                onSend: { cmd in
                    viewModel.sendQuickCommand(cmd)
                }
            )

            // 输入栏
            TerminalInputBar(
                inputText: $viewModel.inputText,
                onSend: { viewModel.sendCommand() },
                isConnected: viewModel.connectionState.isConnected,
                isRunning: viewModel.selectedSession?.isRunning ?? false
            )
        }
        .background(GravityColors.background)
        // 新建会话 Sheet
        .sheet(isPresented: $showAddSheet) {
            newSessionSheet
        }
        // 二次确认弹窗
        .alert("确认执行？", isPresented: Binding(
            get: { viewModel.pendingConfirmation != nil },
            set: { if !$0 { viewModel.cancelPendingCommand() } }
        )) {
            Button("取消", role: .cancel) {
                viewModel.cancelPendingCommand()
            }
            Button("确认执行") {
                viewModel.confirmPendingCommand()
            }
        } message: {
            if let cmd = viewModel.pendingConfirmation {
                Text("将执行: \(cmd.command)")
            }
        }
    }

    // MARK: - 标签页栏

    private var terminalTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(viewModel.sessions) { session in
                    Button(action: { viewModel.selectTab(session.id) }) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(session.isRunning ? GravityColors.success : GravityColors.textSecondary)
                                .frame(width: 5, height: 5)

                            Text(session.name)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(
                                    session.id == viewModel.selectedSessionId
                                        ? GravityColors.textPrimary
                                        : GravityColors.textSecondary
                                )
                                .lineLimit(1)

                            // 关闭按钮（标签页 > 1 时显示）
                            if viewModel.sessions.count > 1 {
                                Button(action: { viewModel.closeTab(session.id) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(GravityColors.textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            session.id == viewModel.selectedSessionId
                                ? GravityColors.cardBackground
                                : Color.clear
                        )
                        .overlay(
                            // 选中态底部指示条
                            session.id == viewModel.selectedSessionId
                                ? Rectangle()
                                    .fill(GravityColors.brand)
                                    .frame(height: 2)
                                    .padding(.horizontal, 10)
                                : nil,
                            alignment: .bottom
                        )
                    }
                    .buttonStyle(.plain)

                    // 分隔线
                    if session.id != viewModel.sessions.last?.id {
                        Rectangle()
                            .fill(GravityColors.border)
                            .frame(width: 0.5, height: 16)
                    }
                }

                // 添加标签页按钮
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(GravityColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)
        }
        .background(GravityColors.background)
        .overlay(
            Rectangle()
                .fill(GravityColors.border)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - 连接信息栏

    private var connectionInfoBar: some View {
        HStack(spacing: 6) {
            ConnectionStatusBadge(
                state: viewModel.connectionState,
                deviceName: ""
            )

            if let session = viewModel.selectedSession, !session.lastOutputDescription.isEmpty {
                Text("· 上次输出: \(session.lastOutputDescription)")
                    .font(.system(size: 11))
                    .foregroundColor(GravityColors.textSecondary)
            }

            Spacer()

            Text("\(viewModel.outputLineCount) 行")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(GravityColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(GravityColors.cardBackground)
    }

    // MARK: - 新建会话

    private var newSessionSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("会话名称", text: $newSessionName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button("创建") {
                    let name = newSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
                    viewModel.createTab(name: name.isEmpty ? nil : name)
                    newSessionName = ""
                    showAddSheet = false
                }
                .buttonStyle(.borderedProminent)
                .tint(GravityColors.brand)
                .disabled(newSessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(.top, 30)
            .background(GravityColors.background)
            .navigationTitle("新建终端会话")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") { showAddSheet = false }
                        .foregroundColor(GravityColors.brand)
                }
            }
        }
        .presentationDetents([.height(200)])
    }
}

#Preview {
    let vm = TerminalViewModel()
    TerminalView(viewModel: vm, onSelectSession: { _ in })
        .preferredColorScheme(.dark)
        .onAppear {
            let mock = MockAgentService()
            Task {
                mock.connect()
                let sessionId = mock.createSession(name: "终端 #1")
                vm.bind(mock: mock)
                mock.sendCommand("git status", sessionId: sessionId)
            }
        }
}

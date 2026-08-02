import SwiftUI

/// 快捷指令编辑器 Sheet
struct QuickCommandEditorView: View {
    let command: QuickCommand?    // nil = 新建
    let onSave: (QuickCommand) -> Void
    let onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var cmd: String = ""
    @State private var icon: String = "terminal"
    @State private var colorHex: String = "#7C3AED"
    @State private var requiresConfirmation: Bool = false

    private let iconOptions: [(name: String, label: String)] = [
        ("terminal", "终端"), ("stop.circle.fill", "中断"),
        ("arrow.triangle.branch", "Git"), ("clock.arrow.circlepath", "历史"),
        ("list.bullet.rectangle", "列表"), ("pc", "电脑"),
        ("internaldrive", "磁盘"), ("network", "网络"),
        ("hammer.fill", "构建"), ("play.fill", "运行"),
        ("arrow.up.doc.fill", "部署"), ("doc.text.magnifyingglass", "日志"),
        ("gearshape.fill", "配置"), ("xmark.circle.fill", "清理"),
    ]

    private let colorOptions: [(name: String, hex: String)] = [
        ("紫色", "#7C3AED"), ("蓝色", "#58A6FF"), ("绿色", "#3FB950"),
        ("红色", "#F85149"), ("橙色", "#D29922"), ("灰色", "#8B949E"),
        ("青色", "#39C5CF"), ("粉色", "#BC8CFF"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                Section("基本信息") {
                    TextField("标题", text: $title)
                    TextField("命令", text: $cmd)
                        .font(.system(size: 14, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                // 图标选择
                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(iconOptions, id: \.name) { option in
                            Button(action: { icon = option.name }) {
                                VStack(spacing: 4) {
                                    Image(systemName: option.name)
                                        .font(.system(size: 20))
                                        .foregroundColor(icon == option.name ? .white : GravityColors.textSecondary)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            icon == option.name
                                                ? Color(hex: colorHex) ?? GravityColors.brand
                                                : GravityColors.cardBackground
                                        )
                                        .cornerRadius(8)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // 颜色选择
                Section("颜色") {
                    HStack(spacing: 12) {
                        ForEach(colorOptions, id: \.hex) { option in
                            Button(action: { colorHex = option.hex }) {
                                Circle()
                                    .fill(Color(hex: option.hex) ?? .gray)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                colorHex == option.hex ? Color.white : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                    .overlay(
                                        colorHex == option.hex
                                            ? Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                            : nil
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // 安全设置
                Section("安全") {
                    Toggle("执行前需要二次确认", isOn: $requiresConfirmation)
                        .tint(GravityColors.brand)
                }

                // 删除按钮（仅编辑模式）
                if command != nil, let onDelete {
                    Section {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            HStack {
                                Spacer()
                                Label("删除此指令", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(GravityColors.background)
            .navigationTitle(command == nil ? "添加快捷指令" : "编辑快捷指令")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(GravityColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        let sortOrder = command?.sortOrder ?? 999
                        let newCmd = QuickCommand(
                            id: command?.id ?? UUID().uuidString,
                            title: title,
                            command: cmd,
                            icon: icon,
                            color: colorHex,
                            requiresConfirmation: requiresConfirmation,
                            sortOrder: sortOrder
                        )
                        onSave(newCmd)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(GravityColors.brand)
                    .disabled(title.isEmpty || cmd.isEmpty)
                }
            }
            .onAppear {
                if let cmd = command {
                    title = cmd.title
                    self.cmd = cmd.command
                    icon = cmd.icon
                    colorHex = cmd.color
                    requiresConfirmation = cmd.requiresConfirmation
                }
            }
        }
    }
}

#Preview {
    QuickCommandEditorView(
        command: QuickCommand.defaults[0],
        onSave: { _ in },
        onDelete: {}
    )
    .preferredColorScheme(.dark)
}

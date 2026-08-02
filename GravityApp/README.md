# Gravity · iOS App

> 🪐 「你的电脑，永远在线」 — 个人开发者的移动编程伴侣

Gravity 让你在 iPhone 上随时查看 Windows 开发机的终端输出、系统状态，并发送命令。通过局域网直连（或 Tailscale 内网），无需服务器。

---

## 🚀 快速构建 IPA

### 前置条件

- **Mac**（macOS 14+）+ **Xcode 15+**
- **Apple ID**（免费即可，不需要付费开发者账号）

### 方法一：Xcode（最简单）

```bash
# 1. 生成 Xcode 项目（需要先安装 XcodeGen）
brew install xcodegen
cd GravityApp
xcodegen generate

# 2. 打开项目
open Gravity.xcodeproj

# 3. 在 Xcode 中：
#    → 选择 Gravity target
#    → Signing & Capabilities → Team 选你的 Apple ID (Personal Team)
#    → 菜单 Product → Archive
#    → 导出时选 "Development" 方式
#    → 得到 Gravity.ipa
```

### 方法二：命令行

```bash
cd GravityApp
bash build.sh release
# IPA 生成在 build/IPA/Gravity.ipa
```

### 安装到 iPhone

- **免费 Apple ID**：用 Xcode → Devices → 拖入 IPA，或通过 Apple Configurator 安装
- **AltStore**：把 IPA 拖入 AltStore，每 7 天自动重签
- **付费开发者**：Ad-Hoc 分发或直接 Archive 到手机

> ⚠️ 免费签名 7 天有效期。个人使用建议配合 AltStore 自动续签。

---

## 📁 项目结构

```
GravityApp/
├── project.yml              # XcodeGen 配置
├── build.sh                 # 构建脚本
├── Gravity/
│   ├── GravityApp.swift     # App 入口
│   ├── Models/              # 数据模型
│   │   ├── GravityMessage   # WebSocket 协议消息
│   │   ├── SystemInfo       # 系统信息模型
│   │   └── TerminalSession  # 终端会话 + 快捷指令
│   ├── Services/            # 服务层
│   │   ├── WebSocketService # WebSocket 连接管理（自动重连+心跳）
│   │   ├── MockAgentService # Mock Agent（独立运行，无需真实 Agent）
│   │   └── ANSIParser       # ANSI escape 序列解析器（16色+256色）
│   ├── ViewModels/          # MVVM ViewModel
│   │   ├── DashboardViewModel
│   │   ├── TerminalViewModel
│   │   └── SettingsViewModel
│   ├── Views/               # SwiftUI 视图
│   │   ├── MainTabView      # 底部 TabBar
│   │   ├── Dashboard/       # 仪表盘（系统状态卡片网格）
│   │   ├── Terminal/        # 终端（标签页+输出+快捷指令+输入）
│   │   ├── Settings/        # 设置（连接/通知/外观/快捷指令编辑）
│   │   └── Components/      # 通用组件（状态指示器+趋势线）
│   └── Storage/
│       └── DataStore        # SwiftData 持久化 + 设计系统色彩
└── README.md
```

---

## 🔧 当前状态（MVP M1+M2）

| 功能 | 状态 |
|---|---|
| Mock 模式（无 Agent 独立运行） | ✅ 完成 |
| 终端多标签页 | ✅ 完成 |
| ANSI 颜色渲染（16色+256色） | ✅ 完成 |
| JSON 自动格式化折叠 | ✅ 完成 |
| 错误行红色高亮 | ✅ 完成 |
| 快捷指令栏（预设 + 自定义） | ✅ 完成 |
| 系统仪表盘（6 张卡片 + 趋势线） | ✅ 完成 |
| 仪表盘卡片详情（CPU 各核心等） | ✅ 完成 |
| WebSocket 连接 + 自动重连 | ✅ 完成 |
| 心跳保活 | ✅ 完成 |
| 断线重连恢复 | ✅ 完成 |
| 设置页（连接/通知/外观） | ✅ 完成 |
| SwiftData 持久化 | ✅ 完成 |
| 深色主题（GitHub Dark 风格） | ✅ 完成 |

### 待对接

- [ ] 真实 Agent 连接（局域网 WebSocket）
- [ ] Tailscale 内网
- [ ] Bark 推送通知
- [ ] Live Activity / 灵动岛
- [ ] 语音输入
- [ ] 文件快传

---

## 🔗 连接 Windows Agent

1. 在 Windows 上启动 Gravity Agent（Go 编写，后续开发）
2. 确认 iPhone 和 Windows 在同一局域网
3. Gravity App → 设置 → 输入 Windows 的局域网 IP + 端口 → 连接
4. 首次配对后，Token 自动保存到 Keychain

---

## 🎨 设计规范

| 项目 | 值 |
|---|---|
| 主背景 | `#0D1117` (GitHub Dark) |
| 卡片背景 | `#161B22` |
| 品牌色 | `#7C3AED` (紫色) |
| 终端字体 | 系统等宽 (SF Mono)，可选 JetBrains Mono |
| 最低 iOS | 17.0 |

---

## 📄 协议

Gravity Protocol v1 · WebSocket JSON · [PRD 详见 D:\Gravity\PRD.md](../PRD.md)

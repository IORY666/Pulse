# Pulse · 极简习惯打卡

> 极简设计 · 隐私优先 · 一次买断 · 永久使用

---

## 📋 Xcode项目配置指南

### 1. 创建Xcode项目

1. 打开 Xcode → `File` → `New` → `Project`
2. 选择 `iOS` → `App`，点击 Next
3. 填写项目信息：
   - **Product Name**: `Pulse`
   - **Team**: 选择你的Apple Developer账号
   - **Organization Identifier**: `com.pulse`
   - **Bundle Identifier**: `com.pulse.habittracker`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Minimum Deployment**: `iOS 17.0`
   - **Storage**: 勾选 `Use SwiftData`
4. 保存到本地目录

### 2. 复制源代码文件

将 `Pulse/` 目录下的文件拖入Xcode项目，保持文件夹结构：

```
Pulse/
├── PulseApp.swift              ← 替换自动生成的App文件
├── Models/
│   ├── Habit.swift
│   └── HabitRecord.swift
├── ViewModels/
│   └── HabitViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── TodayView.swift
│   ├── HabitListView.swift
│   ├── HabitDetailView.swift
│   ├── AddHabitView.swift
│   ├── SettingsView.swift
│   └── PaywallView.swift
├── Store/
│   └── StoreManager.swift
├── Theme/
│   └── ThemeManager.swift
├── Widget/
│   ├── PulseWidget.swift       ← 添加到Widget Extension Target
│   └── WidgetDataSync.swift    ← 添加到主App Target
└── Resources/
    └── Assets.xcassets
```

### 3. 添加Widget Extension Target

1. Xcode → `File` → `New` → `Target`
2. 选择 `Widget Extension`
3. Product Name: `PulseWidget`
4. **取消勾选** `Include Configuration App Intent`
5. 将 `Widget/PulseWidget.swift` 添加到 Widget Extension Target
6. 将 `Widget/WidgetDataSync.swift` 添加到主App Target

### 4. 配置App Group（Widget数据共享必需）

1. 在主App Target → `Signing & Capabilities` → `+ Capability` → 添加 `App Groups`
2. 添加Group: `group.com.pulse.habittracker`
3. 在 Widget Extension Target 重复同样操作
4. 确保两个Target都勾选了同一个App Group

### 5. 配置StoreKit（IAP内购）

1. 在项目设置中添加 `StoreKit.framework`
2. 确保 `StoreManager.swift` 中的 `proProductID` 与 App Store Connect 中配置的一致
3. 创建 `StoreKit Configuration File`（用于本地调试）：
   - `File` → `New` → `File` → `StoreKit Configuration File`
   - 添加一个 Non-Consumable 产品，ID为 `com.pulse.habittracker.pro`

### 6. 配置通知权限

- 在 `Info.plist` 中无需额外配置
- 通知权限在 `HabitViewModel` 中使用 `UNUserNotificationCenter.requestAuthorization` 动态请求

### 7. 构建与运行

1. 选择目标设备（真机或模拟器）
2. `Product` → `Run` (⌘R)
3. Widget需要在真机上测试（或模拟器中长按主屏幕添加Widget）

---

## 🎨 App图标配置

1. 将生成的 `AppIcon.png` (1024x1024) 拖入 `Assets.xcassets` → `AppIcon`
2. Xcode会自动生成各尺寸图标

---

## 🔑 重要：IAP测试

1. 在 `StoreKit Configuration File` 中测试本地IAP
2. 在App Store Connect配置沙盒测试账号
3. 使用沙盒账号在真机上测试购买流程

---

## 📱 最低要求

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Apple Developer Program 会员（用于分发）

---

## 🛠 技术栈

| 技术 | 用途 |
|------|------|
| SwiftUI | UI框架 |
| SwiftData | 本地数据持久化 |
| WidgetKit | 主屏幕小组件 |
| StoreKit 2 | 内购管理 |
| CloudKit | iCloud数据同步 |
| UserNotifications | 本地打卡提醒 |
| App Groups | App与Widget数据共享 |

---

## 📄 许可证

© 2026 Pulse App. All rights reserved.

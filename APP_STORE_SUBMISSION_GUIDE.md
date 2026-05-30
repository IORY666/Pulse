# Pulse · 极简习惯打卡 — App Store上架完整指南

---

## 📋 Part 1: App Store Connect 配置清单

### 第一步：登录 App Store Connect

1. 打开 [https://appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. 使用你的 Apple Developer 账号登录（需年费¥688，确保已续费）

### 第二步：创建新App记录

| 配置项 | 填写内容 |
|--------|----------|
| **平台** | iOS |
| **名称** | Pulse · 极简习惯打卡 |
| **主要语言** | Simplified Chinese（简体中文） |
| **Bundle ID** | `com.pulse.habittracker`（需先在 Certificates, Identifiers & Profiles 中注册） |
| **SKU** | `pulse_habittracker_001` |
| **用户访问权限** | 完全访问 |

### 第三步：App信息配置

| 配置项 | 内容 |
|--------|------|
| **名称（主语言）** | Pulse · 极简习惯打卡 |
| **副标题** | 每天进步一点点 |
| **类别（主要）** | Productivity（效率） |
| **类别（次要）** | Lifestyle（生活） |
| **年龄分级** | 4+ |
| **定价** | 免费（含内购） |
| **版权** | © 2026 Pulse App |

### 第四步：版本信息（1.0.0）

| 字段 | 内容 |
|------|------|
| **宣传文本（Promotional Text）** | 简单到不可能失败的习惯打卡器。一次购买，终身使用。 |
| **描述（Description）** | 见下方完整描述 |
| **关键词（Keywords）** | `习惯,打卡,习惯养成,自律,目标,计划,日常,追踪,提醒,习惯追踪器,好习惯,效率,时间管理,自我提升` |
| **技术支持 URL** | `https://pulseapp.github.io/support` |
| **隐私政策 URL** | `https://pulseapp.github.io/privacy` |
| **营销 URL** | （可选）留空 |

### 第五步：IAP（内购）配置

1. 进入 **App Store Connect → App内购买项目 → 添加**
2. 配置：

| 字段 | 内容 |
|------|------|
| **类型** | Non-Consumable（非消耗型） |
| **参考名称** | Pulse Pro 一次性解锁 |
| **产品ID** | `com.pulse.habittracker.pro` |
| **价格** | $4.99 USD（Tier 5） |
| **显示名称** | Pulse Pro |
| **描述** | 一次性购买解锁全部功能：无限习惯、精美主题、iCloud同步、数据导出 |
| **审核截图** | 上传付费墙截图（App中触发3个习惯限制后的付费墙界面） |

3. 中国的价格会自动按汇率换算（约¥36）

### 第六步：隐私与数据收集

在 **App隐私保护** 中，填写营养标签：

| 数据类型 | 是否收集 | 用途 |
|----------|----------|------|
| **联系信息** | 否 | - |
| **健康与健身** | 否 | - |
| **财务信息** | 否 | - |
| **位置** | 否 | - |
| **敏感信息** | 否 | - |
| **联系人** | 否 | - |
| **用户内容** | 否 | - |
| **浏览历史** | 否 | - |
| **搜索历史** | 否 | - |
| **标识符** | 否 | - |
| **购买** | 是（Apple处理） | App内购买 |
| **使用数据** | 否 | - |
| **诊断** | 否 | - |
| **其他数据** | 否 | - |

**隐私营养标签最终形态**：全部选"Data Not Collected"

### 第七步：截图上传

| 尺寸 | 文件 | 摆放顺序 |
|------|------|----------|
| 6.7" (1290×2796) | `Screenshot_6.7inch_01_Today.png` | 第1张 |
| 6.7" (1290×2796) | `Screenshot_6.7inch_02_Detail.png` | 第2张 |
| 6.7" (1290×2796) | `Screenshot_6.7inch_03_Widget.png` | 第3张 |
| 6.5" (1242×2688) | `Screenshot_6.5inch_01_Today.png` | 第4张 |
| 6.5" (1242×2688) | `Screenshot_6.5inch_02_Detail.png` | 第5张 |
| 6.5" (1242×2688) | `Screenshot_6.5inch_03_Widget.png` | 第6张 |

**注意**：6.7寸为必需尺寸，可自动适配5.5寸。截图放在 `Resources/Screenshots/` 目录下。

---

## 📝 Part 2: 完整App Store描述

### 中文描述（提交用）

```
【极简设计 · 隐私优先 · 一次买断 · 永久使用】

你是否厌倦了臃肿复杂、充满广告和订阅的习惯App？

Pulse是一款极致简约的习惯打卡工具。我们不收集任何数据，不用订阅，只专注于帮你养成好习惯这一件事。

✦ 为什么选择 Pulse ✦
• 极致简约 — 3秒完成打卡，界面清爽不打扰
• 隐私优先 — 100%数据存储在本地，零数据收集，无需注册账号
• 精美Widget — 把你的习惯放到主屏幕，每天解锁手机就看到
• 连续打卡 — 火焰连击激励你保持好习惯，看看能坚持多少天
• 精美统计 — 直观的图表展示你的完成趋势和进步
• 一次买断 — ¥36 永久解锁全部功能，无订阅、无广告、无隐藏收费

✦ 免费版 ✦
• 追踪最多3个习惯
• 每天打卡 + Widget小组件
• 基础统计和连续打卡

✦ Pulse Pro（¥36 一次性买断）✦
• 无限习惯数量
• 10+精美Widget主题
• iCloud多设备数据同步
• CSV数据导出
• 深色/渐变色主题
• 永久更新，未来所有新功能免费

适合想要养成阅读、运动、冥想、喝水、学习、早睡、戒糖、记账等好习惯的你。

现在下载！从今天开始，每天进步一点点。

---

隐私政策：https://pulseapp.github.io/privacy
使用条款：https://pulseapp.github.io/terms
```

### 英文描述（可选，用于海外市场）

```
【Minimalist · Private · Buy Once, Own Forever】

Tired of bloated habit apps with ads and subscriptions?

Pulse is a beautifully simple habit tracker designed to be used in 3 seconds flat. Zero data collection. No accounts. Just you and your habits.

✦ Why Pulse ✦
• Ultra-minimalist — Complete your check-in in 3 seconds
• Privacy-first — 100% local storage, zero data collected
• Beautiful Widgets — Put your habits on your Home Screen
• Streak tracking — Build your flame streak to stay motivated
• Elegant charts — Visualize your progress over time
• One-time purchase — $4.99 unlocks everything forever

✦ Free Features ✦
• Up to 3 habits
• Daily check-in + widgets
• Basic statistics

✦ Pulse Pro ($4.99 one-time) ✦
• Unlimited habits
• 10+ widget themes
• iCloud sync
• CSV export
• Dark mode + gradient themes
• Lifetime updates

Perfect for tracking: reading, exercise, meditation, hydration, studying, sleep, diet, journaling, and more.

Download now and build your first habit today!

Privacy Policy: https://pulseapp.github.io/privacy
Terms of Use: https://pulseapp.github.io/terms
```

---

## 🔍 Part 3: 提交审核前自查清单

### 功能完整性
- [ ] 创建/编辑/删除习惯流程正常（测试3次+）
- [ ] 每日打卡/取消打卡流程正常
- [ ] 连续天数统计正确（模拟多天打卡）
- [ ] 今天完成率计算正确
- [ ] Widget正常刷新（真机测试）
- [ ] 通知提醒正常触发（真机测试）

### IAP流程
- [ ] 3个免费习惯后，创建第4个时触发付费墙
- [ ] 付费墙显示正确（价格、功能列表）
- [ ] 购买流程在沙盒环境测试通过
- [ ] 恢复购买功能正常
- [ ] 购买成功后 Pro 状态持久化（重启App仍在）

### 界面适配
- [ ] iPhone SE (4.7") ~ iPhone Pro Max (6.7") 都显示正常
- [ ] 深色模式切换正常（全部页面）
- [ ] 动态字体大小适配（辅助功能→更大字体）
- [ ] 横屏/竖屏切换正常
- [ ] 启动屏幕（Launch Screen）显示正常

### 崩溃与稳定性
- [ ] 连续快速操作不崩溃（快速切换Tab、快速打卡）
- [ ] 内存警告下不崩溃（模拟器可触发）
- [ ] 无网络环境下正常运行（本App不联网，天然满足）
- [ ] SwiftData数据迁移路径正确（如有模型变更）

### 权限请求
- [ ] 通知权限请求文案合规
- [ ] 无多余权限请求（不需要定位、通讯录、相册、相机等）
- [ ] 拒绝通知权限后App功能仍然正常（只是不提醒）
- [ ] Info.plist中没有多余的Privacy描述

### 审核合规
- [ ] 无"Demo"/"Test"/占位符文本
- [ ] 无隐藏调试菜单或后门
- [ ] 无第三方分析SDK或数据收集代码
- [ ] 无法访问任何外部URL（除非是隐私政策和条款链接）
- [ ] 所有IAP产品在App Store Connect状态为"Ready to Submit"
- [ ] 隐私营养标签已填写
- [ ] 无私有API调用
- [ ] 不使用WebView加载外部内容
- [ ] 无引导用户去外部支付的流程

### 图标和截图
- [ ] App图标 1024x1024 已上传（无alpha通道）
- [ ] 所有截图与App实际功能一致
- [ ] 截图中无"Notch"或"灵动岛"遮挡关键内容（本App截图安全）
- [ ] 截图尺寸符合Apple要求

---

## ⚠️ Part 4: 常见被拒原因及预防方案

### 4.2 最小功能（Minimum Functionality）
**风险**：审核可能认为"习惯打卡"功能太简单
**预防**：
- ✅ Widget小组件增加功能深度
- ✅ 统计图表展示丰富性
- ✅ iCloud同步展示技术能力
- ✅ 在审核备注中说明："本App提供完整的习惯追踪体验，包括Widget、统计图表、iCloud同步、通知提醒等功能模块"

### 3.1.1 内购（In-App Purchase）
**风险**：付费墙触发逻辑可能被误解
**预防**：
- ✅ 确保产品ID在代码和App Store Connect中一致：`com.pulse.habittracker.pro`
- ✅ 审核备注中说明："免费版限制3个习惯，超过3个时展示付费墙。付费墙包含Pro版功能对比和¥36一次性买断按钮。"

### 5.1.1 数据收集和存储（Privacy - Data Collection）
**风险**：未正确声明数据收集
**预防**：
- ✅ 所有数据存本地，不收集任何用户数据
- ✅ 隐私标签全选"Data Not Collected"
- ✅ 隐私政策URL指向有效页面

### 4.0 设计（Design）
**风险**：UI过于简陋
**预防**：
- ✅ 精美的渐变卡片设计
- ✅ 进度环动画
- ✅ Apple原生设计语言

### 2.1 App完整性（App Completeness）
**风险**：崩溃或未完成功能
**预防**：
- ✅ 所有按钮和功能完整可用
- ✅ 无TODO/占位符
- ✅ 完整测试所有流程

---

## 👤 Part 5: 需要你人工操作的步骤

### 你必须自己完成的操作（无法由AI代替）：

1. **Apple Developer账号**
   - 确认开发者账号（¥688/年）已续费且状态活跃
   - 登录 [developer.apple.com](https://developer.apple.com)

2. **注册Bundle ID**
   - 进入 Certificates, Identifiers & Profiles
   - Identifiers → 添加 → App IDs
   - Bundle ID: `com.pulse.habittracker`
   - 启用 Capabilities: App Groups, iCloud (CloudKit), Push Notifications

3. **注册App Group**
   - 添加 App Group: `group.com.pulse.habittracker`
   - （如果还没创建Identifiers → App Groups → 添加）

4. **配置Xcode签名**
   - 打开项目 → Target → Signing & Capabilities
   - Team: 选择你的开发者账号
   - 勾选 "Automatically manage signing"
   - 确保 Bundle Identifier 已改为 `com.pulse.habittracker`

5. **配置App Groups（Widget数据共享）**
   - 主App Target → Signing & Capabilities → + App Groups
   - 添加 `group.com.pulse.habittracker`
   - Widget Extension Target → 同样添加该App Group

6. **创建App Store Connect记录**
   - 按照Part 1的清单填写所有字段

7. **创建IAP产品**
   - App Store Connect → 你的App → App内购买项目
   - 按照Part 1第五步配置

8. **上传二进制包**
   - Xcode → 选择 "Any iOS Device (arm64)" 作为构建目标
   - Product → Archive
   - 在Organizer中选择刚创建的Archive
   - Distribute App → App Store Connect → Upload
   - 等待上传完成

9. **在App Store Connect中提交审核**
   - 选择刚上传的Build
   - 填写出口合规信息（本App不使用加密，选"No"）
   - 填写广告标识符（本App不使用IDFA，选"No"）
   - 点击"提交审核"

10. **等待审核结果**
    - 通常24-48小时内出结果
    - 如被拒，把被拒原因发给我，我来分析并给出修改方案

---

## 💰 Part 6: 收益监控

### 如何查看收益
1. App Store Connect → 趋势 → 销售额和趋势
2. 筛选日期范围
3. 查看"收益"（扣除Apple 30%分成后的金额）

### 循环启动条件
当**预估收益**达到 **¥500** 时，告诉我，我会立即启动下一个App的选品和开发流程。

### 预期收入估算
| 日下载量 | 12%转化率 | 日Pro销量 | 日收入（¥36×0.7） | 达到¥500需天数 |
|----------|-----------|-----------|-------------------|----------------|
| 50 | 6份 | ¥151 | ~17天 |
| 100 | 12份 | ¥302 | ~8天 |
| 200 | 24份 | ¥605 | ~1天 |
| 500 | 60份 | ¥1,512 | <1天 |

---

## 📁 Part 7: 项目文件清单

```
Pulse/
├── README.md                          # 项目说明
├── Pulse/
│   ├── PulseApp.swift                 # App入口
│   ├── Models/
│   │   ├── Habit.swift                # 习惯数据模型
│   │   └── HabitRecord.swift          # 打卡记录模型
│   ├── ViewModels/
│   │   └── HabitViewModel.swift       # 业务逻辑层
│   ├── Views/
│   │   ├── ContentView.swift          # 主TabView
│   │   ├── TodayView.swift            # 今日打卡页
│   │   ├── HabitListView.swift        # 习惯管理页
│   │   ├── HabitDetailView.swift      # 习惯详情+统计
│   │   ├── AddHabitView.swift         # 新建/编辑习惯
│   │   ├── SettingsView.swift         # 设置页面
│   │   └── PaywallView.swift          # Pro付费墙
│   ├── Widget/
│   │   ├── PulseWidget.swift          # Widget入口
│   │   └── WidgetDataSync.swift       # Widget数据同步
│   ├── Store/
│   │   └── StoreManager.swift         # IAP管理
│   └── Theme/
│       └── ThemeManager.swift         # 主题管理
├── Resources/
│   ├── AppIcon.png                    # 1024x1024图标
│   └── Screenshots/
│       ├── Screenshot_6.7inch_01_Today.png
│       ├── Screenshot_6.7inch_02_Detail.png
│       ├── Screenshot_6.7inch_03_Widget.png
│       ├── Screenshot_6.5inch_01_Today.png
│       ├── Screenshot_6.5inch_02_Detail.png
│       └── Screenshot_6.5inch_03_Widget.png
└── Scripts/
    ├── generate_icon.py               # 图标生成脚本
    └── generate_screenshots.py        # 截图生成脚本
```

---

## 🎯 Part 8: 隐私政策URL模板

创建 `https://pulseapp.github.io/privacy` 页面，内容如下：

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pulse 隐私政策</title>
</head>
<body style="font-family: -apple-system, sans-serif; max-width: 800px; margin: 40px auto; padding: 20px;">
    <h1>Pulse · 极简习惯打卡 — 隐私政策</h1>
    <p><strong>最后更新日期：2026年5月30日</strong></p>

    <h2>我们的承诺</h2>
    <p>Pulse 是一款<strong>隐私优先</strong>的习惯追踪应用。我们设计Pulse的核心理念是：你的数据只属于你。</p>

    <h2>数据收集</h2>
    <p><strong>Pulse 不收集任何个人数据。</strong></p>
    <ul>
        <li>我们不收集姓名、邮箱、电话号码等个人信息</li>
        <li>我们不要求注册账号</li>
        <li>我们不使用任何第三方分析工具或SDK</li>
        <li>我们不追踪你的使用行为</li>
        <li>我们不展示任何广告</li>
    </ul>

    <h2>数据存储</h2>
    <p>你创建的所有习惯和打卡记录都<strong>仅存储在您的设备和iCloud账户中</strong>。</p>
    <p>如果你启用了Pro版的iCloud同步功能，数据通过Apple CloudKit服务在你自己的iCloud账户内同步。Pulse的开发者无法访问这些数据。</p>

    <h2>内购</h2>
    <p>Pulse Pro的内购交易由Apple App Store处理。我们无法获取你的支付信息。</p>

    <h2>儿童隐私</h2>
    <p>Pulse不收集任何人的数据，包括13岁以下的儿童。</p>

    <h2>联系我们</h2>
    <p>如有任何隐私相关的问题，请联系：pulseapp@proton.me</p>
</body>
</html>
```

---

## 📌 Part 9: 开发者联系信息模板

| 项目 | 内容 |
|------|------|
| 开发者名称 | 你的姓名/公司名 |
| 联系邮箱 | 你的邮箱（用于App Store审核沟通） |
| 技术支持URL | https://pulseapp.github.io/support |
| 隐私政策URL | https://pulseapp.github.io/privacy |
| 营销URL | （留空或使用相同域名） |

---

## ✅ 准备就绪清单

当你完成以上所有配置后，确认以下最终清单：

- [ ] Xcode项目签名配置完成，0个错误0个警告
- [ ] 已在真机或模拟器上完整测试所有功能
- [ ] 付费墙和IAP沙盒测试通过
- [ ] App Store Connect中App记录已创建且信息完整
- [ ] IAP产品状态为"Ready to Submit"
- [ ] 截图已上传
- [ ] 隐私策略URL可访问
- [ ] 已Archive并上传Build
- [ ] 已点击"Submit for Review"

---

**提交审核后**，等待24-48小时即可得到结果。如遇被拒，将Apple的拒绝原因发给我，我将在24小时内给出修改方案和代码修复。

祝上架顺利！🚀

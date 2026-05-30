# Pulse App — 无需Mac，Windows上发布iOS App

> 你不需要买Mac。你只需要一台能上网的电脑 + GitHub账号 + Apple Developer账号。
> 所有需要在Mac上做的事，都由GitHub Actions的免费macOS云服务器自动完成。

---

## 架构原理

```
你的Windows电脑          GitHub Actions (macOS云服务器)      App Store
──────────────          ────────────────────────────────      ─────────
编辑代码                 自动生成Xcode项目(xcodegen)
git push  ──────────▶   自动签名(fastlane)
                        自动构建(xcodebuild)
                        自动上传(testflight)
                        自动提交审核 ─────────────────────▶  审核 → 上架
                                                                 │
                                                    ┌────────────┘
                                                    ▼
                                              用户下载 →
                                              收益 ¥¥¥ →
                                          monitor_revenue.py
                                          自动监控收益 ──→ 达500元自动通知
```

---

## 你只需要做3件事（全部一次性，共约20分钟）

### ① 购买 Apple Developer Program（¥688/年）

1. 打开 https://developer.apple.com/programs/
2. 点击 "Enroll"
3. 用你的 Apple ID 登录（没有就注册一个）
4. 选择 Individual 计划，支付 ¥688/年
5. 等待确认邮件（通常几分钟）

> ⚠️ **这笔费用是唯一的硬件外成本。** 后续所有App共享同一个开发者账号。

---

### ② 生成 App Store Connect API 密钥（5分钟，一次性）

1. 打开 https://appstoreconnect.apple.com/access/api
2. 点击 **"生成 API 密钥"**（+号）
3. 名称填 `GitHub Actions`
4. 选择访问权限为 **"App Manager"**
5. 点击生成，**立即下载 .p8 文件**（只能下载一次！）
6. 记录以下三个值：
   - **Key ID**（如 `ABC123DEF4`）
   - **Issuer ID**（如 `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`）
   - **.p8 文件内容**（用记事本打开，复制全部文本）

---

### ③ 在 GitHub 设置 Secrets（3分钟）

1. 把这个项目推送到 GitHub（新建仓库 → 上传所有文件）
2. 进入仓库 → **Settings → Secrets and variables → Actions**
3. 点击 **New repository secret**，添加以下5个 secrets：

| Secret Name | 值 | 哪里获取 |
|---|---|---|
| `APPSTORE_KEY_ID` | 你的 Key ID | 步骤② |
| `APPSTORE_ISSUER_ID` | 你的 Issuer ID | 步骤② |
| `APPSTORE_KEY_BASE64` | .p8文件内容的Base64编码 | 步骤②（见下方） |
| `FASTLANE_USER` | 你的 Apple ID 邮箱 | 你的 Apple ID |
| `TEAM_ID` | 你的 Team ID | [developer.apple.com/account](https://developer.apple.com/account) → Membership |

**获取 APPSTORE_KEY_BASE64**（在终端/命令提示符运行）:

```bash
# Windows PowerShell:
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("AuthKey_XXXX.p8")) | Set-Clipboard

# Mac/Linux 终端:
base64 -i AuthKey_XXXX.p8 | pbcopy
```

---

## 完成！之后只做一件事：

在 Windows 上编辑代码 → `git push` → **全自动**构建上传

```bash
# 日常操作：
git add .
git commit -m "更新XXX功能"
git push

# GitHub Actions 自动触发:
# 1. 在 macOS 云服务器上启动
# 2. xcodegen 自动生成 Xcode 项目
# 3. fastlane 自动签名
# 4. 构建 → 上传 TestFlight → (可选)提交审核

# 如果要提交审核，在 GitHub Actions 页面:
# → Actions 标签 → Pulse CI/CD → Run workflow → 选择 "appstore" → Run
```

---

## 工作流命令对照表

| 你想做什么 | 怎么做 |
|-----------|--------|
| 修改App代码 | Windows上编辑 `.swift` 文件 → `git push` |
| 上传TestFlight测试版 | `git push` (自动) |
| 提交App Store审核 | GitHub Actions → Run workflow → 选 `appstore` |
| 仅构建测试(不上传) | GitHub Actions → Run workflow → 选 `build_only` |
| 查看构建日志 | GitHub Actions → 点击最近的运行记录 |
| 修改App图标 | 替换 `Resources/AppIcon.png` → `git push` |
| 修改App截图 | 替换 `Resources/Screenshots/` → 用fastlane上传 |
| 修改App描述/价格 | 在 App Store Connect 网页直接改 |

---

## 首次推送前检查清单

- [ ] `project.yml` 中的 `bundleIdPrefix` 是否正确
- [ ] `Pulse/Info.plist` 中版本号是否设置为 `1.0.0`
- [ ] `Pulse/Pulse.entitlements` 中 App Group 名称正确
- [ ] 代码中 `StoreManager.proProductID` 与 ASC 中 IAP 产品 ID 一致
- [ ] GitHub Secrets 全部 5 个已添加
- [ ] Apple Developer 账号已激活

---

## 常见问题

### Q: 真的不需要Mac吗？
**A: 真的不需要。** GitHub 提供免费的 macOS 云服务器（每月2000分钟免费额度，约33小时，对一个App绰绰有余）。所有编译、打包、签名、上传都由它完成。

### Q: 能在Windows上预览App吗？
**A: 不能直接预览，但可以：**
- 上传到 TestFlight 后在 iPhone 上下载测试
- 或者花 ¥2000-3000 买一台二手 Mac Mini（推荐但不必须）

### Q: IAP（内购）怎么配置？
**A:** 首次需要在 App Store Connect 网页手动创建 Pro 产品：
1. App Store Connect → 你的App → App 内购买项目
2. 添加 → Non-Consumable → ID: `com.pulse.habittracker.pro` → 价格 $4.99

（后续App可以用Python脚本通过API自动创建）

### Q: 如何调试和修bug？
**A:** 
1. 看 GitHub Actions 构建日志找编译错误
2. TestFlight 下载后真机测试找运行时bug
3. 把bug信息发给我（Claude），我来修复代码
4. 修复后 `git push` → 自动重新构建

### Q: 每年 ¥688 能发布几个App？
**A: 无限个。** 一个开发者账号可以发布无数App，iOS和macOS都包含在内。

---

## 成本总览

| 项目 | 金额 | 周期 |
|------|------|------|
| Apple Developer | ¥688 | 年付 |
| GitHub (公开仓库) | ¥0 | 永久免费 |
| GitHub Actions额度 | ¥0 | 2000分钟/月免费 |
| 服务器/域名 | ¥0 | 不需要 |
| **第一个App开发(token)** | **~¥40** | 一次性 |
| **总启动成本** | **≈¥728** | — |
| **后续每个App成本** | **~¥40-50** | 仅token |

> 第一个App回本后（预计1-3周），所有后续App都是纯利润。

---

## 总结：你只需做

```
现在：  ① 买开发者账号(¥688)
       ② 生成API密钥(5分钟)
       ③ 推送到GitHub + 设置Secrets(3分钟)

以后：  git push  ← 就这一条命令

收益达¥500时：告诉我，我自动启动下一个App
```

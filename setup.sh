#!/bin/bash
# ==============================================================
#  Pulse App - 一键部署脚本
#  在 Mac 上运行此脚本，自动完成所有配置
#
#  使用方式:
#    chmod +x setup.sh
#    ./setup.sh
#
#  你只需要:
#    1. 已购买 Apple Developer Program (¥688/年)
#    2. Mac 上已安装 Xcode (App Store 免费下载)
#    3. 运行本脚本，按提示输入 Apple ID
# ==============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                      ║${NC}"
echo -e "${CYAN}║       Pulse · 极简习惯打卡 — 一键部署              ║${NC}"
echo -e "${CYAN}║                                                      ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================
# 第0步：检查前置条件
# ============================================================
echo -e "${YELLOW}[检查] 验证前置条件...${NC}"

# 检查 macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}[错误] 此脚本必须在 macOS 上运行${NC}"
    echo "当前系统: $(uname)"
    echo "请在 Mac 上下载此项目并重新运行"
    exit 1
fi
echo -e "${GREEN}  [OK] macOS 已确认${NC}"

# 检查 Xcode
if ! xcode-select -p &>/dev/null; then
    echo -e "${RED}[错误] 未找到 Xcode Command Line Tools${NC}"
    echo "请先安装 Xcode (App Store 免费下载)，然后运行:"
    echo "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    exit 1
fi
echo -e "${GREEN}  [OK] Xcode 已安装${NC}"

# 检查/安装 Homebrew
if ! command -v brew &>/dev/null; then
    echo -e "${YELLOW}[安装] Homebrew 未安装，正在安装...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo -e "${GREEN}  [OK] Homebrew 安装完成${NC}"
fi

# 检查/安装 Ruby (fastlane 需要)
if ! command -v ruby &>/dev/null; then
    echo -e "${YELLOW}[安装] Ruby...${NC}"
    brew install ruby
fi

# 检查/安装 Bundler
if ! command -v bundle &>/dev/null; then
    echo -e "${YELLOW}[安装] Bundler...${NC}"
    gem install bundler
fi
echo -e "${GREEN}  [OK] Ruby/Bundler 已就绪${NC}"

# 安装 fastlane
echo -e "${YELLOW}[安装] fastlane...${NC}"
bundle install
echo -e "${GREEN}  [OK] fastlane 安装完成${NC}"

# ============================================================
# 第1步：收集 Apple Developer 信息
# ============================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  第1步：Apple Developer 账号信息${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Apple ID
echo -e "${YELLOW}请输入你的 Apple ID (用于开发者账号的邮箱):${NC}"
read -p "Apple ID: " APPLE_ID
if [ -z "$APPLE_ID" ]; then
    echo -e "${RED}[错误] Apple ID 不能为空${NC}"
    exit 1
fi

# Team ID
echo ""
echo -e "${YELLOW}请输入 Team ID${NC}"
echo "获取方式: 打开 https://developer.apple.com/account → Membership 详情"
echo "格式类似: ABC123DEF4"
read -p "Team ID: " TEAM_ID
if [ -z "$TEAM_ID" ]; then
    echo -e "${RED}[错误] Team ID 不能为空${NC}"
    exit 1
fi

# ITC Team ID (通常与 Team ID 相同)
read -p "iTunes Connect Team ID [直接回车使用相同ID]: " ITC_TEAM_ID
ITC_TEAM_ID=${ITC_TEAM_ID:-$TEAM_ID}

# App-specific Password (用于 fastlane 登录)
echo ""
echo -e "${YELLOW}需要 App-Specific Password 用于 fastlane 自动登录${NC}"
echo "获取方式:"
echo "  1. 打开 https://appleid.apple.com"
echo "  2. 登录 → 安全 → App-Specific Passwords → 生成"
echo "  3. 名称填 'fastlane'，复制生成的密码"
read -p "App-Specific Password [如果不提供，后续每次上传都需手动输入]: " APP_PASSWORD

echo ""
echo -e "${GREEN}[OK] 账号信息收集完成${NC}"

# ============================================================
# 第2步：配置 fastlane
# ============================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  第2步：配置 fastlane 与 App Store Connect${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 更新 Appfile
cat > fastlane/Appfile << EOF
# Pulse App - 自动生成的 Appfile
apple_id("${APPLE_ID}")
app_identifier("com.pulse.habittracker")
team_id("${TEAM_ID}")
itc_team_id("${ITC_TEAM_ID}")
EOF
echo -e "${GREEN}  [OK] fastlane/Appfile 已配置${NC}"

# 更新 Deliverfile
sed -i '' "s/your-apple-id@email.com/${APPLE_ID}/g" fastlane/Deliverfile 2>/dev/null || \
    sed -i "s/your-apple-id@email.com/${APPLE_ID}/g" fastlane/Deliverfile
echo -e "${GREEN}  [OK] fastlane/Deliverfile 已配置${NC}"

# 更新 Matchfile
sed -i '' "s/your-apple-id@email.com/${APPLE_ID}/g" fastlane/Matchfile 2>/dev/null || \
    sed -i "s/your-apple-id@email.com/${APPLE_ID}/g" fastlane/Matchfile
sed -i '' "s/YOUR_TEAM_ID/${TEAM_ID}/g" fastlane/Matchfile 2>/dev/null || \
    sed -i "s/YOUR_TEAM_ID/${TEAM_ID}/g" fastlane/Matchfile

# ============================================================
# 第3步：在 developer.apple.com 注册 Bundle ID
# ============================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  第3步：注册 Bundle ID + 创建 App Store Connect 记录${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}[执行] 使用 fastlane produce 自动创建 App ID 和 App Store 记录...${NC}"
echo "这可能需要你输入 Apple ID 密码（用于 App Store Connect 认证）"
echo ""

if [ -n "$APP_PASSWORD" ]; then
    export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD="$APP_PASSWORD"
fi

bundle exec fastlane produce --skip_itc << 'FASTLANE_EOF' || true
    # fastlane produce 会通过 Appfile 自动读取配置
FASTLANE_EOF

# 手动调用 produce
bundle exec fastlane run produce \
    username:"${APPLE_ID}" \
    app_identifier:"com.pulse.habittracker" \
    app_name:"Pulse · 极简习惯打卡" \
    language:"zh-Hans" \
    app_version:"1.0.0" \
    sku:"pulse_habittracker_001" \
    team_id:"${TEAM_ID}" \
    itc_team_id:"${ITC_TEAM_ID}" \
    2>&1 || echo -e "${YELLOW}  [提示] 如果 App 已存在会报错，这是正常的${NC}"

echo -e "${GREEN}  [OK] Bundle ID 和 App Store Connect 记录已处理${NC}"

# ============================================================
# 第4步：管理证书
# ============================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  第4步：管理签名证书${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}[执行] 生成/下载签名证书...${NC}"

# 使用 fastlane cert 自动管理证书（无需额外Git仓库）
bundle exec fastlane run get_certificates \
    username:"${APPLE_ID}" \
    team_id:"${TEAM_ID}" \
    development:false \
    force:false \
    2>&1 || echo -e "${YELLOW}  [提示] 需要登录认证，按提示输入验证码${NC}"

# 使用 fastlane sigh 自动管理 Provisioning Profile
bundle exec fastlane run get_provisioning_profile \
    username:"${APPLE_ID}" \
    team_id:"${TEAM_ID}" \
    app_identifier:"com.pulse.habittracker" \
    adhoc:false \
    force:false \
    2>&1 || echo -e "${YELLOW}  [提示] 需要登录认证${NC}"

echo -e "${GREEN}  [OK] 证书配置完成${NC}"

# ============================================================
# 第5步：上传元数据到 App Store Connect
# ============================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  第5步：上传 App Store 元数据和截图${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}[执行] 上传元数据...${NC}"
bundle exec fastlane run deliver \
    username:"${APPLE_ID}" \
    app_identifier:"com.pulse.habittracker" \
    metadata_path:"fastlane/metadata" \
    skip_screenshots:false \
    skip_binary_upload:true \
    force:true \
    2>&1 || echo -e "${YELLOW}  [提示] 元数据上传需要先创建 App Store 记录${NC}"

# ============================================================
# 第6步：环境变量持久化
# ============================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  第6步：保存配置${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 创建 ~/.pulse_env 用于存储环境变量
cat > ~/.pulse_env << EOF
# Pulse App 环境变量 - 由 setup.sh 自动生成
export PULSE_APPLE_ID="${APPLE_ID}"
export PULSE_TEAM_ID="${TEAM_ID}"
export PULSE_ITC_TEAM_ID="${ITC_TEAM_ID}"
export PULSE_BUNDLE_ID="com.pulse.habittracker"
EOF

# 添加到 shell profile（如果还没有）
SHELL_PROFILE=""
if [ -f "$HOME/.zshrc" ]; then SHELL_PROFILE="$HOME/.zshrc"; fi
if [ -f "$HOME/.bash_profile" ]; then SHELL_PROFILE="$HOME/.bash_profile"; fi
if [ -f "$HOME/.bashrc" ]; then SHELL_PROFILE="$HOME/.bashrc"; fi

if [ -n "$SHELL_PROFILE" ]; then
    if ! grep -q "pulse_env" "$SHELL_PROFILE" 2>/dev/null; then
        echo 'source ~/.pulse_env 2>/dev/null' >> "$SHELL_PROFILE"
        echo -e "${GREEN}  [OK] 已添加到 $SHELL_PROFILE${NC}"
    fi
fi

echo -e "${GREEN}  [OK] 配置已保存到 ~/.pulse_env${NC}"

# ============================================================
# 第7步：首次构建
# ============================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  第7步：首次构建 (可选)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -p "是否现在构建并上传到 TestFlight? (y/n) [y]: " DO_BUILD
DO_BUILD=${DO_BUILD:-y}

if [ "$DO_BUILD" = "y" ] || [ "$DO_BUILD" = "Y" ]; then
    echo -e "${YELLOW}[执行] 构建 Release...${NC}"
    echo "这可能需要 10-20 分钟"
    echo ""

    # 创建 Xcode 项目（如果还没有）
    if [ ! -f "Pulse.xcodeproj/project.pbxproj" ]; then
        echo -e "${YELLOW}[提示] 需要先在 Xcode 中创建项目，然后复制源代码文件${NC}"
        echo "请按照 README.md 中的步骤创建 Xcode 项目"
        echo "然后在 Xcode 中:"
        echo "  1. 配置 Signing & Capabilities"
        echo "  2. 添加 Widget Extension Target"
        echo "  3. 添加 App Groups capability"
        echo ""
        echo "完成后，运行以下命令构建和上传:"
        echo "  bundle exec fastlane beta"
    else
        bundle exec fastlane beta || echo -e "${YELLOW}[提示] 首次构建可能需要手动处理一些配置${NC}"
    fi
else
    echo "跳过构建。之后可运行: bundle exec fastlane beta"
fi

# ============================================================
# 完成
# ============================================================
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                      ║${NC}"
echo -e "${GREEN}║        部署配置完成！                                ║${NC}"
echo -e "${GREEN}║                                                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}  后续操作：${NC}"
echo ""
echo -e "  ${YELLOW}1. 在 Xcode 中创建项目${NC} (如果还没创建):"
echo "     打开 Xcode → New Project → iOS App →"
echo "     Product Name: Pulse"
echo "     Interface: SwiftUI, Language: Swift"
echo "     勾选 Use SwiftData"
echo ""
echo -e "  ${YELLOW}2. 复制源代码${NC}:"
echo "     将 Pulse/ 目录下的 .swift 文件拖入 Xcode 项目"
echo ""
echo -e "  ${YELLOW}3. 上传 TestFlight${NC}:"
echo "     bundle exec fastlane beta"
echo ""
echo -e "  ${YELLOW}4. 提交审核${NC}:"
echo "     bundle exec fastlane release"
echo ""
echo -e "  ${YELLOW}5. 启动收益监控${NC}:"
echo "     python3 Scripts/monitor_revenue.py --watch"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

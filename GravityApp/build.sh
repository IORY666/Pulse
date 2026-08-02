#!/bin/bash
# Gravity iOS App 构建脚本（在 Mac 上运行）
# 用法：./build.sh [debug|release]
#
# 前提条件：
#   1. macOS + Xcode 15+ 已安装
#   2. (可选) brew install xcodegen  → 用于生成 .xcodeproj
#
# 签名说明：
#   免费 Apple ID：在 Xcode → Signing & Capabilities 中选择你的 Personal Team
#   付费开发者：自动签名，无需额外配置

set -e

MODE="${1:-debug}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "════════════════════════════════════════"
echo "  Gravity iOS · 构建脚本"
echo "  模式: $MODE"
echo "════════════════════════════════════════"

# 1. 检查 Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 未找到 xcodebuild，请安装 Xcode 15+"
    exit 1
fi
echo "✓ Xcode $(xcodebuild -version | head -1)"

# 2. 生成 .xcodeproj（如果不存在或使用 xcodegen）
if [ ! -d "Gravity.xcodeproj" ]; then
    if command -v xcodegen &> /dev/null; then
        echo "→ 使用 XcodeGen 生成项目..."
        xcodegen generate
        echo "✓ 项目生成完成"
    else
        echo "⚠ 未找到 XcodeGen，尝试其他方式..."
        echo "  安装: brew install xcodegen"
        echo "  或手动在 Xcode 中创建项目并导入 Gravity/ 目录"
    fi
fi

# 3. 构建
BUILD_DIR="$SCRIPT_DIR/build"
DERIVED_DATA="$BUILD_DIR/DerivedData"

if [ "$MODE" = "release" ]; then
    echo "→ Archive 构建（导出 IPA）..."
    ARCHIVE_PATH="$BUILD_DIR/Gravity.xcarchive"

    xcodebuild archive \
        -project Gravity.xcodeproj \
        -scheme Gravity \
        -archivePath "$ARCHIVE_PATH" \
        -destination "generic/platform=iOS" \
        -derivedDataPath "$DERIVED_DATA" \
        -configuration Release \
        CODE_SIGN_STYLE=Automatic \
        CODE_SIGN_IDENTITY="Apple Development" \
        | xcpretty || xcodebuild archive \
            -project Gravity.xcodeproj \
            -scheme Gravity \
            -archivePath "$ARCHIVE_PATH" \
            -destination "generic/platform=iOS" \
            -derivedDataPath "$DERIVED_DATA" \
            -configuration Release \
            CODE_SIGN_STYLE=Automatic \
            CODE_SIGN_IDENTITY="Apple Development"

    # 导出 IPA
    # 免费 Apple ID: method=development, 付费: method=app-store / ad-hoc
    EXPORT_PLIST="$BUILD_DIR/ExportOptions.plist"
    cat > "$EXPORT_PLIST" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
PLIST

    EXPORT_PATH="$BUILD_DIR/IPA"
    mkdir -p "$EXPORT_PATH"

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_PLIST" \
        | xcpretty || xcodebuild -exportArchive \
            -archivePath "$ARCHIVE_PATH" \
            -exportPath "$EXPORT_PATH" \
            -exportOptionsPlist "$EXPORT_PLIST"

    echo ""
    echo "════════════════════════════════════════"
    echo "  ✅ IPA 已生成"
    echo "  📂 $EXPORT_PATH/Gravity.ipa"
    echo "════════════════════════════════════════"

else
    echo "→ Debug 构建（模拟器）..."
    xcodebuild build \
        -project Gravity.xcodeproj \
        -scheme Gravity \
        -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
        -derivedDataPath "$DERIVED_DATA" \
        -configuration Debug \
        CODE_SIGN_STYLE=Automatic \
        | xcpretty || xcodebuild build \
            -project Gravity.xcodeproj \
            -scheme Gravity \
            -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
            -derivedDataPath "$DERIVED_DATA" \
            -configuration Debug \
            CODE_SIGN_STYLE=Automatic

    APP_PATH=$(find "$DERIVED_DATA/Build/Products/Debug-iphonesimulator" -name "Gravity.app" | head -1)
    echo ""
    echo "════════════════════════════════════════"
    echo "  ✅ Debug 构建完成"
    echo "  📂 $APP_PATH"
    echo "  运行: xcrun simctl boot 'iPhone 15 Pro' && open -a Simulator"
    echo "════════════════════════════════════════"
fi

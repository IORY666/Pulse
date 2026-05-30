import SwiftUI

/// 主题管理器 - 控制App的整体外观
@MainActor
@Observable
final class ThemeManager {
    /// 当前主题模式
    var colorScheme: ColorSchemeType = .system

    /// 主题强调色（Pro用户可自定义）
    var accentColorHex: String = "#4A90D9"

    enum ColorSchemeType: String, CaseIterable {
        case system = "跟随系统"
        case light = "浅色模式"
        case dark = "深色模式"

        var iconName: String {
            switch self {
            case .system: return "iphone"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }
    }

    /// 单例
    static let shared = ThemeManager()

    private init() {
        // 从本地恢复
        if let saved = UserDefaults.standard.string(forKey: "color_scheme"),
           let scheme = ColorSchemeType(rawValue: saved) {
            colorScheme = scheme
        }
        if let accent = UserDefaults.standard.string(forKey: "accent_color") {
            accentColorHex = accent
        }
    }

    /// 保存主题设置
    func save() {
        UserDefaults.standard.set(colorScheme.rawValue, forKey: "color_scheme")
        UserDefaults.standard.set(accentColorHex, forKey: "accent_color")
    }

    /// 获取对应的SwiftUI ColorScheme
    var preferredColorScheme: ColorScheme? {
        switch colorScheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// 从十六进制颜色字符串获取Color
    var accentColor: Color {
        Color(hex: accentColorHex) ?? .blue
    }
}

// MARK: - Color 扩展：支持十六进制字符串

extension Color {
    /// 从十六进制字符串创建Color
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    /// 转换为十六进制字符串
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - 预定义习惯颜色

/// 预定义的习惯颜色选项
struct HabitColors {
    static let options: [(name: String, hex: String)] = [
        ("活力蓝", "#4A90D9"),
        ("清新绿", "#34C759"),
        ("温暖橙", "#FF9500"),
        ("热情红", "#FF3B30"),
        ("优雅紫", "#AF52DE"),
        ("温柔粉", "#FF2D55"),
        ("天空蓝", "#5AC8FA"),
        ("薄荷绿", "#00C7BE"),
        ("阳光黄", "#FFCC00"),
        ("石墨灰", "#8E8E93"),
    ]

    /// 从hex获取显示名称
    static func name(for hex: String) -> String {
        options.first { $0.hex == hex }?.name ?? "自定义"
    }
}

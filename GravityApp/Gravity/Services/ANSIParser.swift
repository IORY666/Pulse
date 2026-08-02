import Foundation
import SwiftUI

/// ANSI Escape Sequence 解析器
/// 将包含 ANSI 控制码的终端输出转为 AttributedString
enum ANSIParser {

    // MARK: - 公共接口

    /// 解析单行 ANSI 文本，返回带样式的 AttributedString
    static func parse(_ rawText: String, baseFontSize: CGFloat = 13) -> AttributedString {
        let cleaned = stripControlChars(rawText)
        var result = AttributedString("")

        // 先按 ANSI SGR 码分段
        let segments = splitBySGR(cleaned)

        for segment in segments {
            var attrs = AttributeContainer()
            attrs.font = .system(size: baseFontSize, weight: .regular, design: .monospaced)
            attrs.foregroundColor = GravityColors.terminalText

            // 应用 SGR 样式
            applySGR(segment.sgrCodes, to: &attrs, baseFontSize: baseFontSize)

            var segText = AttributedString(segment.text)
            segText.mergeAttributes(attrs)
            result.append(segText)
        }

        return result
    }

    /// 检测文本中是否包含 ANSI escape 序列
    static func containsANSI(_ text: String) -> Bool {
        text.contains("\u{001B}[")
    }

    /// 剥离所有 ANSI escape 序列，返回纯文本
    static func strip(_ text: String) -> String {
        let pattern = "\u{001B}\\[[0-9;]*[a-zA-Z]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        return regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
    }

    // MARK: - 内部实现

    /// SGR 码对应的文本段落
    private struct SGRSegment {
        let text: String
        let sgrCodes: [Int]
    }

    /// 剥离控制字符（\r, \b, \a 等），保留 ANSI escape
    private static func stripControlChars(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{0007}", with: "") // BEL
    }

    /// 按 SGR 码分段文本
    private static func splitBySGR(_ text: String) -> [SGRSegment] {
        let pattern = "\u{001B}\\[([0-9;]*)m"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [SGRSegment(text: text, sgrCodes: [])]
        }

        var segments: [SGRSegment] = []
        var currentSGR: [Int] = []
        var lastEnd = text.startIndex

        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches {
            guard let range = Range(match.range, in: text) else { continue }

            // 在 SGR 码之前的文本
            if range.lowerBound > lastEnd {
                let textBefore = String(text[lastEnd..<range.lowerBound])
                if !textBefore.isEmpty {
                    segments.append(SGRSegment(text: textBefore, sgrCodes: currentSGR))
                }
            }

            // 更新当前 SGR 码
            let codeStr = text[Range(match.range(at: 1), in: text)!]
            if codeStr.isEmpty {
                currentSGR = [0] // 重置
            } else {
                let codes = codeStr.split(separator: ";").compactMap { Int($0) }
                currentSGR = codes.isEmpty ? [0] : codes
            }

            lastEnd = range.upperBound
        }

        // 最后一段文本
        if lastEnd < text.endIndex {
            let remaining = String(text[lastEnd...])
            if !remaining.isEmpty {
                segments.append(SGRSegment(text: remaining, sgrCodes: currentSGR))
            }
        }

        return segments.isEmpty ? [SGRSegment(text: text, sgrCodes: [])] : segments
    }

    /// 将 SGR 码应用到属性容器
    private static func applySGR(_ codes: [Int], to attrs: inout AttributeContainer, baseFontSize: CGFloat) {
        guard !codes.isEmpty else { return }

        var i = 0
        while i < codes.count {
            let code = codes[i]
            switch code {
            case 0: // 重置
                attrs.font = .system(size: baseFontSize, weight: .regular, design: .monospaced)
                attrs.foregroundColor = GravityColors.terminalText
                attrs.backgroundColor = nil
                attrs.strikethroughStyle = nil
                attrs.underlineStyle = nil

            case 1: // 粗体
                attrs.font = .system(size: baseFontSize, weight: .bold, design: .monospaced)
            case 2: // 暗淡
                attrs.foregroundColor = GravityColors.terminalText.opacity(0.6)
            case 3: // 斜体
                attrs.font = .system(size: baseFontSize, weight: .regular, design: .monospaced).italic()
            case 4: // 下划线
                attrs.underlineStyle = .single
            case 5, 6: // 慢闪/快闪
                break // iOS 不支持闪烁，忽略
            case 7: // 反色
                let fg = attrs.foregroundColor
                attrs.foregroundColor = attrs.backgroundColor ?? GravityColors.background
                attrs.backgroundColor = fg
            case 8: // 隐藏
                attrs.foregroundColor = .clear
            case 9: // 删除线
                attrs.strikethroughStyle = .single

            // 标准前景色 (30-37)
            case 30: attrs.foregroundColor = ANSIColors.black
            case 31: attrs.foregroundColor = ANSIColors.red
            case 32: attrs.foregroundColor = ANSIColors.green
            case 33: attrs.foregroundColor = ANSIColors.yellow
            case 34: attrs.foregroundColor = ANSIColors.blue
            case 35: attrs.foregroundColor = ANSIColors.magenta
            case 36: attrs.foregroundColor = ANSIColors.cyan
            case 37: attrs.foregroundColor = ANSIColors.white

            // 标准背景色 (40-47)
            case 40: attrs.backgroundColor = ANSIColors.black
            case 41: attrs.backgroundColor = ANSIColors.red
            case 42: attrs.backgroundColor = ANSIColors.green
            case 43: attrs.backgroundColor = ANSIColors.yellow
            case 44: attrs.backgroundColor = ANSIColors.blue
            case 45: attrs.backgroundColor = ANSIColors.magenta
            case 46: attrs.backgroundColor = ANSIColors.cyan
            case 47: attrs.backgroundColor = ANSIColors.white

            // 亮前景色 (90-97)
            case 90: attrs.foregroundColor = ANSIColors.brightBlack
            case 91: attrs.foregroundColor = ANSIColors.brightRed
            case 92: attrs.foregroundColor = ANSIColors.brightGreen
            case 93: attrs.foregroundColor = ANSIColors.brightYellow
            case 94: attrs.foregroundColor = ANSIColors.brightBlue
            case 95: attrs.foregroundColor = ANSIColors.brightMagenta
            case 96: attrs.foregroundColor = ANSIColors.brightCyan
            case 97: attrs.foregroundColor = ANSIColors.brightWhite

            // 亮背景色 (100-107)
            case 100: attrs.backgroundColor = ANSIColors.brightBlack
            case 101: attrs.backgroundColor = ANSIColors.brightRed
            case 102: attrs.backgroundColor = ANSIColors.brightGreen
            case 103: attrs.backgroundColor = ANSIColors.brightYellow
            case 104: attrs.backgroundColor = ANSIColors.brightBlue
            case 105: attrs.backgroundColor = ANSIColors.brightMagenta
            case 106: attrs.backgroundColor = ANSIColors.brightCyan
            case 107: attrs.backgroundColor = ANSIColors.brightWhite

            // 256 色前景 (38;5;n)
            case 38:
                if i + 2 < codes.count, codes[i + 1] == 5 {
                    let colorIndex = codes[i + 2]
                    attrs.foregroundColor = ANSIColors.palette256(colorIndex)
                    i += 2
                }
            // 256 色背景 (48;5;n)
            case 48:
                if i + 2 < codes.count, codes[i + 1] == 5 {
                    let colorIndex = codes[i + 2]
                    attrs.backgroundColor = ANSIColors.palette256(colorIndex)
                    i += 2
                }
            default:
                break
            }
            i += 1
        }
    }
}

// MARK: - ANSI 16 色 + 256 色调色板

private enum ANSIColors {
    // 标准 16 色
    static let black = Color(hex: "#0D1117")!
    static let red = Color(hex: "#F85149")!
    static let green = Color(hex: "#3FB950")!
    static let yellow = Color(hex: "#D29922")!
    static let blue = Color(hex: "#58A6FF")!
    static let magenta = Color(hex: "#BC8CFF")!
    static let cyan = Color(hex: "#39C5CF")!
    static let white = Color(hex: "#C9D1D9")!

    // 亮色变体
    static let brightBlack = Color(hex: "#484F58")!
    static let brightRed = Color(hex: "#FF7B72")!
    static let brightGreen = Color(hex: "#56D364")!
    static let brightYellow = Color(hex: "#E3B341")!
    static let brightBlue = Color(hex: "#79C0FF")!
    static let brightMagenta = Color(hex: "#D2A8FF")!
    static let brightCyan = Color(hex: "#56D4DD")!
    static let brightWhite = Color(hex: "#F0F6FC")!

    /// 256 色调色板简单映射
    static func palette256(_ index: Int) -> Color {
        // 简化：使用 6x6x6 色彩立方体 + 24 级灰度
        if index < 16 {
            return standard16(index)
        } else if index < 232 {
            // 6x6x6 RGB 立方体
            let n = index - 16
            let r = Double((n / 36) % 6) / 5.0
            let g = Double((n / 6) % 6) / 5.0
            let b = Double(n % 6) / 5.0
            return Color(red: r, green: g, blue: b)
        } else {
            // 灰度
            let gray = Double(index - 232) / 23.0
            return Color(red: gray, green: gray, blue: gray)
        }
    }

    private static func standard16(_ index: Int) -> Color {
        switch index {
        case 0: return black;   case 1: return red
        case 2: return green;   case 3: return yellow
        case 4: return blue;    case 5: return magenta
        case 6: return cyan;    case 7: return white
        case 8: return brightBlack;  case 9: return brightRed
        case 10: return brightGreen; case 11: return brightYellow
        case 12: return brightBlue;  case 13: return brightMagenta
        case 14: return brightCyan;  case 15: return brightWhite
        default: return white
        }
    }
}

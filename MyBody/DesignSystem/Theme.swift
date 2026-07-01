import SwiftUI

/// 设计系统 token（规格 §设计系统）。浅色、米白底、青柠点缀。
enum Theme {

    // MARK: 颜色
    enum Palette {
        static let background = Color(hex: 0xF4F2EC)      // 温暖米白
        static let surface = Color(hex: 0xFFFFFF)         // 白卡片
        static let surfaceSecondary = Color(hex: 0xEDECE4) // 步进/筛选未选中
        static let surfaceTertiary = Color(hex: 0xE9E7DF)  // 头像、返回按钮

        static let textPrimary = Color(hex: 0x1C1D1A)      // 暖墨黑
        static let textSecondary = Color(hex: 0x1C1D1A).opacity(0.55)
        static let textTertiary = Color(hex: 0x1C1D1A).opacity(0.40)

        static let accent = Color(hex: 0x82B43C)           // 草绿（主强调）
        static let accentInfo = Color(hex: 0x7FC9E8)        // 次强调（拉日/信息）
        static let danger = Color(hex: 0xE04D38)            // 警示/超量
        static let warning = Color(hex: 0xC68A12)           // RPE 偏高黄

        static let stroke = Color.black.opacity(0.08)       // 卡片边
        static let strokeInner = Color.black.opacity(0.06)  // 行内分隔

        /// 草绿 Hero 渐变（推日 / 进阶处方卡）。
        static let heroGreen = LinearGradient(
            colors: [Color(hex: 0xE7F0C6), .white],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        /// 淡蓝 Hero 渐变（拉日）。
        static let heroBlue = LinearGradient(
            colors: [Color(hex: 0xDCEEF7), .white],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: 圆角
    enum Radius {
        static let card: CGFloat = 22       // 卡片 20–26
        static let cardLarge: CGFloat = 26  // Hero
        static let control: CGFloat = 12    // 控件 9–14
        static let chip: CGFloat = 11
        static let button: CGFloat = 16
    }

    // MARK: 间距（4 的倍数）
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }

    // MARK: 尺寸
    enum Size {
        static let primaryButtonHeight: CGFloat = 54
        static let minTapTarget: CGFloat = 44
    }
}

// MARK: - 颜色十六进制初始化

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - 等宽数字修饰符（规格：数字一律 tabular-nums）

extension View {
    /// 等宽数字对齐。
    func tabularNumbers() -> some View {
        self.monospacedDigit()
    }
}

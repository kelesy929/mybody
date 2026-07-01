import SwiftUI

// MARK: - 主按钮（高 54、圆角 16、青柠底 + 深墨字、加粗 17）

struct PrimaryButton: View {
    let title: String
    var background: Color = Theme.Palette.accent
    var foreground: Color = Theme.Palette.textPrimary
    var accessibilityID: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: Theme.Size.primaryButtonHeight)
                .background(background)
                .foregroundStyle(foreground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
                .shadow(color: background.opacity(0.4), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityID ?? title)
    }
}

// MARK: - 白卡片容器（极淡阴影 + 1px 描边分层）

struct SurfaceCard<Content: View>: View {
    var padding: CGFloat = 18
    var cornerRadius: CGFloat = Theme.Radius.card
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.Palette.stroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

// MARK: - 分化标签 chip（如「推 · PUSH」）

struct SplitTag: View {
    let text: String
    var background: Color = Theme.Palette.accent
    var foreground: Color = Theme.Palette.textPrimary

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .tracking(0.6)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

// MARK: - 小节标题（全大写、字距）

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(0.5)
            .textCase(.uppercase)
            .foregroundStyle(Theme.Palette.textTertiary)
    }
}

// MARK: - 按肌群的容量进度条（达标/超出用黄色）

struct MuscleVolumeBar: View {
    let name: String          // 「胸」
    let current: Int          // 当前组数
    let target: Int           // 周目标组数

    private var pct: Double { target > 0 ? min(1, Double(current) / Double(target)) : 0 }
    private var reached: Bool { current >= target }

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Text(name)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.Palette.textPrimary.opacity(0.75))
                .frame(width: 26, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Palette.surfaceSecondary)
                    Capsule()
                        .fill(reached ? Theme.Palette.warning : Theme.Palette.accent)
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 10)

            Text("\(current)/\(target) 组")
                .font(.system(size: 12, weight: .semibold))
                .tabularNumbers()
                .foregroundStyle(Theme.Palette.textSecondary)
                .frame(width: 56, alignment: .trailing)
        }
    }
}

// MARK: - 本周圆点（已完成✓ / 今天描边 / 休息 / 未来）

struct WeekDot: View {
    enum State { case done, today, rest, future }
    let label: String         // 「一」
    let state: State
    let todayMark: String     // 今天显示分化字，如「推」

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Palette.textTertiary)
            ZStack {
                shape
                Text(mark)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(markColor)
            }
            .frame(width: 34, height: 34)
        }
    }

    @ViewBuilder private var shape: some View {
        let r = RoundedRectangle(cornerRadius: 12, style: .continuous)
        switch state {
        case .done: r.fill(Theme.Palette.accent)
        case .today: r.fill(.clear).overlay(r.stroke(Theme.Palette.accent, lineWidth: 2))
        case .rest: r.fill(Theme.Palette.surfaceTertiary)
        case .future: r.fill(Theme.Palette.surface)
        }
    }

    private var mark: String {
        switch state {
        case .done: return "✓"
        case .today: return todayMark
        case .rest: return "休"
        case .future: return ""
        }
    }

    private var markColor: Color {
        switch state {
        case .done: return Theme.Palette.textPrimary
        case .today: return Theme.Palette.accent
        case .rest: return Theme.Palette.textPrimary.opacity(0.3)
        case .future: return Theme.Palette.textPrimary.opacity(0.25)
        }
    }
}

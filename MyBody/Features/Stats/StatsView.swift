import SwiftUI

/// 数据（Stats）。
/// TODO(阶段 6)：本周容量按肌群、近 4 周总容量趋势柱状、力量进步/PR 列表。
struct StatsView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            Text("数据")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Theme.Palette.textPrimary)
            Text("容量趋势与 PR 将在阶段 6 实现")
                .font(.system(size: 13))
                .foregroundStyle(Theme.Palette.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.background)
    }
}

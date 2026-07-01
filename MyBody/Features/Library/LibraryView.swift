import SwiftUI
import SwiftData

/// 动作库（Library）。
/// TODO(阶段 5)：搜索 + 肌群筛选 chips + 列表行 → 动作详情。
struct LibraryView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.s) {
                Text("动作库")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text("已内置 \(exercises.count) 个动作")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Palette.textSecondary)
                Text("搜索 / 筛选 / 详情将在阶段 5 实现")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Palette.textTertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Palette.background)
        }
    }
}

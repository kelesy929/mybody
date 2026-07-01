import SwiftUI
import SwiftData

/// 训练记录（Active Workout）。
/// TODO(阶段 2)：组表增删、重量/次数步进、完成勾选 + Haptic、组间休息倒计时、完成训练 → 评估。
struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Text("训练记录")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Theme.Palette.textPrimary)
            Text("\(session.splitType.displayName)日 · \(session.loggedExercises.count) 个动作")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Palette.textSecondary)
            Text("组表交互与组间休息将在阶段 2 实现")
                .font(.system(size: 13))
                .foregroundStyle(Theme.Palette.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.background)
        .navigationTitle("推日训练")
        .navigationBarTitleDisplayMode(.inline)
    }
}

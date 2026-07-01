import SwiftUI
import SwiftData
import MyBodyCore

/// 今日评估（核心：今天练够了吗）。规格 §3。
struct EvaluationView: View {
    let session: WorkoutSession
    @Binding var path: [WorkoutRoute]

    @Query private var settingsList: [UserSettings]
    private var settings: UserSettings? { settingsList.first }

    private var result: EvaluationResult {
        let target = settings?.weeklyVolumeTargetKg ?? 7000
        return TrainingEvaluator().evaluate(exercises: session.exerciseSnapshots, weeklyTarget: target)
    }

    var body: some View {
        let r = result
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ringAndVerdict(r).frame(maxWidth: .infinity)
                    statsGrid(r).padding(.top, 18)
                    reasonsSection(r).padding(.top, 22)
                    recommendationCard(r).padding(.top, 16)
                    PrimaryButton(title: "查看明日训练 →") { goTomorrow() }
                        .padding(.top, 18)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .background(Theme.Palette.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: 顶部

    private var header: some View {
        HStack {
            Button { path.removeAll() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Palette.textPrimary.opacity(0.7))
                    .frame(width: 38, height: 38)
                    .background(Theme.Palette.surfaceTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            Spacer()
            Text("今日评估").font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.Palette.textPrimary)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    // MARK: 进度环 + 判定

    private func ringAndVerdict(_ r: EvaluationResult) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().stroke(Theme.Palette.surfaceSecondary, lineWidth: 9)
                Circle()
                    .trim(from: 0, to: min(r.completionPct, 1))
                    .stroke(Theme.Palette.accent, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 3) {
                    Text(r.completionPctLabel)
                        .font(.system(size: 40, weight: .heavy)).tabularNumbers()
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Text("计划完成度").font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.Palette.textSecondary)
                }
            }
            .frame(width: 170, height: 170)
            .padding(.top, 14)

            Text(r.verdictTitle)
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(Theme.Palette.textPrimary)
                .padding(.top, 12)
            Text(r.verdictSubtitle)
                .font(.system(size: 13))
                .foregroundStyle(Theme.Palette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
                .padding(.top, 4)
        }
    }

    // MARK: 2×2 数据格

    private func statsGrid(_ r: EvaluationResult) -> some View {
        let doneSets = VolumeCalculator.doneSets(session.exerciseSnapshots)
        let planned = VolumeCalculator.plannedSets(session.exerciseSnapshots)
        let vol = VolumeCalculator.sessionVolume(session.exerciseSnapshots)
        let avgRPE = VolumeCalculator.averageRPE(session.exerciseSnapshots)
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            statCell(NumberFormat.grouped(Int(vol.rounded())), "总容量 kg", color: Theme.Palette.textPrimary)
            statCell("\(doneSets)/\(planned)", "完成 / 计划组", color: Theme.Palette.textPrimary)
            statCell(String(format: "%.1f", avgRPE), "平均 RPE", color: Theme.Palette.textPrimary)
            statCell(r.achievementPctLabel, "周容量目标达成", color: Theme.Palette.accent)
        }
    }

    private func statCell(_ value: String, _ label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 26, weight: .heavy)).tabularNumbers().foregroundStyle(color)
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.Palette.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Theme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.Palette.stroke, lineWidth: 1))
    }

    // MARK: 评估依据

    private func reasonsSection(_ r: EvaluationResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "评估依据")
            SurfaceCard(padding: 16) {
                VStack(spacing: 0) {
                    ForEach(Array(r.reasons.enumerated()), id: \.offset) { i, reason in
                        HStack(alignment: .top, spacing: 11) {
                            Circle().fill(Theme.Palette.accent).frame(width: 6, height: 6).padding(.top, 7)
                            Text(reason)
                                .font(.system(size: 13.5))
                                .foregroundStyle(Theme.Palette.textPrimary.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 12)
                        if i < r.reasons.count - 1 { Divider().overlay(Theme.Palette.strokeInner) }
                    }
                }
            }
        }
    }

    // MARK: 建议卡（青柠描边）

    private func recommendationCard(_ r: EvaluationResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("建议")
                .font(.system(size: 11, weight: .bold)).tracking(0.5).textCase(.uppercase)
                .foregroundStyle(Theme.Palette.accent)
            Text(r.recommendationTitle)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Theme.Palette.textPrimary)
            Text(r.recommendationText)
                .font(.system(size: 13.5))
                .foregroundStyle(Theme.Palette.textPrimary.opacity(0.7))
                .lineSpacing(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.heroGreen)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.Palette.accent.opacity(0.4), lineWidth: 1))
    }

    // MARK: 明日（阶段 ④ 实现真实编辑；当前先回今日）

    private func goTomorrow() {
        // TODO(阶段 4)：推入明日训练编辑页。当前先回到今日。
        path.removeAll()
    }
}

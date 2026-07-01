import SwiftUI

/// 动作详情（Detail）。从动作库或训练记录的「动作说明」推入。
/// 用 `dismiss` 返回，主按钮行为由调用方注入（训练中=返回，库中=加入今日训练）。
struct ExerciseDetailView: View {
    let exercise: Exercise
    var primaryTitle: String = "加入今日训练"
    var onPrimary: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    videoPlaceholder
                    tagRow.padding(.top, 14)
                    musclesCard.padding(.top, 16)
                    cuesSection.padding(.top, 22)
                    mistakesSection.padding(.top, 22)
                    prescriptionCard.padding(.top, 16)
                    if let onPrimary {
                        PrimaryButton(title: primaryTitle) { onPrimary() }
                            .padding(.top, 18)
                    }
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
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.Palette.textPrimary.opacity(0.7))
                    .frame(width: 38, height: 38)
                    .background(Theme.Palette.surfaceTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            Spacer()
            Text(exercise.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.Palette.textPrimary)
                .lineLimit(1)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }

    // MARK: 视频占位（预留 AVPlayer 接口）

    private var videoPlaceholder: some View {
        ZStack {
            StripePattern()
            Text("[ 动作示范视频 ]")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.Palette.textTertiary)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Theme.Palette.stroke, lineWidth: 1))
    }

    // MARK: 标签（主肌群 / 器械 / 难度）

    private var tagRow: some View {
        HStack(spacing: 8) {
            tag(exercise.muscleGroup.displayName, color: Theme.Palette.textPrimary.opacity(0.7))
            tag(exercise.equipment, color: Theme.Palette.textPrimary.opacity(0.7))
            tag(exercise.difficulty.displayName, color: Theme.Palette.accent)
        }
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 11).padding(.vertical, 6)
            .background(Theme.Palette.surfaceTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Theme.Palette.stroke, lineWidth: 1))
    }

    // MARK: 主要 / 协同肌群

    private var musclesCard: some View {
        SurfaceCard {
            HStack(spacing: 16) {
                muscleBlock("主要肌群", exercise.primaryMuscle, color: Theme.Palette.textPrimary)
                muscleBlock("协同肌群", exercise.synergistsLabel, color: Theme.Palette.textPrimary.opacity(0.7))
            }
        }
    }

    private func muscleBlock(_ label: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(text: label)
            Text(value).font(.system(size: 15, weight: .bold)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 动作要点（编号）

    private var cuesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "动作要点")
            SurfaceCard {
                VStack(spacing: 0) {
                    ForEach(Array(exercise.cues.enumerated()), id: \.offset) { i, cue in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(i + 1)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.Palette.textPrimary)
                                .frame(width: 24, height: 24)
                                .background(Theme.Palette.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            Text(cue)
                                .font(.system(size: 13.5))
                                .foregroundStyle(Theme.Palette.textPrimary.opacity(0.82))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 11)
                        if i < exercise.cues.count - 1 { Divider().overlay(Theme.Palette.strokeInner) }
                    }
                }
            }
        }
    }

    // MARK: 常见错误（红 ✕）

    private var mistakesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "常见错误")
            SurfaceCard {
                VStack(spacing: 0) {
                    ForEach(Array(exercise.mistakes.enumerated()), id: \.offset) { i, mk in
                        HStack(alignment: .top, spacing: 11) {
                            Text("✕").font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.Palette.danger)
                            Text(mk)
                                .font(.system(size: 13.5))
                                .foregroundStyle(Theme.Palette.textPrimary.opacity(0.78))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 11)
                        if i < exercise.mistakes.count - 1 { Divider().overlay(Theme.Palette.strokeInner) }
                    }
                }
            }
        }
    }

    // MARK: 进阶处方（青柠卡）

    private var prescriptionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("进阶处方")
                .font(.system(size: 11, weight: .bold)).tracking(0.5).textCase(.uppercase)
                .foregroundStyle(Theme.Palette.accent)
            Text(exercise.prescription)
                .font(.system(size: 14))
                .foregroundStyle(Theme.Palette.textPrimary.opacity(0.82))
                .lineSpacing(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.heroGreen)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Theme.Palette.accent.opacity(0.18), lineWidth: 1))
    }
}

/// 条纹占位底纹（视频/缩略图占位）。
struct StripePattern: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let step: CGFloat = 14
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.Palette.surfaceSecondary))
                var x: CGFloat = -size.height
                while x < size.width {
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x + size.height, y: size.height))
                    p.addLine(to: CGPoint(x: x + size.height + step / 2, y: size.height))
                    p.addLine(to: CGPoint(x: x + step / 2, y: 0))
                    p.closeSubpath()
                    ctx.fill(p, with: .color(.black.opacity(0.04)))
                    x += step
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

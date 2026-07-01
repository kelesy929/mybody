import SwiftUI
import SwiftData

/// 数据（Stats）。规格 §7。
struct StatsView: View {
    @Query private var sessions: [WorkoutSession]
    @State private var vm = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("数据").font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(Theme.Palette.textPrimary)
                        .padding(.bottom, 2)

                    if !vm.hasData {
                        emptyHint
                    }
                    muscleCard
                    trendCard
                    prCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Theme.Palette.background)
        }
        .onAppear { vm.refresh(sessions: sessions) }
        .onChange(of: sessions) { vm.refresh(sessions: sessions) }
    }

    private var emptyHint: some View {
        SurfaceCard {
            Text("完成一次训练后，这里会出现你的容量、趋势与个人纪录。")
                .font(.system(size: 13))
                .foregroundStyle(Theme.Palette.textSecondary)
        }
    }

    // MARK: 本周容量按肌群

    private var muscleCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("本周容量 · 按肌群").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                ForEach(vm.muscleBars) { m in
                    MuscleVolumeBar(name: m.name, current: m.current, target: m.target)
                        .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: 每周总容量趋势

    private var trendCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("每周总容量趋势").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(vm.trend) { t in
                        VStack(spacing: 8) {
                            Text(t.valueLabel).font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.Palette.textSecondary)
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(t.id == vm.trend.last?.id ? Theme.Palette.accent : Theme.Palette.surfaceSecondary)
                                .frame(height: max(4, CGFloat(t.ratio) * 100))
                            Text(t.label).font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.Palette.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140)
            }
        }
    }

    // MARK: 力量进步 · PR

    private var prCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("力量进步 · 个人纪录").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .padding(.bottom, 8)
                if vm.prs.isEmpty {
                    Text("暂无纪录").font(.system(size: 13)).foregroundStyle(Theme.Palette.textTertiary)
                        .padding(.vertical, 6)
                } else {
                    ForEach(Array(vm.prs.enumerated()), id: \.element.id) { i, pr in
                        HStack {
                            Text(pr.name).font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Theme.Palette.textPrimary)
                            Spacer()
                            Text(pr.value).font(.system(size: 18, weight: .heavy)).tabularNumbers()
                                .foregroundStyle(Theme.Palette.textPrimary)
                            Text(pr.delta).font(.system(size: 12, weight: .bold))
                                .foregroundStyle(pr.up ? Theme.Palette.accent : Theme.Palette.textTertiary)
                                .frame(width: 74, alignment: .trailing)
                        }
                        .padding(.vertical, 13)
                        if i < vm.prs.count - 1 { Divider().overlay(Theme.Palette.strokeInner) }
                    }
                }
            }
        }
    }
}

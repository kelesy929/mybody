import SwiftUI
import SwiftData
import MyBodyCore

/// 今日总览（Home）。训练流程从这里推入全屏。
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var sessions: [WorkoutSession]
    @Query private var settingsList: [UserSettings]

    @State private var vm = TodayViewModel()
    @State private var path: [WorkoutRoute] = []

    private var settings: UserSettings? { settingsList.first }
    /// 今日可开始的会话（planned/active）。
    private var todaySession: WorkoutSession? {
        sessions.first { Calendar.current.isDateInToday($0.date) && $0.status != .done }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    heroCard
                    weekStrip
                    volumeCard
                    if let last = vm.lastSession { lastSessionCard(last) }
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.s)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .background(Theme.Palette.background)
            .navigationTitle("")
            .toolbar { toolbarHeader }
            .navigationDestination(for: WorkoutRoute.self) { route in
                switch route {
                case .active(let s):
                    ActiveWorkoutView(session: s, path: $path)
                case .evaluation(let s):
                    EvaluationView(session: s, path: $path)
                case .tomorrow(let s):
                    TomorrowView(todaySession: s, path: $path)
                case .detail(let ex):
                    ExerciseDetailView(exercise: ex, primaryTitle: "返回训练",
                                       onPrimary: { if !path.isEmpty { path.removeLast() } })
                }
            }
        }
        .onAppear { refresh() }
        .onChange(of: sessions) { refresh() }
    }

    private func refresh() {
        vm.refresh(sessions: sessions, settings: settings)
    }

    // MARK: 顶部（星期+日期，右上角头像）

    @ToolbarContentBuilder
    private var toolbarHeader: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.dateLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Palette.textSecondary)
                Text(vm.greeting)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Theme.Palette.textPrimary)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Text("凯")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.Palette.accent)
                .frame(width: 42, height: 42)
                .background(Theme.Palette.surfaceTertiary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: 训练计划 Hero 卡

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SplitTag(text: vm.hero.splitTag,
                         background: vm.hero.isPull ? Theme.Palette.accentInfo : Theme.Palette.accent)
                Spacer()
                Text(vm.hero.cycleLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            Text(vm.hero.muscles)
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(Theme.Palette.textPrimary)
                .padding(.top, 14)
            Text(vm.hero.meta)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.Palette.textSecondary)
                .padding(.top, 4)

            if vm.hero.hasSession {
                PrimaryButton(title: "开始训练", accessibilityID: "start_workout") { startWorkout() }
                    .padding(.top, 18)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(vm.hero.isPull ? Theme.Palette.heroBlue : Theme.Palette.heroGreen)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous)
                .stroke(Theme.Palette.accent.opacity(0.18), lineWidth: 1))
    }

    // MARK: 本周条

    private var weekStrip: some View {
        SurfaceCard {
            VStack(spacing: 14) {
                HStack {
                    Text("本周").font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Spacer()
                    Text(vm.streakLabel)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.Palette.accent)
                }
                HStack {
                    ForEach(vm.weekDays) { d in
                        Spacer(minLength: 0)
                        WeekDot(label: d.label, state: d.state, todayMark: d.mark)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    // MARK: 本周训练容量

    private var volumeCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("本周训练容量").font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.Palette.textPrimary)
                    Spacer()
                    Text("组数 / 周目标")
                        .font(.system(size: 11)).foregroundStyle(Theme.Palette.textTertiary)
                }
                ForEach(vm.muscleBars) { m in
                    MuscleVolumeBar(name: m.name, current: m.current, target: m.target)
                        .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: 上次同分化摘要

    private func lastSessionCard(_ last: TodayViewModel.LastSession) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: last.dateLabel)
                HStack(spacing: 20) {
                    statBlock(last.volume, "总容量 kg", color: Theme.Palette.textPrimary)
                    statBlock("\(last.doneSets)", "完成组数", color: Theme.Palette.textPrimary)
                    statBlock(last.prValue, last.prName, color: Theme.Palette.accent)
                }
            }
        }
    }

    private func statBlock(_ value: String, _ label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 22, weight: .heavy)).tabularNumbers()
                .foregroundStyle(color)
            Text(label).font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Palette.textTertiary)
        }
    }

    // MARK: 动作

    private func startWorkout() {
        guard let session = todaySession else { return }
        session.status = .active
        path.append(.active(session))
    }
}

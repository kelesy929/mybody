import SwiftUI
import SwiftData
import MyBodyCore

/// 训练记录（Active Workout）。
struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    @Binding var path: [WorkoutRoute]

    @Environment(\.modelContext) private var context
    @Query private var settingsList: [UserSettings]

    @State private var vm: ActiveWorkoutViewModel?

    private var settings: UserSettings? { settingsList.first }

    var body: some View {
        Group {
            if let vm {
                content(vm)
            } else {
                Color.clear
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background(Theme.Palette.background)
        .onAppear {
            if vm == nil {
                let model = ActiveWorkoutViewModel(session: session, settings: settings, context: context)
                model.startClock()
                vm = model
            }
        }
        // 注意：不在 onDisappear 停表——推入「动作说明」详情时本页也会 disappear，
        // 训练计时应继续。停表/保存只在显式退出（X）或完成训练时进行。
    }

    private func content(_ vm: ActiveWorkoutViewModel) -> some View {
        VStack(spacing: 0) {
            header(vm)
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(session.orderedExercises.enumerated()), id: \.element.persistentModelID) { idx, logged in
                        ExerciseCardView(
                            logged: logged,
                            index: idx,
                            showRPE: vm.showRPE,
                            unit: logged.exercise?.isEachSide == true ? "\(vm.unit.displayName)/侧" : vm.unit.displayName,
                            isExpanded: vm.isExpanded(logged),
                            isEachSide: logged.exercise?.isEachSide ?? false,
                            weightStep: logged.exercise?.weightStep ?? 2.5,
                            onExpand: { withAnimation(.easeInOut(duration: 0.2)) { vm.toggleExpand(logged) } },
                            onOpenDetail: { if let ex = logged.exercise { path.append(.detail(ex)) } },
                            onAddSet: { vm.addSet(to: logged) },
                            onWeight: { set, dir in vm.changeWeight(set, step: logged.exercise?.weightStep ?? 2.5, dir) },
                            onReps: { set, d in vm.changeReps(set, d) },
                            onToggle: { set in vm.toggleDone(set) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            bottomBar(vm)
        }
    }

    // MARK: 顶部（X / 标题 + 进度 / 计时器）

    private func header(_ vm: ActiveWorkoutViewModel) -> some View {
        HStack {
            Button { vm.stopClock(persist: true); path.removeAll() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.Palette.textPrimary.opacity(0.7))
                    .frame(width: 38, height: 38)
                    .background(Theme.Palette.surfaceTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Spacer()
            VStack(spacing: 2) {
                Text("\(session.splitType.displayName)日训练")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text(vm.progressLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            Spacer()

            HStack(spacing: 7) {
                Circle().fill(Theme.Palette.accent).frame(width: 7, height: 7)
                Text(vm.elapsedLabel)
                    .font(.system(size: 15, weight: .heavy))
                    .tabularNumbers()
                    .foregroundStyle(Theme.Palette.textPrimary)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Theme.Palette.surfaceTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.Palette.stroke).frame(height: 1)
        }
    }

    // MARK: 底部（组间休息条 + 完成训练）

    private func bottomBar(_ vm: ActiveWorkoutViewModel) -> some View {
        VStack(spacing: 10) {
            if vm.isResting {
                HStack(spacing: 12) {
                    Text("组间休息")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.Palette.textSecondary)
                    Text(vm.restLabel)
                        .font(.system(size: 18, weight: .heavy))
                        .tabularNumbers()
                        .foregroundStyle(Theme.Palette.accent)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.Palette.surfaceSecondary)
                            Capsule().fill(Theme.Palette.accent)
                                .frame(width: geo.size.width * vm.restProgress)
                        }
                    }
                    .frame(height: 6)
                    Button("+15s") { vm.addRest() }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.Palette.textPrimary.opacity(0.7))
                    Button("跳过") { vm.skipRest() }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.Palette.accent)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            PrimaryButton(title: "完成训练 · 评估今天") { finish(vm) }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Theme.Palette.surface)
        .overlay(alignment: .top) { Rectangle().fill(Theme.Palette.stroke).frame(height: 1) }
        .animation(.easeInOut(duration: 0.2), value: vm.isResting)
    }

    private func finish(_ vm: ActiveWorkoutViewModel) {
        vm.finish()
        // 用评估页替换训练页：从评估返回时直接回到今日。
        path = [.evaluation(session)]
    }
}

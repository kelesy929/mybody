import Foundation
import SwiftData
import MyBodyCore

/// 训练记录页的状态与逻辑：运行计时器、组间休息倒计时、组表编辑。
@Observable
@MainActor
final class ActiveWorkoutViewModel {
    let session: WorkoutSession
    private let settings: UserSettings?
    private let context: ModelContext

    var elapsedSec: Int
    var restRemaining: Int?                  // nil = 当前无休息
    var expandedExerciseID: PersistentIdentifier?

    private var workoutTimer: Timer?
    private var restTimer: Timer?

    var showRPE: Bool { settings?.showRPE ?? true }
    var unit: WeightUnit { settings?.unit ?? .kg }
    private var restDuration: Int { settings?.restDurationSec ?? 90 }

    init(session: WorkoutSession, settings: UserSettings?, context: ModelContext) {
        self.session = session
        self.settings = settings
        self.context = context
        self.elapsedSec = session.durationSec
        self.expandedExerciseID = session.orderedExercises.first?.persistentModelID
    }

    // MARK: 计时器

    func startClock() {
        guard workoutTimer == nil else { return }
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.elapsedSec += 1 }
        }
    }

    /// 离开页面时调用：停表并把已用时长写回会话。
    func stopClock(persist: Bool = true) {
        workoutTimer?.invalidate(); workoutTimer = nil
        restTimer?.invalidate(); restTimer = nil
        if persist {
            session.durationSec = elapsedSec
            try? context.save()
        }
    }

    // MARK: 展示派生

    var elapsedLabel: String { Self.mmss(elapsedSec) }
    var restLabel: String { restRemaining.map(Self.mmss) ?? "" }
    var restProgress: Double {
        guard let r = restRemaining, restDuration > 0 else { return 0 }
        return min(1, Double(r) / Double(restDuration))
    }
    var isResting: Bool { restRemaining != nil }

    var progressLabel: String {
        let exDone = session.loggedExercises.filter { $0.isAllDone }.count
        let setsDone = session.loggedExercises.reduce(0) { $0 + $1.doneCount }
        return "\(exDone)/\(session.loggedExercises.count) 动作 · \(setsDone) 组完成"
    }

    // MARK: 展开/收起

    func isExpanded(_ ex: LoggedExercise) -> Bool { expandedExerciseID == ex.persistentModelID }
    func toggleExpand(_ ex: LoggedExercise) {
        expandedExerciseID = isExpanded(ex) ? nil : ex.persistentModelID
    }

    // MARK: 组表编辑（直接改 @Model，SwiftData 主上下文自动落库）

    func changeWeight(_ set: SetEntry, step: Double, _ direction: Double) {
        set.weight = max(0, ((set.weight + direction * step) * 100).rounded() / 100)
        Haptics.light()
    }

    func changeReps(_ set: SetEntry, _ delta: Int) {
        set.reps = max(0, set.reps + delta)
        Haptics.light()
    }

    /// 勾选「完成」→ Haptic + 自动开始组间休息倒计时。
    func toggleDone(_ set: SetEntry) {
        set.isDone.toggle()
        if set.isDone {
            Haptics.success()
            startRest()
        }
    }

    /// 「+ 加一组」复制上一组（重量/次数沿用，未完成）。
    func addSet(to ex: LoggedExercise) {
        let last = ex.orderedSets.last
        let newSet = SetEntry(
            weight: last?.weight ?? 0,
            reps: last?.reps ?? ex.targetRepLow,
            rpe: last?.rpe ?? 8,
            isDone: false,
            orderIndex: (ex.sets.map(\.orderIndex).max() ?? -1) + 1)
        newSet.loggedExercise = ex
        context.insert(newSet)
        Haptics.light()
    }

    // MARK: 组间休息

    private func startRest() {
        restTimer?.invalidate()
        restRemaining = restDuration
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.restTick() }
        }
    }

    private func restTick() {
        guard let r = restRemaining else { return }
        if r <= 1 {
            restRemaining = nil
            restTimer?.invalidate(); restTimer = nil
        } else {
            restRemaining = r - 1
        }
    }

    func addRest() { restRemaining = (restRemaining ?? 0) + 15 }
    func skipRest() {
        restRemaining = nil
        restTimer?.invalidate(); restTimer = nil
    }

    // MARK: 完成训练

    func finish() {
        session.durationSec = elapsedSec
        session.status = .done
        stopClock(persist: false)
        try? context.save()
    }

    static func mmss(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}

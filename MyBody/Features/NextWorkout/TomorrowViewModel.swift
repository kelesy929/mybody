import Foundation
import SwiftData
import MyBodyCore

/// 明日训练页：生成默认推荐 + 就地编辑（增删/调组数/加动作），保存写入 WorkoutPlan。
@Observable
@MainActor
final class TomorrowViewModel {

    struct Item: Identifiable {
        let id = UUID()
        var exerciseID: PersistentIdentifier?
        var name: String
        var sets: Int
        var repLow: Int
        var repHigh: Int
        var note: String
        var isProgression: Bool
    }

    private(set) var split: SplitType
    var items: [Item]
    let tomorrowDate: Date
    private(set) var whyText: String

    private let planner = NextWorkoutPlanner()

    init(todaySession: WorkoutSession, allExercises: [Exercise],
         history: [WorkoutSession], settings: UserSettings?, now: Date = Date()) {

        let cal = Calendar.current
        self.tomorrowDate = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now

        // 明日分化：从今日分化按 PPL 轮换，并满足 48h 恢复约束。
        let done = history.filter { $0.status == .done }
        let recent = done.map { RecentSession(split: $0.splitType, date: $0.date) }
        let today = todaySession.splitType
        let tomorrow = NextWorkoutPlanner().recommendedSplit(today: today, recent: recent, now: now)
        self.split = tomorrow

        // 「为什么是这个分化」解释。
        self.whyText =
            "今天\(today.displayName)日已重度刺激\(today.muscleHeadline)，它们需要约 48 小时恢复。" +
            "明日转向\(tomorrow.muscleHeadline)（\(tomorrow.displayName)），" +
            "让\(today.displayName)类肌群在不影响表现的前提下超量恢复——这正是 Push / Pull / Legs 分化的核心。"

        // 生成默认动作 + 渐进超负荷判定。
        let byName = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.name, $0) })
        var built: [Item] = []
        for scheme in DefaultPlans.schemes(for: tomorrow) {
            guard let ex = byName[scheme.name] else { continue }
            let (note, isProg) = Self.progressionNote(
                for: ex, targetRepHigh: scheme.repHigh, history: done,
                unit: settings?.unit ?? .kg, planner: planner)
            built.append(Item(exerciseID: ex.persistentModelID, name: ex.name,
                              sets: scheme.sets, repLow: scheme.repLow, repHigh: scheme.repHigh,
                              note: note, isProgression: isProg))
        }
        self.items = built
    }

    // MARK: 派生

    var totalSets: Int { items.reduce(0) { $0 + $1.sets } }
    var metaLabel: String {
        "\(items.count) 个动作 · \(totalSets) 组 · 约 \(Int((Double(totalSets) * 3.85).rounded())) 分钟"
    }
    var splitTag: String { "\(split.displayName) · \(split.rawLabel)" }
    var isPull: Bool { split == .pull }

    // MARK: 编辑

    func incSets(_ item: Item) { mutate(item) { $0.sets += 1 } }
    func decSets(_ item: Item) { mutate(item) { $0.sets = max(1, $0.sets - 1) } }
    func remove(_ item: Item) { items.removeAll { $0.id == item.id } }

    private func mutate(_ item: Item, _ change: (inout Item) -> Void) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        change(&items[i])
    }

    /// 可添加的动作：库中尚未加入本计划的（半屏 sheet 用）。
    func availableToAdd(from all: [Exercise]) -> [Exercise] {
        let added = Set(items.map(\.name))
        return all.filter { !added.contains($0.name) }
    }

    func add(_ ex: Exercise) {
        guard !items.contains(where: { $0.name == ex.name }) else { return }
        items.append(Item(exerciseID: ex.persistentModelID, name: ex.name,
                          sets: 3, repLow: 8, repHigh: 12,
                          note: ex.primaryMuscle, isProgression: false))
    }

    // MARK: 保存

    /// 写入 WorkoutPlan(date: 明天)。先删掉同一天的旧计划避免重复。
    func save(context: ModelContext) {
        let cal = Calendar.current
        let day = cal.startOfDay(for: tomorrowDate)
        let existing = (try? context.fetch(FetchDescriptor<WorkoutPlan>())) ?? []
        for p in existing where cal.isDate(p.date, inSameDayAs: day) {
            context.delete(p)
        }

        let plan = WorkoutPlan(date: tomorrowDate, splitType: split)
        context.insert(plan)
        for (i, item) in items.enumerated() {
            let ex = item.exerciseID.flatMap { id in
                (try? context.fetch(FetchDescriptor<Exercise>()))?.first { $0.persistentModelID == id }
            }
            let pi = PlanItem(exercise: ex, nameSnapshot: item.name,
                              sets: item.sets, repLow: item.repLow, repHigh: item.repHigh,
                              note: item.note, isProgression: item.isProgression, orderIndex: i)
            pi.plan = plan
            context.insert(pi)
        }
        try? context.save()
    }

    // MARK: 渐进超负荷

    /// 在历史里找该动作最近一次的最后工作组，判定是否加重量。
    private static func progressionNote(for ex: Exercise, targetRepHigh: Int,
                                        history: [WorkoutSession], unit: WeightUnit,
                                        planner: NextWorkoutPlanner) -> (String, Bool) {
        let logged = history
            .sorted { $0.date > $1.date }
            .flatMap { $0.orderedExercises }
            .first { $0.exercise?.name == ex.name }

        guard let last = logged?.orderedSets.last(where: { $0.isDone }) ?? logged?.orderedSets.last else {
            return (ex.primaryMuscle, false)   // 无历史 → 维持，显示肌群提示
        }

        let perf = ExercisePerformance(
            name: ex.name, weightStep: ex.weightStep,
            lastWeight: last.weight, lastReps: last.reps,
            targetRepHigh: targetRepHigh, lastRPE: last.rpe)
        let s = planner.progression(for: perf, unit: unit)
        return s.isProgression ? (s.note, true) : (ex.primaryMuscle, false)
    }
}

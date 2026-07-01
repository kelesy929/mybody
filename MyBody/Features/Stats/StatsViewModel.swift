import Foundation
import MyBodyCore

/// 数据页派生统计（纯转换，输入 SwiftData 会话数组）。
@Observable
final class StatsViewModel {

    struct MuscleBar: Identifiable { let id = UUID(); let name: String; let current: Int; let target: Int }
    struct TrendBar: Identifiable { let id = UUID(); let label: String; let valueLabel: String; let ratio: Double }
    struct PR: Identifiable { let id = UUID(); let name: String; let value: String; let delta: String; let up: Bool }

    private(set) var muscleBars: [MuscleBar] = []
    private(set) var trend: [TrendBar] = []
    private(set) var prs: [PR] = []
    private(set) var hasData = false

    private let weeklyMuscleTarget: [MuscleGroup: Int] =
        [.chest: 18, .back: 18, .legs: 16, .shoulders: 18, .arms: 14, .core: 12]

    func refresh(sessions: [WorkoutSession], now: Date = Date()) {
        let cal = weekCalendar()
        let done = sessions.filter { $0.status == .done }
        hasData = done.contains { s in s.loggedExercises.contains { $0.sets.contains(where: \.isDone) } }

        buildMuscleBars(done: done, now: now, cal: cal)
        buildTrend(done: done, now: now, cal: cal)
        buildPRs(done: done, now: now, cal: cal)
    }

    // MARK: 本周按肌群

    private func buildMuscleBars(done: [WorkoutSession], now: Date, cal: Calendar) {
        let monday = startOfWeek(now, cal: cal)
        var byMuscle: [MuscleGroup: Int] = [:]
        for s in done where s.date >= monday {
            for ex in s.loggedExercises {
                guard let g = ex.exercise?.muscleGroup else { continue }
                byMuscle[g, default: 0] += ex.sets.filter(\.isDone).count
            }
        }
        let order: [MuscleGroup] = [.chest, .back, .legs, .shoulders, .arms]
        muscleBars = order.map { MuscleBar(name: $0.displayName, current: byMuscle[$0] ?? 0, target: weeklyMuscleTarget[$0] ?? 16) }
    }

    // MARK: 近 4 周总容量趋势

    private func buildTrend(done: [WorkoutSession], now: Date, cal: Calendar) {
        let thisMonday = startOfWeek(now, cal: cal)
        let labels = ["4 周前", "3 周前", "上周", "本周"]
        var volumes: [Double] = []
        for weekBack in stride(from: 3, through: 0, by: -1) {
            let start = cal.date(byAdding: .day, value: -7 * weekBack, to: thisMonday)!
            let end = cal.date(byAdding: .day, value: 7, to: start)!
            let vol = done.filter { $0.date >= start && $0.date < end }
                .reduce(0.0) { $0 + VolumeCalculator.sessionVolume($1.exerciseSnapshots) }
            volumes.append(vol)
        }
        let maxVol = max(volumes.max() ?? 0, 1)
        trend = zip(labels, volumes).map { label, vol in
            TrendBar(label: label,
                     valueLabel: vol >= 1000 ? String(format: "%.1ft", vol / 1000) : "\(Int(vol))",
                     ratio: vol / maxVol)
        }
    }

    // MARK: 力量进步 / PR

    private func buildPRs(done: [WorkoutSession], now: Date, cal: Calendar) {
        let monday = startOfWeek(now, cal: cal)
        struct Agg { var overall = 0.0; var thisWeek = 0.0; var prev = 0.0 }
        var byName: [String: Agg] = [:]

        for s in done {
            let inWeek = s.date >= monday
            for ex in s.loggedExercises {
                guard let name = ex.exercise?.name else { continue }
                for set in ex.sets where set.isDone {
                    var a = byName[name] ?? Agg()
                    a.overall = max(a.overall, set.weight)
                    if inWeek { a.thisWeek = max(a.thisWeek, set.weight) }
                    else { a.prev = max(a.prev, set.weight) }
                    byName[name] = a
                }
            }
        }

        prs = byName
            .filter { $0.value.overall > 0 }
            .sorted { $0.value.overall > $1.value.overall }
            .map { name, a in
                let improved = a.thisWeek > a.prev
                let delta: String
                if improved {
                    delta = a.prev > 0 ? "本周 ↑\(NumberFormat.trim(a.thisWeek - a.prev))" : "本周 新纪录"
                } else {
                    delta = "稳定"
                }
                return PR(name: name, value: "\(NumberFormat.trim(a.overall)) kg", delta: delta, up: improved)
            }
    }

    // MARK: helpers

    private func weekCalendar() -> Calendar {
        var c = Calendar(identifier: .gregorian); c.firstWeekday = 2; return c
    }
    private func startOfWeek(_ date: Date, cal: Calendar) -> Date {
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? cal.startOfDay(for: date)
    }
}

import Foundation

/// 容量与有效组数计算（规格 §A）。纯函数，无状态。
public enum VolumeCalculator {

    /// 单组容量 = weight × reps ×（单侧动作则 ×2）。
    public static func setVolume(weight: Double, reps: Int, isEachSide: Bool) -> Double {
        weight * Double(reps) * (isEachSide ? 2 : 1)
    }

    /// 一个动作（仅 isDone 组）的容量。
    public static func exerciseVolume(_ ex: LoggedExerciseSnapshot) -> Double {
        ex.sets.reduce(0) { acc, s in
            acc + (s.isDone ? setVolume(weight: s.weight, reps: s.reps, isEachSide: ex.isEachSide) : 0)
        }
    }

    /// 会话总容量（所有动作的 isDone 组求和）。
    public static func sessionVolume(_ exercises: [LoggedExerciseSnapshot]) -> Double {
        exercises.reduce(0) { $0 + exerciseVolume($1) }
    }

    /// 某动作的「有效组数」：isDone 且 rpe ≥ effectiveSetRPE（RIR ≤ 3）。
    public static func effectiveSets(_ ex: LoggedExerciseSnapshot, config: EvaluationConfig = .default) -> Int {
        ex.sets.filter { $0.isDone && $0.rpe >= config.effectiveSetRPE }.count
    }

    /// 会话内每个肌群的有效组数。
    public static func effectiveSetsByMuscle(_ exercises: [LoggedExerciseSnapshot],
                                             config: EvaluationConfig = .default) -> [MuscleGroup: Int] {
        var result: [MuscleGroup: Int] = [:]
        for ex in exercises {
            result[ex.muscleGroup, default: 0] += effectiveSets(ex, config: config)
        }
        return result
    }

    /// 完成组数（isDone 的工作组总数）。
    public static func doneSets(_ exercises: [LoggedExerciseSnapshot]) -> Int {
        exercises.reduce(0) { $0 + $1.sets.filter { $0.isDone }.count }
    }

    /// 计划组数（各动作 targetSets 之和）。
    public static func plannedSets(_ exercises: [LoggedExerciseSnapshot]) -> Int {
        exercises.reduce(0) { $0 + $1.targetSets }
    }

    /// 已完成组的平均 RPE（无完成组时返回 0）。
    public static func averageRPE(_ exercises: [LoggedExerciseSnapshot]) -> Double {
        let done = exercises.flatMap { $0.sets }.filter { $0.isDone }
        guard !done.isEmpty else { return 0 }
        return done.reduce(0) { $0 + $1.rpe } / Double(done.count)
    }
}

import Foundation
import MyBodyCore

// 把 SwiftData @Model 映射成 MyBodyCore 的纯值类型，再交给算法。
// 这样核心逻辑不依赖 SwiftData，可在 Windows 上单测。

extension SetEntry {
    var snapshot: SetSnapshot {
        SetSnapshot(weight: weight, reps: reps, rpe: rpe, isDone: isDone)
    }
}

extension LoggedExercise {
    var snapshot: LoggedExerciseSnapshot {
        LoggedExerciseSnapshot(
            name: exercise?.name ?? "",
            muscleGroup: exercise?.muscleGroup ?? .chest,
            isEachSide: exercise?.isEachSide ?? false,
            weightStep: exercise?.weightStep ?? 2.5,
            targetSets: targetSets,
            targetRepHigh: targetRepHigh,
            sets: orderedSets.map(\.snapshot)
        )
    }
}

extension WorkoutSession {
    var exerciseSnapshots: [LoggedExerciseSnapshot] {
        orderedExercises.map(\.snapshot)
    }
}

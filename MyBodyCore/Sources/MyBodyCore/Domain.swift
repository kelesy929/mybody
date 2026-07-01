import Foundation

// MARK: - 纯逻辑用的值类型（DTO）
// App 层把 SwiftData @Model 映射成这些 struct 再交给算法，
// 从而让 MyBodyCore 不依赖 SwiftData、可在 Windows 上单测。

/// 一个工作组的最小快照。
public struct SetSnapshot: Sendable, Equatable {
    public let weight: Double
    public let reps: Int
    public let rpe: Double
    public let isDone: Bool

    public init(weight: Double, reps: Int, rpe: Double, isDone: Bool) {
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.isDone = isDone
    }
}

/// 一个动作在某次训练中的快照（含目标与各组）。
public struct LoggedExerciseSnapshot: Sendable, Equatable {
    public let name: String
    public let muscleGroup: MuscleGroup
    public let isEachSide: Bool          // 单侧动作，容量 ×2
    public let weightStep: Double
    public let targetSets: Int
    public let targetRepHigh: Int
    public let sets: [SetSnapshot]

    public init(name: String, muscleGroup: MuscleGroup, isEachSide: Bool, weightStep: Double,
                targetSets: Int, targetRepHigh: Int, sets: [SetSnapshot]) {
        self.name = name
        self.muscleGroup = muscleGroup
        self.isEachSide = isEachSide
        self.weightStep = weightStep
        self.targetSets = targetSets
        self.targetRepHigh = targetRepHigh
        self.sets = sets
    }
}

/// 近期一次会话（仅恢复约束需要的字段）。
public struct RecentSession: Sendable, Equatable {
    public let split: SplitType
    public let date: Date

    public init(split: SplitType, date: Date) {
        self.split = split
        self.date = date
    }
}

/// 某动作上一次的表现（渐进超负荷判定输入）。
public struct ExercisePerformance: Sendable, Equatable {
    public let name: String
    public let weightStep: Double
    public let lastWeight: Double        // 上次最后一个工作组的重量
    public let lastReps: Int             // 上次最后一个工作组的次数
    public let targetRepHigh: Int        // 目标次数区间上限
    public let lastRPE: Double           // 上次最后一个工作组的 RPE

    public init(name: String, weightStep: Double, lastWeight: Double,
                lastReps: Int, targetRepHigh: Int, lastRPE: Double) {
        self.name = name
        self.weightStep = weightStep
        self.lastWeight = lastWeight
        self.lastReps = lastReps
        self.targetRepHigh = targetRepHigh
        self.lastRPE = lastRPE
    }
}

/// 渐进超负荷建议。
public struct ProgressionSuggestion: Sendable, Equatable {
    public let name: String
    public let recommendedWeight: Double
    public let isProgression: Bool       // true → UI 青柠标注
    public let note: String              // 如 "↑ 62.5kg +2.5"

    public init(name: String, recommendedWeight: Double, isProgression: Bool, note: String) {
        self.name = name
        self.recommendedWeight = recommendedWeight
        self.isProgression = isProgression
        self.note = note
    }
}

// MARK: - 数字格式化小工具（不依赖 Locale，跨平台一致）

public enum NumberFormat {
    /// 去掉无意义的 .0：62.5 → "62.5"，60.0 → "60"。
    public static func trim(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value.rounded()))
        }
        return String(format: "%g", value)
    }

    /// 千分位分组（手写，避免 Locale 依赖）：7420 → "7,420"。
    public static func grouped(_ value: Int) -> String {
        let negative = value < 0
        var digits = Array(String(abs(value)))
        var result = ""
        var count = 0
        while let d = digits.popLast() {
            if count > 0 && count % 3 == 0 { result = "," + result }
            result = String(d) + result
            count += 1
        }
        return (negative ? "-" : "") + result
    }
}

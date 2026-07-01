import Foundation

/// 明日训练推荐（规格 §C）。纯逻辑，可单测。
public struct NextWorkoutPlanner: Sendable {
    public let config: EvaluationConfig
    /// 分化轮换顺序，默认 PPL。
    public let rotation: [SplitType]

    public init(config: EvaluationConfig = .default, rotation: [SplitType] = [.push, .pull, .legs]) {
        self.config = config
        self.rotation = rotation.isEmpty ? [.push, .pull, .legs] : rotation
    }

    // MARK: - 分化轮换

    /// 今日分化 → 明日分化（Push→Pull→Legs→Push…）。
    public func nextSplit(after current: SplitType) -> SplitType {
        guard let idx = rotation.firstIndex(of: current) else { return rotation[0] }
        return rotation[(idx + 1) % rotation.count]
    }

    // MARK: - 肌群映射

    /// 该分化「展示用」的全部参与肌群（含作为协同的臂）。
    public func muscles(for split: SplitType) -> Set<MuscleGroup> {
        switch split {
        case .push: return [.chest, .shoulders, .arms]   // 三头
        case .pull: return [.back, .arms]                // 二头
        case .legs: return [.legs]
        }
    }

    /// 恢复约束用的「主负荷肌群」。
    ///
    /// 假设：刻意排除 `.arms`——推日练三头、拉日练二头属不同头，
    /// 把「臂」算作重叠会错误地阻止 push→pull，违背 PPL 设计本意。
    public func primaryMuscles(for split: SplitType) -> Set<MuscleGroup> {
        switch split {
        case .push: return [.chest, .shoulders]
        case .pull: return [.back]
        case .legs: return [.legs]
        }
    }

    // MARK: - 48h 恢复约束

    /// 候选分化的主负荷肌群，是否与近 `recoveryHours` 小时内训练过的肌群无重叠。
    public func canTrain(_ split: SplitType, recent: [RecentSession], now: Date) -> Bool {
        let cutoff = now.addingTimeInterval(-config.recoveryHours * 3600)
        let recentMuscles = recent
            .filter { $0.date >= cutoff }
            .reduce(into: Set<MuscleGroup>()) { $0.formUnion(primaryMuscles(for: $1.split)) }
        return primaryMuscles(for: split).isDisjoint(with: recentMuscles)
    }

    /// 在轮换顺序里，从今日分化出发，挑出第一个满足 48h 约束的明日分化。
    /// 若全部冲突（极端情况），回退到朴素的下一个分化。
    public func recommendedSplit(today: SplitType, recent: [RecentSession], now: Date) -> SplitType {
        guard let startIdx = rotation.firstIndex(of: today) else {
            return rotation.first { canTrain($0, recent: recent, now: now) } ?? rotation[0]
        }
        for offset in 1...rotation.count {
            let candidate = rotation[(startIdx + offset) % rotation.count]
            if canTrain(candidate, recent: recent, now: now) {
                return candidate
            }
        }
        return nextSplit(after: today)
    }

    // MARK: - 渐进超负荷

    /// 规格 §C：上次该动作最后一个工作组达到目标次数上限且 RPE ≤ ceiling → 建议 +1 档 weightStep。
    /// 否则维持重量（可加次数）。
    public func progression(for p: ExercisePerformance, unit: WeightUnit = .kg) -> ProgressionSuggestion {
        let hitTopReps = p.lastReps >= p.targetRepHigh
        let rpeInRange = p.lastRPE <= config.progressionRPECeiling

        if hitTopReps && rpeInRange {
            let newWeight = p.lastWeight + p.weightStep
            return ProgressionSuggestion(
                name: p.name,
                recommendedWeight: newWeight,
                isProgression: true,
                note: "↑ \(NumberFormat.trim(newWeight))\(unit.displayName) +\(NumberFormat.trim(p.weightStep))"
            )
        } else {
            return ProgressionSuggestion(
                name: p.name,
                recommendedWeight: p.lastWeight,
                isProgression: false,
                note: "维持 \(NumberFormat.trim(p.lastWeight))\(unit.displayName)，尝试多加 1–2 次"
            )
        }
    }
}

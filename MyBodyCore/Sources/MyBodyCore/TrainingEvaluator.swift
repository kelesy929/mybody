import Foundation

/// 评估输入（规格 §B）。
public struct SessionEvaluationInput: Sendable, Equatable {
    public let doneSets: Int
    public let plannedSets: Int
    public let averageRPE: Double
    public let volume: Double
    public let weeklyTarget: Double

    public init(doneSets: Int, plannedSets: Int, averageRPE: Double, volume: Double, weeklyTarget: Double) {
        self.doneSets = doneSets
        self.plannedSets = plannedSets
        self.averageRPE = averageRPE
        self.volume = volume
        self.weeklyTarget = weeklyTarget
    }
}

/// 评估结果。
public struct EvaluationResult: Sendable, Equatable {
    public let completionPct: Double     // done / planned，0...1+
    public let achievementPct: Double    // volume / target，0...1+
    public let isEnough: Bool
    public let ringValue: Double         // 进度环数值 = min(completionPct,1)*100
    public let verdictTitle: String      // 「今天练够了」/「还可以再练」
    public let verdictSubtitle: String
    public let reasons: [String]         // 3 条依据，内嵌真实数字
    public let recommendationTitle: String
    public let recommendationText: String

    /// 便于 UI 直接显示的派生标签。
    public var completionPctLabel: String { "\(Int((completionPct * 100).rounded()))%" }
    public var achievementPctLabel: String { "\(Int((achievementPct * 100).rounded()))%" }
}

/// 「今天练够了吗」评估器（规格 §B）。纯逻辑，可单测。
public struct TrainingEvaluator: Sendable {
    public let config: EvaluationConfig

    public init(config: EvaluationConfig = .default) {
        self.config = config
    }

    public func evaluate(_ input: SessionEvaluationInput) -> EvaluationResult {
        let compPct = input.plannedSets > 0 ? Double(input.doneSets) / Double(input.plannedSets) : 0
        let achieve = input.weeklyTarget > 0 ? input.volume / input.weeklyTarget : 0
        let enough = compPct >= config.completionThreshold && input.averageRPE >= config.rpeThreshold

        let ring = min(compPct, 1) * 100
        let achievePctInt = Int((achieve * 100).rounded())
        let rpeStr = String(format: "%.1f", input.averageRPE)
        let volStr = NumberFormat.grouped(Int(input.volume.rounded()))

        let reasons: [String]
        if enough {
            reasons = [
                "完成 \(input.doneSets)/\(input.plannedSets) 计划组，有效组数已落在 MAV（约 \(config.mav) 组/周）高产出区间。",
                "平均 RPE \(rpeStr)，多组接近力竭（RIR 0–1），机械张力足以触发肌肥大适应。",
                "总容量 \(volStr) kg，达成周目标 \(achievePctInt)%；再加量将逼近 MRV（约 \(config.mrv) 组/周），边际收益递减。",
            ]
        } else {
            let gap = max(0, input.plannedSets - input.doneSets)
            reasons = [
                "完成 \(input.doneSets)/\(input.plannedSets) 计划组，距计划还差 \(gap) 组，尚未稳定越过 MEV（约 \(config.mev) 组/周）。",
                "平均 RPE \(rpeStr)，整体强度未达 \(String(format: "%.1f", config.rpeThreshold))，多数组仍留较多余量（RIR 偏高）。",
                "总容量 \(volStr) kg，仅达成周目标 \(achievePctInt)%；再补几组可把有效容量推进到目标区间。",
            ]
        }

        return EvaluationResult(
            completionPct: compPct,
            achievementPct: achieve,
            isEnough: enough,
            ringValue: ring,
            verdictTitle: enough ? "今天练够了" : "还可以再练",
            verdictSubtitle: enough
                ? "今日训练已达到有效刺激与目标容量，继续加量收益有限。"
                : "完成度或强度还差一点，再补 1–2 组接近目标会更有效。",
            reasons: reasons,
            recommendationTitle: enough ? "建议结束今天的训练" : "建议再补 1–2 组",
            recommendationText: enough
                ? "目标肌群已接近当日最大可恢复容量（MRV）。再加组的边际收益很低，反而会延长 DOMS、压缩明日训练的表现。现在补充蛋白质与充足睡眠，让超量恢复发生。"
                : "挑一个还没力竭的动作再加 1–2 组、把 RPE 推到 9 左右，即可达到今日的有效容量目标，再结束训练。"
        )
    }

    /// 便捷重载：直接从动作快照算出输入再评估。
    public func evaluate(exercises: [LoggedExerciseSnapshot], weeklyTarget: Double) -> EvaluationResult {
        let input = SessionEvaluationInput(
            doneSets: VolumeCalculator.doneSets(exercises),
            plannedSets: VolumeCalculator.plannedSets(exercises),
            averageRPE: VolumeCalculator.averageRPE(exercises),
            volume: VolumeCalculator.sessionVolume(exercises),
            weeklyTarget: weeklyTarget
        )
        return evaluate(input)
    }
}

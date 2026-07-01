import Foundation

/// 训练科学阈值常量集中处，便于以后调参（规格 §B/§A）。
///
/// 假设：MEV/MAV/MRV 取自常见力量训练文献的「每周每肌群组数」经验值，可在此结构调整。
public struct EvaluationConfig: Sendable, Equatable {
    /// 判定「练够」的计划完成度下限（done/planned）。规格默认 0.85。
    public var completionThreshold: Double
    /// 判定「练够」的平均 RPE 下限。规格默认 8.3。
    public var rpeThreshold: Double
    /// 「有效组」的 RPE 下限：RPE ≥ 7 即 RIR ≤ 3，计入有效刺激（规格 §A）。
    public var effectiveSetRPE: Double

    /// 每周每肌群最小有效容量（Minimum Effective Volume，组）。
    public var mev: Int
    /// 每周每肌群最大适应容量（Maximum Adaptive Volume，组）。
    public var mav: Int
    /// 每周每肌群最大可恢复容量（Maximum Recoverable Volume，组）。
    public var mrv: Int

    /// 渐进超负荷的 RPE 上限：上次到达次数上限且 RPE ≤ 此值才加重量（规格 §C）。
    public var progressionRPECeiling: Double
    /// 同一肌群两次训练的最小恢复间隔（小时，规格 §C）。
    public var recoveryHours: Double

    public init(
        completionThreshold: Double = 0.85,
        rpeThreshold: Double = 8.3,
        effectiveSetRPE: Double = 7.0,
        mev: Int = 10,
        mav: Int = 18,
        mrv: Int = 22,
        progressionRPECeiling: Double = 9.0,
        recoveryHours: Double = 48
    ) {
        self.completionThreshold = completionThreshold
        self.rpeThreshold = rpeThreshold
        self.effectiveSetRPE = effectiveSetRPE
        self.mev = mev
        self.mav = mav
        self.mrv = mrv
        self.progressionRPECeiling = progressionRPECeiling
        self.recoveryHours = recoveryHours
    }

    public static let `default` = EvaluationConfig()
}

import Foundation

/// 肌群分组。存储用英文 raw value（迁移/谓词查询更稳），UI 用 `displayName` 取中文。
public enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case chest, back, legs, shoulders, arms, core

    public var displayName: String {
        switch self {
        case .chest: return "胸"
        case .back: return "背"
        case .legs: return "腿"
        case .shoulders: return "肩"
        case .arms: return "臂"
        case .core: return "核心"
        }
    }
}

/// 训练分化（Push / Pull / Legs）。
public enum SplitType: String, Codable, CaseIterable, Sendable {
    case push, pull, legs

    /// 中文短标签（如 Hero 卡片上的「推 · PUSH」取 `displayName` + `rawLabel`）。
    public var displayName: String {
        switch self {
        case .push: return "推"
        case .pull: return "拉"
        case .legs: return "腿"
        }
    }

    /// 英文大写标签。
    public var rawLabel: String { rawValue.uppercased() }

    /// 该分化主打的「目标肌群」标题（原型："胸 · 肩 · 三头" / "背 · 二头"）。
    public var muscleHeadline: String {
        switch self {
        case .push: return "胸 · 肩 · 三头"
        case .pull: return "背 · 二头"
        case .legs: return "股四 · 腘绳 · 臀"
        }
    }
}

/// 一次训练会话的状态。
public enum SessionStatus: String, Codable, Sendable {
    case planned, active, done
}

/// 动作难度。
public enum Difficulty: String, Codable, CaseIterable, Sendable {
    case beginner, intermediate, advanced

    public var displayName: String {
        switch self {
        case .beginner: return "入门"
        case .intermediate: return "进阶"
        case .advanced: return "高级"
        }
    }

    /// 从原型中文难度字符串解析（用于种子数据导入）。
    public init?(chinese: String) {
        switch chinese {
        case "入门": self = .beginner
        case "进阶": self = .intermediate
        case "高级": self = .advanced
        default: return nil
        }
    }
}

/// 重量单位。默认 kg；lb 预留接口，MVP 暂不做完整换算 UI。
public enum WeightUnit: String, Codable, Sendable {
    case kg, lb
    public var displayName: String { rawValue }
}

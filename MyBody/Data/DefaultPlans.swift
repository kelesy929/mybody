import Foundation
import MyBodyCore

/// 各分化的默认动作方案（基于种子库中已有的 12 个动作）。
/// 明日推荐以此为骨架，再叠加渐进超负荷判定。
enum DefaultPlans {
    struct Scheme { let name: String; let sets: Int; let repLow: Int; let repHigh: Int }

    static func schemes(for split: SplitType) -> [Scheme] {
        switch split {
        case .push:
            return [
                Scheme(name: "杠铃卧推", sets: 4, repLow: 6, repHigh: 8),
                Scheme(name: "上斜哑铃卧推", sets: 3, repLow: 8, repHigh: 10),
                Scheme(name: "坐姿器械肩推", sets: 3, repLow: 8, repHigh: 10),
                Scheme(name: "哑铃侧平举", sets: 4, repLow: 12, repHigh: 15),
                Scheme(name: "绳索下压", sets: 3, repLow: 10, repHigh: 12),
            ]
        case .pull:
            return [
                Scheme(name: "引体向上", sets: 4, repLow: 6, repHigh: 10),
                Scheme(name: "杠铃划船", sets: 4, repLow: 8, repHigh: 10),
                Scheme(name: "高位下拉", sets: 3, repLow: 10, repHigh: 12),
            ]
        case .legs:
            return [
                Scheme(name: "杠铃深蹲", sets: 4, repLow: 5, repHigh: 8),
                Scheme(name: "罗马尼亚硬拉", sets: 3, repLow: 8, repHigh: 10),
                Scheme(name: "腿举", sets: 3, repLow: 10, repHigh: 15),
            ]
        }
    }
}

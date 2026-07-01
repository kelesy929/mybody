import Foundation
import SwiftData
import MyBodyCore

/// 明日/未来某天的训练计划，可编辑。
@Model
final class WorkoutPlan {
    var date: Date
    var splitType: SplitType

    @Relationship(deleteRule: .cascade, inverse: \PlanItem.plan)
    var items: [PlanItem]

    init(date: Date, splitType: SplitType, items: [PlanItem] = []) {
        self.date = date
        self.splitType = splitType
        self.items = items
    }

    var orderedItems: [PlanItem] {
        items.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// 总组数。
    var totalSets: Int { items.reduce(0) { $0 + $1.sets } }

    /// Hero 卡副标题：`N 动作 · M 组 · 约 X 分钟`（约 3.3 分钟/组，含组间休息）。
    var metaLabel: String {
        "\(items.count) 个动作 · \(totalSets) 组 · 约 \(Int((Double(totalSets) * 3.3).rounded())) 分钟"
    }
}

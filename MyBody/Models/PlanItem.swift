import Foundation
import SwiftData

/// 计划中的一个动作行。
@Model
final class PlanItem {
    var exercise: Exercise?
    var nameSnapshot: String          // 兜底名：即使关联 Exercise 被删，计划行仍可显示
    var sets: Int
    var repLow: Int
    var repHigh: Int
    var note: String                  // 「↑ 62.5kg +2.5」或「宽握 · 背阔」
    var isProgression: Bool           // 渐进超负荷 → UI 青柠标注
    var orderIndex: Int

    var plan: WorkoutPlan?

    init(exercise: Exercise?, nameSnapshot: String, sets: Int, repLow: Int, repHigh: Int,
         note: String = "", isProgression: Bool = false, orderIndex: Int) {
        self.exercise = exercise
        self.nameSnapshot = nameSnapshot
        self.sets = sets
        self.repLow = repLow
        self.repHigh = repHigh
        self.note = note
        self.isProgression = isProgression
        self.orderIndex = orderIndex
    }

    var displayName: String { exercise?.name ?? nameSnapshot }
    var schemeLabel: String { "× \(repLow)–\(repHigh) 次" }
}

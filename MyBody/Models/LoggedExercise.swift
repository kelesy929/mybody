import Foundation
import SwiftData

/// 某次训练里记录的一个动作（含目标与各组）。
@Model
final class LoggedExercise {
    var exercise: Exercise?
    var targetSets: Int
    var targetRepLow: Int
    var targetRepHigh: Int
    var lastSummary: String           // 「上次 80kg×8」
    var orderIndex: Int

    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.loggedExercise)
    var sets: [SetEntry]

    init(exercise: Exercise?, targetSets: Int, targetRepLow: Int, targetRepHigh: Int,
         lastSummary: String = "", orderIndex: Int, sets: [SetEntry] = []) {
        self.exercise = exercise
        self.targetSets = targetSets
        self.targetRepLow = targetRepLow
        self.targetRepHigh = targetRepHigh
        self.lastSummary = lastSummary
        self.orderIndex = orderIndex
        self.sets = sets
    }

    /// 按 orderIndex 排好序的组。
    var orderedSets: [SetEntry] {
        sets.sorted { $0.orderIndex < $1.orderIndex }
    }

    var targetLabel: String { "\(targetSets) 组 · \(targetRepLow)–\(targetRepHigh) 次" }
    var doneCount: Int { sets.filter { $0.isDone }.count }
    var isAllDone: Bool { !sets.isEmpty && doneCount == sets.count }
}

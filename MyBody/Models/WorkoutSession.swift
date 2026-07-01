import Foundation
import SwiftData
import MyBodyCore

/// 一次训练会话。
@Model
final class WorkoutSession {
    var date: Date
    var splitType: SplitType
    var status: SessionStatus
    var durationSec: Int

    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.session)
    var loggedExercises: [LoggedExercise]

    init(date: Date, splitType: SplitType, status: SessionStatus = .planned,
         durationSec: Int = 0, loggedExercises: [LoggedExercise] = []) {
        self.date = date
        self.splitType = splitType
        self.status = status
        self.durationSec = durationSec
        self.loggedExercises = loggedExercises
    }

    /// 按 orderIndex 排好序的动作（SwiftData 关系数组不保证顺序）。
    var orderedExercises: [LoggedExercise] {
        loggedExercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}

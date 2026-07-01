import Foundation
import SwiftData

/// 一个工作组。
@Model
final class SetEntry {
    var weight: Double
    var reps: Int
    var rpe: Double
    var isDone: Bool
    var orderIndex: Int

    var loggedExercise: LoggedExercise?

    init(weight: Double, reps: Int, rpe: Double = 8, isDone: Bool = false, orderIndex: Int) {
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.isDone = isDone
        self.orderIndex = orderIndex
    }
}

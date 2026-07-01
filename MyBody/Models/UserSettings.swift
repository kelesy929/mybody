import Foundation
import SwiftData
import MyBodyCore

/// 用户设置（单例：容器里仅保留一条）。
@Model
final class UserSettings {
    var unit: WeightUnit
    var restDurationSec: Int           // 默认 90
    var weeklyVolumeTargetKg: Double   // 默认 7000
    var showRPE: Bool                  // 默认 true
    var split: SplitType               // 默认 push（PPL 起点）

    init(unit: WeightUnit = .kg, restDurationSec: Int = 90,
         weeklyVolumeTargetKg: Double = 7000, showRPE: Bool = true,
         split: SplitType = .push) {
        self.unit = unit
        self.restDurationSec = restDurationSec
        self.weeklyVolumeTargetKg = weeklyVolumeTargetKg
        self.showRPE = showRPE
        self.split = split
    }
}

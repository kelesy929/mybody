import Foundation
import SwiftData
import MyBodyCore

/// 动作库条目（内置种子数据 + 用户可加）。
///
/// 假设：枚举 `MuscleGroup` / `Difficulty` 为 String 背书的 Codable，
/// iOS 17 SwiftData 可直接作为存储属性，省去手写 raw 字段桥接。
@Model
final class Exercise {
    /// 中文名，作为种子数据的天然唯一键（用于按名查找/去重）。
    @Attribute(.unique) var name: String
    var nameEN: String
    var muscleGroup: MuscleGroup
    var primaryMuscle: String
    var synergists: [String]          // 协同肌群，UI 以 " · " 连接展示
    var equipment: String
    var difficulty: Difficulty
    var cues: [String]                // 动作要点（编号列表）
    var mistakes: [String]            // 常见错误（红色 ✕）
    var prescription: String          // 进阶处方
    var isEachSide: Bool              // 单侧动作 → 容量 ×2
    var weightStep: Double            // 步进：卧推 2.5 / 肩推 5 / 侧平举 1…

    init(name: String, nameEN: String, muscleGroup: MuscleGroup, primaryMuscle: String,
         synergists: [String], equipment: String, difficulty: Difficulty,
         cues: [String], mistakes: [String], prescription: String,
         isEachSide: Bool, weightStep: Double) {
        self.name = name
        self.nameEN = nameEN
        self.muscleGroup = muscleGroup
        self.primaryMuscle = primaryMuscle
        self.synergists = synergists
        self.equipment = equipment
        self.difficulty = difficulty
        self.cues = cues
        self.mistakes = mistakes
        self.prescription = prescription
        self.isEachSide = isEachSide
        self.weightStep = weightStep
    }

    /// 列表/筛选用的标签（肌群中文短名，如「胸」）。
    var groupTag: String { muscleGroup.displayName }
    /// 副标题「主肌群 · 器械」。
    var metaLabel: String { "\(primaryMuscle) · \(equipment)" }
    var synergistsLabel: String { synergists.joined(separator: " · ") }
}

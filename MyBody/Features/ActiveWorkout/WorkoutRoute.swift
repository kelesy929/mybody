import Foundation

/// 训练流的导航路由（从今日页的 NavigationStack 推入）。
/// 用统一的 path 驱动：今日 →训练记录 →评估 →(明日)；动作详情作为叶子推入。
enum WorkoutRoute: Hashable {
    case active(WorkoutSession)       // 训练记录
    case evaluation(WorkoutSession)   // 今日评估
    case tomorrow(WorkoutSession)     // 明日训练（可编辑），传入刚完成的会话以判定分化
    case detail(Exercise)             // 动作详情
}

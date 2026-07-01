import SwiftUI
import SwiftData

@main
struct MyBodyApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Exercise.self, WorkoutSession.self, LoggedExercise.self, SetEntry.self,
                WorkoutPlan.self, PlanItem.self, UserSettings.self
            )
        } catch {
            fatalError("无法创建 ModelContainer: \(error)")
        }
        // 首次启动播种内置动作 + 默认设置 + 今日计划。
        SeedData.seedIfNeeded(container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)        // 强制浅色，不跟随系统深色
                .tint(Theme.Palette.accent)
        }
        .modelContainer(container)
    }
}

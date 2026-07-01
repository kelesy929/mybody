import SwiftUI

/// 底部三 Tab：今日 / 动作库 / 数据。
struct RootView: View {
    enum Tab { case today, library, stats }
    @State private var tab: Tab = .today

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tag(Tab.today)
                .tabItem { Label("今日", systemImage: "house.fill") }

            LibraryView()
                .tag(Tab.library)
                .tabItem { Label("动作库", systemImage: "list.bullet") }

            StatsView()
                .tag(Tab.stats)
                .tabItem { Label("数据", systemImage: "chart.bar.fill") }
        }
        .tint(Theme.Palette.accent)
    }
}

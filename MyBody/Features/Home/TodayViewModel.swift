import Foundation
import SwiftUI
import MyBodyCore

/// 今日页的派生展示数据（纯转换，输入 SwiftData 取出的数组，便于复用/测试）。
@Observable
final class TodayViewModel {

    // 展示用值类型
    struct Hero {
        let hasSession: Bool
        let splitTag: String          // 「推 · PUSH」
        let cycleLabel: String        // 「周期 3 / 6」
        let muscles: String           // 「胸 · 肩 · 三头」
        let meta: String              // 「5 个动作 · 17 组 · 约 65 分钟」
        let isPull: Bool              // 拉日用淡蓝 Hero
    }
    struct WeekDayData: Identifiable {
        let id = UUID()
        let label: String
        let state: WeekDot.State
        let mark: String
    }
    struct MuscleBarData: Identifiable {
        let id = UUID()
        let name: String
        let current: Int
        let target: Int
    }
    struct LastSession {
        let dateLabel: String         // 「上次推日 · 6 月 27 日」
        let volume: String            // 「7,420」
        let doneSets: Int
        let prValue: String           // 「82.5」
        let prName: String            // 「卧推 PR」
    }

    private(set) var greeting: String = ""
    private(set) var dateLabel: String = ""
    private(set) var hero: Hero = .init(hasSession: false, splitTag: "", cycleLabel: "", muscles: "", meta: "", isPull: false)
    private(set) var streakLabel: String = ""
    private(set) var weekDays: [WeekDayData] = []
    private(set) var muscleBars: [MuscleBarData] = []
    private(set) var lastSession: LastSession?

    /// 每周每肌群目标组数。
    /// 假设：取自原型示例值，作为可调常量；以后可挪进 UserSettings。
    private let weeklyMuscleTarget: [MuscleGroup: Int] =
        [.chest: 18, .back: 18, .legs: 16, .shoulders: 18, .arms: 14, .core: 12]

    /// 用最新数据刷新（在 onAppear / 数据变化时调用）。
    func refresh(sessions: [WorkoutSession], settings: UserSettings?, now: Date = Date()) {
        let cal = Calendar(identifier: .gregorian)
        dateLabel = Self.dateLabel(now)
        greeting = Self.greeting(now)

        // 今日会话（planned/active 且日期是今天）。
        let todaySession = sessions.first {
            cal.isDateInToday($0.date) && $0.status != .done
        }
        let todaySplit = todaySession?.splitType ?? settings?.split ?? .push
        buildHero(todaySession, split: todaySplit, sessions: sessions, now: now)
        buildWeekStrip(sessions: sessions, todaySplit: todaySplit, now: now, cal: cal)
        buildMuscleBars(sessions: sessions, now: now, cal: cal)
        buildLastSession(sessions: sessions, split: todaySplit, now: now)
        streakLabel = "连续 \(Self.streak(sessions: sessions, now: now, cal: cal)) 天 🔥"
    }

    // MARK: Hero

    private func buildHero(_ session: WorkoutSession?, split: SplitType, sessions: [WorkoutSession], now: Date) {
        let cal = Calendar(identifier: .gregorian)
        // 周期：本「中周期」内已完成的会话数 + 1，封顶 6（假设：简单计数，后续可建模 mesocycle）。
        let doneCount = sessions.filter { $0.status == .done }.count
        let cycle = min(doneCount + 1, 6)

        if let s = session {
            let totalSets = s.loggedExercises.reduce(0) { $0 + $1.targetSets }
            let meta = "\(s.loggedExercises.count) 个动作 · \(totalSets) 组 · 约 \(Int((Double(totalSets) * 3.85).rounded())) 分钟"
            hero = Hero(
                hasSession: true,
                splitTag: "\(split.displayName) · \(split.rawLabel)",
                cycleLabel: "周期 \(cycle) / 6",
                muscles: split.muscleHeadline,
                meta: meta,
                isPull: split == .pull)
        } else {
            hero = Hero(
                hasSession: false,
                splitTag: "\(split.displayName) · \(split.rawLabel)",
                cycleLabel: "周期 \(cycle) / 6",
                muscles: split.muscleHeadline,
                meta: "今天还没有安排训练",
                isPull: split == .pull)
        }
    }

    // MARK: 本周条

    private func buildWeekStrip(sessions: [WorkoutSession], todaySplit: SplitType, now: Date, cal: Calendar) {
        let labels = ["一", "二", "三", "四", "五", "六", "日"]
        guard let monday = Self.startOfWeek(now, cal: cal) else { weekDays = []; return }

        weekDays = (0..<7).map { offset in
            let day = cal.date(byAdding: .day, value: offset, to: monday)!
            let isToday = cal.isDate(day, inSameDayAs: now)
            let doneThatDay = sessions.contains { $0.status == .done && cal.isDate($0.date, inSameDayAs: day) }
            let isFuture = day > now && !isToday

            let state: WeekDot.State
            if isToday { state = .today }
            else if doneThatDay { state = .done }
            else if isFuture { state = .future }
            else { state = .rest }

            return WeekDayData(label: labels[offset], state: state,
                               mark: isToday ? todaySplit.displayName : "")
        }
    }

    // MARK: 本周容量条

    private func buildMuscleBars(sessions: [WorkoutSession], now: Date, cal: Calendar) {
        guard let monday = Self.startOfWeek(now, cal: cal) else { muscleBars = []; return }
        let weekSessions = sessions.filter { $0.date >= monday }

        var doneByMuscle: [MuscleGroup: Int] = [:]
        for s in weekSessions {
            for ex in s.loggedExercises {
                guard let group = ex.exercise?.muscleGroup else { continue }
                doneByMuscle[group, default: 0] += ex.sets.filter { $0.isDone }.count
            }
        }

        let order: [MuscleGroup] = [.chest, .back, .legs, .shoulders, .arms]
        muscleBars = order.map { g in
            MuscleBarData(name: g.displayName,
                          current: doneByMuscle[g] ?? 0,
                          target: weeklyMuscleTarget[g] ?? 16)
        }
    }

    // MARK: 上次同分化

    private func buildLastSession(sessions: [WorkoutSession], split: SplitType, now: Date) {
        let cal = Calendar(identifier: .gregorian)
        let candidate = sessions
            .filter { $0.status == .done && $0.splitType == split && !cal.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
            .first
        guard let s = candidate else { lastSession = nil; return }

        let vol = VolumeCalculator.sessionVolume(s.exerciseSnapshots)
        let doneSets = VolumeCalculator.doneSets(s.exerciseSnapshots)
        // PR：本次会话中最重的一个已完成组。
        let heaviest = s.loggedExercises
            .flatMap { ex in ex.sets.filter { $0.isDone }.map { (name: ex.exercise?.name ?? "", w: $0.weight) } }
            .max { $0.w < $1.w }

        lastSession = LastSession(
            dateLabel: "上次\(split.displayName)日 · \(Self.monthDay(s.date))",
            volume: NumberFormat.grouped(Int(vol.rounded())),
            doneSets: doneSets,
            prValue: heaviest.map { NumberFormat.trim($0.w) } ?? "—",
            prName: heaviest.map { "\($0.name) PR" } ?? "PR")
    }

    // MARK: 时间格式化

    private static func greeting(_ date: Date) -> String {
        let h = Calendar.current.component(.hour, from: date)
        let part = h < 6 ? "凌晨好" : h < 12 ? "早上好" : h < 14 ? "中午好" : h < 18 ? "下午好" : "晚上好"
        return "\(part)，阿凯"
    }

    private static func dateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "EEEE · M 月 d 日"
        return f.string(from: date)
    }

    private static func monthDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M 月 d 日"
        return f.string(from: date)
    }

    private static func startOfWeek(_ date: Date, cal: Calendar) -> Date? {
        var c = cal
        c.firstWeekday = 2 // 周一
        let comps = c.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return c.date(from: comps)
    }

    private static func streak(sessions: [WorkoutSession], now: Date, cal: Calendar) -> Int {
        let doneDays = Set(sessions.filter { $0.status == .done }.map { cal.startOfDay(for: $0.date) })
        var count = 0
        var day = cal.startOfDay(for: now)
        // 今天没练也允许从昨天起算连续。
        if !doneDays.contains(day) { day = cal.date(byAdding: .day, value: -1, to: day)! }
        while doneDays.contains(day) {
            count += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }
}

import XCTest
@testable import MyBodyCore

final class NextWorkoutPlannerTests: XCTestCase {

    let planner = NextWorkoutPlanner()

    // MARK: 分化轮换 Push→Pull→Legs→Push

    func testRotation_PPL() {
        XCTAssertEqual(planner.nextSplit(after: .push), .pull)
        XCTAssertEqual(planner.nextSplit(after: .pull), .legs)
        XCTAssertEqual(planner.nextSplit(after: .legs), .push)
    }

    // MARK: 48h 恢复约束

    func testRecovery_sameSplitWithin48hBlocked() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let recent = [RecentSession(split: .push, date: now.addingTimeInterval(-24 * 3600))]

        XCTAssertFalse(planner.canTrain(.push, recent: recent, now: now)) // 24h 前练过推 → 胸/肩未恢复
        XCTAssertTrue(planner.canTrain(.pull, recent: recent, now: now))  // 拉日主肌群=背，不重叠
        XCTAssertTrue(planner.canTrain(.legs, recent: recent, now: now))
    }

    func testRecovery_sameSplitAfter48hAllowed() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let recent = [RecentSession(split: .push, date: now.addingTimeInterval(-72 * 3600))]
        XCTAssertTrue(planner.canTrain(.push, recent: recent, now: now)) // 72h > 48h，已恢复
    }

    func testRecommendedSplit_skipsConflictingSplit() {
        // 今日 legs，但 24h 前刚练过 push → 轮换本应回到 push，但 push 冲突，
        // recommendedSplit 应跳过、继续找到下一个可练的分化。
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let recent = [RecentSession(split: .push, date: now.addingTimeInterval(-24 * 3600))]
        let next = planner.recommendedSplit(today: .legs, recent: recent, now: now)
        XCTAssertNotEqual(next, .push)
        XCTAssertTrue(planner.canTrain(next, recent: recent, now: now))
    }

    // MARK: 渐进超负荷

    func testProgression_triggersWhenTopRepsAndRPEInRange() {
        // 上次最后一组 8 次达到上限 8、RPE 9.0 ≤ 9 → 加一档 step。
        let perf = ExercisePerformance(name: "杠铃卧推", weightStep: 2.5,
                                       lastWeight: 80, lastReps: 8, targetRepHigh: 8, lastRPE: 9.0)
        let s = planner.progression(for: perf)
        XCTAssertTrue(s.isProgression)
        XCTAssertEqual(s.recommendedWeight, 82.5, accuracy: 0.0001)
        XCTAssertEqual(s.note, "↑ 82.5kg +2.5")
    }

    func testProgression_notTriggeredWhenBelowTopReps() {
        let perf = ExercisePerformance(name: "杠铃卧推", weightStep: 2.5,
                                       lastWeight: 80, lastReps: 6, targetRepHigh: 8, lastRPE: 8.0)
        let s = planner.progression(for: perf)
        XCTAssertFalse(s.isProgression)
        XCTAssertEqual(s.recommendedWeight, 80, accuracy: 0.0001)
    }

    func testProgression_notTriggeredWhenRPETooHigh() {
        // 达到次数上限，但 RPE 9.5 > 9 → 力竭过度，不加重量。
        let perf = ExercisePerformance(name: "杠铃划船", weightStep: 2.5,
                                       lastWeight: 60, lastReps: 10, targetRepHigh: 10, lastRPE: 9.5)
        let s = planner.progression(for: perf)
        XCTAssertFalse(s.isProgression)
    }

    func testProgression_fractionalStepFormatsCleanly() {
        // step=1 的侧平举，14→上限15 不触发；用整数步进检查 note 无多余 .0。
        let perf = ExercisePerformance(name: "哑铃弯举", weightStep: 1,
                                       lastWeight: 14, lastReps: 12, targetRepHigh: 12, lastRPE: 8.5)
        let s = planner.progression(for: perf)
        XCTAssertTrue(s.isProgression)
        XCTAssertEqual(s.note, "↑ 15kg +1")
    }
}

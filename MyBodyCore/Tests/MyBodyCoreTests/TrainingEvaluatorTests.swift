import XCTest
@testable import MyBodyCore

final class TrainingEvaluatorTests: XCTestCase {

    let evaluator = TrainingEvaluator()

    // MARK: 练够

    func testEnough_whenHighCompletionAndIntensity() {
        // 完成 17/17 组、平均 RPE 8.9 → 同时越过 0.85 与 8.3 两道阀门。
        let input = SessionEvaluationInput(doneSets: 17, plannedSets: 17,
                                           averageRPE: 8.9, volume: 7420, weeklyTarget: 7000)
        let r = evaluator.evaluate(input)

        XCTAssertTrue(r.isEnough)
        XCTAssertEqual(r.verdictTitle, "今天练够了")
        XCTAssertEqual(r.ringValue, 100, accuracy: 0.0001)        // min(1.0,1)*100
        XCTAssertEqual(r.completionPct, 1.0, accuracy: 0.0001)
        XCTAssertEqual(r.achievementPct, 7420.0 / 7000.0, accuracy: 0.0001)
        XCTAssertEqual(r.reasons.count, 3)
        XCTAssertTrue(r.reasons[1].contains("8.9"))               // 真实 RPE 入文
        XCTAssertTrue(r.reasons[2].contains("7,420"))             // 千分位容量入文
        XCTAssertEqual(r.recommendationTitle, "建议结束今天的训练")
    }

    // MARK: 没练够（完成度不足）

    func testNotEnough_whenLowCompletion() {
        let input = SessionEvaluationInput(doneSets: 10, plannedSets: 17,
                                           averageRPE: 8.9, volume: 4200, weeklyTarget: 7000)
        let r = evaluator.evaluate(input)

        XCTAssertFalse(r.isEnough)                                // 10/17 ≈ 0.588 < 0.85
        XCTAssertEqual(r.verdictTitle, "还可以再练")
        XCTAssertEqual(r.ringValue, 10.0 / 17.0 * 100, accuracy: 0.0001)
        XCTAssertEqual(r.recommendationTitle, "建议再补 1–2 组")
        XCTAssertTrue(r.reasons[0].contains("7 组"))              // 差额 17-10=7
    }

    // MARK: 没练够（强度不足）

    func testNotEnough_whenLowIntensityEvenIfComplete() {
        // 完成度达标，但平均 RPE 7.8 < 8.3 → 仍判「还可以再练」。
        let input = SessionEvaluationInput(doneSets: 17, plannedSets: 17,
                                           averageRPE: 7.8, volume: 7000, weeklyTarget: 7000)
        let r = evaluator.evaluate(input)

        XCTAssertFalse(r.isEnough)
        XCTAssertEqual(r.ringValue, 100, accuracy: 0.0001)        // 环仍满，但判定不算练够
    }

    // MARK: 边界

    func testBoundary_exactThresholdsCountAsEnough() {
        // compPct 恰好 0.85、avgRPE 恰好 8.3 → 用 >= 判定，算练够。
        let input = SessionEvaluationInput(doneSets: 17, plannedSets: 20,
                                           averageRPE: 8.3, volume: 7000, weeklyTarget: 7000)
        let r = evaluator.evaluate(input)
        XCTAssertEqual(r.completionPct, 0.85, accuracy: 0.0001)
        XCTAssertTrue(r.isEnough)
    }

    func testZeroPlanned_doesNotCrash() {
        let input = SessionEvaluationInput(doneSets: 0, plannedSets: 0,
                                           averageRPE: 0, volume: 0, weeklyTarget: 7000)
        let r = evaluator.evaluate(input)
        XCTAssertFalse(r.isEnough)
        XCTAssertEqual(r.ringValue, 0)
    }

    // MARK: 容量计算

    func testVolumeCalculator_eachSideDoublesAndOnlyDoneCounts() {
        let ex = LoggedExerciseSnapshot(
            name: "哑铃侧平举", muscleGroup: .shoulders, isEachSide: true, weightStep: 1,
            targetSets: 3, targetRepHigh: 15,
            sets: [
                SetSnapshot(weight: 12, reps: 15, rpe: 8, isDone: true),   // 12*15*2 = 360
                SetSnapshot(weight: 12, reps: 14, rpe: 9, isDone: true),   // 336
                SetSnapshot(weight: 10, reps: 13, rpe: 9.5, isDone: false) // 未完成，不计
            ])
        XCTAssertEqual(VolumeCalculator.exerciseVolume(ex), 360 + 336, accuracy: 0.0001)
        XCTAssertEqual(VolumeCalculator.effectiveSets(ex), 2)             // 两组 isDone 且 rpe>=7
        XCTAssertEqual(VolumeCalculator.doneSets([ex]), 2)
    }
}

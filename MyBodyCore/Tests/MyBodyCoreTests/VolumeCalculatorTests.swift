import XCTest
@testable import MyBodyCore

final class VolumeCalculatorTests: XCTestCase {

    private func ex(_ group: MuscleGroup, eachSide: Bool, sets: [SetSnapshot], targetSets: Int = 3) -> LoggedExerciseSnapshot {
        LoggedExerciseSnapshot(name: "x", muscleGroup: group, isEachSide: eachSide, weightStep: 2.5,
                               targetSets: targetSets, targetRepHigh: 10, sets: sets)
    }

    func testSetVolume_eachSideDoubles() {
        XCTAssertEqual(VolumeCalculator.setVolume(weight: 30, reps: 10, isEachSide: false), 300, accuracy: 1e-9)
        XCTAssertEqual(VolumeCalculator.setVolume(weight: 30, reps: 10, isEachSide: true), 600, accuracy: 1e-9)
    }

    func testSessionVolume_sumsOnlyDoneAcrossExercises() {
        let a = ex(.chest, eachSide: false, sets: [
            .init(weight: 80, reps: 8, rpe: 8, isDone: true),   // 640
            .init(weight: 80, reps: 8, rpe: 9, isDone: false),  // 忽略
        ])
        let b = ex(.shoulders, eachSide: true, sets: [
            .init(weight: 12, reps: 15, rpe: 8, isDone: true),  // 360
        ])
        XCTAssertEqual(VolumeCalculator.sessionVolume([a, b]), 640 + 360, accuracy: 1e-9)
    }

    func testEffectiveSets_onlyDoneAndRPEAtLeast7() {
        let e = ex(.back, eachSide: false, sets: [
            .init(weight: 60, reps: 8, rpe: 7, isDone: true),    // 有效
            .init(weight: 60, reps: 8, rpe: 6.5, isDone: true),  // rpe<7，无效
            .init(weight: 60, reps: 8, rpe: 9, isDone: false),   // 未完成，无效
        ])
        XCTAssertEqual(VolumeCalculator.effectiveSets(e), 1)
    }

    func testEffectiveSetsByMuscle_aggregates() {
        let chest1 = ex(.chest, eachSide: false, sets: [.init(weight: 80, reps: 8, rpe: 8, isDone: true)])
        let chest2 = ex(.chest, eachSide: false, sets: [.init(weight: 70, reps: 8, rpe: 8, isDone: true)])
        let back = ex(.back, eachSide: false, sets: [.init(weight: 60, reps: 8, rpe: 5, isDone: true)]) // rpe<7
        let map = VolumeCalculator.effectiveSetsByMuscle([chest1, chest2, back])
        XCTAssertEqual(map[.chest], 2)
        XCTAssertEqual(map[.back], 0)
    }

    func testAverageRPE_zeroWhenNoDone() {
        let e = ex(.arms, eachSide: false, sets: [.init(weight: 30, reps: 12, rpe: 9, isDone: false)])
        XCTAssertEqual(VolumeCalculator.averageRPE([e]), 0, accuracy: 1e-9)
    }

    func testDoneAndPlannedSets() {
        let e = ex(.legs, eachSide: false, targetSets_: 4, sets: [
            .init(weight: 100, reps: 5, rpe: 8, isDone: true),
            .init(weight: 100, reps: 5, rpe: 9, isDone: true),
            .init(weight: 100, reps: 5, rpe: 9.5, isDone: false),
        ])
        XCTAssertEqual(VolumeCalculator.doneSets([e]), 2)
        XCTAssertEqual(VolumeCalculator.plannedSets([e]), 4)
    }

    // 便捷重载：evaluate(exercises:weeklyTarget:) 与手动输入一致。
    func testEvaluator_convenienceOverloadMatchesManualInput() {
        let e = ex(.chest, eachSide: false, targetSets_: 4, sets: [
            .init(weight: 80, reps: 8, rpe: 9, isDone: true),
            .init(weight: 80, reps: 8, rpe: 9, isDone: true),
            .init(weight: 80, reps: 8, rpe: 9, isDone: true),
            .init(weight: 80, reps: 8, rpe: 9, isDone: true),
        ])
        let r = TrainingEvaluator().evaluate(exercises: [e], weeklyTarget: 3000)
        XCTAssertEqual(r.completionPct, 1.0, accuracy: 1e-9)   // 4/4
        XCTAssertTrue(r.isEnough)                              // avgRPE 9 ≥ 8.3
    }

    // 明日分化：全部冲突时回退到朴素下一个分化。
    func testRecommendedSplit_fallbackWhenAllConflict() {
        let planner = NextWorkoutPlanner()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // 24h 内三种分化的主肌群都练过 → 全冲突。
        let recent = [
            RecentSession(split: .push, date: now.addingTimeInterval(-3600)),
            RecentSession(split: .pull, date: now.addingTimeInterval(-3600)),
            RecentSession(split: .legs, date: now.addingTimeInterval(-3600)),
        ]
        // 不崩溃，回退到 push 的下一个（pull）。
        XCTAssertEqual(planner.recommendedSplit(today: .push, recent: recent, now: now), .pull)
    }
}

// 便于测试构造（带自定义 targetSets）。
private extension VolumeCalculatorTests {
    func ex(_ group: MuscleGroup, eachSide: Bool, targetSets_: Int, sets: [SetSnapshot]) -> LoggedExerciseSnapshot {
        LoggedExerciseSnapshot(name: "x", muscleGroup: group, isEachSide: eachSide, weightStep: 2.5,
                               targetSets: targetSets_, targetRepHigh: 10, sets: sets)
    }
}

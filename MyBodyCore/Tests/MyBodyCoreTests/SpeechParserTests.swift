import XCTest
@testable import MyBodyCore

final class SpeechParserTests: XCTestCase {

    func testDigitsWithUnits() {
        XCTAssertEqual(SpeechParser.parse("80公斤8个"), SpokenSet(weight: 80, reps: 8))
        XCTAssertEqual(SpeechParser.parse("80公斤 8次"), SpokenSet(weight: 80, reps: 8))
        XCTAssertEqual(SpeechParser.parse("82.5公斤6次"), SpokenSet(weight: 82.5, reps: 6))
    }

    func testTwoBareNumbers_weightThenReps() {
        XCTAssertEqual(SpeechParser.parse("80 8"), SpokenSet(weight: 80, reps: 8))
    }

    func testOnlyReps() {
        XCTAssertEqual(SpeechParser.parse("10个"), SpokenSet(weight: nil, reps: 10))
        XCTAssertEqual(SpeechParser.parse("做了12下"), SpokenSet(weight: nil, reps: 12))
    }

    func testOnlyWeight() {
        XCTAssertEqual(SpeechParser.parse("60公斤"), SpokenSet(weight: 60, reps: nil))
        XCTAssertEqual(SpeechParser.parse("单个数字82.5"), SpokenSet(weight: 82.5, reps: nil))
    }

    func testChineseNumerals() {
        XCTAssertEqual(SpeechParser.parse("八十公斤八个"), SpokenSet(weight: 80, reps: 8))
        XCTAssertEqual(SpeechParser.parse("六十公斤十次"), SpokenSet(weight: 60, reps: 10))
        XCTAssertEqual(SpeechParser.parse("一百二十公斤五次"), SpokenSet(weight: 120, reps: 5))
        XCTAssertEqual(SpeechParser.parse("二十五个"), SpokenSet(weight: nil, reps: 25))
    }

    func testChineseDecimal() {
        XCTAssertEqual(SpeechParser.parse("八十二点五公斤六次"), SpokenSet(weight: 82.5, reps: 6))
    }

    func testRepsBeforeWeight_unitsDisambiguate() {
        // 单位存在时顺序不影响归属。
        XCTAssertEqual(SpeechParser.parse("8个80公斤"), SpokenSet(weight: 80, reps: 8))
    }

    func testGarbage() {
        XCTAssertTrue(SpeechParser.parse("加油").isEmpty)
        XCTAssertTrue(SpeechParser.parse("").isEmpty)
    }
}

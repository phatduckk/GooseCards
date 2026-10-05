import XCTest
@testable import GooseCards

final class GradingTests: XCTestCase {
    func testGradeBoundaries() {
        let cases: [(Double, String)] = [
            (100, "A+"), (97, "A+"),
            (96, "A"), (93, "A"),
            (92, "A-"), (90, "A-"),
            (89, "B+"), (87, "B+"),
            (86, "B"), (83, "B"),
            (82, "B-"), (80, "B-"),
            (79, "C+"), (77, "C+"),
            (76, "C"), (73, "C"),
            (72, "C-"), (70, "C-"),
            (69, "D+"), (67, "D+"),
            (66, "D"), (65, "D"),
            (64, "D-"), (60, "D-"),
            (59.9, "F"), (0, "F"),
        ]
        for (percent, expected) in cases {
            XCTAssertEqual(Grading.letterGrade(forPercent: percent), expected, "percent \(percent)")
        }
    }
}

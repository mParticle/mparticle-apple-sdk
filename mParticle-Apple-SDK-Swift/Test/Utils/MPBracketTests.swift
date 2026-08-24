import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBracketTests: XCTestCase {
    func testDefaultInitializer() {
        let bracket = MPBracketPRIVATE()
        XCTAssertEqual(bracket.mpId, 0)
        XCTAssertEqual(bracket.low, 0)
        XCTAssertEqual(bracket.high, 100)
        XCTAssertFalse(bracket.shouldForward())
    }

    func testShouldForwardForMatchingBucket() {
        let bracket = MPBracketPRIVATE(mpId: Int64.max - 3_141_592, low: 95, high: 97)
        XCTAssertTrue(bracket.shouldForward())

        bracket.high = 96
        XCTAssertFalse(bracket.shouldForward())
    }

    func testShouldForwardNegativeIdentifier() {
        let bracket = MPBracketPRIVATE(mpId: -(Int64.max - 271_828_182), low: 40, high: 41)
        XCTAssertTrue(bracket.shouldForward())

        bracket.low = 41
        XCTAssertFalse(bracket.shouldForward())
    }

    func testShouldNotForwardInvalidBracket() {
        let bracket = MPBracketPRIVATE(mpId: 0, low: 0, high: 0)
        XCTAssertFalse(bracket.shouldForward())

        bracket.mpId = Int64.max - 3_141_592
        XCTAssertFalse(bracket.shouldForward())
    }

    func testEquality() {
        let bracket = MPBracketPRIVATE(mpId: Int64.max - 3_141_592, low: 95, high: 97)
        let other = MPBracketPRIVATE(mpId: -(Int64.max - 271_828_182), low: 40, high: 41)
        XCTAssertFalse(bracket.isEqual(to: other))
        XCTAssertFalse(bracket.isEqual(to: nil))

        other.mpId = Int64.max - 3_141_592
        other.low = 95
        other.high = 97
        XCTAssertTrue(bracket.isEqual(to: other))
        XCTAssertEqual(bracket, other)
        XCTAssertEqual(bracket.hash, other.hash)
    }

    func testDescription() {
        let bracket = MPBracketPRIVATE(mpId: 1, low: 2, high: 3)
        XCTAssertEqual(bracket.description, "<MPBracket: mpId=1, low=2, high=3>")
    }
}

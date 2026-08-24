import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBracketLogicTests: XCTestCase {
    func testShouldForwardForMatchingBucket() {
        XCTAssertTrue(
            MPBracketLogicPRIVATE.shouldForward(
                mpId: Int64.max - 3_141_592,
                low: 95,
                high: 97
            )
        )
    }

    func testShouldNotForwardOutsideBucket() {
        XCTAssertFalse(
            MPBracketLogicPRIVATE.shouldForward(
                mpId: Int64.max - 3_141_592,
                low: 95,
                high: 96
            )
        )
    }

    func testShouldForwardNegativeIdentifier() {
        XCTAssertTrue(
            MPBracketLogicPRIVATE.shouldForward(
                mpId: -(Int64.max - 271_828_182),
                low: 40,
                high: 41
            )
        )
    }

    func testShouldNotForwardInvalidBracket() {
        XCTAssertFalse(MPBracketLogicPRIVATE.shouldForward(mpId: 0, low: 0, high: 100))
        XCTAssertFalse(MPBracketLogicPRIVATE.shouldForward(mpId: 1, low: 0, high: 0))
    }
}

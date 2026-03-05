import XCTest
@testable import mParticle_ComScore

final class MPKitComScoreTests: XCTestCase {

    func test_kitCode_returns39() {
        XCTAssertEqual(MPKitComScore.kitCode().intValue, 39)
    }
}

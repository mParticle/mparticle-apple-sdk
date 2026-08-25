import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPKitExecStatusTests: XCTestCase {
    func testIsValidReturnCodeBoundaries() {
        XCTAssertTrue(MPKitExecStatusPRIVATE.isValidReturnCode(0))
        XCTAssertTrue(MPKitExecStatusPRIVATE.isValidReturnCode(5))
        XCTAssertFalse(MPKitExecStatusPRIVATE.isValidReturnCode(6))
    }

    func testIsSuccessOnlyForZero() {
        XCTAssertTrue(MPKitExecStatusPRIVATE.isSuccess(0))
        XCTAssertFalse(MPKitExecStatusPRIVATE.isSuccess(1))
        XCTAssertFalse(MPKitExecStatusPRIVATE.isSuccess(5))
    }

    func testDefaultForwardCount() {
        XCTAssertEqual(MPKitExecStatusPRIVATE.defaultForwardCount(forReturnCode: 0), 1)
        XCTAssertEqual(MPKitExecStatusPRIVATE.defaultForwardCount(forReturnCode: 1), 0)
        XCTAssertEqual(MPKitExecStatusPRIVATE.defaultForwardCount(forReturnCode: 5), 0)
    }
}

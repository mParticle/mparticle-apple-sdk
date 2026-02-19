import XCTest
@testable import mParticle_Apple_SDK
@testable import mParticle_Adjust

final class MPKitAdjustTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 68
        let actualKitCode = MPKitAdjust.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 68")
    }
}

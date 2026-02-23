import XCTest
@testable import mParticle_Apple_SDK
@testable import mParticle_Kochava

final class MPKitKochavaTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 37
        let actualKitCode = MPKitKochava.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 37")
    }
}

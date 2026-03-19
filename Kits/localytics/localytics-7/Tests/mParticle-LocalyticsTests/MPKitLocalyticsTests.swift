import XCTest
@testable import mParticle_Localytics

final class MPKitLocalyticsTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 84
        let actualKitCode = MPKitLocalytics.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 84")
    }
}

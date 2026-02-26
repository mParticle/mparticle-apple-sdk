import XCTest
@testable import mParticle_Apptimize

final class MPKitApptimizeTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 105
        let actualKitCode = MPKitApptimize.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 105")
    }
}

import XCTest
@testable import mParticle_Leanplum

final class MPKitLeanplumTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 98
        let actualKitCode = MPKitLeanplum.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 98")
    }
}

import XCTest
@testable import mParticle_Singular

final class MPKitSingularTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 119
        let actualKitCode = MPKitSingular.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 119")
    }
}

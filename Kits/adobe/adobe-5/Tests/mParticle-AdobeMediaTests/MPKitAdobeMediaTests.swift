import XCTest
@testable import mParticle_AdobeMedia

final class MPKitAdobeMediaTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 124
        let actualKitCode = MPKitAdobeMedia.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 124")
    }
}

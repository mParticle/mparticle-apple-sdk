import XCTest
@testable import mParticle_Apple_SDK
@testable import mParticle_Iterable

final class MPKitIterableTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 1003
        let actualKitCode = MPKitIterable.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 1003")
    }
}

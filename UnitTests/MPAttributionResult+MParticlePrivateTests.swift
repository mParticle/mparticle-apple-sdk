import XCTest
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif


class MPAttributionResultMParticlePrivateTests: XCTestCase {
    func testDescription() {
        let result = MPAttributionResult(
            kitCode: 1 as NSNumber,
            kitName: "TestKit"
        )
        result?.linkInfo = [:]
        XCTAssertEqual(result?.description(), """
            MPAttributionResult {
              kitCode: 1
              kitName: TestKit
              linkInfo: {
            }
            }
            """)
    }
}

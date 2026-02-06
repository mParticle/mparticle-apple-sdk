import XCTest
import mParticle_Apple_SDK

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

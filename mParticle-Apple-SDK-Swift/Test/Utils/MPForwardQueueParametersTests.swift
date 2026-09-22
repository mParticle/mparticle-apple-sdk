import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPForwardQueueParametersTests: XCTestCase {
    func testDefaultInitializerIsEmpty() {
        let params = MPForwardQueueParameters()
        XCTAssertEqual(params.count, 0)
        XCTAssertNil(params[0])
    }

    func testInitWithParametersStoresValues() {
        let params = MPForwardQueueParameters(parameters: ["a", 1, true])
        XCTAssertEqual(params.count, 3)
        XCTAssertEqual(params[0] as? String, "a")
    }

    func testInitWithEmptyArrayHasZeroCount() {
        let params = MPForwardQueueParameters(parameters: [])
        XCTAssertEqual(params.count, 0)
    }

    func testAddParameterNilRoundTripsToNil() {
        let params = MPForwardQueueParameters()
        params.addParameter(nil)
        XCTAssertEqual(params.count, 1)
        XCTAssertNil(params[0])
    }

    func testAddParameterStoresValue() {
        let params = MPForwardQueueParameters()
        params.addParameter("value")
        XCTAssertEqual(params.count, 1)
        XCTAssertEqual(params[0] as? String, "value")
    }

    func testSubscriptOutOfRangeReturnsNil() {
        let params = MPForwardQueueParameters(parameters: ["only"])
        XCTAssertNil(params[5])
    }
}

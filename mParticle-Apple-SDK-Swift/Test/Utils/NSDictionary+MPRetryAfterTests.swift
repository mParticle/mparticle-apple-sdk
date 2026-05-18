import XCTest
@testable import mParticle_Apple_SDK_Swift

final class NSDictionaryMPRetryAfterTests: XCTestCase {
    func testRetryDateParsesRFC1123String() {
        let headers: NSDictionary = ["Retry-After": "Wed, 21 Oct 2015 07:28:00 GMT"]

        XCTAssertNotNil(headers.retryDate())
    }

    func testRetryDateReturnsNilForInvalidString() {
        let headers: NSDictionary = ["Retry-After": "not-a-date"]

        XCTAssertNil(headers.retryDate())
    }

    func testRetrySecondsReturnsNumberValue() {
        let headers: NSDictionary = ["Retry-After": NSNumber(value: 42)]

        XCTAssertEqual(headers.retrySeconds()?.doubleValue, 42)
    }

    func testRetrySecondsParsesStringValue() {
        let headers: NSDictionary = ["Retry-After": "123.5"]

        XCTAssertEqual(headers.retrySeconds()?.doubleValue, 123.5)
    }

    func testRetrySecondsReturnsNilForInvalidString() {
        let headers: NSDictionary = ["Retry-After": "not-a-number"]

        XCTAssertNil(headers.retrySeconds())
    }

    func testRetrySecondsReturnsNilWhenHeaderMissing() {
        let headers: NSDictionary = ["Other-Header": "1"]

        XCTAssertNil(headers.retrySeconds())
    }
}

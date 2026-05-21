import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPNetworkCommunicationHelperTests: XCTestCase {
    func testCalculateRetryTimeUsesNumberHeader() {
        let headers: NSDictionary = ["Retry-After": NSNumber(value: 42)]

        XCTAssertEqual(MPNetworkCommunicationHelper.calculateRetryTime(for: headers).doubleValue, 42)
    }

    func testCalculateRetryTimeUsesStringSecondsHeader() {
        let headers: NSDictionary = ["Retry-After": "123.5"]

        XCTAssertEqual(MPNetworkCommunicationHelper.calculateRetryTime(for: headers).doubleValue, 123.5)
    }

    func testCalculateRetryTimeFallsBackToDefaultForInvalidString() {
        let headers: NSDictionary = ["Retry-After": "not-a-number"]

        XCTAssertEqual(MPNetworkCommunicationHelper.calculateRetryTime(for: headers).doubleValue, 7200)
    }

    func testCalculateRetryTimeFallsBackToDefaultWhenHeaderMissing() {
        let headers: NSDictionary = ["Other-Header": "1"]

        XCTAssertEqual(MPNetworkCommunicationHelper.calculateRetryTime(for: headers).doubleValue, 7200)
    }

    func testCalculateRetryTimeClampsToMax() {
        let headers: NSDictionary = ["Retry-After": NSNumber(value: 999999)]

        XCTAssertEqual(MPNetworkCommunicationHelper.calculateRetryTime(for: headers).doubleValue, 86400)
    }

    func testCalculateRetryTimeParsesDateHeader() {
        let futureDate = Date().addingTimeInterval(300)
        let retryAfterHeader = MPDateFormatter.string(fromDateRFC1123: futureDate)
        let headers: NSDictionary = ["Retry-After": retryAfterHeader as Any]

        XCTAssertEqual(MPNetworkCommunicationHelper.calculateRetryTime(for: headers).doubleValue, 300, accuracy: 2.0)
    }

    func testCalculateRetryTimeUsesDefaultForPastDateHeader() {
        let pastDate = Date().addingTimeInterval(-300)
        let retryAfterHeader = MPDateFormatter.string(fromDateRFC1123: pastDate)
        let headers: NSDictionary = ["Retry-After": retryAfterHeader as Any]

        XCTAssertEqual(MPNetworkCommunicationHelper.calculateRetryTime(for: headers).doubleValue, 7200)
    }
}

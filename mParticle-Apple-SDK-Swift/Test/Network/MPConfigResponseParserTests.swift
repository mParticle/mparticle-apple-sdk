import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPConfigResponseParserTests: XCTestCase {
    private let limit: TimeInterval = 60 * 60 * 24 // CONFIG_REQUESTS_MAX_EXPIRATION_AGE

    private func maxAge(_ cacheControl: String?) -> NSNumber? {
        MPConfigResponseParser.maxAge(fromCacheControl: cacheControl, maxExpirationAge: limit)
    }

    func testNilHeaderReturnsNil() {
        XCTAssertNil(maxAge(nil))
    }

    func testHeaderWithoutMaxAgeReturnsNil() {
        XCTAssertNil(maxAge("no-cache, must-revalidate"))
    }

    func testParsesMaxAge() {
        XCTAssertEqual(maxAge("max-age=12"), 12)
    }

    func testParsesMaxAgeAmongOtherDirectives() {
        XCTAssertEqual(maxAge("public, max-age=13, must-revalidate"), 13)
    }

    func testIsCaseInsensitive() {
        XCTAssertEqual(maxAge("MAX-AGE=14"), 14)
    }

    func testClampsToMaxExpirationAge() {
        XCTAssertEqual(maxAge("max-age=99999999"), NSNumber(value: limit))
    }
}

import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPURLTests: XCTestCase {
    func testStoresOutgoingAndCanonicalURLs() throws {
        let outgoingURL = try XCTUnwrap(URL(string: "https://example.com/events"))
        let canonicalURL = try XCTUnwrap(URL(string: "https://nativesdks.mparticle.com/v2/events"))

        let url = try XCTUnwrap(MPURL(url: outgoingURL, defaultURL: canonicalURL))

        XCTAssertEqual(url.url, outgoingURL)
        XCTAssertEqual(url.defaultURL, canonicalURL)
        XCTAssertEqual(NSStringFromClass(MPURL.self), "MPURL")
    }

    func testRejectsMissingURLs() throws {
        let validURL = try XCTUnwrap(URL(string: "https://example.com"))

        XCTAssertNil(MPURL(url: nil, defaultURL: validURL))
        XCTAssertNil(MPURL(url: validURL, defaultURL: nil))
    }
}

import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendMessageInfoTests: XCTestCase {
    private let tokenA = Data([0x01, 0x02, 0x03])
    private let tokenB = Data([0x0a, 0xff])

    // MARK: - base64CrashReport

    func testNilReportReturnsNil() {
        XCTAssertNil(MPBackendMessageInfo.base64CrashReport(nil, maxBytes: nil))
    }

    func testFullReportIsBase64EncodedWhenNoLimit() {
        let expected = Data("crash".utf8).base64EncodedString()
        XCTAssertEqual(MPBackendMessageInfo.base64CrashReport("crash", maxBytes: nil), expected)
    }

    func testReportIsTruncatedToMaxBytesBeforeEncoding() {
        // "abcdef" (6 bytes) truncated to 3 -> "abc"
        let expected = Data("abc".utf8).base64EncodedString()
        XCTAssertEqual(MPBackendMessageInfo.base64CrashReport("abcdef", maxBytes: 3), expected)
    }

    func testReportShorterThanMaxIsUntouched() {
        let expected = Data("ab".utf8).base64EncodedString()
        XCTAssertEqual(MPBackendMessageInfo.base64CrashReport("ab", maxBytes: 100), expected)
    }

    // MARK: - pushRegistration

    func testBothTokensNilIsNoChange() {
        XCTAssertNil(MPBackendMessageInfo.pushRegistration(deviceToken: nil, oldDeviceToken: nil))
    }

    func testUnchangedTokenIsNoChange() {
        XCTAssertNil(MPBackendMessageInfo.pushRegistration(deviceToken: tokenA, oldDeviceToken: tokenA))
    }

    func testNewTokenReportsEnabled() {
        let decision = MPBackendMessageInfo.pushRegistration(deviceToken: tokenA, oldDeviceToken: nil)
        XCTAssertEqual(decision?.status, "true")
        XCTAssertEqual(decision?.logToken, tokenA)
    }

    func testChangedTokenReportsEnabledWithNewToken() {
        let decision = MPBackendMessageInfo.pushRegistration(deviceToken: tokenB, oldDeviceToken: tokenA)
        XCTAssertEqual(decision?.status, "true")
        XCTAssertEqual(decision?.logToken, tokenB)
    }

    func testClearedTokenReportsDisabledWithOldToken() {
        let decision = MPBackendMessageInfo.pushRegistration(deviceToken: nil, oldDeviceToken: tokenA)
        XCTAssertEqual(decision?.status, "false")
        XCTAssertEqual(decision?.logToken, tokenA)
    }
}

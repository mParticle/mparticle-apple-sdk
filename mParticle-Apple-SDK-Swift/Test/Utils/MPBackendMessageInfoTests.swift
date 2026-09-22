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

extension MPBackendMessageInfoTests {
    // MARK: - crashReportBytesToRetain

    func testNoTruncationWhenTheMessageAlreadyFits() {
        XCTAssertNil(MPBackendMessageInfo.crashReportBytesToRetain(
            messageLength: 100,
            maxBytes: 100,
            base64ReportLength: 40
        ))
        XCTAssertNil(MPBackendMessageInfo.crashReportBytesToRetain(
            messageLength: 99,
            maxBytes: 100,
            base64ReportLength: 40
        ))
    }

    func testOverflowIsSubtractedFromTheReportLength() {
        // 120 byte message, 100 byte limit -> 20 bytes must go, all from the 40 byte report.
        XCTAssertEqual(
            MPBackendMessageInfo.crashReportBytesToRetain(messageLength: 120, maxBytes: 100, base64ReportLength: 40),
            20
        )
    }

    func testRetainedLengthGoesNegativeWhenTheRestOfTheMessageAlreadyOverflows() {
        // The caller passes this straight to `truncateMessageDataProperty:toLength:`, which ignores
        // a negative length and leaves the report intact — the original arithmetic did the same.
        XCTAssertEqual(
            MPBackendMessageInfo.crashReportBytesToRetain(messageLength: 200, maxBytes: 100, base64ReportLength: 40),
            -60
        )
    }

    // MARK: - shouldUploadMessage

    private var hasher: MPIHasher { MPIHasher(logger: MPLog(logLevel: .none)) }

    func testTriggerMessageTypeMatchUploads() {
        XCTAssertTrue(MPBackendMessageInfo.shouldUploadMessage(
            ofType: "e",
            messageDictionary: nil,
            triggerMessageTypes: ["x", "e"],
            triggerEventTypes: nil,
            hasher: hasher
        ))
    }

    func testNoTriggersConfiguredNeverUploads() {
        XCTAssertFalse(MPBackendMessageInfo.shouldUploadMessage(
            ofType: "e",
            messageDictionary: ["n": "purchase", "et": "1"],
            triggerMessageTypes: nil,
            triggerEventTypes: nil,
            hasher: hasher
        ))
    }

    func testUnknownMessageTypeDoesNotMatch() {
        XCTAssertFalse(MPBackendMessageInfo.shouldUploadMessage(
            ofType: "v",
            messageDictionary: nil,
            triggerMessageTypes: ["e"],
            triggerEventTypes: nil,
            hasher: hasher
        ))
        XCTAssertFalse(MPBackendMessageInfo.shouldUploadMessage(
            ofType: nil,
            messageDictionary: nil,
            triggerMessageTypes: ["e"],
            triggerEventTypes: nil,
            hasher: hasher
        ))
    }

    func testHashedTriggerEventMatchUploads() {
        let hashed = hasher.hashTriggerEventName("purchase", eventType: "1")

        XCTAssertTrue(MPBackendMessageInfo.shouldUploadMessage(
            ofType: "e",
            messageDictionary: ["n": "purchase", "et": "1"],
            triggerMessageTypes: ["x"],
            triggerEventTypes: [hashed],
            hasher: hasher
        ))
    }

    func testHashedTriggerEventMissDoesNotUpload() {
        XCTAssertFalse(MPBackendMessageInfo.shouldUploadMessage(
            ofType: "e",
            messageDictionary: ["n": "purchase", "et": "1"],
            triggerMessageTypes: ["x"],
            triggerEventTypes: ["some-other-hash"],
            hasher: hasher
        ))
    }

    func testAMessageMissingEventNameOrTypeCannotMatchAnEventTrigger() {
        let hashed = hasher.hashTriggerEventName("purchase", eventType: "1")

        XCTAssertFalse(MPBackendMessageInfo.shouldUploadMessage(
            ofType: "e",
            messageDictionary: ["n": "purchase"],
            triggerMessageTypes: nil,
            triggerEventTypes: [hashed],
            hasher: hasher
        ))
        XCTAssertFalse(MPBackendMessageInfo.shouldUploadMessage(
            ofType: "e",
            messageDictionary: nil,
            triggerMessageTypes: nil,
            triggerEventTypes: [hashed],
            hasher: hasher
        ))
    }
}

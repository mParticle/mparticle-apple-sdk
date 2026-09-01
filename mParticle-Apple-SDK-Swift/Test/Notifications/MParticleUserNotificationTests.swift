import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MParticleUserNotificationTests: XCTestCase {
    private func parse(_ string: String?) -> [String: Any]? {
        guard let string, let data = string.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    // MARK: - redaction branches

    func testContentAvailablePayloadIsPassedThroughWhole() {
        let payload: [AnyHashable: Any] = ["content-available": 1, "custom": "value"]

        let notification = MParticleUserNotificationPRIVATE(notificationDictionary: payload)

        let redacted = parse(notification.redactedUserNotificationString)
        XCTAssertEqual(redacted?["custom"] as? String, "value")
        XCTAssertEqual(redacted?["content-available"] as? Int, 1)
        XCTAssertNil(notification.categoryIdentifier)
    }

    func testApsThatIsNotADictionaryYieldsNil() {
        let notification = MParticleUserNotificationPRIVATE(notificationDictionary: ["aps": "not-a-dictionary"])

        XCTAssertNil(notification.redactedUserNotificationString)
        XCTAssertNil(notification.categoryIdentifier)
    }

    func testMissingAlertKeepsWholePayloadButCapturesCategory() {
        let payload: [AnyHashable: Any] = ["aps": ["category": "PROMO", "badge": 3]]

        let notification = MParticleUserNotificationPRIVATE(notificationDictionary: payload)

        XCTAssertEqual(notification.categoryIdentifier, "PROMO")
        let aps = parse(notification.redactedUserNotificationString)?["aps"] as? [String: Any]
        XCTAssertEqual(aps?["badge"] as? Int, 3)
        XCTAssertEqual(aps?["category"] as? String, "PROMO")
    }

    func testStringAlertIsStrippedFromAps() {
        let payload: [AnyHashable: Any] = ["aps": ["alert": "Hello there", "category": "C", "sound": "default"]]

        let notification = MParticleUserNotificationPRIVATE(notificationDictionary: payload)

        XCTAssertEqual(notification.categoryIdentifier, "C")
        let aps = parse(notification.redactedUserNotificationString)?["aps"] as? [String: Any]
        XCTAssertNil(aps?["alert"], "the string alert must be dropped")
        XCTAssertEqual(aps?["category"] as? String, "C")
        XCTAssertEqual(aps?["sound"] as? String, "default")
    }

    func testDictionaryAlertKeepsAlertButDropsBody() {
        let payload: [AnyHashable: Any] = ["aps": ["alert": ["title": "T", "body": "secret"], "badge": 2]]

        let notification = MParticleUserNotificationPRIVATE(notificationDictionary: payload)

        let aps = parse(notification.redactedUserNotificationString)?["aps"] as? [String: Any]
        let alert = aps?["alert"] as? [String: Any]
        XCTAssertEqual(alert?["title"] as? String, "T")
        XCTAssertNil(alert?["body"], "the alert body must be redacted")
        XCTAssertEqual(aps?["badge"] as? Int, 2)
    }

    func testNilDictionaryProducesNoRedaction() {
        let notification = MParticleUserNotificationPRIVATE(notificationDictionary: nil)

        XCTAssertNil(notification.redactedUserNotificationString)
        XCTAssertNil(notification.categoryIdentifier)
    }

    func testNonSerializablePayloadYieldsNilRatherThanCrashing() {
        let payload: [AnyHashable: Any] = ["aps": ["alert": "hi"], "bad": Date()]

        let notification = MParticleUserNotificationPRIVATE(notificationDictionary: payload)

        XCTAssertNil(notification.redactedUserNotificationString)
    }

    // MARK: - equality

    func testEqualWhenBothIdsPositiveAndMatch() {
        XCTAssertTrue(MParticleUserNotificationPRIVATE.isEqual(userNotificationId: 42,
                                                               redactedString: nil,
                                                               otherUserNotificationId: 42,
                                                               otherRedactedString: nil))
    }

    func testDifferentIdsWithoutRedactedStringsAreNotEqual() {
        XCTAssertFalse(MParticleUserNotificationPRIVATE.isEqual(userNotificationId: 1,
                                                                redactedString: nil,
                                                                otherUserNotificationId: 2,
                                                                otherRedactedString: nil))
    }

    func testEqualByRedactedJSONRegardlessOfKeyOrder() {
        let a = "{\"aps\":{\"badge\":1},\"x\":\"y\"}"
        let b = "{\"x\":\"y\",\"aps\":{\"badge\":1}}"

        XCTAssertTrue(MParticleUserNotificationPRIVATE.isEqual(userNotificationId: 0,
                                                               redactedString: a,
                                                               otherUserNotificationId: 0,
                                                               otherRedactedString: b))
    }

    func testDifferentRedactedJSONIsNotEqual() {
        XCTAssertFalse(MParticleUserNotificationPRIVATE.isEqual(userNotificationId: 0,
                                                                redactedString: "{\"a\":1}",
                                                                otherUserNotificationId: 0,
                                                                otherRedactedString: "{\"a\":2}"))
    }

    func testMissingRedactedStringIsNotEqual() {
        XCTAssertFalse(MParticleUserNotificationPRIVATE.isEqual(userNotificationId: 0,
                                                                redactedString: "{\"a\":1}",
                                                                otherUserNotificationId: 0,
                                                                otherRedactedString: nil))
    }
}

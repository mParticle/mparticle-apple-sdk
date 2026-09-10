import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MParticleUserNotificationTests: XCTestCase {
    private enum Mode {
        static let autoDetect = 0
        static let remote = 1
        static let local = 2
    }

    private func makeNotification(_ payload: [AnyHashable: Any]?,
                                  state: String = "foreground",
                                  behavior: UInt = 0,
                                  mode: Int = Mode.remote) -> MParticleUserNotificationPRIVATE {
        MParticleUserNotificationPRIVATE(dictionary: payload, state: state, behavior: behavior, mode: mode)
    }

    private func parse(_ string: String?) -> [String: Any]? {
        guard let string, let data = string.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    // MARK: - Objective-C runtime identity

    func testObjectiveCRuntimeIdentityIsPreserved() {
        XCTAssertEqual(NSStringFromClass(MParticleUserNotificationPRIVATE.self), "MParticleUserNotification")
    }

    // MARK: - designated initializer

    func testInitializerSeedsTheDefaultsTheWrapperSet() {
        let notification = makeNotification(nil, state: "background", behavior: 4)

        XCTAssertEqual(notification.state, "background")
        XCTAssertEqual(notification.behavior, 4)
        XCTAssertEqual(notification.type, "received", "type must stay kMPPushMessageReceived")
        XCTAssertTrue(notification.shouldPersist)
        XCTAssertNotNil(notification.uuid)
        XCTAssertNil(notification.actionTitle)
        XCTAssertNil(notification.actionIdentifier)
        XCTAssertEqual(notification.userNotificationId, 0)
        XCTAssertLessThan(abs(notification.receiptTime.timeIntervalSinceNow), 5)
    }

    func testAutoDetectModeIsCoercedToRemote() {
        XCTAssertEqual(makeNotification(nil, mode: Mode.autoDetect).mode, Mode.remote)
    }

    func testExplicitModeIsPreserved() {
        XCTAssertEqual(makeNotification(nil, mode: Mode.local).mode, Mode.local)
    }

    // MARK: - redaction branches

    func testContentAvailablePayloadIsPassedThroughWhole() {
        let payload: [AnyHashable: Any] = ["content-available": 1, "custom": "value"]

        let notification = makeNotification(payload)

        let redacted = parse(notification.redactedUserNotificationString)
        XCTAssertEqual(redacted?["custom"] as? String, "value")
        XCTAssertEqual(redacted?["content-available"] as? Int, 1)
        XCTAssertNil(notification.categoryIdentifier)
    }

    func testApsThatIsNotADictionaryYieldsNil() {
        let notification = makeNotification(["aps": "not-a-dictionary"])

        XCTAssertNil(notification.redactedUserNotificationString)
        XCTAssertNil(notification.categoryIdentifier)
    }

    func testMissingAlertKeepsWholePayloadButCapturesCategory() {
        let payload: [AnyHashable: Any] = ["aps": ["category": "PROMO", "badge": 3]]

        let notification = makeNotification(payload)

        XCTAssertEqual(notification.categoryIdentifier, "PROMO")
        let aps = parse(notification.redactedUserNotificationString)?["aps"] as? [String: Any]
        XCTAssertEqual(aps?["badge"] as? Int, 3)
        XCTAssertEqual(aps?["category"] as? String, "PROMO")
    }

    func testStringAlertIsStrippedFromAps() {
        let payload: [AnyHashable: Any] = ["aps": ["alert": "Hello there", "category": "C", "sound": "default"]]

        let notification = makeNotification(payload)

        XCTAssertEqual(notification.categoryIdentifier, "C")
        let aps = parse(notification.redactedUserNotificationString)?["aps"] as? [String: Any]
        XCTAssertNil(aps?["alert"], "the string alert must be dropped")
        XCTAssertEqual(aps?["category"] as? String, "C")
        XCTAssertEqual(aps?["sound"] as? String, "default")
    }

    func testDictionaryAlertKeepsAlertButDropsBody() {
        let payload: [AnyHashable: Any] = ["aps": ["alert": ["title": "T", "body": "secret"], "badge": 2]]

        let notification = makeNotification(payload)

        let aps = parse(notification.redactedUserNotificationString)?["aps"] as? [String: Any]
        let alert = aps?["alert"] as? [String: Any]
        XCTAssertEqual(alert?["title"] as? String, "T")
        XCTAssertNil(alert?["body"], "the alert body must be redacted")
        XCTAssertEqual(aps?["badge"] as? Int, 2)
    }

    func testNilDictionaryProducesNoRedaction() {
        let notification = makeNotification(nil)

        XCTAssertNil(notification.redactedUserNotificationString)
        XCTAssertNil(notification.categoryIdentifier)
    }

    func testNonSerializablePayloadYieldsNilRatherThanCrashing() {
        let payload: [AnyHashable: Any] = ["aps": ["alert": "hi"], "bad": Date()]

        let notification = makeNotification(payload)

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

    func testIsEqualRejectsAForeignType() {
        XCTAssertFalse(makeNotification(nil).isEqual(NSObject()))
        XCTAssertFalse(makeNotification(nil).isEqual(nil))
    }

    func testIsEqualComparesTwoInstancesByRedactedPayload() {
        let payload: [AnyHashable: Any] = ["aps": ["alert": "hi", "badge": 1]]

        XCTAssertEqual(makeNotification(payload), makeNotification(payload))
    }

    func testHashIsTheNotificationId() {
        let notification = makeNotification(nil)
        notification.userNotificationId = 99

        XCTAssertEqual(notification.hash, 99)
    }

    // MARK: - description

    func testDescriptionOmitsAbsentFieldsAndIncludesPresentOnes() {
        let bare = makeNotification(nil)
        let bareDescription = bare.description
        XCTAssertTrue(bareDescription.hasPrefix("User Notification\n"))
        XCTAssertTrue(bareDescription.contains(" State: foreground\n"))
        XCTAssertTrue(bareDescription.contains(" Type Id: received\n"))
        XCTAssertFalse(bareDescription.contains("Behavior:"))
        XCTAssertFalse(bareDescription.contains("Notification Id:"))
        XCTAssertFalse(bareDescription.contains("Category identifier:"))

        let full = makeNotification(["aps": ["alert": "hi", "category": "PROMO"]], behavior: 2)
        full.userNotificationId = 7
        let fullDescription = full.description
        XCTAssertTrue(fullDescription.contains(" Category identifier: PROMO\n"))
        XCTAssertTrue(fullDescription.contains(" Behavior: 2\n"))
        XCTAssertTrue(fullDescription.contains(" Notification Id: 7\n"))
        XCTAssertTrue(fullDescription.contains(" Redacted notification: "))
    }

    // MARK: - NSSecureCoding

    func testSupportsSecureCoding() {
        XCTAssertTrue(MParticleUserNotificationPRIVATE.supportsSecureCoding)
    }

    /// The coder mixes class-checked and unchecked decodes; this pins that the archive still
    /// round-trips under `requiringSecureCoding: true`, which is the only thing that asymmetry
    /// could plausibly break.
    func testSecureCodingRoundTripPreservesEveryField() throws {
        let original = makeNotification(["aps": ["alert": "hi", "category": "PROMO", "badge": 5]],
                                        state: "background",
                                        behavior: 6,
                                        mode: Mode.local)
        original.userNotificationId = 1234
        original.actionTitle = "Open"
        original.actionIdentifier = "action.open"
        original.deferredPayload = ["k": "v"]

        let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
        let restored = try XCTUnwrap(NSKeyedUnarchiver.unarchivedObject(ofClass: MParticleUserNotificationPRIVATE.self,
                                                                        from: data))

        XCTAssertEqual(restored.state, "background")
        XCTAssertEqual(restored.type, "received")
        XCTAssertEqual(restored.uuid, original.uuid)
        XCTAssertEqual(restored.userNotificationId, 1234)
        XCTAssertEqual(restored.behavior, 6)
        XCTAssertEqual(restored.mode, Mode.local)
        XCTAssertEqual(restored.categoryIdentifier, "PROMO")
        XCTAssertEqual(restored.redactedUserNotificationString, original.redactedUserNotificationString)
        XCTAssertEqual(restored.actionTitle, "Open")
        XCTAssertEqual(restored.actionIdentifier, "action.open")
        XCTAssertEqual(restored.deferredPayload?["k"] as? String, "v")
        XCTAssertTrue(restored.shouldPersist)
        XCTAssertEqual(restored.receiptTime.timeIntervalSince1970,
                       original.receiptTime.timeIntervalSince1970,
                       accuracy: 0.001)
    }

    func testSecureCodingRoundTripOmitsFieldsThatWereNeverSet() throws {
        let original = makeNotification(nil)

        let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
        let restored = try XCTUnwrap(NSKeyedUnarchiver.unarchivedObject(ofClass: MParticleUserNotificationPRIVATE.self,
                                                                        from: data))

        XCTAssertNil(restored.redactedUserNotificationString)
        XCTAssertNil(restored.categoryIdentifier)
        XCTAssertNil(restored.actionTitle)
        XCTAssertNil(restored.actionIdentifier)
        XCTAssertNil(restored.localAlertDate)
        XCTAssertNil(restored.deferredPayload)
    }
}

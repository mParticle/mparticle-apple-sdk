import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPMessageBuilderFieldsTests: XCTestCase {
    // MARK: - stringForMessageTypeRawValue

    func testStringForEveryKnownMessageType() {
        let expected: [MPMessageTypeSwift: String] = [
            .unknown: "unknown",
            .sessionStart: "ss",
            .sessionEnd: "se",
            .screenView: "v",
            .event: "e",
            .crashReport: "x",
            .optOut: "o",
            .firstRun: "fr",
            .preAttribution: "unknown",
            .pushRegistration: "pr",
            .appStateTransition: "ast",
            .pushNotification: "pm",
            .networkPerformance: "npe",
            .breadcrumb: "bc",
            .profile: "pro",
            .pushNotificationInteraction: "pre",
            .commerceEvent: "cm",
            .userAttributeChange: "uac",
            .userIdentityChange: "uic",
            .media: "media"
        ]

        for (type, string) in expected {
            XCTAssertEqual(
                MPMessageBuilderFields.string(forMessageTypeRawValue: type.rawValue),
                string,
                "\(type)"
            )
        }
    }

    func testStringForMessageTypeRawValueIsNilForAnUnusedRawValue() {
        // 19 sits in the gap between userIdentityChange (18) and media (20).
        XCTAssertNil(MPMessageBuilderFields.string(forMessageTypeRawValue: 19))
    }

    // MARK: - rawMessageTypeForString

    func testRawMessageTypeForEveryKnownString() {
        let expected: [String: MPMessageTypeSwift] = [
            "unknown": .unknown,
            "ss": .sessionStart,
            "se": .sessionEnd,
            "v": .screenView,
            "e": .event,
            "x": .crashReport,
            "o": .optOut,
            "fr": .firstRun,
            "pr": .pushRegistration,
            "ast": .appStateTransition,
            "pm": .pushNotification,
            "npe": .networkPerformance,
            "bc": .breadcrumb,
            "pro": .profile,
            "pre": .pushNotificationInteraction,
            "cm": .commerceEvent,
            "uac": .userAttributeChange,
            "uic": .userIdentityChange,
            "media": .media
        ]

        for (string, type) in expected {
            XCTAssertEqual(
                MPMessageBuilderFields.rawMessageType(forString: string),
                NSNumber(value: type.rawValue),
                string
            )
        }
    }

    func testRawMessageTypeForStringIsNilForAnUnrecognizedString() {
        XCTAssertNil(MPMessageBuilderFields.rawMessageType(forString: "nonsense"))
    }

    func testUnrecognizedStringNeverRoundTripsToPreAttribution() {
        // kMPMessageTypeStringPreAttribution duplicates kMPMessageTypeStringUnknown's
        // value ("unknown"), and unknown is checked first, so "unknown" always maps
        // back to .unknown, never .preAttribution.
        XCTAssertEqual(
            MPMessageBuilderFields.rawMessageType(forString: "unknown"),
            NSNumber(value: MPMessageTypeSwift.unknown.rawValue)
        )
    }

    // MARK: - filteredUserIds

    func testFilteredUserIdsDropsZeroAndKeepsOrder() {
        let userIds = MPMessageBuilderFields.filteredUserIds(from: "0,42,0,7")
        XCTAssertEqual(userIds, [42, 7])
    }

    func testFilteredUserIdsIsEmptyForAllZeroesOrNonNumeric() {
        XCTAssertEqual(MPMessageBuilderFields.filteredUserIds(from: "0,0"), [])
        XCTAssertEqual(MPMessageBuilderFields.filteredUserIds(from: "abc"), [])
    }

    // MARK: - userAttributeChangeFields

    func testUserAttributeChangeFieldsForANewAttribute() {
        let fields = MPMessageBuilderFields.userAttributeChangeFields(
            deleted: false,
            key: "color",
            oldValue: nil,
            newValue: "blue"
        )

        XCTAssertFalse(fields.deleted)
        XCTAssertEqual(fields.attributeKey, "color")
        XCTAssertEqual(fields.oldValue as? NSNull, NSNull())
        XCTAssertEqual(fields.newValue as? String, "blue")
        XCTAssertTrue(fields.newlyAdded)
    }

    func testUserAttributeChangeFieldsForAnUpdatedAttribute() {
        let fields = MPMessageBuilderFields.userAttributeChangeFields(
            deleted: false,
            key: "color",
            oldValue: "red",
            newValue: "blue"
        )

        XCTAssertEqual(fields.oldValue as? String, "red")
        XCTAssertEqual(fields.newValue as? String, "blue")
        XCTAssertFalse(fields.newlyAdded)
    }

    func testUserAttributeChangeFieldsForADeletedAttributeHasNoNewValue() {
        let fields = MPMessageBuilderFields.userAttributeChangeFields(
            deleted: true,
            key: "color",
            oldValue: "red",
            newValue: "blue"
        )

        XCTAssertTrue(fields.deleted)
        XCTAssertEqual(fields.oldValue as? String, "red")
        XCTAssertEqual(fields.newValue as? NSNull, NSNull())
    }

    // MARK: - stateTransitionFields

    func testStateTransitionFieldsPassesEveryFieldThrough() {
        let fields = MPMessageBuilderFields.stateTransitionFields(
            sourceApplication: "com.example.app",
            launchURLString: "myapp://open",
            launchParameters: "params",
            previousSessionInterruptions: 3,
            sessionFinalized: true
        )

        XCTAssertEqual(fields.sourceApplication, "com.example.app")
        XCTAssertEqual(fields.launchURLString, "myapp://open")
        XCTAssertEqual(fields.launchParameters as? String, "params")
        XCTAssertEqual(fields.numberOfSessionInterruptions, 3)
        XCTAssertTrue(fields.sessionFinalized)
    }

    func testStateTransitionFieldsPreservesNilsForMissingLaunchInfo() {
        let fields = MPMessageBuilderFields.stateTransitionFields(
            sourceApplication: nil,
            launchURLString: nil,
            launchParameters: nil,
            previousSessionInterruptions: 0,
            sessionFinalized: false
        )

        XCTAssertNil(fields.sourceApplication)
        XCTAssertNil(fields.launchURLString)
        XCTAssertNil(fields.launchParameters)
        XCTAssertEqual(fields.numberOfSessionInterruptions, 0)
        XCTAssertFalse(fields.sessionFinalized)
    }
}

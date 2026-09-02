import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPDataPlanFilterPolicyTests: XCTestCase {
    // MARK: - key building

    func testScreenKeyStripsUnderscores() {
        XCTAssertEqual(
            MPDataPlanFilterPolicy.matchKey(screenName: "my_screen_name"),
            "screen_view.myscreenname"
        )
    }

    func testEventKeyOrdersNameBeforeTypeAndLowercasesTheType() {
        XCTAssertEqual(
            MPDataPlanFilterPolicy.matchKey(eventType: "User_Content", eventName: "My Event"),
            "custom_event.My Event.usercontent"
        )
    }

    func testMatchKeyStripsUnderscoresFromTheKeyOnly() {
        XCTAssertEqual(
            MPDataPlanFilterPolicy.matchKey(matchType: "product_action", key: "add_to_cart"),
            "product_action.addtocart"
        )
    }

    func testNilComponentsRenderAsTheObjCNilDescription() {
        // These keys came from `%@`, which renders nil as "(null)".
        XCTAssertEqual(MPDataPlanFilterPolicy.matchKey(screenName: nil), "screen_view.(null)")
        XCTAssertEqual(
            MPDataPlanFilterPolicy.matchKey(matchType: "product_action", key: nil),
            "product_action.(null)"
        )
        XCTAssertEqual(
            MPDataPlanFilterPolicy.matchKey(eventType: nil, eventName: nil),
            "custom_event.(null).(null)"
        )
    }

    // MARK: - keyForMatch

    func testKeyForCustomEventNeedsBothNameAndType() {
        XCTAssertEqual(
            MPDataPlanFilterPolicy.key(forMatch: [
                "type": "custom_event",
                "criteria": ["event_name": "e", "custom_event_type": "Other"]
            ]),
            "custom_event.e.other"
        )
        XCTAssertNil(MPDataPlanFilterPolicy.key(forMatch: [
            "type": "custom_event", "criteria": ["event_name": "e"]
        ]))
        XCTAssertNil(MPDataPlanFilterPolicy.key(forMatch: [
            "type": "custom_event", "criteria": ["custom_event_type": "Other"]
        ]))
    }

    func testKeyForScreenViewAndActions() {
        XCTAssertEqual(
            MPDataPlanFilterPolicy.key(forMatch: [
                "type": "screen_view", "criteria": ["screen_name": "a_b"]
            ]),
            "screen_view.ab"
        )
        XCTAssertEqual(
            MPDataPlanFilterPolicy.key(forMatch: [
                "type": "promotion_action", "criteria": ["action": "view"]
            ]),
            "promotion_action.view"
        )
    }

    func testKeyForSelfNamedMatchTypes() {
        for type in ["product_impression", "user_attributes", "user_identities"] {
            XCTAssertEqual(MPDataPlanFilterPolicy.key(forMatch: ["type": type]), type)
        }
    }

    func testKeyIsNilForUnknownOrMissingTypes() {
        XCTAssertNil(MPDataPlanFilterPolicy.key(forMatch: nil))
        XCTAssertNil(MPDataPlanFilterPolicy.key(forMatch: [:]))
        XCTAssertNil(MPDataPlanFilterPolicy.key(forMatch: ["type": "nonsense"]))
    }

    // MARK: - blocking

    func testNothingIsBlockedWhenBlockingIsOff() {
        XCTAssertFalse(MPDataPlanFilterPolicy.isBlockedUserAttributeKey(
            "unplanned", plannedAttributes: ["planned"], blockUserAttributes: false
        ))
        XCTAssertFalse(MPDataPlanFilterPolicy.isBlockedUserIdentityType(
            7, plannedIdentities: [NSNumber(value: 1)], blockUserIdentities: false
        ))
    }

    func testNothingIsBlockedWhenThePlanHasNoEntry() {
        XCTAssertFalse(MPDataPlanFilterPolicy.isBlockedUserAttributeKey(
            "anything", plannedAttributes: nil, blockUserAttributes: true
        ))
        XCTAssertFalse(MPDataPlanFilterPolicy.isBlockedUserIdentityType(
            7, plannedIdentities: nil, blockUserIdentities: true
        ))
    }

    func testUnplannedKeysAndIdentitiesAreBlocked() {
        XCTAssertTrue(MPDataPlanFilterPolicy.isBlockedUserAttributeKey(
            "unplanned", plannedAttributes: ["planned"], blockUserAttributes: true
        ))
        XCTAssertFalse(MPDataPlanFilterPolicy.isBlockedUserAttributeKey(
            "planned", plannedAttributes: ["planned"], blockUserAttributes: true
        ))
        XCTAssertTrue(MPDataPlanFilterPolicy.isBlockedUserIdentityType(
            7, plannedIdentities: [NSNumber(value: 1)], blockUserIdentities: true
        ))
        XCTAssertFalse(MPDataPlanFilterPolicy.isBlockedUserIdentityType(
            1, plannedIdentities: [NSNumber(value: 1)], blockUserIdentities: true
        ))
    }

    func testAnEmptyPlanBlocksEverything() {
        XCTAssertTrue(MPDataPlanFilterPolicy.isBlockedUserAttributeKey(
            "anything", plannedAttributes: [], blockUserAttributes: true
        ))
        XCTAssertTrue(MPDataPlanFilterPolicy.isBlockedUserIdentityType(
            1, plannedIdentities: [], blockUserIdentities: true
        ))
    }
}

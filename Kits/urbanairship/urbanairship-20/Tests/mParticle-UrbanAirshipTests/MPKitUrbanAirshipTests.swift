import XCTest
@testable import mParticle_Apple_SDK
@testable import mParticle_UrbanAirship

final class MPKitUrbanAirshipTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 25
        let actualKitCode = MPKitUrbanAirship.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 25")
    }

    func testEventTagsMappingUsesCorrectKey() {
        let kit = MPKitUrbanAirship()
        kit.configuration = makeConfiguration(
            eventTagsMapType: "EventClass.Id",
            eventAttributeTagsMapType: "EventAttributeClass.Id"
        )

        let mappings = kit.value(forKey: "eventTagsMapping") as? [NSObject]
        let firstMapType = mappings?.first?.value(forKey: "mapType") as? String

        XCTAssertEqual(firstMapType, "EventClass.Id",
                       "eventTagsMapping should be populated from eventUserTags, not eventAttributeUserTags")
    }

    func testEventAttributeTagsMappingUsesCorrectKey() {
        let kit = MPKitUrbanAirship()
        kit.configuration = makeConfiguration(
            eventTagsMapType: "EventClass.Id",
            eventAttributeTagsMapType: "EventAttributeClass.Id"
        )

        let mappings = kit.value(forKey: "eventAttributeTagsMapping") as? [NSObject]
        let firstMapType = mappings?.first?.value(forKey: "mapType") as? String

        XCTAssertEqual(firstMapType, "EventAttributeClass.Id",
                       "eventAttributeTagsMapping should be populated from eventAttributeUserTags")
    }

    // MARK: - Malformed server configuration

    // Server configuration is parsed JSON, so any value can arrive as a number, boolean or
    // container.
    // Nothing here calls -start: it takes off the real vendor SDK, once per process.

    private let nonStringValues: [Any] = [42, true, [Any](), [String: Any]()]

    func testNonStringNamedUserIdFieldIsTreatedAsUnset() {
        for value in nonStringValues {
            let kit = MPKitUrbanAirship()
            kit.configuration = ["namedUserIdField": value]

            // .other maps to no associated identifier, so neither path reaches the Airship SDK.
            let status = kit.setUserIdentity("user-1", identityType: .other)

            XCTAssertEqual(status.returnCode, .unavailable,
                           "namedUserIdField of \(type(of: value)) should be treated as unset")
        }
    }

    func testNonStringTagMappingsAreIgnored() {
        for value in nonStringValues {
            let kit = MPKitUrbanAirship()
            kit.configuration = ["eventUserTags": value, "eventAttributeUserTags": value]

            XCTAssertEqual((kit.value(forKey: "eventTagsMapping") as? [NSObject])?.count ?? 0, 0)
            XCTAssertEqual((kit.value(forKey: "eventAttributeTagsMapping") as? [NSObject])?.count ?? 0, 0)
        }
    }

    func testMalformedTagMappingJSONIsIgnored() {
        for json in ["[1, \"tag\", null, []]", "{\"maptype\": \"EventClass.Id\"}"] {
            let encoded = json.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? json
            let kit = MPKitUrbanAirship()
            kit.configuration = ["eventUserTags": encoded, "eventAttributeUserTags": encoded]

            XCTAssertEqual((kit.value(forKey: "eventTagsMapping") as? [NSObject])?.count ?? 0, 0)
            XCTAssertEqual((kit.value(forKey: "eventAttributeTagsMapping") as? [NSObject])?.count ?? 0, 0)
        }
    }

    func testNonScalarTagSettingsAreTreatedAsOff() {
        for value in [[Any](), [String: Any]()] as [Any] {
            let kit = MPKitUrbanAirship()
            kit.configuration = ["enableTags": value, "includeUserAttributes": value]
            kit.perform(Selector(("updateConfiguredSettings")))

            XCTAssertEqual(kit.value(forKey: "enableTags") as? Bool, false)
            XCTAssertEqual(kit.value(forKey: "includeUserAttributes") as? Bool, false)
        }

        let kit = MPKitUrbanAirship()
        kit.configuration = ["enableTags": "true", "includeUserAttributes": true]
        kit.perform(Selector(("updateConfiguredSettings")))

        XCTAssertEqual(kit.value(forKey: "enableTags") as? Bool, true)
        XCTAssertEqual(kit.value(forKey: "includeUserAttributes") as? Bool, true)
    }

    // MARK: - Logout

    private let kitIdentifierKeys: Set<String> = [
        "customer_id", "facebook_id", "twitter_id", "google_id",
        "microsoft_id", "yahoo_id", "email", "facebook_custom_audience_id"
    ]

    private let logoutSelector = #selector(MPKitProtocol.onLogoutComplete(_:request:))

    func testLogoutResetsTheMappedNamedUserAndRemovesTheKitIdentifiers() {
        let kit = AirshipRecordingKit()
        kit.configuration = ["namedUserIdField": "customerId"]
        guard kit.responds(to: logoutSelector) else {
            return XCTFail("The kit should handle logout")
        }

        let status = kit.onLogoutComplete(FilteredUserStub(), request: FilteredMPIdentityApiRequest())

        XCTAssertEqual(status.returnCode, .success)
        XCTAssertEqual(kit.calls, [.reset, .associate(nil, kitIdentifierKeys)],
                       "Logout should reset the contact and remove only the identifiers the kit sets")
    }

    func testLogoutLeavesTheContactAloneWhenNoNamedUserIsMapped() {
        let configurations: [[String: String]] = [[:], ["namedUserIdField": "none"]]
        for configuration in configurations {
            let kit = AirshipRecordingKit()
            kit.configuration = configuration
            guard kit.responds(to: logoutSelector) else {
                return XCTFail("The kit should handle logout")
            }

            let status = kit.onLogoutComplete(FilteredUserStub(), request: FilteredMPIdentityApiRequest())

            XCTAssertEqual(status.returnCode, .success)
            XCTAssertEqual(kit.calls, [.associate(nil, kitIdentifierKeys)],
                           "With configuration \(configuration) the kit never set a named user to reset")
        }
    }

    func testLogoutAppliesTheNextUsersIdentitiesAfterTheReset() {
        let kit = AirshipRecordingKit()
        kit.configuration = ["namedUserIdField": "customerId"]
        guard kit.responds(to: logoutSelector) else {
            return XCTFail("The kit should handle logout")
        }
        let nextUser = FilteredUserStub(userIdentities: [
            NSNumber(value: MPUserIdentity.customerId.rawValue): "example-user-id",
            NSNumber(value: MPUserIdentity.email.rawValue): "user@example.com"
        ])

        _ = kit.onLogoutComplete(nextUser, request: FilteredMPIdentityApiRequest())

        XCTAssertEqual(Array(kit.calls.prefix(2)), [.reset, .associate(nil, kitIdentifierKeys)])
        let applied = kit.calls.dropFirst(2)
        XCTAssertEqual(applied.count, 3)
        XCTAssertTrue(applied.contains(.identify("example-user-id")))
        XCTAssertTrue(applied.contains(.associate("example-user-id", ["customer_id"])))
        XCTAssertTrue(applied.contains(.associate("user@example.com", ["email"])))
    }

    func testSetUserIdentityWritesTheNamedUserAndIdentifier() {
        let kit = AirshipRecordingKit()
        kit.configuration = ["namedUserIdField": "email"]
        // Without the private write methods this call would reach the Airship SDK, which is not taken off.
        guard MPKitUrbanAirship.instancesRespond(to: NSSelectorFromString("identifyAirshipContact:")) else {
            return XCTFail("The kit should route its Airship identity writes through its own methods")
        }

        let status = kit.setUserIdentity("user@example.com", identityType: .email)

        XCTAssertEqual(status.returnCode, .success)
        XCTAssertEqual(kit.calls, [.identify("user@example.com"), .associate("user@example.com", ["email"])])
    }

    private func makeConfiguration(eventTagsMapType: String, eventAttributeTagsMapType: String) -> [String: String] {
        [
            "appKey": "test-app-key",
            "appSecret": "test-app-secret",
            "eventUserTags": percentEncodedTagJSON(mapType: eventTagsMapType),
            "eventAttributeUserTags": percentEncodedTagJSON(mapType: eventAttributeTagsMapType)
        ]
    }

    private func percentEncodedTagJSON(mapType: String) -> String {
        let json = "[{\"maptype\":\"\(mapType)\",\"value\":\"test-tag\",\"map\":\"abc123\"}]"
        return json.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? json
    }
}

// Replaces the kit's private Airship identity writes through Objective-C dispatch, so tests can
// read what the kit asks of Airship without taking off the Airship SDK.
private final class AirshipRecordingKit: MPKitUrbanAirship {
    enum Call: Equatable {
        case identify(String)
        case reset
        case associate(String?, Set<String>)
    }

    private(set) var calls: [Call] = []

    @objc(identifyAirshipContact:)
    func identifyAirshipContact(_ namedUser: String) {
        calls.append(.identify(namedUser))
    }

    @objc func resetAirshipContact() {
        calls.append(.reset)
    }

    @objc(setAirshipAssociatedIdentifier:forKeys:)
    func setAirshipAssociatedIdentifier(_ identifier: String?, forKeys keys: [String]) {
        calls.append(.associate(identifier, Set(keys)))
    }
}

private final class FilteredUserStub: FilteredMParticleUser {
    private let stubIdentities: [NSNumber: String]

    init(userIdentities: [NSNumber: String] = [:]) {
        stubIdentities = userIdentities
        super.init()
    }

    override var userIdentities: [NSNumber: String] { stubIdentities }
}

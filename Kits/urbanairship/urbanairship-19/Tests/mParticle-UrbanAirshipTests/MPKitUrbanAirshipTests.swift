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

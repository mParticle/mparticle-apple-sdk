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
        kit.setConfiguration(makeConfiguration(
            eventTagsMapType: "EventClass.Id",
            eventAttributeTagsMapType: "EventAttributeClass.Id"
        ))

        let mappings = kit.value(forKey: "eventTagsMapping") as? [NSObject]
        let firstMapType = mappings?.first?.value(forKey: "mapType") as? String

        XCTAssertEqual(firstMapType, "EventClass.Id",
                       "eventTagsMapping should be populated from eventUserTags, not eventAttributeUserTags")
    }

    func testEventAttributeTagsMappingUsesCorrectKey() {
        let kit = MPKitUrbanAirship()
        kit.setConfiguration(makeConfiguration(
            eventTagsMapType: "EventClass.Id",
            eventAttributeTagsMapType: "EventAttributeClass.Id"
        ))

        let mappings = kit.value(forKey: "eventAttributeTagsMapping") as? [NSObject]
        let firstMapType = mappings?.first?.value(forKey: "mapType") as? String

        XCTAssertEqual(firstMapType, "EventAttributeClass.Id",
                       "eventAttributeTagsMapping should be populated from eventAttributeUserTags")
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

import XCTest
@testable import mParticle_FirebaseGA4

final class MPKitFirebaseGA4AnalyticsSwiftTests: XCTestCase {

    var kit: MPKitFirebaseGA4Analytics!

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()
        kit = MPKitFirebaseGA4Analytics()
        kit.configuration = [:]
    }

    override func tearDownWithError() throws {
        kit = nil
        try super.tearDownWithError()
    }

    // MARK: - convertToKeyValuePairs

    func test_convertToKeyValuePairs_createsLowercasedMapping() {
        let mappings: [[String: String]] = [
            ["value": "ad_storage", "map": "Advertising"],
            ["value": "analytics_storage", "map": "Analytics"]
        ]

        let result = kit.convert(toKeyValuePairs: mappings)
        XCTAssertEqual(result["ad_storage"] as! String, "advertising")
        XCTAssertEqual(result["analytics_storage"] as! String, "analytics")
    }

    // MARK: - mappingForKey

    func test_mappingForKey_withValidJSON_returnsArray() {
        let jsonString = """
        [
            { "value": "ad_storage", "map": "Advertising" },
            { "value": "analytics_storage", "map": "Analytics" }
        ]
        """
        kit.configuration["consentMappingSDK"] = jsonString

        let result = kit.mapping(forKey: "consentMappingSDK")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.count, 2)
    }

    func test_mappingForKey_withInvalidJSON_returnsNil() {
        kit.configuration["consentMappingSDK"] = "{ not valid json }"
        let result = kit.mapping(forKey: "consentMappingSDK")
        XCTAssertNil(result)
    }

    // MARK: - resolvedConsentForMappingKey

    func test_resolvedConsentForMappingKey_withGDPRMapping_returnsTrue() {
        let consent = MPGDPRConsent()
        consent.consented = true
        let gdprConsents = ["advertising": consent]

        let mapping = ["ad_storage": "advertising"]

        let result = kit.resolvedConsent(
            forMappingKey: "ad_storage",
            defaultKey: "defaultAdStorageConsentSDK",
            gdprConsents: gdprConsents,
            mapping: mapping
        )
        XCTAssertEqual(result, true)
    }

    func test_resolvedConsentForMappingKey_withGDPRMapping_returnsFalse() {
        let consent = MPGDPRConsent()
        consent.consented = false
        let gdprConsents = ["advertising": consent]

        let mapping = ["ad_storage": "advertising"]

        let result = kit.resolvedConsent(
            forMappingKey: "ad_storage",
            defaultKey: "defaultAdStorageConsentSDK",
            gdprConsents: gdprConsents,
            mapping: mapping
        )
        XCTAssertEqual(result, false)
    }

    func test_resolvedConsentForMappingKey_withDefaultValue_returnsFalse() {
        kit.configuration["defaultAdStorageConsentSDK"] = "Denied"

        let result = kit.resolvedConsent(
            forMappingKey: "ad_storage",
            defaultKey: "defaultAdStorageConsentSDK",
            gdprConsents: [:],
            mapping: [:]
        )
        XCTAssertEqual(result, false)
    }

    func test_resolvedConsentForMappingKey_withNoMappingOrDefault_returnsNil() {
        let result = kit.resolvedConsent(
            forMappingKey: "ad_storage",
            defaultKey: "defaultAdStorageConsentSDK",
            gdprConsents: [:],
            mapping: [:]
        )
        XCTAssertNil(result)
    }
}

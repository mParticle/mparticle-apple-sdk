import XCTest
@testable import mParticle_AppsFlyer
import AppsFlyerLib

extension MPCommerceEvent {
    static func mock(action: MPCommerceEventAction = .purchase, products: [MPProduct] = []) -> MPCommerceEvent {
        let event = MPCommerceEvent(action: .purchase)!
        event.addProducts(products)
        return event
    }
}

final class MPKitAppsFlyerTests: XCTestCase {
    var kit: MPKitAppsFlyer!
    var mock: AppsFlyerLibMock!
    static let product1 = MPProduct(name: "foo", sku: "foo-sku", quantity: 3, price: 50)
    static let product2 = MPProduct(name: "foo2", sku: "foo-sku-2", quantity: 2, price: 50)
    static let product3 = MPProduct(name: "foo3", sku: "foo-sku-,3", quantity: 2, price: 50)

    let fakeProducts: [MPProduct] = [
        MPKitAppsFlyerTests.product1,
        MPKitAppsFlyerTests.product2,
        MPKitAppsFlyerTests.product3
    ]

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        kit = MPKitAppsFlyer()
        kit.configuration = [:]
        mock = AppsFlyerLibMock()
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

    // MARK: - sharingFilterForPartnersFromConfiguration

    func test_sharingFilterForPartners_validJSON_returnsList() {
        kit.configuration["sharingFilterForPartners"] = #"["partner_1", "partner_2"]"#
        let result = kit.sharingFilterForPartners(fromConfiguration: kit.configuration)
        XCTAssertEqual(result, ["partner_1", "partner_2"])
    }

    func test_sharingFilterForPartners_emptyOrMissing_returnsNil() {
        XCTAssertNil(kit.sharingFilterForPartners(fromConfiguration: [:]))
        kit.configuration["sharingFilterForPartners"] = ""
        XCTAssertNil(kit.sharingFilterForPartners(fromConfiguration: kit.configuration))
    }

    func test_sharingFilterForPartners_invalidJSON_returnsNil() {
        kit.configuration["sharingFilterForPartners"] = "not a json array"
        let result = kit.sharingFilterForPartners(fromConfiguration: kit.configuration)
        XCTAssertNil(result)
    }

    func test_sharingFilterForPartners_invalidEscapedJSON_returnsNil() {
        kit.configuration["sharingFilterForPartners"] = #"[\"test_1\", \"test_2\"]"#
        let result = kit.sharingFilterForPartners(fromConfiguration: kit.configuration)
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

    func testComputeQuantityWithNoEvent() {
        XCTAssertEqual(MPKitAppsFlyer.computeProductQuantity(nil).intValue, 1)
    }

    func testComputeQuantityWithNoProducts() {
        let event = MPCommerceEvent(action: .purchase)
        XCTAssertEqual(MPKitAppsFlyer.computeProductQuantity(event).intValue, 1)
    }

    func testComputeQuantityWithProductWithNoQuantity() {
        let event = MPCommerceEvent(action: .purchase)
        event!.addProducts([.init(name: "foo", sku: "bar", quantity: 0, price: 50)])

        XCTAssertEqual(MPKitAppsFlyer.computeProductQuantity(event).intValue, 1)
    }

    func testComputeQuantityWithProductWithMultipleQuantities() {
        let event = MPCommerceEvent(action: .purchase)
        event!.addProducts([
            MPKitAppsFlyerTests.product1,
            MPKitAppsFlyerTests.product2
        ])

        XCTAssertEqual(MPKitAppsFlyer.computeProductQuantity(event).intValue, 5)
    }

    func testGenerateSkuStringNoEvent() {
        XCTAssertNil(MPKitAppsFlyer.generateProductIdList(nil))
    }

    func testGenerateSkuStringNoProducts() {
        let event = MPCommerceEvent.mock()
        XCTAssertNil(MPKitAppsFlyer.generateProductIdList(event))
    }

    func testGenerateSkuStringSingleProduct() {
        let event = MPCommerceEvent.mock(products: [
            MPKitAppsFlyerTests.product1
        ])
        XCTAssertEqual(MPKitAppsFlyer.generateProductIdList(event), "foo-sku")
    }

    func testGenerateSkuStringMultipleProducts() {
        let event = MPCommerceEvent.mock(products: [
            MPKitAppsFlyerTests.product1,
            MPKitAppsFlyerTests.product2
        ])
        XCTAssertEqual(MPKitAppsFlyer.generateProductIdList(event), "foo-sku,foo-sku-2")
    }

    func testGenerateSkuStringEmbeddedCommas() {
        let event = MPCommerceEvent.mock(products: fakeProducts)
        XCTAssertEqual(MPKitAppsFlyer.generateProductIdList(event), "foo-sku,foo-sku-2,foo-sku-%2C3")
    }

    func testRouteCommerce() {
        let event = MPCommerceEvent.mock(products: fakeProducts)
        event.customAttributes = ["test": "Malarkey"]

        let af = MPKitAppsFlyer()

        af.providerKitInstance = mock
        af.routeCommerceEvent(event)

        checkLogEventParams()

        XCTAssertEqual(mock.logEventValues!["test"] as! String, "Malarkey")
    }

    func testRouteCommerceNilCustomAttributes() {
        let event = MPCommerceEvent.mock(products: fakeProducts)
        event.customAttributes = nil

        let af = MPKitAppsFlyer()

        af.providerKitInstance = mock
        af.routeCommerceEvent(event)

        checkLogEventParams()
    }

    func checkLogEventParams() {
        XCTAssertTrue(mock.logEventCalled)
        XCTAssertEqual(mock.logEventEventName, AFEventPurchase)
        let expectedUserId = MParticle.sharedInstance().identity.currentUser?.userId.stringValue ?? "0"
        XCTAssertEqual(mock.logEventValues!["af_customer_user_id"] as! String, expectedUserId)
        XCTAssertEqual(mock.logEventValues!["af_quantity"] as! NSNumber, 7)
        XCTAssertEqual(mock.logEventValues!["af_content_id"] as! String, "foo-sku,foo-sku-2,foo-sku-%2C3")
    }

}

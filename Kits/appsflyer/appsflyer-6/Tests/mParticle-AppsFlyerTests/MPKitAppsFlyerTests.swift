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

    // MARK: - didBecomeActive / manualStart

    func test_didBecomeActive_manualStartTrue_doesNotCallAppsFlyerStart() {
        kit.configuration = ["manualStart": true]
        kit.providerKitInstance = mock

        _ = kit.didBecomeActive()

        XCTAssertEqual(mock.startCallCount, 0)
    }

    func test_didBecomeActive_manualStartFalse_callsAppsFlyerStart() {
        kit.configuration = ["manualStart": false]
        kit.providerKitInstance = mock

        _ = kit.didBecomeActive()

        XCTAssertEqual(mock.startCallCount, 1)
    }

    func test_didBecomeActive_manualStartOmitted_callsAppsFlyerStart() {
        kit.configuration = [:]
        kit.providerKitInstance = mock

        _ = kit.didBecomeActive()

        XCTAssertEqual(mock.startCallCount, 1)
    }

    // MARK: - setUserIdentity / userIdentificationType

    func test_setUserIdentity_customerId_legacy_forwardsToAppsFlyer() {
        kit.configuration = [:]
        kit.providerKitInstance = mock

        let status = kit.setUserIdentity("ext-cust-1", identityType: .customerId)

        XCTAssertEqual(status.returnCode, .success)
        XCTAssertEqual(mock.setCustomerUserIDCallCount, 1)
        XCTAssertEqual(mock.lastCustomerUserID, "ext-cust-1")
    }

    func test_setUserIdentity_customerId_customerIdMode_forwardsToAppsFlyer() {
        kit.configuration = ["userIdentificationType": "CustomerId"]
        kit.providerKitInstance = mock

        let status = kit.setUserIdentity("ext-cust-2", identityType: .customerId)

        XCTAssertEqual(status.returnCode, .success)
        XCTAssertEqual(mock.setCustomerUserIDCallCount, 1)
        XCTAssertEqual(mock.lastCustomerUserID, "ext-cust-2")
    }

    func test_setUserIdentity_customerId_mpidMode_doesNotCallSetCustomerUserID() {
        kit.configuration = ["userIdentificationType": "MPID"]
        kit.providerKitInstance = mock

        let status = kit.setUserIdentity("ext-cust-ignored", identityType: .customerId)

        XCTAssertEqual(status.returnCode, .success)
        XCTAssertEqual(mock.setCustomerUserIDCallCount, 0)
        XCTAssertNil(mock.lastCustomerUserID)
    }

    func test_setUserIdentity_email_doesNotUseCustomerUserIDPath() {
        kit.configuration = ["userIdentificationType": "MPID"]
        kit.providerKitInstance = mock

        let status = kit.setUserIdentity("a@b.com", identityType: .email)

        XCTAssertEqual(status.returnCode, .success)
        XCTAssertEqual(mock.setCustomerUserIDCallCount, 0)
    }

    func test_setUserIdentity_unsupportedIdentity_returnsFail() {
        kit.configuration = [:]
        kit.providerKitInstance = mock

        let status = kit.setUserIdentity("x", identityType: .other)

        XCTAssertEqual(status.returnCode, .fail)
        XCTAssertEqual(mock.setCustomerUserIDCallCount, 0)
    }

    // MARK: - updateCustomerUserIDIfNeededForUser (via identity callbacks)

    func test_onIdentifyComplete_mpidMode_setsCustomerUserID() {
        kit.configuration = ["userIdentificationType": "MPID"]
        kit.providerKitInstance = mock

        let user = FilteredMParticleUserMock(userId: 12345)
        let request = FilteredMPIdentityApiRequest()

        _ = kit.onIdentifyComplete(user, request: request)

        XCTAssertEqual(mock.setCustomerUserIDCallCount, 1)
        XCTAssertEqual(mock.lastCustomerUserID, "12345")
    }

    func test_onIdentifyComplete_customerIdMode_withCustomerId_setsCustomerUserID() {
        kit.configuration = ["userIdentificationType": "CustomerId"]
        kit.providerKitInstance = mock

        let user = FilteredMParticleUserMock(
            userId: 99,
            userIdentities: [NSNumber(value: MPUserIdentity.customerId.rawValue): "cust-abc"]
        )
        let request = FilteredMPIdentityApiRequest()

        _ = kit.onIdentifyComplete(user, request: request)

        XCTAssertEqual(mock.setCustomerUserIDCallCount, 1)
        XCTAssertEqual(mock.lastCustomerUserID, "cust-abc")
    }

    func test_onLogoutComplete_customerIdMode_nilCustomerId_doesNotSetCustomerUserID() {
        kit.configuration = ["userIdentificationType": "CustomerId"]
        kit.providerKitInstance = mock

        let user = FilteredMParticleUserMock(userId: 99, userIdentities: [:])
        let request = FilteredMPIdentityApiRequest()

        _ = kit.onLogoutComplete(user, request: request)

        XCTAssertEqual(mock.setCustomerUserIDCallCount, 0)
        XCTAssertNil(mock.lastCustomerUserID)
    }

    func test_onLogoutComplete_customerIdMode_emptyCustomerId_doesNotSetCustomerUserID() {
        kit.configuration = ["userIdentificationType": "CustomerId"]
        kit.providerKitInstance = mock

        let user = FilteredMParticleUserMock(
            userId: 99,
            userIdentities: [NSNumber(value: MPUserIdentity.customerId.rawValue): ""]
        )
        let request = FilteredMPIdentityApiRequest()

        _ = kit.onLogoutComplete(user, request: request)

        XCTAssertEqual(mock.setCustomerUserIDCallCount, 0)
        XCTAssertNil(mock.lastCustomerUserID)
    }

    func test_onLogoutComplete_mpidMode_setsCustomerUserID() {
        kit.configuration = ["userIdentificationType": "MPID"]
        kit.providerKitInstance = mock

        let user = FilteredMParticleUserMock(userId: 77777)
        let request = FilteredMPIdentityApiRequest()

        _ = kit.onLogoutComplete(user, request: request)

        XCTAssertEqual(mock.setCustomerUserIDCallCount, 1)
        XCTAssertEqual(mock.lastCustomerUserID, "77777")
    }

    func test_onLoginComplete_customerIdMode_withCustomerId_setsCustomerUserID() {
        kit.configuration = ["userIdentificationType": "CustomerId"]
        kit.providerKitInstance = mock

        let user = FilteredMParticleUserMock(
            userId: 42,
            userIdentities: [NSNumber(value: MPUserIdentity.customerId.rawValue): "new-user-123"]
        )
        let request = FilteredMPIdentityApiRequest()

        _ = kit.onLoginComplete(user, request: request)

        XCTAssertEqual(mock.setCustomerUserIDCallCount, 1)
        XCTAssertEqual(mock.lastCustomerUserID, "new-user-123")
    }

    func test_onIdentifyComplete_legacyMode_doesNotSetCustomerUserID() {
        kit.configuration = [:]
        kit.providerKitInstance = mock

        let user = FilteredMParticleUserMock(userId: 12345)
        let request = FilteredMPIdentityApiRequest()

        _ = kit.onIdentifyComplete(user, request: request)

        XCTAssertEqual(mock.setCustomerUserIDCallCount, 0)
        XCTAssertNil(mock.lastCustomerUserID)
    }

    func test_onModifyComplete_mpidMode_setsCustomerUserID() {
        kit.configuration = ["userIdentificationType": "MPID"]
        kit.providerKitInstance = mock

        let user = FilteredMParticleUserMock(userId: 55555)
        let request = FilteredMPIdentityApiRequest()

        _ = kit.onModifyComplete(user, request: request)

        XCTAssertEqual(mock.setCustomerUserIDCallCount, 1)
        XCTAssertEqual(mock.lastCustomerUserID, "55555")
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

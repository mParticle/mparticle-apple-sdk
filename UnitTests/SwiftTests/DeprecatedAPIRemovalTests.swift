import XCTest
@testable import mParticle_Apple_SDK

/// Tests to verify deprecated APIs have been removed in SDK 9.0
final class DeprecatedAPIRemovalTests: XCTestCase {

    // MARK: - MPCommerceEvent Deprecated Methods Removed

    func test_MPCommerceEvent_allKeys_removed() {
        let event = MPCommerceEvent(action: .purchase)!
        XCTAssertFalse(
            event.responds(to: NSSelectorFromString("allKeys")),
            "allKeys method should be removed - use customAttributes.allKeys"
        )
    }

    func test_MPCommerceEvent_userDefinedAttributes_getter_removed() {
        let event = MPCommerceEvent(action: .purchase)!
        XCTAssertFalse(
            event.responds(to: NSSelectorFromString("userDefinedAttributes")),
            "userDefinedAttributes getter should be removed - use customAttributes"
        )
    }

    func test_MPCommerceEvent_userDefinedAttributes_setter_removed() {
        let event = MPCommerceEvent(action: .purchase)!
        XCTAssertFalse(
            event.responds(to: NSSelectorFromString("setUserDefinedAttributes:")),
            "setUserDefinedAttributes: should be removed - use customAttributes"
        )
    }

    func test_MPCommerceEvent_objectForKeyedSubscript_removed() {
        let event = MPCommerceEvent(action: .purchase)!
        XCTAssertFalse(
            event.responds(to: NSSelectorFromString("objectForKeyedSubscript:")),
            "objectForKeyedSubscript: should be removed"
        )
    }

    func test_MPCommerceEvent_setObjectForKeyedSubscript_removed() {
        let event = MPCommerceEvent(action: .purchase)!
        XCTAssertFalse(
            event.responds(to: NSSelectorFromString("setObject:forKeyedSubscript:")),
            "setObject:forKeyedSubscript: should be removed"
        )
    }

    func test_MParticle_logEvent_acceptsCommerceEventDirectly() {
        // Verify logEvent: can accept MPCommerceEvent (as MPCommerceEvent extends MPBaseEvent)
        // This is the recommended approach in SDK 9.0
        let mp = MParticle.sharedInstance()
        XCTAssertTrue(
            mp.responds(to: NSSelectorFromString("logEvent:")),
            "logEvent: should exist and accept MPCommerceEvent"
        )
    }

    // MARK: - MPProduct Deprecated Properties Removed

    func test_MPProduct_affiliation_removed() {
        let product = MPProduct(name: "Test", sku: "123", quantity: 1, price: 9.99)
        XCTAssertFalse(
            product.responds(to: NSSelectorFromString("affiliation")),
            "affiliation should be removed - use MPTransactionAttributes.affiliation"
        )
    }

    func test_MPProduct_currency_removed() {
        let product = MPProduct(name: "Test", sku: "123", quantity: 1, price: 9.99)
        XCTAssertFalse(
            product.responds(to: NSSelectorFromString("currency")),
            "currency should be removed - use MPCommerceEvent.currency"
        )
    }

    func test_MPProduct_transactionId_removed() {
        let product = MPProduct(name: "Test", sku: "123", quantity: 1, price: 9.99)
        XCTAssertFalse(
            product.responds(to: NSSelectorFromString("transactionId")),
            "transactionId should be removed - use MPTransactionAttributes.transactionId"
        )
    }

    func test_MPProduct_revenueAmount_removed() {
        let product = MPProduct(name: "Test", sku: "123", quantity: 1, price: 9.99)
        XCTAssertFalse(
            product.responds(to: NSSelectorFromString("revenueAmount")),
            "revenueAmount should be removed"
        )
    }

    func test_MPProduct_shippingAmount_removed() {
        let product = MPProduct(name: "Test", sku: "123", quantity: 1, price: 9.99)
        XCTAssertFalse(
            product.responds(to: NSSelectorFromString("shippingAmount")),
            "shippingAmount should be removed - use MPTransactionAttributes.shipping"
        )
    }

    func test_MPProduct_taxAmount_removed() {
        let product = MPProduct(name: "Test", sku: "123", quantity: 1, price: 9.99)
        XCTAssertFalse(
            product.responds(to: NSSelectorFromString("taxAmount")),
            "taxAmount should be removed - use MPTransactionAttributes.tax"
        )
    }

    func test_MPProduct_totalAmount_removed() {
        let product = MPProduct(name: "Test", sku: "123", quantity: 1, price: 9.99)
        XCTAssertFalse(
            product.responds(to: NSSelectorFromString("totalAmount")),
            "totalAmount should be removed - use MPTransactionAttributes.revenue"
        )
    }

    func test_MPProduct_unitPrice_removed() {
        let product = MPProduct(name: "Test", sku: "123", quantity: 1, price: 9.99)
        XCTAssertFalse(
            product.responds(to: NSSelectorFromString("unitPrice")),
            "unitPrice should be removed - use price property"
        )
    }

    func test_MPProduct_deprecatedInitializer_totalAmount_removed() {
        // This initializer should not exist
        // initWithName:category:quantity:totalAmount:
        let productClass: AnyClass = MPProduct.self
        XCTAssertFalse(
            productClass.instancesRespond(to: NSSelectorFromString("initWithName:category:quantity:totalAmount:")),
            "initWithName:category:quantity:totalAmount: should be removed"
        )
    }

    func test_MPProduct_deprecatedInitializer_revenueAmount_removed() {
        // This initializer should not exist
        // initWithName:category:quantity:revenueAmount:
        let productClass: AnyClass = MPProduct.self
        XCTAssertFalse(
            productClass.instancesRespond(to: NSSelectorFromString("initWithName:category:quantity:revenueAmount:")),
            "initWithName:category:quantity:revenueAmount: should be removed"
        )
    }

    // MARK: - MPEvent Deprecated Property Removed

    func test_MPEvent_info_getter_removed() {
        let event = MPEvent(name: "Test", type: .other)!
        XCTAssertFalse(
            event.responds(to: NSSelectorFromString("info")),
            "info getter should be removed - use customAttributes"
        )
    }

    func test_MPEvent_info_setter_removed() {
        let event = MPEvent(name: "Test", type: .other)!
        XCTAssertFalse(
            event.responds(to: NSSelectorFromString("setInfo:")),
            "setInfo: should be removed - use customAttributes"
        )
    }

    // MARK: - Verify Replacement APIs Exist

    func test_MPEvent_customAttributes_exists() {
        let event = MPEvent(name: "Test", type: .other)!
        XCTAssertTrue(
            event.responds(to: NSSelectorFromString("customAttributes")),
            "customAttributes should exist as replacement for info"
        )
        XCTAssertTrue(
            event.responds(to: NSSelectorFromString("setCustomAttributes:")),
            "setCustomAttributes: should exist"
        )
    }

    func test_MPCommerceEvent_customAttributes_exists() {
        let event = MPCommerceEvent(action: .purchase)!
        XCTAssertTrue(
            event.responds(to: NSSelectorFromString("customAttributes")),
            "customAttributes should exist as replacement for userDefinedAttributes"
        )
    }

    func test_MPProduct_price_exists() {
        let product = MPProduct(name: "Test", sku: "123", quantity: 1, price: 9.99)
        XCTAssertTrue(
            product.responds(to: NSSelectorFromString("price")),
            "price should exist as replacement for unitPrice"
        )
    }

    func test_MPTransactionAttributes_exists() {
        let transactionAttributes = MPTransactionAttributes()
        XCTAssertNotNil(transactionAttributes)
        XCTAssertTrue(
            transactionAttributes.responds(to: NSSelectorFromString("affiliation")),
            "MPTransactionAttributes.affiliation should exist"
        )
        XCTAssertTrue(
            transactionAttributes.responds(to: NSSelectorFromString("shipping")),
            "MPTransactionAttributes.shipping should exist"
        )
        XCTAssertTrue(
            transactionAttributes.responds(to: NSSelectorFromString("tax")),
            "MPTransactionAttributes.tax should exist"
        )
        XCTAssertTrue(
            transactionAttributes.responds(to: NSSelectorFromString("revenue")),
            "MPTransactionAttributes.revenue should exist"
        )
        XCTAssertTrue(
            transactionAttributes.responds(to: NSSelectorFromString("transactionId")),
            "MPTransactionAttributes.transactionId should exist"
        )
    }
}

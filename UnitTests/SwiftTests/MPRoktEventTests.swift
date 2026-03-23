import XCTest
@testable import mParticle_Apple_SDK
import RoktContracts

/// Tests to verify RoktContracts event types are accessible from Swift
/// via the mParticle SDK's re-export of RoktContracts.
final class RoktEventContractsTests: XCTestCase {

    // MARK: - Nested Class Access Tests

    func test_initComplete() {
        let event = RoktEvent.InitComplete(success: true)
        XCTAssertNotNil(event)
        XCTAssertTrue(event is RoktEvent)
        XCTAssertTrue(event.success)
    }

    func test_placementReady() {
        let event = RoktEvent.PlacementReady(identifier: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is RoktEvent)
        XCTAssertEqual(event.identifier, "test-placement")
    }

    func test_placementClosed() {
        let event = RoktEvent.PlacementClosed(identifier: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertEqual(event.identifier, "test-placement")
    }

    func test_embeddedSizeChanged() {
        let event = RoktEvent.EmbeddedSizeChanged(identifier: "embed", updatedHeight: 250.5)
        XCTAssertNotNil(event)
        XCTAssertEqual(event.identifier, "embed")
        XCTAssertEqual(event.updatedHeight, 250.5, accuracy: 0.001)
    }

    func test_openUrl() {
        let event = RoktEvent.OpenUrl(identifier: "test", url: "https://example.com")
        XCTAssertNotNil(event)
        XCTAssertEqual(event.url, "https://example.com")
    }

    func test_cartItemInstantPurchase() {
        let event = RoktEvent.CartItemInstantPurchase(
            identifier: "placement1",
            name: "Test Item",
            cartItemId: "v1:abc:canal",
            catalogItemId: "cat-123",
            currency: "USD",
            description: "A test item",
            linkedProductId: nil,
            providerData: "{}",
            quantity: NSDecimalNumber(value: 1),
            totalPrice: NSDecimalNumber(value: 49.99),
            unitPrice: NSDecimalNumber(value: 49.99)
        )
        XCTAssertNotNil(event)
        XCTAssertEqual(event.cartItemId, "v1:abc:canal")
        XCTAssertEqual(event.catalogItemId, "cat-123")
    }

    // MARK: - Type Checking Tests

    func test_typeChecking() {
        let events: [RoktEvent] = [
            RoktEvent.InitComplete(success: true),
            RoktEvent.PlacementReady(identifier: "test"),
            RoktEvent.PlacementClosed(identifier: "test"),
            RoktEvent.ShowLoadingIndicator(),
            RoktEvent.HideLoadingIndicator(),
        ]

        XCTAssertEqual(events.count, 5)
        XCTAssertTrue(events[0] is RoktEvent.InitComplete)
        XCTAssertTrue(events[1] is RoktEvent.PlacementReady)
        XCTAssertTrue(events[2] is RoktEvent.PlacementClosed)
        XCTAssertTrue(events[3] is RoktEvent.ShowLoadingIndicator)
        XCTAssertTrue(events[4] is RoktEvent.HideLoadingIndicator)
    }

    // MARK: - Obj-C Runtime Class Name Tests

    func test_classExists_roktEvent() {
        XCTAssertNotNil(NSClassFromString("RoktEvent"))
    }

    func test_classExists_roktInitComplete() {
        XCTAssertNotNil(NSClassFromString("RoktInitComplete"))
    }

    func test_classExists_roktPlacementReady() {
        XCTAssertNotNil(NSClassFromString("RoktPlacementReady"))
    }

    func test_classExists_roktCartItemInstantPurchase() {
        XCTAssertNotNil(NSClassFromString("RoktCartItemInstantPurchase"))
    }

    func test_classExists_roktEmbeddedSizeChanged() {
        XCTAssertNotNil(NSClassFromString("RoktEmbeddedSizeChanged"))
    }

    // MARK: - Config Builder Tests

    func test_roktConfig_builder() {
        let config = RoktConfig.Builder().colorMode(.dark).build()
        XCTAssertNotNil(config)
        XCTAssertEqual(config.colorMode, .dark)
    }

    func test_roktConfig_builderWithCache() {
        let cacheConfig = RoktConfig.CacheConfig(cacheDuration: 3600, cacheAttributes: ["key": "value"])
        let config = RoktConfig.Builder()
            .colorMode(.light)
            .cacheConfig(cacheConfig)
            .build()
        XCTAssertNotNil(config)
        XCTAssertEqual(config.colorMode, .light)
        XCTAssertTrue(config.cacheConfig.isCacheEnabled())
    }

    // MARK: - RoktEmbeddedView Tests

    func test_roktEmbeddedView() {
        let view = RoktEmbeddedView()
        XCTAssertNotNil(view)
        XCTAssertTrue(view is UIView)
    }

    // MARK: - RoktPlacementOptions Tests

    func test_roktPlacementOptions() {
        let options = RoktPlacementOptions(timestamp: 1234567890)
        XCTAssertEqual(options.jointSdkSelectPlacements, 1234567890)
    }
}

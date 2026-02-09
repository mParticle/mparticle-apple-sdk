import XCTest
@testable import mParticle_Apple_SDK_NoLocation

/// Tests to verify Rokt event classes use nested access via NS_SWIFT_NAME
final class MPRoktEventTests: XCTestCase {

    // MARK: - Nested Class Instantiation Tests

    func test_MPRoktInitComplete_nestedAccess() {
        let event = MPRoktEvent.MPRoktInitComplete(success: true)
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent, "MPRoktInitComplete should inherit from MPRoktEvent")
        XCTAssertTrue(event.success)
    }

    func test_MPRoktInitComplete_withFailure() {
        let event = MPRoktEvent.MPRoktInitComplete(success: false)
        XCTAssertNotNil(event)
        XCTAssertFalse(event.success)
    }

    func test_MPRoktPlacementReady_nestedAccess() {
        let event = MPRoktEvent.MPRoktPlacementReady(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktPlacementClosed_nestedAccess() {
        let event = MPRoktEvent.MPRoktPlacementClosed(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktPlacementCompleted_nestedAccess() {
        let event = MPRoktEvent.MPRoktPlacementCompleted(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktPlacementInteractive_nestedAccess() {
        let event = MPRoktEvent.MPRoktPlacementInteractive(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktPlacementFailure_nestedAccess() {
        let event = MPRoktEvent.MPRoktPlacementFailure(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktOfferEngagement_nestedAccess() {
        let event = MPRoktEvent.MPRoktOfferEngagement(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktPositiveEngagement_nestedAccess() {
        let event = MPRoktEvent.MPRoktPositiveEngagement(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktFirstPositiveEngagement_nestedAccess() {
        let event = MPRoktEvent.MPRoktFirstPositiveEngagement(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktOpenUrl_nestedAccess() {
        let event = MPRoktEvent.MPRoktOpenUrl(placementId: "test-placement", url: "https://example.com")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
        XCTAssertEqual(event.url, "https://example.com")
    }

    func test_MPRoktShowLoadingIndicator_nestedAccess() {
        let event = MPRoktEvent.MPRoktShowLoadingIndicator()
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
    }

    func test_MPRoktHideLoadingIndicator_nestedAccess() {
        let event = MPRoktEvent.MPRoktHideLoadingIndicator()
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
    }

    func test_MPRoktCartItemInstantPurchase_classExists() {
        let eventClass: AnyClass? = NSClassFromString("MPRoktCartItemInstantPurchase")
        XCTAssertNotNil(eventClass, "MPRoktCartItemInstantPurchase should exist")
    }

    // MARK: - MPRoktEmbeddedSizeChanged Tests

    func test_MPRoktEmbeddedSizeChanged_nestedAccess() {
        let event = MPRoktEvent.MPRoktEmbeddedSizeChanged(placementId: "embed-placement", updatedHeight: 250.5)
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "embed-placement")
        XCTAssertEqual(event.updatedHeight, 250.5, accuracy: 0.001)
    }

    func test_MPRoktEmbeddedSizeChanged_zeroHeight() {
        let event = MPRoktEvent.MPRoktEmbeddedSizeChanged(placementId: "embed-placement", updatedHeight: 0)
        XCTAssertNotNil(event)
        XCTAssertEqual(event.updatedHeight, 0, accuracy: 0.001)
    }

    func test_MPRoktEmbeddedSizeChanged_classExists() {
        let eventClass: AnyClass? = NSClassFromString("MPRoktEmbeddedSizeChanged")
        XCTAssertNotNil(eventClass, "MPRoktEmbeddedSizeChanged should exist")
    }

    // MARK: - Type Checking Tests

    func test_roktEvent_typeChecking_withIsOperator() {
        let events: [MPRoktEvent] = [
            MPRoktEvent.MPRoktInitComplete(success: true),
            MPRoktEvent.MPRoktPlacementReady(placementId: "test"),
            MPRoktEvent.MPRoktPlacementClosed(placementId: "test"),
            MPRoktEvent.MPRoktPlacementCompleted(placementId: "test"),
            MPRoktEvent.MPRoktPlacementInteractive(placementId: "test"),
            MPRoktEvent.MPRoktPlacementFailure(placementId: "test"),
            MPRoktEvent.MPRoktEmbeddedSizeChanged(placementId: "test", updatedHeight: 100)
        ]

        XCTAssertEqual(events.count, 7)

        for event in events {
            XCTAssertTrue(event is MPRoktEvent, "All events should be MPRoktEvent instances")
        }

        XCTAssertTrue(events[0] is MPRoktEvent.MPRoktInitComplete)
        XCTAssertTrue(events[1] is MPRoktEvent.MPRoktPlacementReady)
        XCTAssertTrue(events[2] is MPRoktEvent.MPRoktPlacementClosed)
        XCTAssertTrue(events[3] is MPRoktEvent.MPRoktPlacementCompleted)
        XCTAssertTrue(events[4] is MPRoktEvent.MPRoktPlacementInteractive)
        XCTAssertTrue(events[5] is MPRoktEvent.MPRoktPlacementFailure)
        XCTAssertTrue(events[6] is MPRoktEvent.MPRoktEmbeddedSizeChanged)
    }

    func test_roktEvent_switchStatement_works() {
        let event: MPRoktEvent = MPRoktEvent.MPRoktPlacementReady(placementId: "test")
        var matched = false

        if event is MPRoktEvent.MPRoktPlacementReady {
            matched = true
        }

        XCTAssertTrue(matched, "Type matching should work with is operator")
    }

    func test_roktEvent_casting_works() {
        let event: MPRoktEvent = MPRoktEvent.MPRoktOpenUrl(placementId: "test", url: "https://example.com")

        if let openUrlEvent = event as? MPRoktEvent.MPRoktOpenUrl {
            XCTAssertEqual(openUrlEvent.url, "https://example.com")
        } else {
            XCTFail("Casting to MPRoktOpenUrl should succeed")
        }
    }

    func test_roktEvent_casting_embeddedSizeChanged() {
        let event: MPRoktEvent = MPRoktEvent.MPRoktEmbeddedSizeChanged(placementId: "test", updatedHeight: 300)

        if let sizeEvent = event as? MPRoktEvent.MPRoktEmbeddedSizeChanged {
            XCTAssertEqual(sizeEvent.placementId, "test")
            XCTAssertEqual(sizeEvent.updatedHeight, 300, accuracy: 0.001)
        } else {
            XCTFail("Casting to MPRoktEmbeddedSizeChanged should succeed")
        }
    }

    // MARK: - Class Existence Tests

    func test_MPRoktEvent_classExists() {
        let eventClass: AnyClass? = NSClassFromString("MPRoktEvent")
        XCTAssertNotNil(eventClass, "MPRoktEvent base class should exist")
    }

    func test_MPRoktInitComplete_classExists() {
        let eventClass: AnyClass? = NSClassFromString("MPRoktInitComplete")
        XCTAssertNotNil(eventClass, "MPRoktInitComplete should exist")
    }

    func test_MPRoktPlacementReady_classExists() {
        let eventClass: AnyClass? = NSClassFromString("MPRoktPlacementReady")
        XCTAssertNotNil(eventClass, "MPRoktPlacementReady should exist")
    }

    func test_MPRoktPlacementClosed_classExists() {
        let eventClass: AnyClass? = NSClassFromString("MPRoktPlacementClosed")
        XCTAssertNotNil(eventClass, "MPRoktPlacementClosed should exist")
    }

    func test_MPRoktCartItemInstantPurchase_classExists_runtime() {
        let eventClass: AnyClass? = NSClassFromString("MPRoktCartItemInstantPurchase")
        XCTAssertNotNil(eventClass, "MPRoktCartItemInstantPurchase should exist")
    }

    func test_MPRoktEmbeddedSizeChanged_classExists_runtime() {
        let eventClass: AnyClass? = NSClassFromString("MPRoktEmbeddedSizeChanged")
        XCTAssertNotNil(eventClass, "MPRoktEmbeddedSizeChanged should exist")
    }
}

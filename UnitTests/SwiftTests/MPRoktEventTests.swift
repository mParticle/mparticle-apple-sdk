import XCTest
@testable import mParticle_Apple_SDK

/// Tests to verify Rokt event classes are now top-level (not nested) in SDK 9.0
final class MPRoktEventTests: XCTestCase {

    // MARK: - Top-Level Class Instantiation Tests

    func test_MPRoktInitComplete_isTopLevelClass() {
        let event = MPRoktInitComplete(success: true)
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent, "MPRoktInitComplete should inherit from MPRoktEvent")
        XCTAssertTrue(event.success)
    }

    func test_MPRoktInitComplete_withFailure() {
        let event = MPRoktInitComplete(success: false)
        XCTAssertNotNil(event)
        XCTAssertFalse(event.success)
    }

    func test_MPRoktPlacementReady_isTopLevelClass() {
        let event = MPRoktPlacementReady(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktPlacementClosed_isTopLevelClass() {
        let event = MPRoktPlacementClosed(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktPlacementCompleted_isTopLevelClass() {
        let event = MPRoktPlacementCompleted(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktPlacementInteractive_isTopLevelClass() {
        let event = MPRoktPlacementInteractive(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktPlacementFailure_isTopLevelClass() {
        let event = MPRoktPlacementFailure(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktOfferEngagement_isTopLevelClass() {
        let event = MPRoktOfferEngagement(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktPositiveEngagement_isTopLevelClass() {
        let event = MPRoktPositiveEngagement(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktFirstPositiveEngagement_isTopLevelClass() {
        let event = MPRoktFirstPositiveEngagement(placementId: "test-placement")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_MPRoktOpenUrl_isTopLevelClass() {
        let event = MPRoktOpenUrl(placementId: "test-placement", url: "https://example.com")
        XCTAssertNotNil(event)
        XCTAssertTrue(event is MPRoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
        XCTAssertEqual(event.url, "https://example.com")
    }

    func test_MPRoktShowLoadingIndicator_isTopLevelClass() {
        // Verify class exists and is a top-level class (not nested)
        let eventClass: AnyClass? = NSClassFromString("MPRoktShowLoadingIndicator")
        XCTAssertNotNil(eventClass, "MPRoktShowLoadingIndicator should be accessible as top-level class")
    }

    func test_MPRoktHideLoadingIndicator_isTopLevelClass() {
        // Verify class exists and is a top-level class (not nested)
        let eventClass: AnyClass? = NSClassFromString("MPRoktHideLoadingIndicator")
        XCTAssertNotNil(eventClass, "MPRoktHideLoadingIndicator should be accessible as top-level class")
    }

    func test_MPRoktCartItemInstantPurchase_isTopLevelClass() {
        // Verify class exists and is a top-level class (not nested)
        let eventClass: AnyClass? = NSClassFromString("MPRoktCartItemInstantPurchase")
        XCTAssertNotNil(eventClass, "MPRoktCartItemInstantPurchase should be accessible as top-level class")
    }

    // MARK: - Type Checking Tests

    func test_roktEvent_typeChecking_withIsOperator() {
        let events: [MPRoktEvent] = [
            MPRoktInitComplete(success: true),
            MPRoktPlacementReady(placementId: "test"),
            MPRoktPlacementClosed(placementId: "test"),
            MPRoktPlacementCompleted(placementId: "test"),
            MPRoktPlacementInteractive(placementId: "test"),
            MPRoktPlacementFailure(placementId: "test")
        ]

        XCTAssertEqual(events.count, 6)

        for event in events {
            XCTAssertTrue(event is MPRoktEvent, "All events should be MPRoktEvent instances")
        }

        XCTAssertTrue(events[0] is MPRoktInitComplete)
        XCTAssertTrue(events[1] is MPRoktPlacementReady)
        XCTAssertTrue(events[2] is MPRoktPlacementClosed)
        XCTAssertTrue(events[3] is MPRoktPlacementCompleted)
        XCTAssertTrue(events[4] is MPRoktPlacementInteractive)
        XCTAssertTrue(events[5] is MPRoktPlacementFailure)
    }

    func test_roktEvent_switchStatement_works() {
        let event: MPRoktEvent = MPRoktPlacementReady(placementId: "test")
        var matched = false

        if event is MPRoktPlacementReady {
            matched = true
        }

        XCTAssertTrue(matched, "Type matching should work with is operator")
    }

    func test_roktEvent_casting_works() {
        let event: MPRoktEvent = MPRoktOpenUrl(placementId: "test", url: "https://example.com")

        if let openUrlEvent = event as? MPRoktOpenUrl {
            XCTAssertEqual(openUrlEvent.url, "https://example.com")
        } else {
            XCTFail("Casting to MPRoktOpenUrl should succeed")
        }
    }

    // MARK: - Class Existence Tests

    func test_MPRoktEvent_classExists() {
        let eventClass: AnyClass? = NSClassFromString("MPRoktEvent")
        XCTAssertNotNil(eventClass, "MPRoktEvent base class should exist")
    }

    func test_MPRoktInitComplete_classExists() {
        let eventClass: AnyClass? = NSClassFromString("MPRoktInitComplete")
        XCTAssertNotNil(eventClass, "MPRoktInitComplete should exist as top-level class")
    }

    func test_MPRoktPlacementReady_classExists() {
        let eventClass: AnyClass? = NSClassFromString("MPRoktPlacementReady")
        XCTAssertNotNil(eventClass, "MPRoktPlacementReady should exist as top-level class")
    }

    func test_MPRoktPlacementClosed_classExists() {
        let eventClass: AnyClass? = NSClassFromString("MPRoktPlacementClosed")
        XCTAssertNotNil(eventClass, "MPRoktPlacementClosed should exist as top-level class")
    }

    func test_MPRoktCartItemInstantPurchase_classExists() {
        let eventClass: AnyClass? = NSClassFromString("MPRoktCartItemInstantPurchase")
        XCTAssertNotNil(eventClass, "MPRoktCartItemInstantPurchase should exist as top-level class")
    }
}

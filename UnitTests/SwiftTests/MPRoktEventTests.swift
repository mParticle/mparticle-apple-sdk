import XCTest
import RoktContracts

/// Exercises Rokt event types from RoktContracts (formerly MPRoktEvent in core).
final class MPRoktEventTests: XCTestCase {
    func test_RoktInitComplete() {
        let event = RoktEvent.InitComplete(success: true)
        XCTAssertNotNil(event)
        XCTAssertTrue(event is RoktEvent)
        XCTAssertTrue(event.success)
    }

    func test_RoktInitComplete_failure() {
        let event = RoktEvent.InitComplete(success: false)
        XCTAssertFalse(event.success)
    }

    func test_RoktPlacementReady() {
        let event = RoktEvent.PlacementReady(placementId: "test-placement")
        XCTAssertTrue(event is RoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_RoktPlacementClosed() {
        let event = RoktEvent.PlacementClosed(placementId: "test-placement")
        XCTAssertTrue(event is RoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_RoktPlacementCompleted() {
        let event = RoktEvent.PlacementCompleted(placementId: "test-placement")
        XCTAssertTrue(event is RoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_RoktPlacementInteractive() {
        let event = RoktEvent.PlacementInteractive(placementId: "test-placement")
        XCTAssertTrue(event is RoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_RoktPlacementFailure() {
        let event = RoktEvent.PlacementFailure(placementId: "test-placement")
        XCTAssertTrue(event is RoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_RoktOfferEngagement() {
        let event = RoktEvent.OfferEngagement(placementId: "test-placement")
        XCTAssertTrue(event is RoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_RoktPositiveEngagement() {
        let event = RoktEvent.PositiveEngagement(placementId: "test-placement")
        XCTAssertTrue(event is RoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_RoktFirstPositiveEngagement() {
        let event = RoktEvent.FirstPositiveEngagement(placementId: "test-placement")
        XCTAssertTrue(event is RoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
    }

    func test_RoktOpenUrl() {
        let event = RoktEvent.OpenUrl(placementId: "test-placement", url: "https://example.com")
        XCTAssertTrue(event is RoktEvent)
        XCTAssertEqual(event.placementId, "test-placement")
        XCTAssertEqual(event.url, "https://example.com")
    }

    func test_RoktShowLoadingIndicator() {
        let event = RoktEvent.ShowLoadingIndicator()
        XCTAssertTrue(event is RoktEvent)
    }

    func test_RoktHideLoadingIndicator() {
        let event = RoktEvent.HideLoadingIndicator()
        XCTAssertTrue(event is RoktEvent)
    }

    func test_RoktCartItemInstantPurchase_runtimeClass() {
        let eventClass: AnyClass? = NSClassFromString("RoktCartItemInstantPurchase")
        XCTAssertNotNil(eventClass)
    }

    func test_roktEvent_typeChecking() {
        let events: [RoktEvent] = [
            RoktEvent.InitComplete(success: true),
            RoktEvent.PlacementReady(placementId: "test"),
            RoktEvent.PlacementClosed(placementId: "test"),
            RoktEvent.PlacementCompleted(placementId: "test"),
            RoktEvent.PlacementInteractive(placementId: "test"),
            RoktEvent.PlacementFailure(placementId: "test"),
        ]
        XCTAssertEqual(events.count, 6)
        for event in events {
            XCTAssertTrue(event is RoktEvent)
        }
        XCTAssertTrue(events[0] is RoktEvent.InitComplete)
        XCTAssertTrue(events[1] is RoktEvent.PlacementReady)
    }

    func test_roktEvent_casting_OpenUrl() {
        let event: RoktEvent = RoktEvent.OpenUrl(placementId: "test", url: "https://example.com")
        guard let openUrl = event as? RoktEvent.OpenUrl else {
            return XCTFail("expected OpenUrl")
        }
        XCTAssertEqual(openUrl.url, "https://example.com")
    }

    func test_RoktEvent_runtimeClass() {
        XCTAssertNotNil(NSClassFromString("RoktEvent"))
    }

    func test_RoktInitComplete_runtimeClass() {
        XCTAssertNotNil(NSClassFromString("RoktInitComplete"))
    }
}

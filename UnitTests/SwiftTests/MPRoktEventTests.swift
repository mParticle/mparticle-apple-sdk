import XCTest
import RoktContracts

/// Exercises Rokt event types from RoktContracts (formerly MPRoktEvent in core).
final class MPRoktEventTests: XCTestCase {
    func test_RoktInitComplete() {
        let event = RoktEvent.InitComplete(success: true)
        XCTAssertNotNil(event)
        XCTAssertTrue(event is RoktEvent.InitComplete)
        XCTAssertTrue(event.success)
    }

    func test_RoktInitComplete_failure() {
        let event = RoktEvent.InitComplete(success: false)
        XCTAssertFalse(event.success)
    }

    func test_RoktPlacementReady() {
        let event = RoktEvent.PlacementReady(identifier: "test-placement")
        XCTAssertTrue(event is RoktEvent.PlacementReady)
        XCTAssertEqual(event.identifier, "test-placement")
    }

    func test_RoktPlacementClosed() {
        let event = RoktEvent.PlacementClosed(identifier: "test-placement")
        XCTAssertTrue(event is RoktEvent.PlacementClosed)
        XCTAssertEqual(event.identifier, "test-placement")
    }

    func test_RoktPlacementCompleted() {
        let event = RoktEvent.PlacementCompleted(identifier: "test-placement")
        XCTAssertTrue(event is RoktEvent.PlacementCompleted)
        XCTAssertEqual(event.identifier, "test-placement")
    }

    func test_RoktPlacementInteractive() {
        let event = RoktEvent.PlacementInteractive(identifier: "test-placement")
        XCTAssertTrue(event is RoktEvent.PlacementInteractive)
        XCTAssertEqual(event.identifier, "test-placement")
    }

    func test_RoktPlacementFailure() {
        let event = RoktEvent.PlacementFailure(identifier: "test-placement")
        XCTAssertTrue(event is RoktEvent.PlacementFailure)
        XCTAssertEqual(event.identifier, "test-placement")
    }

    func test_RoktOfferEngagement() {
        let event = RoktEvent.OfferEngagement(identifier: "test-placement")
        XCTAssertTrue(event is RoktEvent.OfferEngagement)
        XCTAssertEqual(event.identifier, "test-placement")
    }

    func test_RoktPositiveEngagement() {
        let event = RoktEvent.PositiveEngagement(identifier: "test-placement")
        XCTAssertTrue(event is RoktEvent.PositiveEngagement)
        XCTAssertEqual(event.identifier, "test-placement")
    }

    func test_RoktFirstPositiveEngagement() {
        let event = RoktEvent.FirstPositiveEngagement(identifier: "test-placement")
        XCTAssertTrue(event is RoktEvent.FirstPositiveEngagement)
        XCTAssertEqual(event.identifier, "test-placement")
    }

    func test_RoktOpenUrl() {
        let event = RoktEvent.OpenUrl(identifier: "test-placement", url: "https://example.com")
        XCTAssertTrue(event is RoktEvent.OpenUrl)
        XCTAssertEqual(event.identifier, "test-placement")
        XCTAssertEqual(event.url, "https://example.com")
    }

    func test_RoktShowLoadingIndicator() {
        let event = RoktEvent.ShowLoadingIndicator()
        XCTAssertTrue(event is RoktEvent.ShowLoadingIndicator)
    }

    func test_RoktHideLoadingIndicator() {
        let event = RoktEvent.HideLoadingIndicator()
        XCTAssertTrue(event is RoktEvent.HideLoadingIndicator)
    }

    func test_RoktEmbeddedSizeChanged() {
        let event = RoktEvent.EmbeddedSizeChanged(identifier: "embed-1", updatedHeight: 250.5)
        XCTAssertTrue(event is RoktEvent.EmbeddedSizeChanged)
        XCTAssertEqual(event.identifier, "embed-1")
        XCTAssertEqual(event.updatedHeight, 250.5)
        XCTAssertTrue(event is RoktEvent)
    }

    func test_RoktEmbeddedSizeChanged_runtimeClass() {
        XCTAssertNotNil(NSClassFromString("RoktEmbeddedSizeChanged"))
    }

    func test_RoktCartItemInstantPurchase_runtimeClass() {
        let eventClass: AnyClass? = NSClassFromString("RoktCartItemInstantPurchase")
        XCTAssertNotNil(eventClass)
    }

    func test_roktEvent_casting_OpenUrl() {
        let event: RoktEvent = RoktEvent.OpenUrl(identifier: "test", url: "https://example.com")
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

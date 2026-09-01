import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPSessionTimingPolicyTests: XCTestCase {
    // MARK: - Session timeout clamp

    func testSessionTimeoutIsFlooredAtTheMinimum() {
        XCTAssertEqual(MPSessionTimingPolicy.clampedSessionTimeout(0.0, minimum: 1.0), 1.0)
        XCTAssertEqual(MPSessionTimingPolicy.clampedSessionTimeout(-5.0, minimum: 1.0), 1.0)
    }

    func testSessionTimeoutAboveTheMinimumIsUnchanged() {
        XCTAssertEqual(MPSessionTimingPolicy.clampedSessionTimeout(120.0, minimum: 1.0), 120.0)
    }

    // MARK: - Default upload interval

    func testDefaultUploadIntervalUsesDebugCadenceInDevelopment() {
        XCTAssertEqual(
            MPSessionTimingPolicy.defaultUploadInterval(isDevelopment: true, debugInterval: 60.0, productionInterval: 600.0),
            60.0
        )
    }

    func testDefaultUploadIntervalUsesProductionCadenceOtherwise() {
        XCTAssertEqual(
            MPSessionTimingPolicy.defaultUploadInterval(isDevelopment: false, debugInterval: 60.0, productionInterval: 600.0),
            600.0
        )
    }

    // MARK: - Upload interval clamp

    func testUploadIntervalIsFlooredAtOneSecond() {
        XCTAssertEqual(MPSessionTimingPolicy.clampedUploadInterval(0.5, tvOSCeiling: 600.0), 1.0)
    }

    func testUploadIntervalIsPlatformDependentAboveTheFloor() {
        let clamped = MPSessionTimingPolicy.clampedUploadInterval(5000.0, tvOSCeiling: 600.0)
        #if os(tvOS)
            XCTAssertEqual(clamped, 600.0)
        #else
            XCTAssertEqual(clamped, 5000.0)
        #endif
    }

    // MARK: - Should end session

    func testSessionNeverEndsWhenNoBackgroundEventRecorded() {
        XCTAssertFalse(MPSessionTimingPolicy.shouldEndSession(now: 1000.0, lastEventInBackground: 0.0, sessionTimeout: 60.0))
    }

    func testSessionEndsOnceIdleReachesTheTimeout() {
        XCTAssertTrue(MPSessionTimingPolicy.shouldEndSession(now: 1060.0, lastEventInBackground: 1000.0, sessionTimeout: 60.0))
    }

    func testSessionDoesNotEndBeforeTheTimeout() {
        XCTAssertFalse(MPSessionTimingPolicy.shouldEndSession(now: 1059.0, lastEventInBackground: 1000.0, sessionTimeout: 60.0))
    }
}

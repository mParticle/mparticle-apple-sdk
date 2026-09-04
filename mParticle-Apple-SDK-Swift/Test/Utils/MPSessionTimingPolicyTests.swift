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

extension MPSessionTimingPolicyTests {
    // MARK: - cleanUpPlan

    private static let ninetyDays: TimeInterval = 90 * 24 * 60 * 60
    private static let twentyFourHours: TimeInterval = 24 * 60 * 60

    func testNoPlanBeforeTheNextCleanUpTime() {
        XCTAssertNil(MPSessionTimingPolicy.cleanUpPlan(
            now: 1000,
            nextCleanUpTime: 1000,
            maxAgeSeconds: nil,
            defaultMaxAge: Self.ninetyDays,
            interval: Self.twentyFourHours
        ))
        XCTAssertNil(MPSessionTimingPolicy.cleanUpPlan(
            now: 1000,
            nextCleanUpTime: 2000,
            maxAgeSeconds: nil,
            defaultMaxAge: Self.ninetyDays,
            interval: Self.twentyFourHours
        ))
    }

    func testDuePlanUsesTheDefaultRetentionWhenUnconfigured() throws {
        let plan = try XCTUnwrap(MPSessionTimingPolicy.cleanUpPlan(
            now: 1_000_000,
            nextCleanUpTime: 0,
            maxAgeSeconds: nil,
            defaultMaxAge: Self.ninetyDays,
            interval: Self.twentyFourHours
        ))

        XCTAssertEqual(plan.deleteRecordsOlderThan, 1_000_000 - Self.ninetyDays)
        XCTAssertEqual(plan.nextCleanUpTime, 1_000_000 + Self.twentyFourHours)
    }

    func testConfiguredRetentionOverridesTheDefault() throws {
        let plan = try XCTUnwrap(MPSessionTimingPolicy.cleanUpPlan(
            now: 1_000_000,
            nextCleanUpTime: 0,
            maxAgeSeconds: NSNumber(value: 60),
            defaultMaxAge: Self.ninetyDays,
            interval: Self.twentyFourHours
        ))

        XCTAssertEqual(plan.deleteRecordsOlderThan, 999_940)
        XCTAssertEqual(plan.nextCleanUpTime, 1_000_000 + Self.twentyFourHours)
    }

    func testAZeroRetentionPrunesEverythingUpToNow() throws {
        let plan = try XCTUnwrap(MPSessionTimingPolicy.cleanUpPlan(
            now: 500,
            nextCleanUpTime: 0,
            maxAgeSeconds: NSNumber(value: 0),
            defaultMaxAge: Self.ninetyDays,
            interval: Self.twentyFourHours
        ))

        XCTAssertEqual(plan.deleteRecordsOlderThan, 500)
    }
}

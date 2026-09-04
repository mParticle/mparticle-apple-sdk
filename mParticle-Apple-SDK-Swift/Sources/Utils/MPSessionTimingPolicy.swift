import Foundation

/// Pure timing arithmetic for session timeout and upload cadence. The caller
/// keeps every side effect (ivar caching, timer restart, environment reads,
/// logging); this type only computes values.
@objc public final class MPSessionTimingPolicy: NSObject {
    /// The session timeout can never drop below the platform minimum.
    @objc(clampedSessionTimeout:minimum:)
    public static func clampedSessionTimeout(_ requested: TimeInterval, minimum: TimeInterval) -> TimeInterval {
        max(requested, minimum)
    }

    /// The default upload interval before any caller override: the debug
    /// cadence in a development environment, otherwise the production cadence.
    @objc(defaultUploadIntervalForDevelopment:debugInterval:productionInterval:)
    public static func defaultUploadInterval(isDevelopment: Bool, debugInterval: TimeInterval,
                                             productionInterval: TimeInterval) -> TimeInterval {
        isDevelopment ? debugInterval : productionInterval
    }

    /// A caller-supplied upload interval is floored at one second, and on tvOS
    /// additionally capped at the production ceiling.
    @objc(clampedUploadInterval:tvOSCeiling:)
    public static func clampedUploadInterval(_ requested: TimeInterval, tvOSCeiling: TimeInterval) -> TimeInterval {
        var interval = max(requested, 1.0)
        #if os(tvOS)
            interval = min(interval, tvOSCeiling)
        #endif
        return interval
    }

    /// A session times out when the app has been idle in the background for at
    /// least the session timeout. A zero last-event time means no background
    /// idle has been recorded yet, so the session never ends.
    @objc(shouldEndSessionWithNow:lastEventInBackground:sessionTimeout:)
    public static func shouldEndSession(now: TimeInterval, lastEventInBackground: TimeInterval,
                                        sessionTimeout: TimeInterval) -> Bool {
        if lastEventInBackground == 0.0 {
            return false
        }
        return now - lastEventInBackground >= sessionTimeout
    }

    /// When the periodic database clean-up is due, what cutoff to prune to and when to run next.
    ///
    /// `nil` means the clean-up is not due yet, so the caller prunes nothing and leaves its stored
    /// next-run time alone. `maxAgeSeconds` falls back to `defaultMaxAge` when the caller has not
    /// configured a retention window.
    @objc(cleanUpPlanWithNow:nextCleanUpTime:maxAgeSeconds:defaultMaxAge:interval:)
    public static func cleanUpPlan(
        now: TimeInterval,
        nextCleanUpTime: TimeInterval,
        maxAgeSeconds: NSNumber?,
        defaultMaxAge: TimeInterval,
        interval: TimeInterval
    ) -> MPCleanUpPlan? {
        guard nextCleanUpTime < now else { return nil }
        let maxAge = maxAgeSeconds?.doubleValue ?? defaultMaxAge
        return MPCleanUpPlan(deleteRecordsOlderThan: now - maxAge, nextCleanUpTime: now + interval)
    }
}

/// The outcome of a due database clean-up: what to prune and when to run again.
@objc(MPCleanUpPlan)
public final class MPCleanUpPlan: NSObject {
    @objc public let deleteRecordsOlderThan: TimeInterval
    @objc public let nextCleanUpTime: TimeInterval

    init(deleteRecordsOlderThan: TimeInterval, nextCleanUpTime: TimeInterval) {
        self.deleteRecordsOlderThan = deleteRecordsOlderThan
        self.nextCleanUpTime = nextCleanUpTime
        super.init()
    }
}

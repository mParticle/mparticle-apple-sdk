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
}

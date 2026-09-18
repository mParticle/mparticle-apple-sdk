import Foundation

/// Owns the live session and timing values. Compound transitions use the same lock as individual accessors.
@objc(MPBackendSessionState)
public final class MPBackendSessionState: NSObject {
    private let lock = NSRecursiveLock()
    private var storedTimeAppWentToBackground: TimeInterval = 0
    private var storedTimeAppWentToBackgroundInCurrentSession: TimeInterval = 0
    private var storedNextCleanUpTime: TimeInterval = 0
    private var storedPreviousForegroundTime: NSNumber?
    private var storedSession: MPSessionPRIVATE?
    private var storedTimeOfLastEventInBackground: TimeInterval = 0

    @objc public var sessionTimeout: TimeInterval = 0
    @objc public var timeOfLastEventInBackground: TimeInterval {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedTimeOfLastEventInBackground
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storedTimeOfLastEventInBackground = newValue
        }
    }
    @objc public var timeAppWentToBackground: TimeInterval {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedTimeAppWentToBackground
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storedTimeAppWentToBackground = newValue
        }
    }
    @objc public var timeAppWentToBackgroundInCurrentSession: TimeInterval {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedTimeAppWentToBackgroundInCurrentSession
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storedTimeAppWentToBackgroundInCurrentSession = newValue
        }
    }
    @objc public var nextCleanUpTime: TimeInterval {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedNextCleanUpTime
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storedNextCleanUpTime = newValue
        }
    }
    @objc public var previousForegroundTime: NSNumber? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedPreviousForegroundTime
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storedPreviousForegroundTime = newValue
        }
    }


    // Access pending state only inside withSessionLock so creation and adoption stay atomic.
    var pendingSessionUUID: String?
    var pendingSessionStartTime: TimeInterval?

    @objc public var session: MPSessionPRIVATE? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedSession
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storedSession = newValue
        }
    }

    /// Allows Objective-C transitions to use the same lock as nested session access.
    @objc(withSessionLock:)
    public func withSessionLock(_ transition: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        transition()
    }
}

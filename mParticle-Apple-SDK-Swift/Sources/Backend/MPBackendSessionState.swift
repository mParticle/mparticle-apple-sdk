import Foundation

/// Owns the live session and the recursive boundary shared by session transitions.
@objc(MPBackendSessionState)
public final class MPBackendSessionState: NSObject {
    private let lock = NSRecursiveLock()
    private var storedSession: MPSessionPRIVATE?
    private var storedTimeOfLastEventInBackground: TimeInterval = 0

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

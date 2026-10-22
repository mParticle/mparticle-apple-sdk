import Foundation

/// Backs `-[MParticle isKitActive:]`, `-kitInstance:` and `-kitInstance:completionHandler:`.
///
/// Reading the active-kit registry needs Objective-C kit types this module cannot import, so
/// `mParticle.m` supplies both lookups as closures.
@objc(MPKitActivity)
public final class MPKitActivity: NSObject {
    // Mirror mParticleKitDidBecomeActiveNotification and mParticleKitInstanceKey
    // (mParticle-Apple-SDK/MPEnums.m). The Swift module cannot import the ObjC module to read
    // them; MPKitActivityTests.testPendingHandlerRunsWhenKitStartsDuringConfiguration (ObjC) only
    // passes when they match.
    private static let kitDidBecomeActiveNotification = Notification.Name("mParticleKitDidBecomeActiveNotification")
    private static let kitInstanceKey = "mParticleKitInstanceKey"

    private let isKitActiveForCode: (NSNumber?) -> Bool
    private let kitInstanceForCode: (NSNumber?) -> Any?
    // A pending handler is never removed: it runs again on every later activation of its kit.
    // Appends happen on the caller's thread and reads on main, so both go through the lock.
    private var pendingHandlers: [(integrationId: NSNumber, handler: (Any?) -> Void)] = []
    private let pendingHandlersLock = NSLock()

    @objc public init(
        isKitActive: @escaping (NSNumber?) -> Bool,
        kitInstance: @escaping (NSNumber?) -> Any?
    ) {
        isKitActiveForCode = isKitActive
        kitInstanceForCode = kitInstance
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleKitDidBecomeActive(_:)),
            name: Self.kitDidBecomeActiveNotification, object: nil
        )
    }

    @objc public func isKitActive(_ integrationId: NSNumber?) -> Bool {
        isKitActiveForCode(integrationId)
    }

    @objc public func kitInstance(_ integrationId: NSNumber?) -> Any? {
        kitInstanceForCode(integrationId)
    }

    /// Calls `handler` now when the kit has an instance, otherwise each time the kit reports it
    /// became active.
    @objc(kitInstance:withHandler:)
    public func kitInstance(_ integrationId: NSNumber, handler: @escaping (Any?) -> Void) {
        if let instance = kitInstanceForCode(integrationId) {
            handler(instance)
        } else {
            pendingHandlersLock.lock()
            pendingHandlers.append((integrationId, handler))
            pendingHandlersLock.unlock()
        }
    }

    @objc private func handleKitDidBecomeActive(_ notification: Notification) {
        let integrationId = notification.userInfo?[Self.kitInstanceKey]
        // Some kits post synchronously while configureKits holds kitsSemaphore, and resolving a pending
        // handler's instance waits on it. Resolve once configuration has released it.
        DispatchQueue.main.async {
            self.pendingHandlersLock.lock()
            let pendingHandlers = self.pendingHandlers
            self.pendingHandlersLock.unlock()
            for pending in pendingHandlers where pending.integrationId.isEqual(integrationId) {
                pending.handler(self.kitInstanceForCode(pending.integrationId))
            }
        }
    }
}

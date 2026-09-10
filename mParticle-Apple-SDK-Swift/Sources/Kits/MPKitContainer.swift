import Foundation

// swiftlint:disable type_name
/// Internal Swift owner for kit-container runtime identity and registry state.
///
/// SDK event types remain in the Objective-C target, so calls involving those types are
/// executed by a private adapter discovered at runtime. This keeps the container out of the
/// public Objective-C umbrella without introducing a dependency from the Swift module back to
/// the Objective-C module.
@objc(MPKitContainer_PRIVATE) public final class MPKitContainer_PRIVATE: NSObject {
    private static let registryLock = NSLock()
    private static let registry = NSMutableSet(capacity: 2)

    /// Tracks kit teardown work deferred to the main queue by `flushSerializedKits` and
    /// `freeKitRegister:integrationId:` (stop(), disk cleanup, notification). Workspace-switch
    /// callers in `mParticle.m` enter this group before dispatching that work and leave it
    /// after, so `notifyWhenKitTeardownComplete(_:block:)` lets them wait for old kits to
    /// actually finish stopping before starting the next workspace's kits - deferring the work
    /// off the execution adapter's kitsSemaphore (to avoid holding that lock across arbitrary
    /// kit/observer code) would otherwise leave no guarantee that a kit with process-wide
    /// teardown (e.g. one whose stop() shuts down a shared SDK singleton) finishes before the
    /// new workspace's identical kit starts back up. Scoped statically alongside the registry
    /// itself, rather than per `MPKitContainer_PRIVATE` instance, since a workspace switch
    /// tears down kits registered against the old instance while mParticle.m is already
    /// constructing the next one.
    private static let kitTeardownGroup = DispatchGroup()

    @objc public static func enterKitTeardownGroup() {
        kitTeardownGroup.enter()
    }

    @objc public static func leaveKitTeardownGroup() {
        kitTeardownGroup.leave()
    }

    @objc public static func notifyWhenKitTeardownComplete(_ queue: DispatchQueue, block: @escaping () -> Void) {
        kitTeardownGroup.notify(queue: queue, execute: block)
    }

    @discardableResult
    @objc public static func registerKit(_ kitRegister: Any) -> Bool {
        registryLock.lock()
        registry.add(kitRegister)
        registryLock.unlock()
        return true
    }

    @objc public static func removeRegisteredKit(_ kitRegister: Any) {
        registryLock.lock()
        registry.remove(kitRegister)
        registryLock.unlock()
    }

    @objc public static func registeredKits() -> NSSet? {
        registryLock.lock()
        defer { registryLock.unlock() }
        // swiftformat:disable:next isEmpty
        guard registry.count > 0 else { return nil }
        return registry.copy() as? NSSet
    }

    @objc public static func resetRegistry() {
        registryLock.lock()
        defer { registryLock.unlock() }
        registry.removeAllObjects()
    }

    @objc public let executionAdapter: NSObject

    @objc override public init() {
        if let adapterType = NSClassFromString("MPKitContainerExecutionAdapter") as? NSObject.Type {
            executionAdapter = adapterType.init()
        } else {
            NSLog("mParticle -> MPKitContainerExecutionAdapter is unavailable; kit forwarding is disabled.")
            executionAdapter = NSObject()
        }
        super.init()
    }

    override public func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) || executionAdapter.responds(to: aSelector)
    }

    override public func forwardingTarget(for aSelector: Selector!) -> Any? {
        if executionAdapter.responds(to: aSelector) {
            return executionAdapter
        }
        return super.forwardingTarget(for: aSelector)
    }
}
// swiftlint:enable type_name

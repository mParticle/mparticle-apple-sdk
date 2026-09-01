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

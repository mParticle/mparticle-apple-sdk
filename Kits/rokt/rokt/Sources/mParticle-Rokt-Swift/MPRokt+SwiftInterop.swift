import Foundation
import ObjectiveC
import mParticle_Apple_SDK
import RoktContracts

// Swift omits `events:onEvent:` and the full `selectPlacements:…onEvent:` from generated Swift API (RoktEvent block bridging).
extension MPRokt {
    public func subscribeToPlacementEvents(
        _ identifier: String,
        onEvent: @escaping (RoktEvent) -> Void
    ) {
        typealias Block = @convention(block) (RoktEvent) -> Void
        let sel = NSSelectorFromString("events:onEvent:")
        guard let method = class_getInstanceMethod(MPRokt.self, sel) else { return }
        let imp = method_getImplementation(method)
        typealias Fn = @convention(c) (AnyObject, Selector, NSString, Block?) -> Void
        unsafeBitCast(imp, to: Fn.self)(self, sel, identifier as NSString, onEvent as Block)
    }

    public func subscribeToGlobalEvents(_ onEvent: @escaping (RoktEvent) -> Void) {
        typealias Block = @convention(block) (RoktEvent) -> Void
        let sel = NSSelectorFromString("globalEvents:")
        guard let method = class_getInstanceMethod(MPRokt.self, sel) else { return }
        let imp = method_getImplementation(method)
        typealias Fn = @convention(c) (AnyObject, Selector, Block) -> Void
        unsafeBitCast(imp, to: Fn.self)(self, sel, onEvent as Block)
    }

    public func selectPlacements(
        _ identifier: String,
        attributes: [String: String],
        embeddedViews: [String: RoktEmbeddedView]?,
        config: RoktConfig?,
        onEvent: ((RoktEvent) -> Void)?
    ) {
        typealias EventBlock = @convention(block) (RoktEvent) -> Void
        let sel = NSSelectorFromString("selectPlacements:attributes:embeddedViews:config:onEvent:")
        guard let method = class_getInstanceMethod(MPRokt.self, sel) else { return }
        let imp = method_getImplementation(method)
        typealias Fn = @convention(c) (
            AnyObject,
            Selector,
            NSString,
            NSDictionary?,
            NSDictionary?,
            RoktConfig?,
            EventBlock?
        ) -> Void
        let attrs = attributes as NSDictionary
        let embedded = embeddedViews as NSDictionary?
        let block: EventBlock? = onEvent.map { cb in cb as EventBlock }
        unsafeBitCast(imp, to: Fn.self)(self, sel, identifier as NSString, attrs, embedded, config, block)
    }
}

import Foundation
import ObjectiveC
import mParticle_Apple_SDK
import RoktContracts

// Swift omits several `MPRokt` APIs that use `RoktEvent` blocks or `RoktPaymentExtension` from the generated Swift API.
extension MPRokt {
    /// Bridges `registerPaymentExtension:` when Swift cannot import the ObjC declaration.
    public func registerPaymentExtension(_ paymentExtension: PaymentExtension) {
        let sel = NSSelectorFromString("registerPaymentExtension:")
        guard let method = class_getInstanceMethod(MPRokt.self, sel) else { return }
        let imp = method_getImplementation(method)
        typealias Fn = @convention(c) (AnyObject, Selector, AnyObject) -> Void
        unsafeBitCast(imp, to: Fn.self)(self, sel, paymentExtension as AnyObject)
    }

    /// Bridges `selectShoppableAds:attributes:config:onEvent:` when Swift cannot import the ObjC declaration.
    public func selectShoppableAds(
        _ identifier: String,
        attributes: [String: String],
        config: RoktConfig?,
        onEvent: ((RoktEvent) -> Void)?
    ) {
        typealias EventBlock = @convention(block) (RoktEvent) -> Void
        let sel = NSSelectorFromString("selectShoppableAds:attributes:config:onEvent:")
        guard let method = class_getInstanceMethod(MPRokt.self, sel) else { return }
        let imp = method_getImplementation(method)
        typealias Fn = @convention(c) (
            AnyObject,
            Selector,
            NSString,
            NSDictionary,
            RoktConfig?,
            EventBlock?
        ) -> Void
        let block: EventBlock? = onEvent.map { $0 as EventBlock }
        unsafeBitCast(imp, to: Fn.self)(
            self,
            sel,
            identifier as NSString,
            attributes as NSDictionary,
            config,
            block
        )
    }

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

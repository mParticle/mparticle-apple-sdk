import Foundation
import ObjectiveC
import mParticle_Apple_SDK_ObjC
import RoktContracts

// Swift cannot auto-import MPRokt methods whose signatures reference
// forward-declared Swift-origin types (RoktEvent, RoktConfig, etc.)
// from the ObjC header.  These extensions bridge the gap so partners
// can call the same API names in Swift as in Objective-C.
extension MPRokt {

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
            AnyObject, Selector, NSString, NSDictionary?, NSDictionary?, RoktConfig?, EventBlock?
        ) -> Void
        let block: EventBlock? = onEvent.map { $0 as EventBlock }
        unsafeBitCast(imp, to: Fn.self)(
            self, sel,
            identifier as NSString,
            attributes as NSDictionary,
            embeddedViews as NSDictionary?,
            config,
            block
        )
    }

    public func events(
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

    public func globalEvents(onEvent: @escaping (RoktEvent) -> Void) {
        typealias Block = @convention(block) (RoktEvent) -> Void
        let sel = NSSelectorFromString("globalEvents:")
        guard let method = class_getInstanceMethod(MPRokt.self, sel) else { return }
        let imp = method_getImplementation(method)
        typealias Fn = @convention(c) (AnyObject, Selector, Block) -> Void
        unsafeBitCast(imp, to: Fn.self)(self, sel, onEvent as Block)
    }

    public func registerPaymentExtension(_ paymentExtension: PaymentExtension) {
        let sel = NSSelectorFromString("registerPaymentExtension:")
        guard let method = class_getInstanceMethod(MPRokt.self, sel) else { return }
        let imp = method_getImplementation(method)
        typealias Fn = @convention(c) (AnyObject, Selector, AnyObject) -> Void
        unsafeBitCast(imp, to: Fn.self)(self, sel, paymentExtension as AnyObject)
    }

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
            AnyObject, Selector, NSString, NSDictionary, RoktConfig?, EventBlock?
        ) -> Void
        let block: EventBlock? = onEvent.map { $0 as EventBlock }
        unsafeBitCast(imp, to: Fn.self)(
            self, sel,
            identifier as NSString,
            attributes as NSDictionary,
            config,
            block
        )
    }
}

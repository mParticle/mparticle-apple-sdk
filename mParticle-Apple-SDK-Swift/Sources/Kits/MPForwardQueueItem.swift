import Foundation

@objc public enum MPQueueItemType: UInt {
    case event
    case ecommerce
    case generalPurpose
}

/// Opaque queued kit call owned by Swift while SDK event values remain Objective-C objects.
@objc(MPForwardQueueItem) public final class MPForwardQueueItem: NSObject {
    @objc public let commerceEvent: AnyObject?
    @objc public let event: AnyObject?
    @objc public let messageType: UInt
    @objc public let queueItemType: MPQueueItemType
    @objc public let selector: Selector?
    @objc public let queueParameters: AnyObject?

    @objc(initWithCommerceEvent:)
    public init?(commerceEvent: AnyObject?) {
        guard let commerceEvent else { return nil }
        self.commerceEvent = commerceEvent
        event = nil
        messageType = 0
        queueItemType = .ecommerce
        selector = nil
        queueParameters = nil
        super.init()
    }

    @objc(initWithSelector:event:messageType:)
    public init?(selector: Selector?, event: AnyObject?, messageType: UInt) {
        guard let selector, let event else { return nil }
        commerceEvent = nil
        self.event = event
        self.messageType = messageType
        queueItemType = .event
        self.selector = selector
        queueParameters = nil
        super.init()
    }

    @objc(initWithSelector:parameters:messageType:)
    public init?(selector: Selector?, parameters: AnyObject?, messageType: UInt) {
        guard let selector else { return nil }
        commerceEvent = nil
        event = nil
        self.messageType = messageType
        queueItemType = .generalPurpose
        self.selector = selector
        queueParameters = parameters
        super.init()
    }
}

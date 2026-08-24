import Foundation

@objc public final class MPExecutorPRIVATE: NSObject {
    private let queue: DispatchQueue
    private let queueKey = DispatchSpecificKey<UInt8>()

    override public init() {
        queue = DispatchQueue(label: "com.mparticle.messageQueue")
        super.init()
        queue.setSpecific(key: queueKey, value: 1)
    }

    @objc public var messageQueue: DispatchQueue { queue }

    @objc public var isMessageQueue: Bool {
        DispatchQueue.getSpecific(key: queueKey) == 1
    }

    @objc(executeOnMessage:)
    public func executeOnMessage(_ block: @escaping () -> Void) {
        if isMessageQueue {
            block()
        } else {
            queue.async(execute: block)
        }
    }

    @objc(executeOnMessageSync:)
    public func executeOnMessageSync(_ block: @escaping () -> Void) {
        if isMessageQueue {
            block()
        } else {
            queue.sync(execute: block)
        }
    }

    @objc(executeOnMain:)
    public func executeOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

    @objc(executeOnMainSync:)
    public func executeOnMainSync(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync(execute: block)
        }
    }
}

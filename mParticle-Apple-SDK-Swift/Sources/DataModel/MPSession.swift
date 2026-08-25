import Foundation

@objc public final class MPSessionPRIVATE: NSObject {
    @objc public var sessionId: Int64
    @objc public var uuid: String
    @objc public var backgroundTime: TimeInterval
    @objc public var startTime: TimeInterval
    @objc public var endTime: TimeInterval
    @objc public var length: TimeInterval
    @objc public var eventCounter: UInt32
    @objc public var numberOfInterruptions: UInt32
    @objc public var suspendTime: TimeInterval
    @objc public var userId: NSNumber
    @objc public var sessionUserIds: String
    @objc public var attributesDictionary: NSMutableDictionary
    @objc public var applicationInfo: NSDictionary?
    @objc public var deviceInfo: NSDictionary?

    @objc public var persisted: Bool { sessionId != 0 }

    @objc public var foregroundTime: TimeInterval {
        let foreground = length - backgroundTime
        return foreground < 0 ? 0 : foreground
    }

    @objc public init(
        sessionId: Int64,
        uuid: String,
        backgroundTime: TimeInterval,
        startTime: TimeInterval,
        endTime: TimeInterval,
        attributes: NSMutableDictionary?,
        numberOfInterruptions: UInt32,
        eventCounter: UInt32,
        suspendTime: TimeInterval,
        userId: NSNumber,
        sessionUserIds: String,
        applicationInfo: NSDictionary?,
        deviceInfo: NSDictionary?
    ) {
        self.sessionId = sessionId
        self.uuid = uuid
        self.backgroundTime = backgroundTime
        self.startTime = startTime
        self.endTime = endTime
        length = endTime - startTime
        self.eventCounter = eventCounter
        self.numberOfInterruptions = numberOfInterruptions
        self.suspendTime = suspendTime
        self.sessionUserIds = sessionUserIds
        self.applicationInfo = applicationInfo
        self.deviceInfo = deviceInfo
        attributesDictionary = attributes ?? NSMutableDictionary()
        self.userId = userId
        super.init()
    }

    @objc public func applyEndTime(_ proposedEndTime: TimeInterval) {
        if proposedEndTime > startTime {
            endTime = proposedEndTime
            length = endTime - startTime
        } else if length > 0 {
            endTime = startTime + length
        } else {
            endTime = startTime
        }
    }

    @objc public func resolveLength() -> TimeInterval {
        if length == 0 && endTime > startTime {
            length = endTime - startTime
        }
        return length
    }

    @objc public func incrementCounter() {
        eventCounter += 1
    }

    @objc public func suspendSession() {
        numberOfInterruptions += 1
        suspendTime = Date().timeIntervalSince1970
    }

    @objc public func copySession() -> MPSessionPRIVATE {
        MPSessionPRIVATE(
            sessionId: sessionId,
            uuid: uuid,
            backgroundTime: backgroundTime,
            startTime: startTime,
            endTime: endTime,
            attributes: attributesDictionary.mutableCopy() as? NSMutableDictionary,
            numberOfInterruptions: numberOfInterruptions,
            eventCounter: eventCounter,
            suspendTime: suspendTime,
            userId: userId,
            sessionUserIds: sessionUserIds,
            applicationInfo: applicationInfo,
            deviceInfo: deviceInfo
        )
    }

    @objc public func isEqual(toSession other: MPSessionPRIVATE) -> Bool {
        sessionId == other.sessionId && eventCounter == other.eventCounter && uuid == other.uuid
    }

    override public var hash: Int {
        Int(truncatingIfNeeded: sessionId) ^ Int(eventCounter) ^ uuid.hashValue
    }
}

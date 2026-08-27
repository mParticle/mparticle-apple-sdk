import Foundation

@objc(MPSession)
public final class MPSessionPRIVATE: NSObject, NSCopying {
    private let lock = NSRecursiveLock()
    private var storedSessionId: Int64
    private var storedUUID: String
    private var storedBackgroundTime: TimeInterval
    private var storedStartTime: TimeInterval
    private var storedEndTime: TimeInterval
    private var storedLength: TimeInterval
    private var storedEventCounter: UInt32
    private var storedNumberOfInterruptions: UInt32
    private var storedSuspendTime: TimeInterval
    private var storedUserId: NSNumber
    private var storedSessionUserIds: String
    private var storedAttributesDictionary: NSMutableDictionary
    private var storedAppInfo: NSDictionary?
    private var storedDeviceInfo: NSDictionary?

    @objc dynamic public var sessionId: Int64 {
        get { withLock { storedSessionId } }
        set { withLock { storedSessionId = newValue } }
    }

    @objc dynamic public var uuid: String {
        get { withLock { storedUUID } }
        set { withLock { storedUUID = newValue } }
    }

    @objc dynamic public var backgroundTime: TimeInterval {
        get { withLock { storedBackgroundTime } }
        set { withLock { storedBackgroundTime = newValue } }
    }

    @objc dynamic public var startTime: TimeInterval {
        get { withLock { storedStartTime } }
        set { withLock { storedStartTime = newValue } }
    }

    @objc dynamic public var endTime: TimeInterval {
        get { withLock { storedEndTime } }
        set { applyEndTime(newValue) }
    }

    @objc dynamic public var length: TimeInterval {
        get {
            withLock {
                if storedLength == 0, storedEndTime > storedStartTime {
                    willChangeValue(forKey: "length")
                    storedLength = storedEndTime - storedStartTime
                    didChangeValue(forKey: "length")
                }
                return storedLength
            }
        }
        set { withLock { storedLength = newValue } }
    }

    @objc dynamic public private(set) var eventCounter: UInt32 {
        get { withLock { storedEventCounter } }
        set { withLock { storedEventCounter = newValue } }
    }

    @objc dynamic public private(set) var numberOfInterruptions: UInt32 {
        get { withLock { storedNumberOfInterruptions } }
        set { withLock { storedNumberOfInterruptions = newValue } }
    }

    @objc dynamic public private(set) var suspendTime: TimeInterval {
        get { withLock { storedSuspendTime } }
        set { withLock { storedSuspendTime = newValue } }
    }

    @objc dynamic public var userId: NSNumber {
        get { withLock { storedUserId } }
        set { withLock { storedUserId = newValue } }
    }

    @objc dynamic public var sessionUserIds: String {
        get { withLock { storedSessionUserIds } }
        set { withLock { storedSessionUserIds = newValue } }
    }

    @objc dynamic public var attributesDictionary: NSMutableDictionary {
        get { withLock { storedAttributesDictionary } }
        set { withLock { storedAttributesDictionary = newValue } }
    }

    @objc dynamic public var appInfo: NSDictionary? {
        get { withLock { storedAppInfo } }
        set { withLock { storedAppInfo = newValue } }
    }

    @objc dynamic public var deviceInfo: NSDictionary? {
        get { withLock { storedDeviceInfo } }
        set { withLock { storedDeviceInfo = newValue } }
    }

    @objc public var persisted: Bool {
        withLock { storedSessionId != 0 }
    }

    @objc public var foregroundTime: TimeInterval {
        withLock { max(storedLength - storedBackgroundTime, 0) }
    }

    override public convenience init() {
        let now = Date().timeIntervalSince1970
        self.init(startTime: now, userId: MPUserDefaults.storedMpId())
    }

    @objc(initWithStartTime:userId:)
    public convenience init(startTime: TimeInterval, userId: NSNumber) {
        self.init(startTime: startTime, userId: userId, uuid: nil)
    }

    @objc(initWithStartTime:userId:uuid:)
    public convenience init(startTime: TimeInterval, userId: NSNumber, uuid: String?) {
        self.init(
            sessionId: 0,
            uuid: uuid ?? UUID().uuidString,
            backgroundTime: 0,
            startTime: startTime,
            endTime: startTime,
            attributes: nil,
            numberOfInterruptions: 0,
            eventCounter: 0,
            suspendTime: 0,
            userId: userId,
            sessionUserIds: userId.stringValue,
            applicationInfo: nil,
            deviceInfo: nil
        )
    }

    // swiftlint:disable line_length
    @objc(
        initWithSessionId:UUID:backgroundTime:startTime:endTime:attributes:numberOfInterruptions:eventCounter:suspendTime:userId:sessionUserIds:appInfo:deviceInfo:
    )
    // swiftlint:enable line_length
    public init(
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
        storedSessionId = sessionId
        storedUUID = uuid
        storedBackgroundTime = backgroundTime
        storedStartTime = startTime
        storedEndTime = endTime
        storedLength = endTime - startTime
        storedEventCounter = eventCounter
        storedNumberOfInterruptions = numberOfInterruptions
        storedSuspendTime = suspendTime
        storedUserId = userId
        storedSessionUserIds = sessionUserIds
        storedAttributesDictionary = attributes ?? NSMutableDictionary()
        storedAppInfo = applicationInfo
        storedDeviceInfo = deviceInfo
        super.init()
    }

    @objc public func incrementCounter() {
        withLock {
            willChangeValue(forKey: "eventCounter")
            storedEventCounter += 1
            didChangeValue(forKey: "eventCounter")
        }
    }

    @objc public func suspendSession() {
        withLock {
            willChangeValue(forKey: "numberOfInterruptions")
            willChangeValue(forKey: "suspendTime")
            storedNumberOfInterruptions += 1
            storedSuspendTime = Date().timeIntervalSince1970
            didChangeValue(forKey: "numberOfInterruptions")
            didChangeValue(forKey: "suspendTime")
        }
    }

    @objc public func copy(with _: NSZone? = nil) -> Any {
        withLock {
            MPSessionPRIVATE(
                sessionId: storedSessionId,
                uuid: storedUUID,
                backgroundTime: storedBackgroundTime,
                startTime: storedStartTime,
                endTime: storedEndTime,
                attributes: storedAttributesDictionary.mutableCopy() as? NSMutableDictionary,
                numberOfInterruptions: storedNumberOfInterruptions,
                eventCounter: storedEventCounter,
                suspendTime: storedSuspendTime,
                userId: storedUserId,
                sessionUserIds: storedSessionUserIds,
                applicationInfo: storedAppInfo,
                deviceInfo: storedDeviceInfo
            )
        }
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MPSessionPRIVATE else { return false }
        return isEqual(toSession: other)
    }

    @objc(isEqualToSession:)
    public func isEqual(toSession other: MPSessionPRIVATE) -> Bool {
        sessionId == other.sessionId && eventCounter == other.eventCounter && uuid == other.uuid
    }

    override public var hash: Int {
        withLock {
            Int(truncatingIfNeeded: storedSessionId) ^ Int(storedEventCounter) ^ storedUUID.hashValue
        }
    }

    override public var description: String {
        withLock {
            "Session\n Id: \(storedSessionId)\n UUID: \(storedUUID)\n Background time: "
                + "\(String(format: "%.0f", storedBackgroundTime))\n Foreground time: "
                + "\(String(format: "%.0f", max(storedLength - storedBackgroundTime, 0)))\n Start: "
                + "\(String(format: "%.0f", storedStartTime))\n End: \(String(format: "%.0f", storedEndTime))"
                + "\n Length: \(String(format: "%.0f", storedLength))\n EventCounter: \(storedEventCounter)"
                + "\n Persisted: \(storedSessionId != 0 ? 1 : 0)\n Interruptions: \(storedNumberOfInterruptions)"
                + "\n Attributes: \(storedAttributesDictionary)\n"
        }
    }

    private func applyEndTime(_ proposedEndTime: TimeInterval) {
        withLock {
            if proposedEndTime > storedStartTime {
                storedEndTime = proposedEndTime
                storedLength = storedEndTime - storedStartTime
            } else if storedLength > 0 {
                storedEndTime = storedStartTime + storedLength
            } else {
                storedEndTime = storedStartTime
            }
        }
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}

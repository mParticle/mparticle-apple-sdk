import Foundation

@objc(MPMessage)
public final class MPMessagePRIVATE: NSObject, NSCopying, NSSecureCoding {
    @objc public var sessionId: NSNumber?
    @objc public var messageId: Int64
    @objc public var uuid: String?
    @objc public var messageType: String?
    @objc public var messageData: Data?
    @objc public var timestamp: TimeInterval
    @objc public var uploadStatus: Int
    @objc public var userId: NSNumber
    @objc public var dataPlanId: String?
    @objc public var dataPlanVersion: NSNumber?
    @objc public var shouldUploadEvent = true

    @objc public static var supportsSecureCoding: Bool { true }

    @objc(initWithSessionId:messageId:UUID:messageType:messageData:timestamp:uploadStatus:userId:dataPlanId:dataPlanVersion:)
    public init(
        sessionId: NSNumber?,
        messageId: Int64,
        uuid: String?,
        messageType: String?,
        messageData: Data?,
        timestamp: TimeInterval,
        uploadStatus: Int,
        userId: NSNumber,
        dataPlanId: String?,
        dataPlanVersion: NSNumber?
    ) {
        self.sessionId = sessionId
        self.messageId = messageId
        self.uuid = uuid
        self.messageType = messageType
        self.messageData = messageData
        self.timestamp = timestamp
        self.uploadStatus = uploadStatus
        self.userId = userId
        self.dataPlanId = dataPlanId
        self.dataPlanVersion = dataPlanVersion
        super.init()
    }

    @objc(initWithSession:messageType:messageInfo:uploadStatus:UUID:timestamp:userId:dataPlanId:dataPlanVersion:)
    public convenience init(
        session: MPSessionPRIVATE?,
        messageType: String,
        messageInfo: NSDictionary,
        uploadStatus: Int,
        uuid: String,
        timestamp: TimeInterval,
        userId: NSNumber,
        dataPlanId: String?,
        dataPlanVersion: NSNumber?
    ) {
        self.init(
            sessionId: session.map { NSNumber(value: $0.sessionId) },
            messageId: 0,
            uuid: uuid,
            messageType: messageType,
            messageData: Self.sanitizedJSONData(from: messageInfo),
            timestamp: timestamp,
            uploadStatus: uploadStatus,
            userId: userId,
            dataPlanId: dataPlanId,
            dataPlanVersion: dataPlanVersion
        )
    }

    public required convenience init?(coder: NSCoder) {
        self.init(
            sessionId: coder.decodeObject(of: NSNumber.self, forKey: "sessionId"),
            messageId: coder.decodeInt64(forKey: "messageId"),
            uuid: coder.decodeObject(of: NSString.self, forKey: "uuid") as String?,
            messageType: coder.decodeObject(of: NSString.self, forKey: "messageType") as String?,
            messageData: coder.decodeObject(of: NSData.self, forKey: "messageData") as Data?,
            timestamp: coder.decodeDouble(forKey: "timestamp"),
            uploadStatus: coder.decodeInteger(forKey: "uploadStatus"),
            userId: NSNumber(value: coder.decodeInt64(forKey: "mpid")),
            dataPlanId: coder.decodeObject(of: NSString.self, forKey: "dataPlanId") as String?,
            dataPlanVersion: coder.decodeObject(of: NSNumber.self, forKey: "dataPlanVersion")
        )
        if coder.containsValue(forKey: "shouldUploadEvent") {
            shouldUploadEvent = coder.decodeBool(forKey: "shouldUploadEvent")
        }
    }

    @objc public func encode(with coder: NSCoder) {
        coder.encode(sessionId, forKey: "sessionId")
        coder.encode(messageId, forKey: "messageId")
        coder.encode(uuid, forKey: "uuid")
        coder.encode(messageType, forKey: "messageType")
        coder.encode(messageData, forKey: "messageData")
        coder.encode(timestamp, forKey: "timestamp")
        coder.encode(uploadStatus, forKey: "uploadStatus")
        coder.encode(userId.int64Value, forKey: "mpid")
        coder.encode(dataPlanId, forKey: "dataPlanId")
        coder.encode(dataPlanVersion, forKey: "dataPlanVersion")
        coder.encode(shouldUploadEvent, forKey: "shouldUploadEvent")
    }

    @objc(sanitizedJSONDataFromMessageInfo:)
    public static func sanitizedJSONData(from messageInfo: NSDictionary) -> Data? {
        let dictionary = NSMutableDictionary(dictionary: messageInfo)
        if !JSONSerialization.isValidJSONObject(messageInfo) {
            fixInvalidKeys(dictionary, messageInfo: messageInfo)
        }
        return try? JSONSerialization.data(withJSONObject: dictionary, options: [])
    }

    @objc(fixInvalidKeysInDictionary:messageInfo:)
    public static func fixInvalidKeys(_ messageDictionary: NSMutableDictionary, messageInfo: NSDictionary) {
        for key in messageInfo.allKeys {
            guard let key = key as? String else { continue }
            if let nested = messageInfo[key] as? NSDictionary {
                if !JSONSerialization.isValidJSONObject(nested) {
                    let mutableNested = (messageDictionary[key] as? NSDictionary)?.mutableCopy() as? NSMutableDictionary
                    if let mutableNested {
                        fixInvalidKeys(mutableNested, messageInfo: nested)
                    }
                    messageDictionary[key] = mutableNested
                }
            } else if let value = messageInfo[key] as? NSNumber {
                let doubleValue = value.doubleValue
                if doubleValue.isInfinite || doubleValue.isNaN {
                    NSLog("mParticle -> Invalid Message Data for key: %@", key)
                    NSLog("mParticle -> Value should not be infinite. Removing value from message data")
                    messageDictionary[key] = nil
                }
            }
        }
    }

    @objc(truncateMessageDataProperty:toLength:)
    public func truncateMessageDataProperty(_ property: String?, toLength length: Int) {
        guard let property, length >= 0, let payload = messageData else { return }
        guard let json = try? JSONSerialization.jsonObject(with: payload, options: []),
              let dictionary = (json as? NSDictionary)?.mutableCopy() as? NSMutableDictionary,
              let value = dictionary[property] as? String
        else {
            return
        }

        let bytes = Data(value.utf8)
        dictionary[property] = String(data: Data(bytes.prefix(min(bytes.count, length))), encoding: .utf8)
        messageData = try? JSONSerialization.data(withJSONObject: dictionary, options: [])
    }

    @objc public func dictionaryRepresentation() -> NSDictionary? {
        guard let messageData else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(with: messageData, options: []) as? NSDictionary else {
            NSLog("mParticle -> Error serializing message.")
            return nil
        }
        return dictionary
    }

    @objc public func serializedString() -> String? {
        guard let messageData else { return nil }
        return String(data: messageData, encoding: .utf8)
    }

    @objc public func copy(with _: NSZone? = nil) -> Any {
        let copy = MPMessagePRIVATE(
            sessionId: sessionId,
            messageId: messageId,
            uuid: uuid,
            messageType: messageType,
            messageData: messageData,
            timestamp: timestamp,
            uploadStatus: uploadStatus,
            userId: userId,
            dataPlanId: dataPlanId,
            dataPlanVersion: dataPlanVersion
        )
        copy.shouldUploadEvent = shouldUploadEvent
        return copy
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MPMessagePRIVATE else { return false }
        return isEqual(toMessage: other)
    }

    @objc(isEqualToMessage:)
    public func isEqual(toMessage other: MPMessagePRIVATE) -> Bool {
        sessionId == other.sessionId
            && messageId == other.messageId
            && timestamp == other.timestamp
            && stringsEqual(messageType, other.messageType)
            && dataEqual(messageData, other.messageData)
            && shouldUploadEvent == other.shouldUploadEvent
            && dataPlanId == other.dataPlanId
            && dataPlanVersion == other.dataPlanVersion
    }

    override public var hash: Int {
        var result = sessionId?.hashValue ?? 0
        result ^= dataPlanId?.hashValue ?? 0
        result ^= dataPlanVersion?.hashValue ?? 0
        result ^= Int(truncatingIfNeeded: messageId)
        result ^= Int(timestamp)
        result ^= messageType?.hashValue ?? 0
        result ^= messageData?.hashValue ?? 0
        result ^= shouldUploadEvent ? 1 : 0
        return result
    }

    override public var description: String {
        "Message\n Id: \(messageId)\n UUID: \(uuid ?? "(null)")\n Session: \(sessionId?.description ?? "(null)")"
            + "\n Type: \(messageType ?? "(null)")\n timestamp: \(String(format: "%.0f", timestamp))"
            + "\n Data Plan: \(dataPlanId ?? "(null)") \(dataPlanVersion?.description ?? "(null)")"
            + "\n Content: \(serializedString() ?? "(null)")\n"
    }

    private func stringsEqual(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs, let rhs else { return false }
        return lhs == rhs
    }

    private func dataEqual(_ lhs: Data?, _ rhs: Data?) -> Bool {
        guard let lhs, let rhs else { return false }
        return lhs == rhs
    }
}

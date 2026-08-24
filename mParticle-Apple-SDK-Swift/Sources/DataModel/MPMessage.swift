import Foundation

@objc public final class MPMessagePRIVATE: NSObject {
    @objc public var sessionId: NSNumber?
    @objc public var messageId: Int64
    @objc public var uuid: String
    @objc public var messageType: String
    @objc public var messageData: Data
    @objc public var timestamp: TimeInterval
    @objc public var uploadStatus: Int
    @objc public var userId: NSNumber
    @objc public var dataPlanId: String?
    @objc public var dataPlanVersion: NSNumber?
    @objc public var shouldUploadEvent = true

    @objc(initWithSessionId:messageId:UUID:messageType:messageData:timestamp:uploadStatus:userId:dataPlanId:dataPlanVersion:)
    public init(
        sessionId: NSNumber?,
        messageId: Int64,
        uuid: String,
        messageType: String,
        messageData: Data,
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
                    let temp = (messageDictionary[key] as? NSDictionary)?.mutableCopy() as? NSMutableDictionary
                    if let temp {
                        fixInvalidKeys(temp, messageInfo: nested)
                    }
                    messageDictionary[key] = temp
                }
            } else if let value = messageInfo[key] as? NSNumber {
                let doubleValue = value.doubleValue
                if doubleValue == Double.infinity || doubleValue == -Double.infinity || doubleValue.isNaN {
                    NSLog("mParticle -> Invalid Message Data for key: %@", key)
                    NSLog("mParticle -> Value should not be infinite. Removing value from message data")
                    messageDictionary[key] = nil
                }
            }
        }
    }

    @objc(truncateMessageDataProperty:toLength:)
    public func truncateMessageDataProperty(_ property: String?, toLength length: Int) {
        guard let property, length >= 0 else { return }
        guard let json = try? JSONSerialization.jsonObject(with: messageData, options: []),
              let messageDataDict = (json as? NSDictionary)?.mutableCopy() as? NSMutableDictionary
        else { return }

        guard let propertyValue = messageDataDict[property] as? String else { return }

        let propertyValueData = Data(propertyValue.utf8)
        let truncatedCount = min(propertyValueData.count, length)
        let truncatedData = propertyValueData.prefix(truncatedCount)
        messageDataDict[property] = String(data: Data(truncatedData), encoding: .utf8)
        if let updated = try? JSONSerialization.data(withJSONObject: messageDataDict, options: []) {
            messageData = updated
        }
    }

    @objc public func dictionaryRepresentation() -> NSDictionary? {
        do {
            let json = try JSONSerialization.jsonObject(with: messageData, options: [])
            if json is NSDictionary {
                return json as? NSDictionary
            }
            NSLog("mParticle -> Error serializing message.")
            return nil
        } catch {
            NSLog("mParticle -> Error serializing message.")
            return nil
        }
    }

    @objc public func serializedString() -> String? {
        String(data: messageData, encoding: .utf8)
    }

    @objc public func copyMessage() -> MPMessagePRIVATE {
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

    @objc public func isEqual(toMessage other: MPMessagePRIVATE) -> Bool {
        sessionIdsEqual(other.sessionId)
            && messageId == other.messageId
            && timestamp == other.timestamp
            && messageType == other.messageType
            && messageData == other.messageData
            && shouldUploadEvent == other.shouldUploadEvent
            && optionalEqual(dataPlanId, other.dataPlanId)
            && optionalNumberEqual(dataPlanVersion, other.dataPlanVersion)
    }

    override public var hash: Int {
        (sessionId?.hashValue ?? 0)
            ^ (dataPlanId?.hashValue ?? 0)
            ^ (dataPlanVersion?.hashValue ?? 0)
            ^ Int(truncatingIfNeeded: messageId)
            ^ Int(timestamp)
            ^ messageType.hashValue
            ^ messageData.hashValue
            ^ (shouldUploadEvent ? 1 : 0)
    }

    private func sessionIdsEqual(_ other: NSNumber?) -> Bool {
        (sessionId == nil && other == nil) || sessionId == other
    }

    private func optionalEqual(_ lhs: String?, _ rhs: String?) -> Bool {
        (lhs == nil && rhs == nil) || lhs == rhs
    }

    private func optionalNumberEqual(_ lhs: NSNumber?, _ rhs: NSNumber?) -> Bool {
        (lhs == nil && rhs == nil) || lhs == rhs
    }
}

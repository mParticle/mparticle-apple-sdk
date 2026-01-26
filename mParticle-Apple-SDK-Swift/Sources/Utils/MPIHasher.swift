import Foundation

@objc public class MPIHasher: NSObject {
    private let logger: MPLog
    
    @objc public init(logger: MPLog) {
        self.logger = logger
    }
    
    @objc public func hashFNV1a(_ data: Data) -> Int64 {
        var rampHash: UInt64 = 0xCBF2_9CE4_8422_2325

        for byte in data {
            rampHash = (rampHash ^ UInt64(byte)) &* 0x100_0000_01B3
        }
        return Int64(bitPattern: rampHash)
    }

    @objc public func hashString(_ stringToHash: String) -> String {
        if stringToHash.isEmpty {
            return ""
        }

        let lowercaseStringToHash = stringToHash.lowercased()
        guard let dataToHash = lowercaseStringToHash.data(using: .utf8) else {
            logger.warning("Hash String Failed. Could not encode string as data")
            return ""
        }

        var hash: Int32 = 0
        for byte in dataToHash {
            hash = ((hash << 5) &- hash) &+ Int32(byte)
        }

        return String(hash)
    }

    @objc public func hashStringUTF16(_ stringToHash: String) -> String {
        guard let data = stringToHash.data(using: .utf16LittleEndian) else {
            logger.warning("Hash String UTF16 Failed. Could not encode string as data")
            return ""
        }
        let hash = hashFNV1a(data)
        return String(hash)
    }

    @objc public func hashEventType(_ eventType: MPEventTypeSwift) -> String {
        return hashString(String(eventType.rawValue))
    }

    @objc public func eventType(forHash hashString: String) -> MPEventTypeSwift {
        for i in 1...MPEventTypeSwift.impression.rawValue {
            if let eventType = MPEventTypeSwift(rawValue: i), hashString == hashEventType(eventType) {
                return eventType
            }
        }
        return .other
    }

    @objc public func hashEventType(_ eventType: MPEventTypeSwift, eventName: String, isLogScreen: Bool) -> String {
        let stringToBeHashed: String
        if isLogScreen {
            stringToBeHashed = "0\(eventName)"
        } else {
            stringToBeHashed = "\(eventType.rawValue)\(eventName)"
        }
        return hashString(stringToBeHashed)
    }

    @objc public func hashEventAttributeKey(
        _ eventType: MPEventTypeSwift,
        eventName: String,
        customAttributeName: String,
        isLogScreen: Bool
    ) -> String {
        let stringToBeHashed: String
        if isLogScreen {
            stringToBeHashed = "0\(eventName)\(customAttributeName)"
        } else {
            stringToBeHashed = "\(eventType.rawValue)\(eventName)\(customAttributeName)"
        }
        return hashString(stringToBeHashed)
    }

    @objc public func hashUserAttributeKey(_ userAttributeKey: String) -> String {
        return hashString(userAttributeKey)
    }

    @objc public func hashUserAttributeValue(_ userAttributeValue: String) -> String {
        return hashString(userAttributeValue)
    }

    // User Identities are not actually hashed, this method is named this way to
    // be consistent with the filter class. UserIdentityType is also a number
    @objc public func hashUserIdentity(_ userIdentity: MPUserIdentitySwift) -> String {
        return String(userIdentity.rawValue)
    }

    @objc public func hashConsentPurpose(_ regulationPrefix: String, purpose: String) -> String {
        return hashString("\(regulationPrefix)\(purpose)")
    }

    @objc public func hashCommerceEventAttribute(_ commerceEventType: MPEventTypeSwift, key: String) -> String {
        return hashString("\(commerceEventType.rawValue)\(key)")
    }

    @objc public func hashTriggerEventName(_ eventName: String, eventType: String) -> String {
        return hashString("\(eventName)\(eventType)")
    }
}

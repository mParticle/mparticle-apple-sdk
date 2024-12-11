//
//  MPIHasher.swift
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 10/24/23.
//

import Foundation

@objc public class MPIHasher : NSObject {

    @objc public class func hashFNV1a(_ data: Data) -> Int64 {
        var rampHash: UInt64 = 0xcbf29ce484222325
        
        for byte in data {
            rampHash = (rampHash ^ UInt64(byte)) &* 0x100000001B3
        }
        return Int64(bitPattern: rampHash)
    }

    @objc public class func hashString(_ stringToHash: String) -> String {
        if stringToHash.isEmpty {
            return "";
        }
        
        let lowercaseStringToHash = stringToHash.lowercased()
        guard let dataToHash = lowercaseStringToHash.data(using: .utf8) else {
            MPLog.warning("Hash String Failed. Could not encode string as data")
            return ""
        }
       
        var hash: Int32 = 0
        for byte in dataToHash {
            hash = ((hash << 5) &- hash) &+ Int32(byte);
        }
        
        return String(hash)
    }

    @objc public class func hashStringUTF16(_ stringToHash: String) -> String {
        guard let data = stringToHash.data(using: .utf16LittleEndian) else {
            MPLog.warning("Hash String UTF16 Failed. Could not encode string as data")
            return ""
        }
        let hash = hashFNV1a(data)
        return String(hash)
    }

    @objc public class func hashEventType(_ eventType: MPEventType) -> String {
        return hashString(String(eventType.rawValue))
    }

    @objc public class func eventType(forHash hashString: String) -> MPEventType {
        for i in 1...MPEventType.impression.rawValue {
            if let eventType = MPEventType(rawValue: i), hashString == hashEventType(eventType) {
                return eventType
            }
        }
        return .other
    }

    @objc public class func hashEventType(_ eventType: MPEventType, eventName: String, isLogScreen: Bool) -> String {
        let stringToBeHashed: String
        if isLogScreen {
            stringToBeHashed = "0\(eventName)"
        } else {
            stringToBeHashed = "\(eventType.rawValue)\(eventName)"
        }
        return hashString(stringToBeHashed)
    }

    @objc public class func hashEventAttributeKey(_ eventType: MPEventType, eventName: String, customAttributeName: String, isLogScreen: Bool) -> String {
        let stringToBeHashed: String
        if isLogScreen {
            stringToBeHashed = "0\(eventName)\(customAttributeName)"
        } else {
            stringToBeHashed = "\(eventType.rawValue)\(eventName)\(customAttributeName)"
        }
        return hashString(stringToBeHashed)
    }

    @objc public class func hashUserAttributeKey(_ userAttributeKey: String) -> String {
        return hashString(userAttributeKey)
    }

    @objc public class func hashUserAttributeValue(_ userAttributeValue: String) -> String {
        return hashString(userAttributeValue)
    }

    // User Identities are not actually hashed, this method is named this way to
    // be consistent with the filter class. UserIdentityType is also a number
    @objc public class func hashUserIdentity(_ userIdentity: MPUserIdentity) -> String {
        return String(userIdentity.rawValue)
    }

    @objc public class func hashConsentPurpose(_ regulationPrefix: String, purpose: String) -> String {
        return hashString("\(regulationPrefix)\(purpose)")
    }

    @objc public class func hashCommerceEventAttribute(_ commerceEventType: MPEventType, key: String) -> String {
        return hashString("\(commerceEventType.rawValue)\(key)")
    }

    @objc public class func hashTriggerEventName(_ eventName: String, eventType: String) -> String {
        return hashString("\(eventName)\(eventType)")
    }
}

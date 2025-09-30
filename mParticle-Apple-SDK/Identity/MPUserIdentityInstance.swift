//
//  MPUserIdentityInstance.swift
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 12/3/24.
//

@objc public final class MPUserIdentityInstance_PRIVATE : NSObject {

    @objc public var value: String?
    @objc public var dateFirstSet: Date?
    @objc public var type: MPUserIdentity
    @objc public var isFirstTimeSet = false

    @objc public init(type: MPUserIdentity, value: String?) {
        self.type = type
        self.value = value
    }

    @objc public init(type: MPUserIdentity, value: String?, dateFirstSet: Date, isFirstTimeSet: Bool) {
        self.type = type
        self.value = value
        self.dateFirstSet = dateFirstSet
        self.isFirstTimeSet = isFirstTimeSet
    }

    @objc public convenience init(userIdentityDictionary: [String : Any]) {
        let typeInt = userIdentityDictionary[MessageKeys.kMPUserIdentityTypeKey] as? UInt ?? 0
        let type = MPUserIdentity(rawValue: typeInt) ?? .other
        let value = userIdentityDictionary[MessageKeys.kMPUserIdentityIdKey] as? String
        let firstSetMillis = userIdentityDictionary[MessageKeys.kMPDateUserIdentityWasFirstSet] as? Double ?? 0.0
        let dateFirstSet = Date(timeIntervalSince1970: firstSetMillis / 1000.0)
        let isFirstSet = userIdentityDictionary[MessageKeys.kMPIsFirstTimeUserIdentityHasBeenSet] as? Bool ?? false
        self.init(type: type, value: value, dateFirstSet: dateFirstSet, isFirstTimeSet: isFirstSet)
    }

    // TODO: Change return type to [AnyHashable: Any] once no longer used by Obj-C callers
    @objc public func dictionaryRepresentation() -> NSMutableDictionary {
        var identityDictionary = [AnyHashable: Any]()
        identityDictionary[MessageKeys.kMPUserIdentityTypeKey] = type.rawValue
        identityDictionary[MessageKeys.kMPIsFirstTimeUserIdentityHasBeenSet] = isFirstTimeSet
        
        if let dateFirstSet = dateFirstSet {
            identityDictionary[MessageKeys.kMPDateUserIdentityWasFirstSet] = MPMilliseconds(timestamp: dateFirstSet.timeIntervalSince1970)
        }
        
        if let value = value {
            identityDictionary[MessageKeys.kMPUserIdentityIdKey] = value
        }
        
        return NSMutableDictionary(dictionary: identityDictionary)
    }
}

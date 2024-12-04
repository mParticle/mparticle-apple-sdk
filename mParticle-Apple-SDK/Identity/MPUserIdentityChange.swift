//
//  MPUserIdentityChange.swift
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 12/3/24.
//

@objc public final class MPUserIdentityChange_PRIVATE : NSObject {

    @objc public var newUserIdentity: MPUserIdentityInstance_PRIVATE?
    @objc public var oldUserIdentity: MPUserIdentityInstance_PRIVATE?
    @objc public private(set) var changed = false
    
    private var _timestamp: Date?
    @objc public var timestamp: Date? {
        get {
            if _timestamp == nil {
                _timestamp = Date()
            }
            return _timestamp
        }
        set {
            _timestamp = newValue
        }
    }

    @objc public init(newUserIdentity: MPUserIdentityInstance_PRIVATE?, userIdentities: [[String : Any]]?) {
        self.newUserIdentity = newUserIdentity
        self.changed = true
        
        if let userIdentities = userIdentities {
            for ui in userIdentities {
                if let idTypeInt = ui[MessageKeys.kMPUserIdentityTypeKey] as? UInt,
                    let idType = MPUserIdentity(rawValue: idTypeInt),
                    let idValue = ui[MessageKeys.kMPUserIdentityIdKey] as? String,
                    idType == newUserIdentity?.type && idValue == newUserIdentity?.value {
                    
                    self.changed = false
                    break
                }
            }
        }
    }

    @objc public convenience init(newUserIdentity: MPUserIdentityInstance_PRIVATE?, oldUserIdentity: MPUserIdentityInstance_PRIVATE?, timestamp: Date?, userIdentities: [[String : Any]]?) {
        self.init(newUserIdentity: newUserIdentity, userIdentities: userIdentities)
        self.oldUserIdentity = oldUserIdentity
        self.timestamp = timestamp
    }
}

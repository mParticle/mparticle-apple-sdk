import Foundation

@objc public final class MPUserIdentityChangePRIVATE: NSObject {
    @objc public var newUserIdentity: MPUserIdentityInstancePRIVATE?
    @objc public var oldUserIdentity: MPUserIdentityInstancePRIVATE?
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

    @objc public init(newUserIdentity: MPUserIdentityInstancePRIVATE?, userIdentities: [[String: Any]]?) {
        self.newUserIdentity = newUserIdentity
        changed = true

        if let userIdentities = userIdentities {
            for ui in userIdentities {
                if let idTypeInt = ui[MessageKeys.kMPUserIdentityTypeKey] as? UInt,
                   let idType = MPUserIdentitySwift(rawValue: idTypeInt),
                   let idValue = ui[MessageKeys.kMPUserIdentityIdKey] as? String,
                   idType == newUserIdentity?.type && idValue == newUserIdentity?.value {
                    changed = false
                    break
                }
            }
        }
    }

    @objc public convenience init(
        newUserIdentity: MPUserIdentityInstancePRIVATE?,
        oldUserIdentity: MPUserIdentityInstancePRIVATE?,
        timestamp: Date?,
        userIdentities: [[String: Any]]?
    ) {
        self.init(newUserIdentity: newUserIdentity, userIdentities: userIdentities)
        self.oldUserIdentity = oldUserIdentity
        self.timestamp = timestamp
    }
}

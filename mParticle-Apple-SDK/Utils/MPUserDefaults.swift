//
//  MPUserDefaults.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 1/10/25.
//

import Foundation
private var userDefaults: MPUserDefaults?
private var sharedGroupID: String?
private let NSUserDefaultsPrefix: String = "mParticle::"
private let userSpecificKeys : [String] = ["lud",   /* kMPAppLastUseDateKey */
                                           "lc",    /* kMPAppLaunchCountKey */
                                           "lcu",   /* kMPAppLaunchCountSinceUpgradeKey */
                                           "ua",    /* kMPUserAttributeKey */
                                           "ui",    /* kMPUserIdentityArrayKey */
                                           "ck",    /* kMPRemoteConfigCookiesKey */
                                           "ltv",   /* kMPLifeTimeValueKey */
                                           "is_ephemeral",  /* kMPIsEphemeralKey */
                                           "last_date_used",    /* kMPLastIdentifiedDate  */
                                           "consent_state", /* kMPConsentStateKey  */
                                           "fsu",   /* kMPFirstSeenUser */
                                           "lsu"    /* kMPLastSeenUser */
                                            ]
private let kApiKey: String = "apiKey"
private let kSecret: String = "secret"
private let kEventsHost: String = "eventsHost"
private let kEventsTrackingHost: String = "eventsTrackingHost"
private let kOverridesEventsSubdirectory: String = "overridesEventsSubdirectory"
private let kAliasHost: String = "aliasHost"
private let kAliasTrackingHost: String = "aliasTrackingHost"
private let kOverridesAliasSubdirectory: String = "overridesAliasSubdirectory"
private let kEventsOnly: String = "eventsOnly"
private let kMPUserIdentitySharedGroupIdentifier = "sgi"
private let kMResponseConfigurationKey = "responseConfiguration"
private let kMResponseConfigurationMigrationKey = "responseConfigurationMigrated"



@objc(MPUploadSettings) public class MPUploadSettings: NSObject, NSCopying, NSSecureCoding {
    public func copy(with zone: NSZone? = nil) -> Any {
        return MPUploadSettings(apiKey: self.apiKey,
                                secret: self.secret,
                                eventsHost: self.eventsHost,
                                eventsTrackingHost: self.eventsTrackingHost,
                                overridesEventsSubdirectory: self.overridesEventsSubdirectory,
                                aliasHost: self.aliasHost,
                                aliasTrackingHost: self.aliasTrackingHost,
                                overridesAliasSubdirectory: self.overridesAliasSubdirectory,
                                eventsOnly: self.eventsOnly)
    }
    
    public static var supportsSecureCoding: Bool = true
    
    public func encode(with coder: NSCoder) {
        coder.encode(apiKey, forKey: kApiKey)
        coder.encode(secret, forKey: kSecret)
        coder.encode(eventsHost, forKey: kEventsHost)
        coder.encode(eventsTrackingHost, forKey: kEventsTrackingHost)
        coder.encode(overridesEventsSubdirectory, forKey: kOverridesEventsSubdirectory)
        coder.encode(aliasHost, forKey: kAliasHost)
        coder.encode(aliasTrackingHost, forKey: kAliasTrackingHost)
        coder.encode(overridesAliasSubdirectory, forKey: kOverridesAliasSubdirectory)
        coder.encode(eventsOnly, forKey: kEventsOnly)
    }
    
    @objc public required init?(coder: NSCoder) {
        self.apiKey = coder.decodeObject(forKey: kApiKey) as! String
        self.secret = coder.decodeObject(forKey: kSecret) as! String
        self.eventsHost = coder.decodeObject(forKey: kEventsHost) as? String
        self.eventsTrackingHost = coder.decodeObject(forKey: kEventsTrackingHost) as? String
        self.overridesEventsSubdirectory = coder.decodeBool(forKey: kOverridesEventsSubdirectory)
        self.aliasHost = coder.decodeObject(forKey: kAliasHost) as? String
        self.aliasTrackingHost = coder.decodeObject(forKey: kAliasTrackingHost) as? String
        self.overridesAliasSubdirectory = coder.decodeBool(forKey: kOverridesAliasSubdirectory)
        self.eventsOnly = coder.decodeBool(forKey: kEventsOnly)
        
    }
    
    @objc public var apiKey: String
    @objc public var secret: String
    @objc public var eventsHost: String?
    @objc public var eventsTrackingHost: String?
    @objc public var overridesEventsSubdirectory: Bool = false
    @objc public var aliasHost: String?
    @objc public var aliasTrackingHost: String?
    @objc public var overridesAliasSubdirectory: Bool = false
    @objc public var eventsOnly: Bool = false
    
    @objc public override init() {
        self.apiKey = ""
        self.secret = ""
        super.init()
    }
    
    @objc public class func currentUploadSettings(stateMachine: MPStateMachine_PRIVATE, networkOptions: MPNetworkOptions) -> MPUploadSettings {
        return MPUploadSettings(apiKey: stateMachine.apiKey, secret: stateMachine.secret, networkOptions: networkOptions)
    }
    
    @objc public init(apiKey: String, secret: String, eventsHost: String? = nil, eventsTrackingHost: String? = nil, overridesEventsSubdirectory: Bool = false, aliasHost: String? = nil, aliasTrackingHost: String? = nil, overridesAliasSubdirectory: Bool = false, eventsOnly: Bool = false) {
        self.apiKey = apiKey
        self.secret = secret
        self.eventsHost = eventsHost
        self.eventsTrackingHost = eventsTrackingHost
        self.overridesEventsSubdirectory = overridesEventsSubdirectory
        self.aliasHost = aliasHost
        self.aliasTrackingHost = aliasTrackingHost
        self.overridesAliasSubdirectory = overridesAliasSubdirectory
        self.eventsOnly = eventsOnly
        
        super.init()
    }

    @objc public init(apiKey: String, secret: String, networkOptions: MPNetworkOptions) {
        self.apiKey = apiKey
        self.secret = secret
        self.eventsHost = networkOptions.eventsHost
        self.eventsTrackingHost = networkOptions.eventsTrackingHost
        self.overridesEventsSubdirectory = networkOptions.overridesEventsSubdirectory
        self.aliasHost = networkOptions.aliasHost
        self.aliasTrackingHost = networkOptions.aliasTrackingHost
        self.overridesAliasSubdirectory = networkOptions.overridesAliasSubdirectory
        self.eventsOnly = networkOptions.eventsOnly
        
        super.init()
    }
}

@objc public class MPUserDefaults : NSObject {
    private var stateMachine: MPStateMachine_PRIVATE?
    private var backendController: MPBackendController_PRIVATE?
    private var identity: MPIdentityApi?
    
    required public init(stateMachine: MPStateMachine_PRIVATE, backendController: MPBackendController_PRIVATE, identity: MPIdentityApi) {
        self.stateMachine = stateMachine
        self.backendController = backendController
        self.identity = identity
        super.init()
    }

    @objc public class func standardUserDefaults(stateMachine: MPStateMachine_PRIVATE, backendController: MPBackendController_PRIVATE, identity: MPIdentityApi) -> MPUserDefaults {
        if userDefaults == nil {
            userDefaults = self.init(stateMachine: stateMachine, backendController: backendController, identity: identity)
        }
         
        return userDefaults!
    }

    @objc public func mpObject(forKey key: String, userId: NSNumber) -> Any? {
        let prefixedKey = MPUserDefaults.prefixedKey(key, userId: userId)
        
        var mpObject = self.customUserDefaults().object(forKey: prefixedKey)
        if mpObject == nil {
            mpObject = UserDefaults.standard.object(forKey: prefixedKey)
        }
        return mpObject
    }

    @objc public func setMPObject(_ value: Any?, forKey key: String, userId: NSNumber) {
        let prefixedKey = MPUserDefaults.prefixedKey(key, userId: userId)
        
        UserDefaults.standard.set(value, forKey: prefixedKey)
        if sharedGroupID != nil {
            UserDefaults(suiteName: sharedGroupID)?.set(value, forKey: prefixedKey)
        }
    }

    @objc public func removeMPObject(forKey key: String, userId: NSNumber) {
        let prefixedKey = MPUserDefaults.prefixedKey(key, userId: userId)
        
        UserDefaults.standard.removeObject(forKey: prefixedKey)
        if sharedGroupID != nil {
            UserDefaults(suiteName: sharedGroupID)?.removeObject(forKey: prefixedKey)
        }
    }

    @objc public func removeMPObject(forKey key: String) {
        self.removeMPObject(forKey: key, userId: MPPersistenceController_PRIVATE.mpId())
    }

    @objc public subscript(key: String) -> Any? {
        get {
            if key == "mpid" {
                return self.mpObject(forKey: key, userId: 0)
            }
            return self.mpObject(forKey: key, userId: MPPersistenceController_PRIVATE.mpId())
        }
        set {
            if let obj = newValue {
                if key == "mpid" {
                    self.setMPObject(obj, forKey: key, userId: 0)
                } else {
                    self.setMPObject(obj, forKey: key, userId: MPPersistenceController_PRIVATE.mpId())
                }
            } else {
                self.removeMPObject(forKey: key, userId: MPPersistenceController_PRIVATE.mpId())
            }
        }
    }

    @objc public func synchronize() {
        UserDefaults.standard.synchronize()
        if sharedGroupID != nil {
            UserDefaults(suiteName: sharedGroupID)?.synchronize()
        }
    }

    @objc public func migrateUserKeys(withUserId userId: NSNumber) {
        userSpecificKeys.forEach { key in
            let globalKey = MPUserDefaults.globalKeyForKey(key)
            let userKey = MPUserDefaults.userKeyForKey(key, userId: userId)
            guard let value = UserDefaults.standard.object(forKey: globalKey) else { return }
            self.customUserDefaults().set(value, forKey: userKey)
        }
        
        self.synchronize()
    }

    @objc public func migrateFirstLastSeenUsers() {
        let globalFirstSeenDateMs = self.mpObject(forKey: Miscellaneous.kMPAppInitialLaunchTimeKey, userId: MPPersistenceController_PRIVATE.mpId())
        let globalLastSeenDateMs = NSNumber(value: Date().timeIntervalSince1970 * 1000)
        let users: [MParticleUser] = self.identity?.getAllUsers() ?? []
        for user in users {
            self.setMPObject(globalFirstSeenDateMs, forKey: Miscellaneous.kMPFirstSeenUser, userId: user.userId)
            self.setMPObject(globalLastSeenDateMs, forKey: Miscellaneous.kMPLastSeenUser, userId: user.userId)
        }
    }

    @objc public func setSharedGroupIdentifier(_ groupIdentifier: String?) {
        let storedGroupID = self.mpObject(forKey: kMPUserIdentitySharedGroupIdentifier, userId: MPPersistenceController_PRIVATE.mpId()) as? String
        
        if storedGroupID == groupIdentifier {
             
        } else if let groupIdentifier = groupIdentifier, !groupIdentifier.isEmpty {
            self.migrateToSharedGroupIdentifier(groupIdentifier: groupIdentifier)
        } else {
            self.migrateFromSharedGroupIdentifier()
        }
    }

    @objc public func migrateToSharedGroupIdentifier(groupIdentifier: String) {
        let standardUserDefaults = UserDefaults.standard
        let groupUserDefaults = UserDefaults(suiteName: groupIdentifier)
        
        let prefixedKey =
        MPUserDefaults.prefixedKey(kMPUserIdentitySharedGroupIdentifier, userId: MPPersistenceController_PRIVATE.mpId())
        standardUserDefaults.set(groupIdentifier, forKey: prefixedKey)
        groupUserDefaults?.set(groupIdentifier, forKey: prefixedKey)
        
        let predicate = NSPredicate(format: "SELF CONTAINS %@", NSUserDefaultsPrefix)
        let mParticleKeys = UserDefaults.standard.dictionaryRepresentation().keys.filter { predicate.evaluate(with: $0) }
        
        for key in mParticleKeys {
            groupUserDefaults?.set(standardUserDefaults.object(forKey: key), forKey: key)
        }
    }

    @objc public func migrateFromSharedGroupIdentifier() {
        let standardUserDefaults = UserDefaults.standard
        let groupUserDefaults = UserDefaults(suiteName: sharedGroupID)
        
        let predicate = NSPredicate(format: "SELF CONTAINS %@", NSUserDefaultsPrefix)
        let mParticleKeys = UserDefaults.standard.dictionaryRepresentation().keys.filter { predicate.evaluate(with: $0) }
        
        for key in mParticleKeys {
            groupUserDefaults?.removeObject(forKey: key)
        }
        
        let prefixedKey =
        MPUserDefaults.prefixedKey(kMPUserIdentitySharedGroupIdentifier, userId: MPPersistenceController_PRIVATE.mpId())
        standardUserDefaults.removeObject(forKey: prefixedKey)
        groupUserDefaults?.removeObject(forKey: prefixedKey)
    }

    @objc public func getConfiguration() -> [AnyHashable : Any]? {
        guard let userID = self.identity?.currentUser?.userId else {return nil}
        
        if UserDefaults.standard.object(forKey: kMResponseConfigurationMigrationKey) == nil {
            migrateConfiguration()
        }
        
        let configurationData = self.mpObject(forKey: kMResponseConfigurationKey, userId: userID) as? Data
        guard let configurationData = configurationData else { return nil }
        
        let configuration = NSKeyedUnarchiver.unarchiveObject(with: configurationData) as? [AnyHashable : Any]
        
        return configuration
    }

    @objc public func getKitConfigurations() -> [Any]? {
        return self.getConfiguration()?[RemoteConfig.kMPRemoteConfigKitsKey] as? [Any]
    }

    @objc public func setConfiguration(_ responseConfiguration: [AnyHashable : Any], eTag: String, requestTimestamp: TimeInterval, currentAge: Double, maxAge: NSNumber?) {
        let configurationData = NSKeyedArchiver.archivedData(withRootObject: responseConfiguration)
        let userID = self.identity?.currentUser?.userId ?? 0
        
        self.setMPObject(eTag, forKey: Miscellaneous.kMPHTTPETagHeaderKey, userId: userID)
        self.setMPObject(configurationData, forKey: kMResponseConfigurationKey, userId: userID)
        self.setMPObject(requestTimestamp - currentAge, forKey: Miscellaneous.kMPConfigProvisionedTimestampKey, userId: userID)
        self.setMPObject(maxAge, forKey: Miscellaneous.kMPConfigMaxAgeHeaderKey, userId: userID)
    }

    @objc public func migrateConfiguration() {
        guard let userID = self.identity?.currentUser?.userId else {return}
        let eTag = self.mpObject(forKey: Miscellaneous.kMPHTTPETagHeaderKey, userId: userID) as? String
        
        let fileManager = FileManager.default
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let stateMachineURL = cachesURL.appendingPathComponent("StateMachine")
        let configurationURL = stateMachineURL.appendingPathComponent("RequestConfig.cfg")
        let configuration = self.mpObject(forKey: kMResponseConfigurationKey, userId: userID)
        
        if fileManager.fileExists(atPath: configurationURL.path) {
            do {
                try fileManager.removeItem(at: configurationURL)
            } catch {
                MPLog.error("Failed to remove old configuration file: \(error)")
            }
            self.deleteConfiguration()
            MPLog.debug( "Configuration Migration Complete")
        } else if (eTag != nil && configuration == nil) || (eTag == nil && configuration != nil) {
            self.deleteConfiguration()
            MPLog.debug( "Configuration Migration Complete")
        }
        
        UserDefaults.standard.set(1, forKey: kMResponseConfigurationMigrationKey)
    }

    @objc public func deleteConfiguration() {
        self.removeMPObject(forKey: kMResponseConfigurationKey)
        self.removeMPObject(forKey: Miscellaneous.kMPHTTPETagHeaderKey)
        self.removeMPObject(forKey: Miscellaneous.kMPConfigProvisionedTimestampKey)
        self.removeMPObject(forKey: Miscellaneous.kMPConfigMaxAgeHeaderKey)
        self.removeMPObject(forKey: Miscellaneous.kMPConfigParameters)

        MPLog.debug( "Configuration Deleted")
    }

    @objc public func resetDefaults() {
        let dict = UserDefaults.standard.dictionaryRepresentation()
        let predicate = NSPredicate(format: "SELF CONTAINS %@", NSUserDefaultsPrefix)
        let mParticleKeys = dict.keys.filter { predicate.evaluate(with: $0) }
        
        if sharedGroupID != nil {
            self.setSharedGroupIdentifier(nil)
        }
        
        for key in mParticleKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        userDefaults = nil
        
        UserDefaults.standard.synchronize()
    }

    @objc public func isExistingUserId(_ userId: NSNumber) -> Bool {
        let dateLastIdentified = self.mpObject(forKey: Miscellaneous.kMPLastIdentifiedDate, userId: userId)
        
        return dateLastIdentified != nil
    }

    @objc public func userIDsInUserDefaults() -> [NSNumber] {
        let keyArray = self.customUserDefaults().dictionaryRepresentation().keys
        
        var uniqueUserIDs: [NSNumber] = []
        for key in keyArray {
            if let value = self.customUserDefaults().object(forKey: key) {
                let keyComponents = key.components(separatedBy: "::")
                if keyComponents.count == 3 {
                    let UserID = NSNumber(value: Int64(keyComponents[1]) ?? 0)
                    uniqueUserIDs.append(UserID)
                }
            }
        }
        
        return uniqueUserIDs
    }

    @objc public func isConfigurationExpired() -> Bool {
        var isConfigurationExpired: Bool = true
        
        let configProvisioned = self.mpObject(forKey: Miscellaneous.kMPConfigProvisionedTimestampKey, userId: MPPersistenceController_PRIVATE.mpId()) as? NSNumber
        let maxAge = self.mpObject(forKey: Miscellaneous.kMPConfigMaxAgeHeaderKey, userId: MPPersistenceController_PRIVATE.mpId())
        
        if let configProvisioned = configProvisioned {
            let intervalConfigProvisioned = configProvisioned.doubleValue
            let intervalNow = Date().timeIntervalSince1970
            let delta = intervalNow - intervalConfigProvisioned
            var expirationAge = Miscellaneous.CONFIG_REQUESTS_DEFAULT_EXPIRATION_AGE
            if let maxAge = maxAge as? NSNumber {
                expirationAge = min(maxAge.doubleValue, Miscellaneous.CONFIG_REQUESTS_MAX_EXPIRATION_AGE)
            }
            isConfigurationExpired = delta > expirationAge
        }
        
        return isConfigurationExpired
    }

    @objc public func setSideloadedKitsCount(_ sideloadedKitsCount: UInt) {
        UserDefaults.standard.set(sideloadedKitsCount, forKey: Miscellaneous.MPSideloadedKitsCountUserDefaultsKey)
    }

    @objc public func sideloadedKitsCount() -> UInt {
        UserDefaults.standard.object(forKey: Miscellaneous.MPSideloadedKitsCountUserDefaultsKey) as? UInt ?? 0
    }

    @objc public func setLastUploadSettings(_ lastUploadSettings: MPUploadSettings?) {
        if let lastUploadSettings = lastUploadSettings {
            let data = NSKeyedArchiver.archivedData(withRootObject: lastUploadSettings)
            UserDefaults.standard.set(data, forKey: Miscellaneous.kMPLastUploadSettingsUserDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Miscellaneous.kMPLastUploadSettingsUserDefaultsKey)
        }
    }

    @objc public func lastUploadSettings() -> MPUploadSettings? {
        let data = UserDefaults.standard.data(forKey: Miscellaneous.kMPLastUploadSettingsUserDefaultsKey)
        
        if let data = data {
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? MPUploadSettings
        } else {
            return nil
        }
    }
    
    @objc public class func isOlderThanConfigMaxAgeSeconds() -> Bool {
        var shouldConfigurationBeDeleted: Bool = false
        
        if let userDefaults = userDefaults  {
            let configProvisioned = userDefaults[Miscellaneous.kMPConfigProvisionedTimestampKey] as? NSNumber
            let maxAgeSeconds = MParticle.sharedInstance().configMaxAgeSeconds
            
            if let configProvisioned = configProvisioned, let maxAgeSeconds = maxAgeSeconds, maxAgeSeconds.doubleValue > 0 {
                let intervalConfigProvisioned: TimeInterval = configProvisioned.doubleValue
                shouldConfigurationBeDeleted = (Date().timeIntervalSince1970 - intervalConfigProvisioned) > maxAgeSeconds.doubleValue
            }
            
            if shouldConfigurationBeDeleted {
                userDefaults.deleteConfiguration()
            }
        }
        return shouldConfigurationBeDeleted
    }

    @objc public class func stringFromDeviceToken(_ deviceToken: Data) -> String? {
        let deviceToken = deviceToken as NSData
        if deviceToken.length == 0 { return nil }
        
        return deviceToken.map { String(format: "%02x", $0) }.joined()
    }

    @objc public class func restore() -> MPResponseConfig? {
        if let userDefaults = userDefaults {
            if let configuration = userDefaults.getConfiguration(), let stateMachine = userDefaults.stateMachine, let backendController = userDefaults.backendController {
                let responseConfig = MPResponseConfig(configuration: configuration, stateMachine: stateMachine, backendController: backendController)
                
                return responseConfig
            }
        }
        
        return nil
    }

    @objc public class func deleteConfig() {
        if let userDefaults = userDefaults {
            userDefaults.deleteConfiguration()
        }
    }
    
    
    // Private Methods
    private class func globalKeyForKey(_ keyName: String) -> String {
        return "\(NSUserDefaultsPrefix)\(keyName)"
    }

    private class func userKeyForKey(_ keyName: String, userId: NSNumber) -> String {
        return "\(NSUserDefaultsPrefix)\(userId)::\(keyName)"
    }
    
    private class func prefixedKey(_ keyName: String, userId: NSNumber) -> String {
        var prefixedKey: String?
        if userSpecificKeys.contains(keyName) {
            prefixedKey = userKeyForKey(keyName, userId: userId)
        } else {
            prefixedKey = globalKeyForKey(keyName)
        }
        return prefixedKey ?? ""
    }
    
    private func customUserDefaults() -> UserDefaults {
        if let sharedGroupID = sharedGroupID {
            return UserDefaults(suiteName: sharedGroupID)!
        } else {
            return UserDefaults.standard
        }
    }
}

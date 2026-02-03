internal import mParticle_Apple_SDK_Swift

private var userDefaults: MPUserDefaults?
private var sharedGroupID: String?
private let NSUserDefaultsPrefix = "mParticle::"
private let userSpecificKeys = ["lud", /* kMPAppLastUseDateKey */
                                "lc", /* kMPAppLaunchCountKey */
                                "lcu", /* kMPAppLaunchCountSinceUpgradeKey */
                                "ua", /* kMPUserAttributeKey */
                                "ui", /* kMPUserIdentityArrayKey */
                                "ck", /* kMPRemoteConfigCookiesKey */
                                "ltv", /* kMPLifeTimeValueKey */
                                "is_ephemeral", /* kMPIsEphemeralKey */
                                "last_date_used", /* kMPLastIdentifiedDate  */
                                "consent_state", /* kMPConsentStateKey  */
                                "fsu", /* kMPFirstSeenUser */
                                "lsu" /* kMPLastSeenUser */ ]
private let kMPUserIdentitySharedGroupIdentifier = "sgi"
private let kMResponseConfigurationKey = "responseConfiguration"
private let kMResponseConfigurationMigrationKey = "responseConfigurationMigrated"

@objc
public protocol MPUserDefaultsProtocol {
    func setMPObject(_ value: Any?, forKey key: String, userId: NSNumber)
    func synchronize()
}

@objc
protocol MPUserDefaultsConnectorProtocol {
    var stateMachine: MPStateMachine_PRIVATE? { get }
    var backendController: MPBackendController_PRIVATE? { get }
    var identity: MPIdentityApi? { get }
    
    var logger: MPLog { get }
    
    var deferredKitConfiguration: [[AnyHashable: Any]]? { get set }
    
    func configureKits(_ kitConfigurations: [[AnyHashable: Any]]?)
    
    func configureCustomModules(_ customModuleSettings: [[AnyHashable: Any]]?)
    func configureRampPercentage(_ rampPercentage: NSNumber?)
    func configureTriggers(_ triggerDictionary: [AnyHashable: Any]?)
    func configureAliasMaxWindow(_ aliasMaxWindow: NSNumber?)
    func configureDataBlocking(_ blockSettings: [AnyHashable: Any]?)
    func userId() -> NSNumber?
    func setAllowASR(_ allowASR: Bool)
    func setEnableAudienceAPI(_ enableAudienceAPI: Bool)
    func setExceptionHandlingMode(_ exceptionHandlingMode: String?)
    func setSessionTimeout(_ sessionTimeout: TimeInterval)
    func setPushNotificationMode(_ pushNotificationMode: String)
    
    func isAppExtension() -> Bool
    
    func registerForRemoteNotifications()
    func unregisterForRemoteNotifications()
}

@objc public class MPUserDefaults: NSObject, MPUserDefaultsProtocol {
    private let connector: MPUserDefaultsConnectorProtocol

    @objc init(connector: MPUserDefaultsConnectorProtocol) {
        self.connector = connector
    }

    @objc class func standardUserDefaults(connector: MPUserDefaultsConnectorProtocol) -> MPUserDefaults {
        if userDefaults == nil {
            userDefaults = MPUserDefaults(connector: connector)
        }

        return userDefaults!
    }

    @objc public func mpObject(forKey key: String, userId: NSNumber) -> Any? {
        let prefixedKey = MPUserDefaults.prefixedKey(key, userId: userId)

        var mpObject = customUserDefaults().object(forKey: prefixedKey)
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
        removeMPObject(forKey: key, userId: MPPersistenceController_PRIVATE.mpId())
    }

    @objc public subscript(key: String) -> Any? {
        get {
            if key == "mpid" {
                return mpObject(forKey: key, userId: 0)
            }
            return mpObject(forKey: key, userId: MPPersistenceController_PRIVATE.mpId())
        }
        set {
            if let obj = newValue {
                if key == "mpid" {
                    setMPObject(obj, forKey: key, userId: 0)
                } else {
                    setMPObject(obj, forKey: key, userId: MPPersistenceController_PRIVATE.mpId())
                }
            } else {
                removeMPObject(forKey: key, userId: MPPersistenceController_PRIVATE.mpId())
            }
        }
    }

    @objc public func synchronize() {
        UserDefaults.standard.synchronize()
        if sharedGroupID != nil {
            UserDefaults(suiteName: sharedGroupID)?.synchronize()
        }
    }

    @objc public func setSharedGroupIdentifier(_ groupIdentifier: String?) {
        let storedGroupID = mpObject(
            forKey: kMPUserIdentitySharedGroupIdentifier,
            userId: MPPersistenceController_PRIVATE.mpId()
        ) as? String

        if storedGroupID == groupIdentifier {
        } else if let groupIdentifier = groupIdentifier, !groupIdentifier.isEmpty {
            migrateToSharedGroupIdentifier(groupIdentifier: groupIdentifier)
        } else {
            migrateFromSharedGroupIdentifier()
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

    @objc public func getConfiguration() -> [AnyHashable: Any]? {
        guard let userID = connector.identity?.currentUser?.userId else { return nil }

        if UserDefaults.standard.object(forKey: kMResponseConfigurationMigrationKey) == nil {
            migrateConfiguration()
        }

        let configurationData = mpObject(forKey: kMResponseConfigurationKey, userId: userID) as? Data
        guard let configurationData = configurationData else { return nil }

        do {
            let allowedClasses: [AnyClass] = [
                NSDictionary.self,
                NSArray.self,
                NSString.self,
                NSNumber.self,
                NSDate.self,
                NSData.self,
                NSURL.self,
                NSNull.self // Required for null values from JSON
            ]

            if let nsDict = try NSKeyedUnarchiver.unarchivedObject(
                ofClasses: allowedClasses,
                from: configurationData
            ) as? NSDictionary {
                // Manually convert NSDictionary to Swift Dictionary
                var swiftDict: [AnyHashable: Any] = [:]
                nsDict.enumerateKeysAndObjects { key, value, _ in
                    if let hashableKey = key as? AnyHashable {
                        swiftDict[hashableKey] = value
                    }
                }
                return swiftDict
            }
        } catch {
            connector.logger.error("Failed to unarchive configuration: \(error)")
        }
        return nil
    }

    @objc public func getKitConfigurations() -> [Any]? {
        return getConfiguration()?[RemoteConfig.kMPRemoteConfigKitsKey] as? [Any]
    }

    @objc public func setConfiguration(
        _ responseConfiguration: [AnyHashable: Any],
        eTag: String,
        requestTimestamp: TimeInterval,
        currentAge: TimeInterval,
        maxAge: NSNumber?
    ) {
        do {
            let configurationData = try NSKeyedArchiver.archivedData(
                withRootObject: responseConfiguration,
                requiringSecureCoding: true
            )
            let userID = connector.identity?.currentUser?.userId ?? 0

            setMPObject(eTag, forKey: Miscellaneous.kMPHTTPETagHeaderKey, userId: userID)
            setMPObject(configurationData, forKey: kMResponseConfigurationKey, userId: userID)
            setMPObject(requestTimestamp - currentAge, forKey: Miscellaneous.kMPConfigProvisionedTimestampKey, userId: userID)
            setMPObject(maxAge, forKey: Miscellaneous.kMPConfigMaxAgeHeaderKey, userId: userID)
        } catch {
            connector.logger.error("Failed to archive configuration: \(error)")
        }
    }

    @objc public func migrateConfiguration() {
        guard let userID = connector.identity?.currentUser?.userId else { return }
        let eTag = mpObject(forKey: Miscellaneous.kMPHTTPETagHeaderKey, userId: userID) as? String

        let fileManager = FileManager.default
        guard let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        let stateMachineURL = cachesURL.appendingPathComponent("StateMachine")
        let configurationURL = stateMachineURL.appendingPathComponent("RequestConfig.cfg")
        let configuration = mpObject(forKey: kMResponseConfigurationKey, userId: userID)

        if fileManager.fileExists(atPath: configurationURL.path) {
            do {
                try fileManager.removeItem(at: configurationURL)
            } catch {
                connector.logger.error("Failed to remove old configuration file: \(error)")
            }
            deleteConfiguration()
            connector.logger.debug("Configuration Migration Complete")
        } else if (eTag != nil && configuration == nil) || (eTag == nil && configuration != nil) {
            deleteConfiguration()
            connector.logger.debug("Configuration Migration Complete")
        }

        UserDefaults.standard.set(1, forKey: kMResponseConfigurationMigrationKey)
    }

    @objc public func deleteConfiguration() {
        removeMPObject(forKey: kMResponseConfigurationKey)
        removeMPObject(forKey: Miscellaneous.kMPHTTPETagHeaderKey)
        removeMPObject(forKey: Miscellaneous.kMPConfigProvisionedTimestampKey)
        removeMPObject(forKey: Miscellaneous.kMPConfigMaxAgeHeaderKey)
        removeMPObject(forKey: Miscellaneous.kMPConfigParameters)

        connector.logger.debug("Configuration Deleted")
    }

    @objc public func resetDefaults() {
        let dict = UserDefaults.standard.dictionaryRepresentation()
        let predicate = NSPredicate(format: "SELF CONTAINS %@", NSUserDefaultsPrefix)
        let mParticleKeys = dict.keys.filter { predicate.evaluate(with: $0) }

        if sharedGroupID != nil {
            setSharedGroupIdentifier(nil)
        }

        for key in mParticleKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        userDefaults = nil

        UserDefaults.standard.synchronize()
    }

    @objc public func isExistingUserId(_ userId: NSNumber) -> Bool {
        let dateLastIdentified = mpObject(forKey: Miscellaneous.kMPLastIdentifiedDate, userId: userId)

        return dateLastIdentified != nil
    }

    @objc public func userIDsInUserDefaults() -> [NSNumber] {
        let keyArray = customUserDefaults().dictionaryRepresentation().keys

        var uniqueUserIDs: [NSNumber] = []
        for key in keyArray {
            if let _ = customUserDefaults().object(forKey: key) {
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
        var isConfigurationExpired = true

        let configProvisioned = mpObject(
            forKey: Miscellaneous.kMPConfigProvisionedTimestampKey,
            userId: MPPersistenceController_PRIVATE.mpId()
        ) as? NSNumber
        let maxAge = mpObject(forKey: Miscellaneous.kMPConfigMaxAgeHeaderKey, userId: MPPersistenceController_PRIVATE.mpId())

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
        setMPObject(sideloadedKitsCount, forKey: Miscellaneous.MPSideloadedKitsCountUserDefaultsKey, userId: 0)
    }

    @objc public func sideloadedKitsCount() -> UInt {
        mpObject(forKey: Miscellaneous.MPSideloadedKitsCountUserDefaultsKey, userId: 0) as? UInt ?? 0
    }

    @objc public func setLastUploadSettings(_ lastUploadSettings: MPUploadSettings?) {
        if let lastUploadSettings = lastUploadSettings {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: lastUploadSettings, requiringSecureCoding: true)
                setMPObject(data, forKey: Miscellaneous.kMPLastUploadSettingsUserDefaultsKey, userId: 0)
            } catch {
                connector.logger.error("Failed to archive upload settings: \(error)")
            }
        } else {
            removeMPObject(forKey: Miscellaneous.kMPLastUploadSettingsUserDefaultsKey, userId: 0)
        }
    }

    @objc public func lastUploadSettings() -> MPUploadSettings? {
        if let data = mpObject(forKey: Miscellaneous.kMPLastUploadSettingsUserDefaultsKey, userId: 0) as? Data {
            do {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: MPUploadSettings.self, from: data)
            } catch {
                connector.logger.error("Failed to unarchive upload settings: \(error)")
            }
        }
        return nil
    }

    @objc public class func isOlderThanConfigMaxAgeSeconds() -> Bool {
        var shouldConfigurationBeDeleted = false

        if let userDefaults = userDefaults {
            let configProvisioned = userDefaults[Miscellaneous.kMPConfigProvisionedTimestampKey] as? NSNumber
            let maxAgeSeconds = MParticle.sharedInstance().configMaxAgeSeconds

            if let configProvisioned = configProvisioned, let maxAgeSeconds = maxAgeSeconds, maxAgeSeconds.doubleValue > 0 {
                let intervalConfigProvisioned: TimeInterval = configProvisioned.doubleValue
                shouldConfigurationBeDeleted = (Date().timeIntervalSince1970 - intervalConfigProvisioned) > maxAgeSeconds
                    .doubleValue
            }

            if shouldConfigurationBeDeleted {
                userDefaults.deleteConfiguration()
            }
        }
        return shouldConfigurationBeDeleted
    }

    @objc public class func stringFromDeviceToken(_ deviceToken: Data) -> String? {
        if deviceToken.isEmpty { return nil }

        return deviceToken.map { String(format: "%02x", $0) }.joined()
    }

    @objc public class func restore() -> MPResponseConfig? {
        if let userDefaults = userDefaults {
            if let configuration = userDefaults.getConfiguration(), userDefaults.connector.stateMachine != nil,
               userDefaults.connector.backendController != nil {
                let responseConfig = MPResponseConfig(
                    configuration: configuration,
                    connector: userDefaults.connector
                )

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
            return UserDefaults(suiteName: sharedGroupID) ?? .standard
        } else {
            return .standard
        }
    }
}

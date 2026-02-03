import Foundation

@objcMembers
public class Notifications: NSObject {
    static let kMPCrashReportOccurredNotification = Notification.Name("MPCrashReportOccurredNotification")
    static let kMPConfigureExceptionHandlingNotification = Notification.Name("MPConfigureExceptionHandlingNotification")
    static let kMPUserNotificationDictionaryKey = Notification.Name("MPUserNotificationDictionaryKey")
    static let kMPUserNotificationActionKey = Notification.Name("MPUserNotificationActionKey")
    static let kMPRemoteNotificationDeviceTokenNotification = Notification.Name("MPRemoteNotificationDeviceTokenNotification")
    static let kMPRemoteNotificationDeviceTokenKey = Notification.Name("MPRemoteNotificationDeviceTokenKey")
    static let kMPRemoteNotificationOldDeviceTokenKey = Notification.Name("MPRemoteNotificationOldDeviceTokenKey")
}

@objc
public protocol MPUserDefaultsConnectorProtocol {
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
    func setCrashMaxPLReportLength(_ crashMaxPLReportLength: NSNumber)
    
    func isAppExtension() -> Bool
    
    func registerForRemoteNotifications()
    func unregisterForRemoteNotifications()
    
    func canCreateConfiguration() -> Bool
    func mpId() -> NSNumber
}

@objcMembers
public class RemoteConfig: NSObject {
    static let kMPRemoteConfigExceptionHandlingModeKey = "cue"
    static let kMPRemoteConfigExceptionHandlingModeAppDefined = "appdefined"
    static let kMPRemoteConfigExceptionHandlingModeForce = "forcecatch"
    static let kMPRemoteConfigExceptionHandlingModeIgnore = "forceignore"
    static let kMPRemoteConfigCrashMaxPLReportLength = "crml"
    static let kMPRemoteConfigAppDefined = "appdefined"
    static let kMPRemoteConfigForceTrue = "forcetrue"
    static let kMPRemoteConfigForceFalse = "forcefalse"
    public static let kMPRemoteConfigKitsKey = "eks"
    static let kMPRemoteConfigKitHashesKey = "hs"
    static let kMPRemoteConfigConsumerInfoKey = "ci"
    static let kMPRemoteConfigCookiesKey = "ck"
    static let kMPRemoteConfigMPIDKey = "mpid"
    static let kMPRemoteConfigCustomModuleSettingsKey = "cms"
    static let kMPRemoteConfigCustomModuleIdKey = "id"
    static let kMPRemoteConfigCustomModulePreferencesKey = "pr"
    static let kMPRemoteConfigCustomModuleLocationKey = "f"
    static let kMPRemoteConfigCustomModulePreferenceSettingsKey = "ps"
    static let kMPRemoteConfigCustomModuleReadKey = "k"
    static let kMPRemoteConfigCustomModuleDataTypeKey = "t"
    static let kMPRemoteConfigCustomModuleWriteKey = "n"
    static let kMPRemoteConfigCustomModuleDefaultKey = "d"
    static let kMPRemoteConfigCustomSettingsKey = "cs"
    static let kMPRemoteConfigSandboxModeKey = "dbg"
    static let kMPRemoteConfigSessionTimeoutKey = "stl"
    static let kMPRemoteConfigPushNotificationDictionaryKey = "pn"
    static let kMPRemoteConfigPushNotificationModeKey = "pnm"
    static let kMPRemoteConfigPushNotificationTypeKey = "rnt"
    static let kMPRemoteConfigLocationKey = "lct"
    static let kMPRemoteConfigLocationModeKey = "ltm"
    static let kMPRemoteConfigLocationAccuracyKey = "acc"
    static let kMPRemoteConfigLocationMinimumDistanceKey = "mdf"
    static let kMPRemoteConfigRampKey = "rp"
    static let kMPRemoteConfigTriggerKey = "tri"
    static let kMPRemoteConfigTriggerEventsKey = "evts"
    static let kMPRemoteConfigTriggerMessageTypesKey = "dts"
    static let kMPRemoteConfigUniqueIdentifierKey = "das"
    static let kMPRemoteConfigBracketKey = "bk"
    static let kMPRemoteConfigRestrictIDFA = "rdlat"
    static let kMPRemoteConfigAliasMaxWindow = "alias_max_window"
    static let kMPRemoteConfigAllowASR = "iasr"
    static let kMPRemoteConfigExcludeAnonymousUsersKey = "eau"
    static let kMPRemoteConfigFlagsKey = "flags"
    static let kMPRemoteConfigAudienceAPIKey = "AudienceAPI"
    static let kMPRemoteConfigDataPlanningResults = "dpr"
    static let kMPRemoteConfigDataPlanning = "dtpn"
    static let kMPRemoteConfigDataPlanningBlock = "blok"
    static let kMPRemoteConfigDataPlanningBlockUnplannedEvents = "ev"
    static let kMPRemoteConfigDataPlanningBlockUnplannedEventAttributes = "ea"
    static let kMPRemoteConfigDataPlanningBlockUnplannedUserAttributes = "ua"
    static let kMPRemoteConfigDataPlanningBlockUnplannedIdentities = "id"
    static let kMPRemoteConfigDataPlanningDataPlanId = "dpid"
    static let kMPRemoteConfigDataPlanningDataPlanVersion = "dpvn"
    static let kMPRemoteConfigDataPlanningDataPlanError = "error"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValue = "vers"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueDoc = "version_document"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueDataPoints = "data_points"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueMatch = "match"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueType = "type"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueValidator = "validator"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueDefinition = "definition"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueAdditionalProperties = "additionalProperties"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueUserAttributes = "user_attributes"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueCustomEvent = "custom_event"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueCustomEventType = "custom_event_type"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueEventName = "event_name"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueScreenView = "screen_view"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueScreenName = "screen_name"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueProductAction = "product_action"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueUnknown = "unknown"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueAddToCart = "add_to_cart"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueRemoveFromCart = "remove_from_cart"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueCheckout = "checkout"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueCheckoutOption = "checkout_option"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueClick = "click"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueViewDetail = "view_detail"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValuePurchase = "purchase"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueRefund = "refund"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueAddToWishlist = "add_to_wishlist"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueRemoveFromWishlist = "remove_from_wish_list"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValuePromotionAction = "promotion_action"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueProductImpressions = "product_impressions"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueCriteria = "criteria"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueAction = "action"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionUnknown = "unknown"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionView = "view"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionClick = "click"
}

@objc public class MPResponseConfig: NSObject {
    @objc public private(set) var configuration: [AnyHashable: Any]?
    private let connector: MPUserDefaultsConnectorProtocol

    @objc public convenience init?(
        configuration: [AnyHashable: Any],
        connector: MPUserDefaultsConnectorProtocol
    ) {
        self.init(
            configuration: configuration,
            dataReceivedFromServer: true,
            connector: connector
        )
    }

    @objc public init?(
        configuration: [AnyHashable: Any],
        dataReceivedFromServer: Bool,
        connector: MPUserDefaultsConnectorProtocol
    ) {
        self.configuration = configuration
        self.connector = connector
        super.init()

        if self.configuration == nil || self.configuration?.isEmpty == true {
            return nil
        }
        setUp(dataReceivedFromServer: dataReceivedFromServer)
    }

    @objc private func setUp(dataReceivedFromServer: Bool) {
        if let config = configuration {
            if dataReceivedFromServer {
                var hasConsentFilters = false

                if let configKitDictionary = config[RemoteConfig.kMPRemoteConfigKitsKey] as? [[String: Any]] {
                    for kitDictionary in configKitDictionary {
                        let consentKitFilter = kitDictionary[ConsentFilteringSwift.kMPConsentKitFilter] as? [String: Any]
                        hasConsentFilters = consentKitFilter != nil && !consentKitFilter!.isEmpty
                        var hasRegulationOrPurposeFilters = false

                        if let hashes = kitDictionary[RemoteConfig.kMPRemoteConfigKitHashesKey] as? [String: Any],
                           !hashes.isEmpty {
                            if let regulationFilters =
                                hashes[ConsentFilteringSwift.kMPConsentRegulationFilters] as? [String: Any],
                               !regulationFilters.isEmpty {
                                hasRegulationOrPurposeFilters = true
                            }
                            if let purposeFilters = hashes[ConsentFilteringSwift.kMPConsentPurposeFilters] as? [String: Any],
                               !purposeFilters.isEmpty {
                                hasRegulationOrPurposeFilters = true
                            }
                        }

                        if hasConsentFilters || hasRegulationOrPurposeFilters {
                            hasConsentFilters = true
                        }
                    }
                }

                var hasInitialIdentity = false
                if let mpid = connector.userId(), mpid != 0 {
                    hasInitialIdentity = true
                }

                let shouldDefer = hasConsentFilters && !hasInitialIdentity
                if !shouldDefer {
                    DispatchQueue.main.async {
                        self.connector.configureKits(config[RemoteConfig.kMPRemoteConfigKitsKey] as? [[AnyHashable: Any]])
                    }
                } else {
                    connector.deferredKitConfiguration = config[RemoteConfig.kMPRemoteConfigKitsKey] as? [[AnyHashable: Any]]
                }
            }

            connector.configureCustomModules(config[RemoteConfig.kMPRemoteConfigCustomModuleSettingsKey] as? [[AnyHashable: Any]])
            connector.configureRampPercentage(config[RemoteConfig.kMPRemoteConfigRampKey] as? NSNumber)
            connector.configureTriggers(config[RemoteConfig.kMPRemoteConfigTriggerKey] as? [AnyHashable: Any])
            connector.configureAliasMaxWindow(config[RemoteConfig.kMPRemoteConfigAliasMaxWindow] as? NSNumber)
            connector.configureDataBlocking(config[RemoteConfig.kMPRemoteConfigDataPlanningResults] as? [AnyHashable: Any])

            connector.setAllowASR(config[RemoteConfig.kMPRemoteConfigAllowASR] as? Bool ?? false)
            if let remoteConfigFlags = config[RemoteConfig.kMPRemoteConfigFlagsKey] as? [AnyHashable: Any] {
                if let audienceAPIFlag = remoteConfigFlags[RemoteConfig.kMPRemoteConfigAudienceAPIKey] as? String {
                    connector.setEnableAudienceAPI(audienceAPIFlag == "True")
                }
            }

            // Exception handling
            if let auxString = config[RemoteConfig.kMPRemoteConfigExceptionHandlingModeKey] as? String {
                connector.setExceptionHandlingMode(auxString)
                NotificationCenter.default.post(Notification(name: Notifications.kMPConfigureExceptionHandlingNotification))
            }

            // Crash size limiting
            if let crashMaxReportLength = config[RemoteConfig.kMPRemoteConfigCrashMaxPLReportLength] as? NSNumber {
                connector.setCrashMaxPLReportLength(crashMaxReportLength)
            }

            // Session timeout
            if let sessionTimeout = config[RemoteConfig.kMPRemoteConfigSessionTimeoutKey] as? NSNumber {
                connector.setSessionTimeout(sessionTimeout.doubleValue)
            }

            #if os(iOS)
                // Push notifications
                if let pushNotificationDictionary = config["pn"] as? [AnyHashable: Any] {
                    configurePushNotifications(pushNotificationDictionary)
                }
            #endif
        }
    }

    #if os(iOS)
        @objc public func configurePushNotifications(_ pushNotificationDictionary: [AnyHashable: Any]) {
            if let pushNotificationMode =
                pushNotificationDictionary[RemoteConfig.kMPRemoteConfigPushNotificationModeKey] as? String {
                connector.setPushNotificationMode(pushNotificationMode)
                if !connector.isAppExtension() {
                    if pushNotificationMode == RemoteConfig.kMPRemoteConfigForceTrue {
                        connector.registerForRemoteNotifications()
                    } else if pushNotificationMode == RemoteConfig.kMPRemoteConfigForceFalse {
                        connector.unregisterForRemoteNotifications()
                    }
                }
            }
        }
    #endif
}

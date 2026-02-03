internal import mParticle_Apple_SDK_Swift

@objc public class MPResponseConfig: NSObject {
    @objc public private(set) var configuration: [AnyHashable: Any]?
    private let connector: MPUserDefaultsConnectorProtocol

    @objc convenience init?(
        configuration: [AnyHashable: Any],
        connector: MPUserDefaultsConnectorProtocol
    ) {
        self.init(
            configuration: configuration,
            dataReceivedFromServer: true,
            connector: connector
        )
    }

    @objc init?(
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
                if let mpid = MParticle.sharedInstance().identity.currentUser?.userId, mpid != 0 {
                    hasInitialIdentity = true
                }

                let shouldDefer = hasConsentFilters && !hasInitialIdentity
                if !shouldDefer {
                    DispatchQueue.main.async {
                        self.connector.configureKits(config[RemoteConfig.kMPRemoteConfigKitsKey] as? [[AnyHashable: Any]])
                    }
                } else {
                    MParticle.sharedInstance()
                        .deferredKitConfiguration_PRIVATE = config[RemoteConfig.kMPRemoteConfigKitsKey] as? [[AnyHashable: Any]]
                }
            }

            connector.stateMachine?
                .configureCustomModules(config[RemoteConfig.kMPRemoteConfigCustomModuleSettingsKey] as? [[AnyHashable: Any]])
            connector.stateMachine?.configureRampPercentage(config[RemoteConfig.kMPRemoteConfigRampKey] as? NSNumber)
            connector.stateMachine?.configureTriggers(config[RemoteConfig.kMPRemoteConfigTriggerKey] as? [AnyHashable: Any])
            connector.stateMachine?.configureAliasMaxWindow(config[RemoteConfig.kMPRemoteConfigAliasMaxWindow] as? NSNumber)
            connector.stateMachine?
                .configureDataBlocking(config[RemoteConfig.kMPRemoteConfigDataPlanningResults] as? [AnyHashable: Any])

            connector.stateMachine?.allowASR = config[RemoteConfig.kMPRemoteConfigAllowASR] as? Bool ?? false
            if let remoteConfigFlags = config[RemoteConfig.kMPRemoteConfigFlagsKey] as? [AnyHashable: Any] {
                if let audienceAPIFlag = remoteConfigFlags[RemoteConfig.kMPRemoteConfigAudienceAPIKey] as? String {
                    connector.stateMachine?.enableAudienceAPI = audienceAPIFlag == "True"
                }
            }

            // Exception handling
            if let auxString = config[RemoteConfig.kMPRemoteConfigExceptionHandlingModeKey] as? String {
                connector.stateMachine?.exceptionHandlingMode = auxString
                NotificationCenter.default.post(Notification(name: Notifications.kMPConfigureExceptionHandlingNotification))
            }

            // Crash size limiting
            if let crashMaxReportLength = config[RemoteConfig.kMPRemoteConfigCrashMaxPLReportLength] as? NSNumber {
                connector.stateMachine?.crashMaxPLReportLength = crashMaxReportLength
            }

            // Session timeout
            if let sessionTimeout = config[RemoteConfig.kMPRemoteConfigSessionTimeoutKey] as? NSNumber {
                connector.backendController?.sessionTimeout = sessionTimeout.doubleValue
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
                connector.stateMachine?.pushNotificationMode = pushNotificationMode
                if !MPStateMachine_PRIVATE.isAppExtension() {
                    let app = MPApplication_PRIVATE.sharedUIApplication()

                    if pushNotificationMode == RemoteConfig.kMPRemoteConfigForceTrue {
                        app?.registerForRemoteNotifications()
                    } else if pushNotificationMode == RemoteConfig.kMPRemoteConfigForceFalse {
                        app?.unregisterForRemoteNotifications()
                    }
                }
            }
        }
    #endif
}

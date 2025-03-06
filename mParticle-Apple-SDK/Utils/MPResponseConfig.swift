//
//  MPResponseConfig.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 12/2/24.
//

import Foundation

@objc public class MPResponseConfig : NSObject {
    @objc public private(set) var configuration: [AnyHashable : Any]?
    private var stateMachine: MPStateMachine_PRIVATE
    private var backendController: MPBackendController_PRIVATE
    
    @objc public convenience init?(configuration: [AnyHashable : Any], stateMachine: MPStateMachine_PRIVATE, backendController: MPBackendController_PRIVATE) {
        self.init(configuration: configuration, dataReceivedFromServer: true, stateMachine: stateMachine, backendController: backendController)
    }
    
    @objc public init?(configuration: [AnyHashable : Any], dataReceivedFromServer: Bool, stateMachine: MPStateMachine_PRIVATE, backendController: MPBackendController_PRIVATE) {
        self.configuration = configuration
        self.stateMachine = stateMachine
        self.backendController = backendController
        super.init()
        
        if self.configuration == nil || self.configuration?.count == 0 {
            return nil
        }
        self.setUp(dataReceivedFromServer: dataReceivedFromServer)
    }
    
    @objc private func setUp(dataReceivedFromServer: Bool) {
        if let config = self.configuration {
            if dataReceivedFromServer {
                var hasConsentFilters = false
                
                if let configKitDictionary = config[RemoteConfig.kMPRemoteConfigKitsKey] as? [[String : Any]] {
                    for kitDictionary in configKitDictionary {
                        let consentKitFilter = kitDictionary[ConsentFiltering.kMPConsentKitFilter] as? [String : Any]
                        hasConsentFilters = consentKitFilter != nil && consentKitFilter!.count > 0
                        var hasRegulationOrPurposeFilters = false
                        
                        if let hashes = kitDictionary[RemoteConfig.kMPRemoteConfigKitHashesKey] as? [String : Any], hashes.count > 0 {
                            if let regulationFilters = hashes[ConsentFiltering.kMPConsentRegulationFilters] as? [String : Any], regulationFilters.count > 0 {
                                hasRegulationOrPurposeFilters = true
                            }
                            if let purposeFilters = hashes[ConsentFiltering.kMPConsentPurposeFilters] as? [String : Any], purposeFilters.count > 0 {
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
                        MParticle.sharedInstance().kitContainer_PRIVATE.configureKits(config[RemoteConfig.kMPRemoteConfigKitsKey] as? [[AnyHashable : Any]])
                    }
                } else {
                    MParticle.sharedInstance().deferredKitConfiguration_PRIVATE = config[RemoteConfig.kMPRemoteConfigKitsKey] as? [[AnyHashable : Any]]
                }
            }
            
            stateMachine.configureCustomModules(config[RemoteConfig.kMPRemoteConfigCustomModuleSettingsKey] as? [[AnyHashable : Any]])
            stateMachine.configureRampPercentage(config[RemoteConfig.kMPRemoteConfigRampKey] as? NSNumber)
            stateMachine.configureTriggers(config[RemoteConfig.kMPRemoteConfigTriggerKey] as? [AnyHashable : Any])
            stateMachine.configureAliasMaxWindow(config[RemoteConfig.kMPRemoteConfigAliasMaxWindow] as? NSNumber)
            stateMachine.configureDataBlocking(config[RemoteConfig.kMPRemoteConfigDataPlanningResults] as? [AnyHashable : Any])
            
            stateMachine.allowASR = config[RemoteConfig.kMPRemoteConfigAllowASR] as? Bool ?? false
            stateMachine.enableDirectRouting = config[RemoteConfig.kMPRemoteConfigDirectURLRouting] as? Bool ?? false
            if let remoteConfigFlags = config[RemoteConfig.kMPRemoteConfigFlagsKey] as? [AnyHashable : Any] {
                if let audienceAPIFlag = remoteConfigFlags[RemoteConfig.kMPRemoteConfigAudienceAPIKey] as? String {
                    stateMachine.enableAudienceAPI = audienceAPIFlag == "True"
                }
            }
            
            // Exception handling
            if let auxString = config[RemoteConfig.kMPRemoteConfigExceptionHandlingModeKey] as? String {
                stateMachine.exceptionHandlingMode = auxString
                NotificationCenter.default.post(Notification(name: Notifications.kMPConfigureExceptionHandlingNotification))
            }
            
            // Crash size limiting
            if let crashMaxReportLength = config[RemoteConfig.kMPRemoteConfigCrashMaxPLReportLength] as? NSNumber {
                stateMachine.crashMaxPLReportLength = crashMaxReportLength
            }
            
            // Session timeout
            if let sessionTimeout = config[RemoteConfig.kMPRemoteConfigSessionTimeoutKey] as? NSNumber {
                self.backendController.sessionTimeout = sessionTimeout.doubleValue
            }
            
#if os(iOS)
            // Push notifications
            if let pushNotificationDictionary = config["pn"] as? [AnyHashable : Any] {
                self.configurePushNotifications(pushNotificationDictionary)
            }
            
            // Location tracking
            if let locationTrackingDictionary = config["lct"] as? [AnyHashable : Any] {
                self.configureLocationTracking(locationTrackingDictionary)
            }
#endif
        }
    }
    
#if os(iOS)
    @objc public func configureLocationTracking(_ locationDictionary: [AnyHashable : Any]) {
        if let locationMode = locationDictionary[RemoteConfig.kMPRemoteConfigLocationModeKey] as? String {
            stateMachine.locationTrackingMode = locationMode
            
#if !MPARTICLE_LOCATION_DISABLE
            if locationMode == RemoteConfig.kMPRemoteConfigForceTrue {
                if let accuracy = locationDictionary[RemoteConfig.kMPRemoteConfigLocationAccuracyKey] as? NSNumber, let minimumDistance = locationDictionary[RemoteConfig.kMPRemoteConfigLocationMinimumDistanceKey] as? NSNumber {
                    MParticle.sharedInstance().beginLocationTracking(accuracy.doubleValue, minDistance: minimumDistance.doubleValue, authorizationRequest: MPLocationAuthorizationRequest.always)
                }
            } else if locationMode == RemoteConfig.kMPRemoteConfigForceFalse {
                MParticle.sharedInstance().endLocationTracking()
            }
#endif
        }
    }
    
    @objc public func configurePushNotifications(_ pushNotificationDictionary: [AnyHashable : Any]) {
        if let pushNotificationMode = pushNotificationDictionary[RemoteConfig.kMPRemoteConfigPushNotificationModeKey] as? String {
            stateMachine.pushNotificationMode = pushNotificationMode
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


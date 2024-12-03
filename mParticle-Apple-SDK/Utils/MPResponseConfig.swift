////
////  MPResponseConfig.swift
////  mParticle-Apple-SDK
////
////  Created by Brandon Stalnaker on 12/2/24.
////
//
//import Foundation
//
//@objc public class MPResponseConfig : NSObject, NSSecureCoding {
//    @objc public static var supportsSecureCoding: Bool
//    
//    @objc public func encode(with coder: NSCoder) {
//        <#code#>
//    }
//    
//    @objc public required init?(coder: NSCoder) {
//        <#code#>
//    }
//    
//
//    
//    @objc public private(set) var configuration: [AnyHashable : Any]
//    private var stateMachine: MPStateMachine_PRIVATE
//    
//    @objc public convenience init(configuration: [AnyHashable : Any]) {
//        self.init(configuration: configuration, dataReceivedFromServer: true)
//    }
//
//    @objc public init(configuration: [AnyHashable : Any], dataReceivedFromServer: Bool) {
//        self.configuration = configuration;
//        var stateMachine = MParticle.sharedInstance()
//
//        MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
//        
//        if (dataReceivedFromServer) {
//            BOOL hasConsentFilters = NO;
//            
//            if (!MPIsNull(self->_configuration[kMPRemoteConfigKitsKey])) {
//                for (NSDictionary *kitDictionary in self->_configuration[kMPRemoteConfigKitsKey]) {
//                    
//                    NSDictionary *consentKitFilter = kitDictionary[kMPConsentKitFilter];
//                    BOOL hasConsentKitFilter = MPIsNonEmptyDictionary(consentKitFilter);
//                    
//                    BOOL hasRegulationOrPurposeFilters = NO;
//                    
//                    NSDictionary *hashes = kitDictionary[kMPRemoteConfigKitHashesKey];
//                    
//                    if (MPIsNonEmptyDictionary(hashes)) {
//                        
//                        NSDictionary *regulationFilters = hashes[kMPConsentRegulationFilters];
//                        NSDictionary *purposeFilters = hashes[kMPConsentPurposeFilters];
//                        
//                        BOOL hasRegulationFilters = MPIsNonEmptyDictionary(regulationFilters);
//                        BOOL hasPurposeFilters = MPIsNonEmptyDictionary(purposeFilters);
//                        
//                        if (hasRegulationFilters || hasPurposeFilters) {
//                            hasRegulationOrPurposeFilters = YES;
//                        }
//                        
//                    }
//                    
//                    if (hasConsentKitFilter || hasRegulationOrPurposeFilters) {
//           
//                        hasConsentFilters = YES;
//                        break;
//                        
//                    }
//                }
//            }
//            
//            
//            NSNumber *mpid = [MPPersistenceController mpId];
//            BOOL hasInitialIdentity = mpid != nil && ![mpid isEqual:@0];
//            
//            BOOL shouldDefer = hasConsentFilters && !hasInitialIdentity;
//            
//            if (!shouldDefer) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [[MParticle sharedInstance].kitContainer configureKits:self->_configuration[kMPRemoteConfigKitsKey]];
//                });
//            } else {
//                [MParticle sharedInstance].deferredKitConfiguration = [self->_configuration[kMPRemoteConfigKitsKey] copy];
//            }
//            
//        }
//        
//        [stateMachine configureCustomModules:_configuration[kMPRemoteConfigCustomModuleSettingsKey]];
//        [stateMachine configureRampPercentage:_configuration[kMPRemoteConfigRampKey]];
//        [stateMachine configureTriggers:_configuration[kMPRemoteConfigTriggerKey]];
//        [stateMachine configureAliasMaxWindow:_configuration[kMPRemoteConfigAliasMaxWindow]];
//        [stateMachine configureDataBlocking:_configuration[kMPRemoteConfigDataPlanningResults]];
//        
//        stateMachine.allowASR = [_configuration[kMPRemoteConfigAllowASR] boolValue];
//        stateMachine.enableDirectRouting = [_configuration[kMPRemoteConfigDirectURLRouting] boolValue];
//            
//        // Exception handling
//        NSString *auxString = !MPIsNull(_configuration[kMPRemoteConfigExceptionHandlingModeKey]) ? _configuration[kMPRemoteConfigExceptionHandlingModeKey] : nil;
//        if (auxString) {
//            stateMachine.exceptionHandlingMode = [auxString copy];
//            
//            [[NSNotificationCenter defaultCenter] postNotificationName:kMPConfigureExceptionHandlingNotification
//                                                                object:nil
//                                                              userInfo:nil];
//        }
//        
//        // Crash size limiting
//        NSNumber *auxNumber = !MPIsNull(_configuration[kMPRemoteConfigCrashMaxPLReportLength]) ? _configuration[kMPRemoteConfigCrashMaxPLReportLength] : nil;
//        if (auxNumber != nil) {
//            stateMachine.crashMaxPLReportLength = auxNumber;
//        }
//        
//        
//        // Session timeout
//        auxNumber = _configuration[kMPRemoteConfigSessionTimeoutKey];
//        if (auxNumber != nil) {
//            [MParticle sharedInstance].backendController.sessionTimeout = [auxNumber doubleValue];
//        }
//        
//    #if TARGET_OS_IOS == 1
//        // Push notifications
//        NSDictionary *auxDictionary = !MPIsNull(_configuration[kMPRemoteConfigPushNotificationDictionaryKey]) ? _configuration[kMPRemoteConfigPushNotificationDictionaryKey] : nil;
//        if (auxDictionary) {
//            [self configurePushNotifications:auxDictionary];
//        }
//        
//        // Location tracking
//        auxDictionary = !MPIsNull(_configuration[kMPRemoteConfigLocationKey]) ? _configuration[kMPRemoteConfigLocationKey] : nil;
//        if (auxDictionary) {
//            [self configureLocationTracking:auxDictionary];
//        }
//    #endif
//        
//        return self;
//    }
//
//    
//    @objc public class func restore() -> MPResponseConfig? {
//        
//    }
//
//    @objc public class func delete() {
//        
//    }
//
//    @objc public class func isOlderThanConfigMaxAgeSeconds() -> Bool {
//        
//    }
//}
//

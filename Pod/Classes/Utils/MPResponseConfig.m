//
//  MPResponseConfig.m
//
//  Copyright 2015 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPResponseConfig.h"
#import "MPConstants.h"
#import "MPStateMachine.h"
#import <UIKit/UIKit.h>
#import "mParticle.h"
#import "MPKitContainer.h"

@implementation MPResponseConfig

- (instancetype)initWithConfiguration:(NSDictionary *)configurationDictionary {
    self = [super init];
    if (!self || MPIsNull(configurationDictionary)) {
        return nil;
    }
    
    [[MPKitContainer sharedInstance] configureKits:configurationDictionary[kMPRemoteConfigKitsKey]];

    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.latestSDKVersion = configurationDictionary[kMPRemoteConfigLatestSDKVersionKey];
    [stateMachine configureCustomModules:configurationDictionary[kMPRemoteConfigCustomModuleSettingsKey]];
    [stateMachine configureRampPercentage:configurationDictionary[kMPRemoteConfigRampKey]];
    [stateMachine configureTriggers:configurationDictionary[kMPRemoteConfigTriggerKey]];
    
    _influencedOpenTimer = !MPIsNull(configurationDictionary[kMPRemoteConfigInfluencedOpenTimerKey]) ? configurationDictionary[kMPRemoteConfigInfluencedOpenTimerKey] : nil;
    
    // Exception handling
    NSString *auxString = !MPIsNull(configurationDictionary[kMPRemoteConfigExceptionHandlingModeKey]) ? configurationDictionary[kMPRemoteConfigExceptionHandlingModeKey] : nil;
    if (auxString && ![auxString isEqualToString:stateMachine.exceptionHandlingMode]) {
        stateMachine.exceptionHandlingMode = [auxString copy];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kMPConfigureExceptionHandlingNotification
                                                            object:nil
                                                          userInfo:nil];
    }
    
    // Network performance
    auxString = !MPIsNull(configurationDictionary[kMPRemoteConfigNetworkPerformanceModeKey]) ? configurationDictionary[kMPRemoteConfigNetworkPerformanceModeKey] : nil;
    if (auxString) {
        [self configureNetworkPerformanceMeasurement:auxString];
    }
    
    // Session timeout
    NSNumber *auxNumber = configurationDictionary[kMPRemoteConfigSessionTimeoutKey];
    if (auxNumber) {
        [MParticle sharedInstance].sessionTimeout = [auxNumber doubleValue];
    }
    
    // Upload interval
    auxNumber = !MPIsNull(configurationDictionary[kMPRemoteConfigUploadIntervalKey]) ? configurationDictionary[kMPRemoteConfigUploadIntervalKey] : nil;
    if (auxNumber) {
        [MParticle sharedInstance].uploadInterval = [auxNumber doubleValue];
    }
    
    // Push notifications
    NSDictionary *auxDictionary = !MPIsNull(configurationDictionary[kMPRemoteConfigPushNotificationDictionaryKey]) ? configurationDictionary[kMPRemoteConfigPushNotificationDictionaryKey] : nil;
    if (auxDictionary) {
        [self configurePushNotifications:auxDictionary];
    }
    
    // Location tracking
    auxDictionary = !MPIsNull(configurationDictionary[kMPRemoteConfigLocationKey]) ? configurationDictionary[kMPRemoteConfigLocationKey] : nil;
    if (auxDictionary) {
        [self configureLocationTracking:auxDictionary];
    }
    
    return self;
}

#pragma mark Private methods
- (void)configureLocationTracking:(NSDictionary *)locationDictionary {
    NSString *locationMode = locationDictionary[kMPRemoteConfigLocationModeKey];
    [MPStateMachine sharedInstance].locationTrackingMode = locationMode;
    
    if ([locationMode isEqualToString:kMPRemoteConfigForceTrue]) {
        NSNumber *accurary = locationDictionary[kMPRemoteConfigLocationAccuracyKey];
        NSNumber *minimumDistance = locationDictionary[kMPRemoteConfigLocationMinimumDistanceKey];
        
        [[MParticle sharedInstance] beginLocationTracking:[accurary doubleValue] minDistance:[minimumDistance doubleValue] authorizationRequest:MPLocationAuthorizationRequestAlways];
    } else if ([locationMode isEqualToString:kMPRemoteConfigForceFalse]) {
        [[MParticle sharedInstance] endLocationTracking];
    }
}

- (void)configureNetworkPerformanceMeasurement:(NSString *)networkPerformanceMeasuringMode {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];

    if ([networkPerformanceMeasuringMode isEqualToString:stateMachine.networkPerformanceMeasuringMode]) {
        return;
    }
    
    stateMachine.networkPerformanceMeasuringMode = [networkPerformanceMeasuringMode copy];
    
    if ([stateMachine.networkPerformanceMeasuringMode isEqualToString:kMPRemoteConfigForceTrue]) {
        [[MParticle sharedInstance] beginMeasuringNetworkPerformance];
    } else if ([stateMachine.networkPerformanceMeasuringMode isEqualToString:kMPRemoteConfigForceFalse]) {
        [[MParticle sharedInstance] endMeasuringNetworkPerformance];
    }
}

- (void)configurePushNotifications:(NSDictionary *)pushNotificationDictionary {
    NSString *pushNotificationMode = pushNotificationDictionary[kMPRemoteConfigPushNotificationModeKey];
    [MPStateMachine sharedInstance].pushNotificationMode = pushNotificationMode;
    UIApplication *app = [UIApplication sharedApplication];
    
    if ([pushNotificationMode isEqualToString:kMPRemoteConfigForceTrue]) {
        NSNumber *pushNotificationType = pushNotificationDictionary[kMPRemoteConfigPushNotificationTypeKey];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [app registerForRemoteNotificationTypes:[pushNotificationType integerValue]];
#pragma clang diagnostic pop
    } else if ([pushNotificationMode isEqualToString:kMPRemoteConfigForceFalse]) {
        [app unregisterForRemoteNotifications];
    }
}

@end

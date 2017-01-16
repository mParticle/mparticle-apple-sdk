//
//  MPNotificationController.mm
//
//  Copyright 2016 mParticle, Inc.
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

#import "MPNotificationController.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "NSUserDefaults+mParticle.h"
#include "MPHasher.h"

@interface MPNotificationController() {
    BOOL backgrounded;
}

@end

#if TARGET_OS_IOS == 1
static NSData *deviceToken = nil;
static int64_t launchNotificationHash = 0;
#endif

@implementation MPNotificationController

#if TARGET_OS_IOS == 1
- (instancetype)initWithDelegate:(id<MPNotificationControllerDelegate>)delegate {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _delegate = delegate;
    backgrounded = YES;

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleApplicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleApplicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleRemoteNotificationReceived:)
                               name:kMPRemoteNotificationReceivedNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleLocalNotificationReceived:)
                               name:kMPLocalNotificationReceivedNotification
                             object:nil];
    
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter removeObserver:self name:kMPRemoteNotificationReceivedNotification object:nil];
    [notificationCenter removeObserver:self name:kMPLocalNotificationReceivedNotification object:nil];
}

#pragma mark Private methods
- (MParticleUserNotification *)userNotificationWithDictionary:(NSDictionary *)notificationDictionary actionIdentifier:(NSString *)actionIdentifier state:(NSString *)state userNotificationMode:(MPUserNotificationMode)userNotificationMode runningMode:(MPUserNotificationRunningMode)runningMode {
    if (!state) {
        state = backgrounded || actionIdentifier ? kMPPushNotificationStateBackground : kMPPushNotificationStateForeground;
    } else {
        state = state;
    }
        
    MParticleUserNotification *userNotification = [[MParticleUserNotification alloc] initWithDictionary:notificationDictionary
                                                                                       actionIdentifier:actionIdentifier
                                                                                                  state:state
                                                                                                   mode:userNotificationMode
                                                                                            runningMode:runningMode];
    
    return userNotification;
}

#pragma mark Notification handlers
- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    backgrounded = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        launchNotificationHash = 0;
    });
}

- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    __weak MPNotificationController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MPNotificationController *strongSelf = weakSelf;
        
        if (strongSelf) {
            strongSelf->backgrounded = NO;
        }
    });
}

- (void)handleLocalNotificationReceived:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSDictionary *notificationDictionary = userInfo[kMPUserNotificationDictionaryKey];
    NSString *actionIdentifier = userInfo[kMPUserNotificationActionKey];
    
    MParticleUserNotification *userNotification = [self userNotificationWithDictionary:notificationDictionary
                                                                      actionIdentifier:actionIdentifier
                                                                                 state:nil
                                                                  userNotificationMode:MPUserNotificationModeLocal
                                                                           runningMode:static_cast<MPUserNotificationRunningMode>([userInfo[kMPUserNotificationRunningModeKey] integerValue])];
    
    [self.delegate receivedUserNotification:userNotification];
}

- (void)handleRemoteNotificationReceived:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSDictionary *notificationDictionary = userInfo[kMPUserNotificationDictionaryKey];
    NSString *actionIdentifier = userInfo[kMPUserNotificationActionKey];
    
    MParticleUserNotification *userNotification = [self userNotificationWithDictionary:notificationDictionary
                                                                      actionIdentifier:actionIdentifier
                                                                                 state:nil
                                                                  userNotificationMode:MPUserNotificationModeRemote
                                                                           runningMode:static_cast<MPUserNotificationRunningMode>([userInfo[kMPUserNotificationRunningModeKey] integerValue])];
    
    [self.delegate receivedUserNotification:userNotification];
}

#pragma mark Public static methods
+ (NSData *)deviceToken {
    if (deviceToken) {
        return deviceToken;
    }
    
#ifndef MP_UNIT_TESTING
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    deviceToken = userDefaults[kMPDeviceTokenKey];
#else
    deviceToken = [@"<000000000000000000000000000000>" dataUsingEncoding:NSUTF8StringEncoding];
#endif
    
    return deviceToken;
}

+ (NSDictionary *)dictionaryFromLocalNotification:(UILocalNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    if (!userInfo) {
        return nil;
    }
    
    NSMutableDictionary *apsDictionary = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    apsDictionary[kMPUserNotificationAlertKey] = @{kMPUserNotificationBodyKey:notification.alertBody};
    apsDictionary[@"content-available"] = @1;

    if (notification.applicationIconBadgeNumber > 0) {
        apsDictionary[@"badge"] = @(notification.applicationIconBadgeNumber);
    }
    
    if (notification.soundName) {
        apsDictionary[@"sound"] = notification.soundName;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 && notification.category) {
        apsDictionary[kMPUserNotificationCategoryKey] = notification.category;
    }
    
    return @{kMPUserNotificationApsKey:apsDictionary};
}

+ (void)setDeviceToken:(NSData *)devToken {
    if ([MPNotificationController deviceToken] && [[MPNotificationController deviceToken] isEqualToData:devToken]) {
        return;
    }
    
    NSData *newDeviceToken = [devToken copy];
    NSData *oldDeviceToken = [deviceToken copy];
    
    deviceToken = devToken;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *deviceTokenDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
        if (newDeviceToken) {
            deviceTokenDictionary[kMPRemoteNotificationDeviceTokenKey] = newDeviceToken;
        }
        
        if (oldDeviceToken) {
            deviceTokenDictionary[kMPRemoteNotificationOldDeviceTokenKey] = oldDeviceToken;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:kMPRemoteNotificationDeviceTokenNotification
                                                            object:nil
                                                          userInfo:deviceTokenDictionary];
    });
}

+ (int64_t)launchNotificationHash {
    return launchNotificationHash;
}

#pragma mark Public methods
- (MParticleUserNotification *)newUserNotificationWithDictionary:(NSDictionary *)notificationDictionary actionIdentifier:(NSString *)actionIdentifier state:(NSString *)state {
    MParticleUserNotification *userNotification = [self userNotificationWithDictionary:notificationDictionary
                                                                      actionIdentifier:actionIdentifier
                                                                                 state:state
                                                                  userNotificationMode:MPUserNotificationModeRemote
                                                                           runningMode:MPUserNotificationRunningModeForeground];
    
    return userNotification;
}
#endif

@end

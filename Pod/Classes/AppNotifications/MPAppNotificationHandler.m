//
//  MPAppNotificationHandler.m
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

#import "MPAppNotificationHandler.h"
#import "MPStateMachine.h"
#import "MPLaunchInfo.h"
#import "MPNotificationController.h"
#import "MPForwardRecord.h"
#import "MPPersistenceController.h"
#import "MPLogger.h"
#import "MPKitContainer.h"
#import "MPKitExecStatus.h"
#import "MPKitAbstract.h"

@interface MPAppNotificationHandler() {
    dispatch_queue_t processUserNotificationQueue;
}
@end


@implementation MPAppNotificationHandler

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    processUserNotificationQueue = dispatch_queue_create("com.mParticle.ProcessUserNotificationQueue", DISPATCH_QUEUE_SERIAL);
    _runningMode = MPUserNotificationRunningModeForeground;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleApplicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleApplicationWillEnterForeground:)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];

    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

+ (instancetype)sharedInstance {
    static MPAppNotificationHandler *sharedInstance = nil;
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        sharedInstance = [[MPAppNotificationHandler alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark Notification handlers
- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    _runningMode = MPUserNotificationRunningModeBackground;
}

- (void)handleApplicationWillEnterForeground:(NSNotification *)notification {
    _runningMode = MPUserNotificationRunningModeForeground;
}

#pragma mark Public methods
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    [MPNotificationController setDeviceToken:nil];
    
    SEL failedRegistrationSelector = @selector(failedToRegisterForUserNotifications:);
    NSArray<__kindof MPKitAbstract *> *activeKits = [[MPKitContainer sharedInstance] activeKits];
    NSNumber *lastKit = nil;
    
    for (MPKitAbstract *kit in activeKits) {
        if ([kit respondsToSelector:failedRegistrationSelector]) {
            MPKitExecStatus *execStatus = [kit failedToRegisterForUserNotifications:error];
            
            if (execStatus.success && ![lastKit isEqualToNumber:execStatus.kitCode]) {
                lastKit = execStatus.kitCode;
                
                MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushRegistration
                                                                                   execStatus:execStatus
                                                                                    stateFlag:NO];
                
                [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                
                MPLogDebug(@"Forwarded fail to register for remote notification call to kit: %@", [MPKitAbstract nameForKit:execStatus.kitCode]);
            }
        }
    }
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    [MPNotificationController setDeviceToken:deviceToken];
    
    SEL deviceTokenSelector = @selector(setDeviceToken:);
    NSArray<__kindof MPKitAbstract *> *activeKits = [[MPKitContainer sharedInstance] activeKits];
    NSNumber *lastKit = nil;
    
    for (MPKitAbstract *kit in activeKits) {
        if ([kit respondsToSelector:deviceTokenSelector]) {
            MPKitExecStatus *execStatus = [kit setDeviceToken:deviceToken];
            
            if (execStatus.success && ![lastKit isEqualToNumber:execStatus.kitCode]) {
                lastKit = execStatus.kitCode;
                
                MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushRegistration
                                                                                   execStatus:execStatus
                                                                                    stateFlag:(deviceToken != nil)];
                
                [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                
                MPLogDebug(@"Forwarded remote notification registration call to kit: %@", [MPKitAbstract nameForKit:execStatus.kitCode]);
            }
        }
    }
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    if ([MPStateMachine sharedInstance].optOut) {
        return;
    }
    
    [self receivedUserNotification:userInfo actionIdentifier:identifier userNoticicationMode:MPUserNotificationModeRemote];
    
    SEL handleActionWithIdentifierSelector = @selector(handleActionWithIdentifier:forRemoteNotification:);
    NSArray<__kindof MPKitAbstract *> *activeKits = [[MPKitContainer sharedInstance] activeKits];
    
    for (MPKitAbstract *kit in activeKits) {
        if ([kit respondsToSelector:handleActionWithIdentifierSelector]) {
            [kit handleActionWithIdentifier:identifier forRemoteNotification:userInfo];
        }
    }
}

- (void)openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options {
    NSString *sourceApplication = options[UIApplicationOpenURLOptionsSourceApplicationKey];
    id annotation =  options[UIApplicationOpenURLOptionsAnnotationKey];
    
    [self openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        return;
    }
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    NSArray<__kindof MPKitAbstract *> *activeKits = [[MPKitContainer sharedInstance] activeKits];
    SEL openURLSourceAppAnnotationSelector = @selector(openURL:sourceApplication:annotation:);
    
    for (MPKitAbstract *kit in activeKits) {
        if ([kit respondsToSelector:openURLSourceAppAnnotationSelector]) {
            [kit openURL:url sourceApplication:sourceApplication annotation:annotation];
        }
    }
}

- (void)receivedUserNotification:(NSDictionary *)userInfo actionIdentifier:(NSString *)actionIdentifier userNoticicationMode:(MPUserNotificationMode)userNotificationMode {
    if ([MPStateMachine sharedInstance].optOut || !userInfo) {
        return;
    }
    
    __weak MPAppNotificationHandler *weakSelf = self;
    dispatch_async(processUserNotificationQueue, ^{
        __strong MPAppNotificationHandler *strongSelf = weakSelf;
        
        NSMutableDictionary *userNotificationDictionary = [@{kMPUserNotificationDictionaryKey:userInfo,
                                                             kMPUserNotificationRunningModeKey:@(strongSelf.runningMode)}
                                                           mutableCopy];
        if (actionIdentifier) {
            userNotificationDictionary[kMPUserNotificationActionKey] = actionIdentifier;
        }
        
        NSString *notificationName;
        if (userNotificationMode == MPUserNotificationModeAutoDetect) {
            MPUserNotificationCommand command = [userInfo[kMPUserNotificationCommandKey] integerValue];
            
            notificationName = command != MPUserNotificationCommandAlertUserLocalTime ? kMPRemoteNotificationReceivedNotification : kMPLocalNotificationReceivedNotification;
        } else {
            notificationName = userNotificationMode == MPUserNotificationModeRemote ? kMPRemoteNotificationReceivedNotification : kMPLocalNotificationReceivedNotification;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                            object:strongSelf
                                                          userInfo:userNotificationDictionary];
    });
    
    if (!actionIdentifier) {
        SEL receivedNotificationSelector = @selector(receivedUserNotification:);
        NSArray<__kindof MPKitAbstract *> *activeKits = [[MPKitContainer sharedInstance] activeKits];
        NSNumber *lastKit = nil;
        
        for (MPKitAbstract *kit in activeKits) {
            if ([kit respondsToSelector:receivedNotificationSelector]) {
                MPKitExecStatus *execStatus = [kit receivedUserNotification:userInfo];
                
                if (execStatus.success && ![lastKit isEqualToNumber:execStatus.kitCode]) {
                    lastKit = execStatus.kitCode;
                    
                    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushNotification
                                                                                       execStatus:execStatus];
                    
                    [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                    
                    MPLogDebug(@"Forwarded push notifications call to kit: %@", [MPKitAbstract nameForKit:execStatus.kitCode]);
                }
            }
        }
    }
}

- (BOOL)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^__nonnull)(NSArray * __nullable restorableObjects))restorationHandler {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        return NO;
    }
    
    stateMachine.launchInfo = nil;
    
    NSArray<__kindof MPKitAbstract *> *activeKits = [[MPKitContainer sharedInstance] activeKits];
    SEL continueUserActivitySelector = @selector(continueUserActivity:restorationHandler:);
    
    for (MPKitAbstract *kit in activeKits) {
        if ([kit respondsToSelector:continueUserActivitySelector]) {
            [kit continueUserActivity:userActivity restorationHandler:restorationHandler];
        }
    }
    return NO;
}

- (void)didUpdateUserActivity:(nonnull NSUserActivity *)userActivity {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    if (stateMachine.optOut) {
        return;
    }
    
    NSArray<__kindof MPKitAbstract *> *activeKits = [[MPKitContainer sharedInstance] activeKits];
    SEL didUpdateUserActivitySelector = @selector(didUpdateUserActivity:);
    
    for (MPKitAbstract *kit in activeKits) {
        if ([kit respondsToSelector:didUpdateUserActivitySelector]) {
            [kit didUpdateUserActivity:userActivity];
        }
    }
}

@end

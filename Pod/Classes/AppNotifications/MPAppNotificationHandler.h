//
//  MPAppNotificationHandler.h
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

#import <Foundation/Foundation.h>
#import "MParticleUserNotification.h"

@interface MPAppNotificationHandler : NSObject

@property (nonatomic, unsafe_unretained, readonly) MPUserNotificationRunningMode runningMode;

+ (instancetype)sharedInstance;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo;
- (void)openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options;
- (void)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
- (void)receivedUserNotification:(NSDictionary *)userInfo actionIdentifier:(NSString *)actionIdentifier userNoticicationMode:(MPUserNotificationMode)userNotificationMode;

@end

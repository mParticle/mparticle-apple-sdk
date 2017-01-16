//
//  MParticleUserNotification.h
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

#import "MPDataModelAbstract.h"

typedef NS_ENUM(NSInteger, MPUserNotificationMode) {
    MPUserNotificationModeAutoDetect = 0,
    MPUserNotificationModeRemote,
    MPUserNotificationModeLocal
};

typedef NS_ENUM(NSInteger, MPUserNotificationRunningMode) {
    MPUserNotificationRunningModeBackground = 1,
    MPUserNotificationRunningModeForeground
};

extern NSString * _Nonnull const kMPUserNotificationApsKey;
extern NSString * _Nonnull const kMPUserNotificationAlertKey;
extern NSString * _Nonnull const kMPUserNotificationBodyKey;
extern NSString * _Nonnull const kMPUserNotificationContentAvailableKey;
extern NSString * _Nonnull const kMPUserNotificationCategoryKey;

#if TARGET_OS_IOS == 1

@interface MParticleUserNotification : MPDataModelAbstract <NSCoding>

@property (nonatomic, strong, nullable) NSString *actionIdentifier;
@property (nonatomic, strong, nullable) NSString *actionTitle;
@property (nonatomic, strong, nonnull) NSString *type;
@property (nonatomic, strong, readonly, nullable) NSString *categoryIdentifier;
@property (nonatomic, strong, readonly, nullable) NSString *redactedUserNotificationString;
@property (nonatomic, strong, readonly, nonnull) NSString *state;

- (nonnull instancetype)initWithDictionary:(nonnull NSDictionary *)notificationDictionary actionIdentifier:(nullable NSString *)actionIdentifier state:(nonnull NSString *)state mode:(MPUserNotificationMode)mode runningMode:(MPUserNotificationRunningMode)runningMode;

@end

#endif

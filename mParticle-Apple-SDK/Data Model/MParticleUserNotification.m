//
//  MParticleUserNotification.m
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

#import "MParticleUserNotification.h"

NSString *const kMPUserNotificationApsKey = @"aps";
NSString *const kMPUserNotificationAlertKey = @"alert";
NSString *const kMPUserNotificationBodyKey = @"body";
NSString *const kMPUserNotificationContentAvailableKey = @"content-available";
NSString *const kMPUserNotificationCategoryKey = @"category";

#if TARGET_OS_IOS == 1

#import "MPIConstants.h"
#import "MPDateFormatter.h"
#import <UIKit/UIKit.h>
#import "MPStateMachine.h"
#import "MPILogger.h"

@implementation MParticleUserNotification

- (instancetype)initWithDictionary:(NSDictionary *)notificationDictionary actionIdentifier:(NSString *)actionIdentifier state:(NSString *)state mode:(MPUserNotificationMode)mode runningMode:(MPUserNotificationRunningMode)runningMode {
    self = [super init];
    if (!self || !state) {
        return nil;
    }
    
    _state = state;
    _redactedUserNotificationString = [self redactUserNotification:notificationDictionary];
    _uuid = [[NSUUID UUID] UUIDString];
    
    if (actionIdentifier) {
        _actionIdentifier = [actionIdentifier copy];
        _type = kMPPushMessageAction;
        
        if (_categoryIdentifier) {
            UIUserNotificationSettings *userNotificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
            
            if (userNotificationSettings) {
                for (UIUserNotificationCategory *category in userNotificationSettings.categories) {
                    if ([category.identifier isEqualToString:_categoryIdentifier]) {
                        for (UIUserNotificationAction *action in [category actionsForContext:UIUserNotificationActionContextDefault]) {
                            if ([action.identifier isEqualToString:actionIdentifier]) {
                                _actionTitle = action.title;
                                break;
                            }
                        }
                        
                        break;
                    }
                }
            }
        }
    } else {
        _actionIdentifier = nil;
        _actionTitle = nil;
        _type = kMPPushMessageReceived;
    }
    
    return self;
}

#pragma mark Private methods
- (NSString *)redactUserNotification:(NSDictionary *)notificationDictionary {
    NSString * (^dictionaryToString)(NSDictionary *) = ^(NSDictionary *dictionary) {
        NSString *dictionaryString = nil;
        
        if (dictionary == nil) {
            return dictionaryString;
        }
        
        NSError *error = nil;
        @try {
            NSData *dictionaryData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
            
            if (!error) {
                dictionaryString = [[NSString alloc] initWithData:dictionaryData encoding:NSUTF8StringEncoding];
            }
        } @catch (NSException *exception) {
            MPILogError(@"Exception serializing a notification dictionary: %@", [exception reason]);
        }
        
        return dictionaryString;
    };
    
    NSString *redactedNotificationString = nil;
    
    if (notificationDictionary[kMPUserNotificationContentAvailableKey]) {
        redactedNotificationString = dictionaryToString(notificationDictionary);
        return redactedNotificationString;
    }
    
    NSMutableDictionary *mPushNotificationDictionary = [notificationDictionary mutableCopy];
    NSDictionary *apsDictionary = mPushNotificationDictionary[kMPUserNotificationApsKey];
    
    if (![apsDictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    _categoryIdentifier = apsDictionary[kMPUserNotificationCategoryKey];
    
    id alert = apsDictionary[kMPUserNotificationAlertKey];
    
    if (!alert) {
        redactedNotificationString = dictionaryToString(notificationDictionary);
        return redactedNotificationString;
    }
    
    [mPushNotificationDictionary removeObjectForKey:kMPUserNotificationApsKey];
    NSMutableDictionary *mAPSDictionary = [[NSMutableDictionary alloc] initWithCapacity:apsDictionary.count];
    NSEnumerator *apsEnumerator = [apsDictionary keyEnumerator];
    NSString *apsKey;
    
    if ([alert isKindOfClass:[NSString class]]) {
        while ((apsKey = [apsEnumerator nextObject])) {
            if (![apsKey isEqualToString:kMPUserNotificationAlertKey]) {
                mAPSDictionary[apsKey] = apsDictionary[apsKey];
            }
        }
    } else if ([alert isKindOfClass:[NSDictionary class]]) {
        while ((apsKey = [apsEnumerator nextObject])) {
            if ([apsKey isEqualToString:kMPUserNotificationAlertKey]) {
                NSMutableDictionary *alertDictionary = [[NSMutableDictionary alloc] init];
                NSEnumerator *alertEnumerator = [alert keyEnumerator];
                NSString *alertKey;
                
                while ((alertKey = [alertEnumerator nextObject])) {
                    if ([alertKey isEqualToString:kMPUserNotificationBodyKey]) {
                        continue;
                    }
                    
                    alertDictionary[alertKey] = alert[alertKey];
                }
                
                mAPSDictionary[kMPUserNotificationAlertKey] = alertDictionary;
            } else {
                mAPSDictionary[apsKey] = apsDictionary[apsKey];
            }
        }
    }
    
    mPushNotificationDictionary[kMPUserNotificationApsKey] = mAPSDictionary;

    redactedNotificationString = dictionaryToString(mPushNotificationDictionary);
    
    return redactedNotificationString;
}

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_state forKey:@"state"];
    [coder encodeObject:_type forKey:@"type"];
    [coder encodeObject:_uuid forKey:@"uuid"];
    
    if (_redactedUserNotificationString) {
        [coder encodeObject:_redactedUserNotificationString forKey:@"redactedUserNotificationString"];
    }
    
    if (_categoryIdentifier) {
        [coder encodeObject:_categoryIdentifier forKey:@"categoryIdentifier"];
    }
    
    if (_actionIdentifier) {
        [coder encodeObject:_actionIdentifier forKey:@"actionIdentifier"];
    }
    
    if (_actionTitle) {
        [coder encodeObject:_actionTitle forKey:@"actionTitle"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _state = [coder decodeObjectForKey:@"state"];
    _type = [coder decodeObjectForKey:@"type"];
    _uuid = [coder decodeObjectForKey:@"uuid"];
    
    id object = [coder decodeObjectForKey:@"categoryIdentifier"];
    if (object) {
        _categoryIdentifier = (NSString *)object;
    }
    
    object = [coder decodeObjectForKey:@"redactedUserNotificationString"];
    if (object) {
        _redactedUserNotificationString = (NSString *)object;
    }
    
    object = [coder decodeObjectForKey:@"actionIdentifier"];
    if (object) {
        _actionIdentifier = (NSString *)object;
    }
    
    object = [coder decodeObjectForKey:@"actionTitle"];
    if (object) {
        _actionTitle = (NSString *)object;
    }
    
    return self;
}

@end

#endif

//
//  MPKitAbstract.h
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
#import "MPKitExecStatus.h"
#import <CoreLocation/CoreLocation.h>
#import "MPEnums.h"

@class MPCommerceEvent;
@class MPEvent;
@class MPMediaTrack;
@class MPUserSegments;

/**
 */
@protocol MPKitInstanceProtocol <NSObject>
@optional
// Application
- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url sourceApplication:(nonnull NSString *)sourceApplication annotation:(nullable id)annotation;
- (nonnull MPKitExecStatus *)failedToRegisterForUserNotifications:(nullable NSError *)error;
- (nonnull MPKitExecStatus *)handleActionWithIdentifier:(nonnull NSString *)identifier forRemoteNotification:(nonnull NSDictionary *)userInfo;
- (nonnull MPKitExecStatus *)receivedUserNotification:(nonnull NSDictionary *)userInfo;
- (nonnull MPKitExecStatus *)setDeviceToken:(nonnull NSData *)deviceToken;
- (nonnull MPKitExecStatus *)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^__nonnull)(NSArray * __nullable restorableObjects))restorationHandler;
- (nonnull MPKitExecStatus *)didUpdateUserActivity:(nonnull NSUserActivity *)userActivity;
// Location tracking
- (nonnull MPKitExecStatus *)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter;
- (nonnull MPKitExecStatus *)endLocationTracking;
- (nonnull MPKitExecStatus *)setLocation:(nonnull CLLocation *)location;
// Session management
- (nonnull MPKitExecStatus *)beginSession;
- (nonnull MPKitExecStatus *)endSession;
// User attributes and identities
- (nonnull MPKitExecStatus *)incrementUserAttribute:(nonnull NSString *)key byValue:(nonnull NSNumber *)value;
- (nonnull MPKitExecStatus *)removeUserAttribute:(nonnull NSString *)key;
- (nonnull MPKitExecStatus *)setUserAttribute:(nonnull NSString *)key value:(nullable NSString *)value;
- (nonnull MPKitExecStatus *)setUserIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType;
- (nonnull MPKitExecStatus *)setUserTag:(nonnull NSString *)tag;
// e-Commerce
- (nonnull MPKitExecStatus *)logCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent;
- (nonnull MPKitExecStatus *)logLTVIncrease:(double)increaseAmount event:(nonnull MPEvent *)event;
// Events
- (nonnull MPKitExecStatus *)logEvent:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)logInstall;
- (nonnull MPKitExecStatus *)logout;
- (nonnull MPKitExecStatus *)logScreen:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)logUpdate;
// Timed events
- (nonnull MPKitExecStatus *)beginTimedEvent:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)endTimedEvent:(nonnull MPEvent *)event;
// Errors and exceptions
- (nonnull MPKitExecStatus *)leaveBreadcrumb:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)logError:(nullable NSString *)message eventInfo:(nullable NSDictionary *)eventInfo;
- (nonnull MPKitExecStatus *)logException:(nonnull NSException *)exception;
// Assorted
- (nonnull MPKitExecStatus *)setDebugMode:(BOOL)debugMode;
- (nonnull MPKitExecStatus *)setKitAttribute:(nonnull NSString *)key value:(nullable id)value;
- (nonnull MPKitExecStatus *)setOptOut:(BOOL)optOut;
- (void)start;
- (nullable NSString *)surveyURLWithUserAttributes:(nonnull NSDictionary *)userAttributes;
- (void)synchronize;
// Media tracking
- (nonnull MPKitExecStatus *)beginPlaying:(nonnull MPMediaTrack *)mediaTrack;
- (nonnull MPKitExecStatus *)endPlaying:(nonnull MPMediaTrack *)mediaTrack;
- (nonnull MPKitExecStatus *)logMetadataWithMediaTrack:(nonnull MPMediaTrack *)mediaTrack;
- (nonnull MPKitExecStatus *)logTimedMetadataWithMediaTrack:(nonnull MPMediaTrack *)mediaTrack;
- (nonnull MPKitExecStatus *)updatePlaybackPosition:(nonnull MPMediaTrack *)mediaTrack;

@end


/**
 */
@interface MPKitAbstract : NSObject <MPKitInstanceProtocol> {
@protected
    NSDictionary *cachedUserAttributes;
    NSArray *cachedUserIdentities;
    BOOL frameworkAvailable;
    BOOL started;
    BOOL kitDebugMode;
}

@property (nonatomic, unsafe_unretained) BOOL active;
@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nonnull) NSNumber *kitCode;
@property (nonatomic, strong, nullable) NSDictionary *userAttributes;
@property (nonatomic, strong, nullable) NSArray *userIdentities;
@property (nonatomic, unsafe_unretained) BOOL forwardedEvents;

+ (nullable NSString *)nameForKit:(nonnull NSNumber *)kitCode;
- (nonnull instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration startImmediately:(BOOL)startImmediately __attribute__((objc_requires_super));
- (nonnull instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration __attribute__((objc_requires_super));
- (BOOL)canExecuteSelector:(nonnull SEL)selector __attribute__((objc_requires_super));
- (nullable id const)kitInstance;
- (nullable NSString *)kitName;
- (nullable NSDictionary *)parsedEventInfo:(nullable NSDictionary *)eventInfo;
- (nullable NSString *)stringRepresentation:(nullable id)value;
- (void)setBracketConfiguration:(nullable NSDictionary *)bracketConfiguration __attribute__((objc_requires_super));
- (void)setConfiguration:(nonnull NSDictionary *)configuration __attribute__((objc_requires_super));
- (BOOL)started;

@end

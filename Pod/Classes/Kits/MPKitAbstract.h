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
- (MPKitExecStatus *)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
- (MPKitExecStatus *)failedToRegisterForUserNotifications:(NSError *)error;
- (MPKitExecStatus *)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo;
- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo;
- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken;
// Location tracking
- (MPKitExecStatus *)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter;
- (MPKitExecStatus *)endLocationTracking;
- (MPKitExecStatus *)setLocation:(CLLocation *)location;
// Session management
- (MPKitExecStatus *)beginSession;
- (MPKitExecStatus *)endSession;
// User attributes and identities
- (MPKitExecStatus *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value;
- (MPKitExecStatus *)removeUserAttribute:(NSString *)key;
- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value;
- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType;
- (MPKitExecStatus *)setUserTag:(NSString *)tag;
// e-Commerce
- (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent;
- (MPKitExecStatus *)logLTVIncrease:(double)increaseAmount event:(MPEvent *)event;
// Events
- (MPKitExecStatus *)logEvent:(MPEvent *)event;
- (MPKitExecStatus *)logInstall;
- (MPKitExecStatus *)logout;
- (MPKitExecStatus *)logScreen:(MPEvent *)event;
- (MPKitExecStatus *)logUpdate;
// Timed events
- (MPKitExecStatus *)beginTimedEvent:(MPEvent *)event;
- (MPKitExecStatus *)endTimedEvent:(MPEvent *)event;
// Errors and exceptions
- (MPKitExecStatus *)leaveBreadcrumb:(MPEvent *)event;
- (MPKitExecStatus *)logError:(NSString *)message eventInfo:(NSDictionary *)eventInfo;
- (MPKitExecStatus *)logException:(NSException *)exception;
// Assorted
- (MPKitExecStatus *)setDebugMode:(BOOL)debugMode;
- (MPKitExecStatus *)setKitAttribute:(NSString *)key value:(id)value;
- (MPKitExecStatus *)setOptOut:(BOOL)optOut;
- (void)start;
- (NSString *)surveyURLWithUserAttributes:(NSDictionary *)userAttributes;
- (void)synchronize;
// Media tracking
- (MPKitExecStatus *)beginPlaying:(MPMediaTrack *)mediaTrack;
- (MPKitExecStatus *)endPlaying:(MPMediaTrack *)mediaTrack;
- (MPKitExecStatus *)logMetadataWithMediaTrack:(MPMediaTrack *)mediaTrack;
- (MPKitExecStatus *)logTimedMetadataWithMediaTrack:(MPMediaTrack *)mediaTrack;
- (MPKitExecStatus *)updatePlaybackPosition:(MPMediaTrack *)mediaTrack;

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
@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, strong) NSNumber *kitCode;
@property (nonatomic, strong) NSDictionary *userAttributes;
@property (nonatomic, strong) NSArray *userIdentities;
@property (nonatomic, unsafe_unretained) BOOL forwardedEvents;

- (instancetype)initWithConfiguration:(NSDictionary *)configuration startImmediately:(BOOL)startImmediately __attribute__((objc_requires_super));
- (instancetype)initWithConfiguration:(NSDictionary *)configuration __attribute__((objc_requires_super));
- (BOOL)canExecuteSelector:(SEL)selector __attribute__((objc_requires_super));
- (id const)kitInstance;
- (NSDictionary *)parsedEventInfo:(NSDictionary *)eventInfo;
- (NSString *)stringRepresentation:(id)value;
- (void)setBracketConfiguration:(NSDictionary *)bracketConfiguration __attribute__((objc_requires_super));
- (void)setConfiguration:(NSDictionary *)configuration __attribute__((objc_requires_super));
- (BOOL)started;

@end

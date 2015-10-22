//
//  MPBackend.h
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

#import <CoreLocation/CoreLocation.h>
#import "MPEnums.h"

@class MPSession;
@class MPMessage;
@class MPNetworkPerformance;
@class MPNotificationController;
@class MPEvent;
@class MPMediaTrack;
@class MPCommerceEvent;

@protocol MPBackendControllerDelegate;

typedef NS_ENUM(NSUInteger, MPProfileChange) {
    MPProfileChangeSignup = 1,
    MPProfileChangeLogin,
    MPProfileChangeLogout,
    MPProfileChangeUpdate,
    MPProfileChangeDelete
};

typedef NS_ENUM(NSUInteger, MPExecStatus) {
    MPExecStatusSuccess = 0,
    MPExecStatusFail,
    MPExecStatusMissingParam,
    MPExecStatusDisabledRemotely,
    MPExecStatusEnabledRemotely,
    MPExecStatusOptOut,
    MPExecStatusDataBeingFetched,
    MPExecStatusInvalidDataType,
    MPExecStatusDataBeingUploaded,
    MPExecStatusServerBusy,
    MPExecStatusItemNotFound,
    MPExecStatusDisabledInSettings,
    MPExecStatusDelayedExecution,
    MPExecStatusContinuedDelayedExecution,
    MPExecStatusSDKNotStarted,
    MPExecStatusNoConnectivity
};

typedef NS_ENUM(NSUInteger, MPInitializationStatus) {
    MPInitializationStatusNotStarted = 0,
    MPInitializationStatusStarting,
    MPInitializationStatusStarted
};

@interface MPBackendController : NSObject

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, weak) id<MPBackendControllerDelegate> delegate;
@property (nonatomic, unsafe_unretained, readwrite) NSTimeInterval sessionTimeout;
@property (nonatomic, unsafe_unretained, readwrite) NSTimeInterval uploadInterval;
@property (nonatomic, unsafe_unretained, readonly) MPInitializationStatus initializationStatus;

- (instancetype)initWithDelegate:(id<MPBackendControllerDelegate>)delegate __attribute__((objc_designated_initializer));
- (MPExecStatus)beginLocationTrackingWithAccuracy:(CLLocationAccuracy)accuracy distanceFilter:(CLLocationDistance)distance authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest;
- (MPExecStatus)endLocationTracking;
- (void)beginSession:(void (^)(MPSession *session, MPSession *previousSession, MPExecStatus execStatus))completionHandler;
- (void)endSession;
- (void)beginTimedEvent:(MPEvent *)event attempt:(NSUInteger)attempt completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler;
- (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value error:(out NSError *__autoreleasing *)error;
- (MPEvent *)eventWithName:(NSString *)eventName;
- (NSString *)execStatusDescription:(MPExecStatus)execStatus;
- (MPExecStatus)fetchSegments:(NSTimeInterval)timeout endpointId:(NSString *)endpointId completionHandler:(void (^)(NSArray *segments, NSTimeInterval elapsedTime, NSError *error))completionHandler;
- (NSNumber *)incrementSessionAttribute:(MPSession *)session key:(NSString *)key byValue:(NSNumber *)value;
- (NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value;
- (void)leaveBreadcrumb:(MPEvent *)event attempt:(NSUInteger)attempt completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler;
- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent attempt:(NSUInteger)attempt completionHandler:(void (^)(MPCommerceEvent *commerceEvent, MPExecStatus execStatus))completionHandler;
- (void)logError:(NSString *)message exception:(NSException *)exception topmostContext:(id)topmostContext eventInfo:(NSDictionary *)eventInfo attempt:(NSUInteger)attempt completionHandler:(void (^)(NSString *message, MPExecStatus execStatus))completionHandler;
- (void)logEvent:(MPEvent *)event attempt:(NSUInteger)attempt completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler;
- (void)logNetworkPerformanceMeasurement:(MPNetworkPerformance *)networkPerformance attempt:(NSUInteger)attempt completionHandler:(void (^)(MPNetworkPerformance *networkPerformance, MPExecStatus execStatus))completionHandler;
- (void)logScreen:(MPEvent *)event attempt:(NSUInteger)attempt completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler;
- (void)profileChange:(MPProfileChange)profile attempt:(NSUInteger)attempt completionHandler:(void (^)(MPProfileChange profile, MPExecStatus execStatus))completionHandler;
- (void)setOptOut:(BOOL)optOutStatus attempt:(NSUInteger)attempt completionHandler:(void (^)(BOOL optOut, MPExecStatus execStatus))completionHandler;
- (MPExecStatus)setSessionAttribute:(MPSession *)session key:(NSString *)key value:(id)value;
- (void)setUserAttribute:(NSString *)key value:(id)value attempt:(NSUInteger)attempt completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler;
- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType attempt:(NSUInteger)attempt completionHandler:(void (^)(NSString *identityString, MPUserIdentity identityType, MPExecStatus execStatus))completionHandler;
- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret firstRun:(BOOL)firstRun installationType:(MPInstallationType)installationType proxyAppDelegate:(BOOL)proxyAppDelegate completionHandler:(dispatch_block_t)completionHandler;
- (void)resetTimer;
- (MPExecStatus)upload;
// Media Tracking
- (void)beginPlaying:(MPMediaTrack *)mediaTrack attempt:(NSUInteger)attempt completionHandler:(void (^)(MPMediaTrack *mediaTrack, MPExecStatus execStatus))completionHandler;
- (MPExecStatus)discardMediaTrack:(MPMediaTrack *)mediaTrack;
- (void)endPlaying:(MPMediaTrack *)mediaTrack attempt:(NSUInteger)attempt completionHandler:(void (^)(MPMediaTrack *mediaTrack, MPExecStatus execStatus))completionHandler;
- (void)logMetadataWithMediaTrack:(MPMediaTrack *)mediaTrack attempt:(NSUInteger)attempt completionHandler:(void (^)(MPMediaTrack *mediaTrack, MPExecStatus execStatus))completionHandler;
- (void)logTimedMetadataWithMediaTrack:(MPMediaTrack *)mediaTrack attempt:(NSUInteger)attempt completionHandler:(void (^)(MPMediaTrack *mediaTrack, MPExecStatus execStatus))completionHandler;
- (NSArray *)mediaTracks;
- (MPMediaTrack *)mediaTrackWithChannel:(NSString *)channel;
- (void)updatePlaybackPosition:(MPMediaTrack *)mediaTrack attempt:(NSUInteger)attempt completionHandler:(void (^)(MPMediaTrack *mediaTrack, MPExecStatus execStatus))completionHandler;

@end

@protocol MPBackendControllerDelegate <NSObject>
- (void)forwardLogInstall;
- (void)forwardLogUpdate;
- (void)sessionDidBegin:(MPSession *)session;
- (void)sessionDidEnd:(MPSession *)session;
@end

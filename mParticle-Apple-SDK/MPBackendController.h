//
//  MPBackend.h
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

#import "MPEnums.h"
#import "MPNetworkCommunication.h"

#if TARGET_OS_IOS == 1
    #import "MPNotificationController.h"
    #import <CoreLocation/CoreLocation.h>

    @class MParticleUserNotification;
#endif

@class MPCommerceEvent;
@class MPDataModelAbstract;
@class MPEvent;
@class MPEventAbstract;
@class MPNetworkPerformance;
@class MPNotificationController;
@class MPMessage;
@class MPSession;

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
#if TARGET_OS_IOS == 1
<MPNotificationControllerDelegate>

@property (nonatomic, strong, nonnull) MPNotificationController *notificationController;
#endif

@property (nonatomic, weak, nullable) id<MPBackendControllerDelegate> delegate;
@property (nonatomic, strong, nullable) NSMutableSet<MPEvent *> *eventSet;
@property (nonatomic, strong, nullable) MPNetworkCommunication *networkCommunication;
@property (nonatomic, strong, nullable) MPSession *session;
@property (nonatomic, unsafe_unretained, readwrite) NSTimeInterval sessionTimeout;
@property (nonatomic, unsafe_unretained, readonly) MPInitializationStatus initializationStatus;
@property (nonatomic, unsafe_unretained) NSTimeInterval uploadInterval;
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, id> *userAttributes;

- (nonnull instancetype)initWithDelegate:(nonnull id<MPBackendControllerDelegate>)delegate;
- (void)beginSession:(void (^ _Nullable)(MPSession * _Nullable session, MPSession * _Nullable previousSession, MPExecStatus execStatus))completionHandler;
- (void)endSession:(nonnull MPSession *)session;
- (void)beginTimedEvent:(nonnull MPEvent *)event attempt:(NSUInteger)attempt completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (nullable MPEvent *)eventWithName:(nonnull NSString *)eventName;
- (nullable NSString *)execStatusDescription:(MPExecStatus)execStatus;
- (MPExecStatus)fetchSegments:(NSTimeInterval)timeout endpointId:(nullable NSString *)endpointId completionHandler:(void (^ _Nonnull)(NSArray * _Nullable segments, NSTimeInterval elapsedTime, NSError * _Nullable error))completionHandler;
- (nullable NSNumber *)incrementUserAttribute:(nonnull NSString *)key byValue:(nonnull NSNumber *)value;
- (void)logError:(nullable NSString *)message exception:(nullable NSException *)exception topmostContext:(nullable id)topmostContext eventInfo:(nullable NSDictionary *)eventInfo attempt:(NSUInteger)attempt completionHandler:(void (^ _Nonnull)(NSString * _Nullable message, MPExecStatus execStatus))completionHandler;
- (void)logEvent:(nonnull MPEventAbstract *)event attempt:(NSUInteger)attempt completionHandler:(void (^ _Nonnull)(MPEventAbstract * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)logNetworkPerformanceMeasurement:(nonnull MPNetworkPerformance *)networkPerformance attempt:(NSUInteger)attempt completionHandler:(void (^ _Nullable)(MPNetworkPerformance * _Nonnull networkPerformance, MPExecStatus execStatus))completionHandler;
- (void)profileChange:(MPProfileChange)profile attempt:(NSUInteger)attempt completionHandler:(void (^ _Nonnull)(MPProfileChange profile, MPExecStatus execStatus))completionHandler;
- (void)setOptOut:(BOOL)optOutStatus attempt:(NSUInteger)attempt completionHandler:(void (^ _Nonnull)(BOOL optOut, MPExecStatus execStatus))completionHandler;
- (void)setUserAttribute:(nonnull NSString *)key value:(nullable id)value attempt:(NSUInteger)attempt completionHandler:(void (^ _Nullable)(NSString * _Nonnull key, id _Nullable value, MPExecStatus execStatus))completionHandler;
- (void)setUserAttribute:(nonnull NSString *)key values:(nullable NSArray<NSString *> *)values attempt:(NSUInteger)attempt completionHandler:(void (^ _Nullable)(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus))completionHandler;
- (void)setUserIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType attempt:(NSUInteger)attempt completionHandler:(void (^ _Nonnull)(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus))completionHandler;
- (void)startWithKey:(nonnull NSString *)apiKey secret:(nonnull NSString *)secret firstRun:(BOOL)firstRun installationType:(MPInstallationType)installationType proxyAppDelegate:(BOOL)proxyAppDelegate completionHandler:(dispatch_block_t _Nonnull)completionHandler;
- (void)saveMessage:(nonnull MPDataModelAbstract *)abstractMessage updateSession:(BOOL)updateSession;
- (MPExecStatus)uploadWithCompletionHandler:(void (^ _Nullable)())completionHandler;

#if TARGET_OS_IOS == 1
- (MPExecStatus)beginLocationTrackingWithAccuracy:(CLLocationAccuracy)accuracy distanceFilter:(CLLocationDistance)distance authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest;
- (MPExecStatus)endLocationTracking;
- (void)handleDeviceTokenNotification:(nonnull NSNotification *)notification;
- (void)receivedUserNotification:(nonnull MParticleUserNotification *)userNotification;
#endif

@end

@protocol MPBackendControllerDelegate <NSObject>
- (void)forwardLogInstall;
- (void)forwardLogUpdate;
- (void)sessionDidBegin:(nonnull MPSession *)session;
- (void)sessionDidEnd:(nonnull MPSession *)session;
@end

#ifndef mParticle_Apple_SDK_MPKitProtocol_h
#define mParticle_Apple_SDK_MPKitProtocol_h

#import <Foundation/Foundation.h>
#import "MPEnums.h"
#import "MPForwardRecord.h"
#import <UIKit/UIKit.h>

#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    #import <CoreLocation/CoreLocation.h>
#endif
#endif

@class MPCommerceEvent;
@class MPBaseEvent;
@class MPEvent;
@class MPKitExecStatus;
@class MPKitAPI;
@class MPConsentState;
@class FilteredMParticleUser;
@class FilteredMPIdentityApiRequest;
@class MPRoktEmbeddedView;
@class MPRoktConfig;
@class MPRoktEventCallback;

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    @class UNUserNotificationCenter;
    @class UNNotification;
    @class UNNotificationResponse;
#endif


@protocol MPKitProtocol <NSObject>
#pragma mark - Required methods
@property (nonatomic, readonly) BOOL started;

- (nonnull MPKitExecStatus *)didFinishLaunchingWithConfiguration:(nonnull NSDictionary *)configuration;

// Value ignored for sideloaded kits, so a value like -1 is recommended, sideloadedKitCode is used instead which is set by the SDK
+ (nonnull NSNumber *)kitCode;

#pragma mark - Optional methods
@optional

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, strong, nullable, readonly) id providerKitInstance;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;

// Only used for sideloaded kits
@property (nonatomic, strong, nonnull) NSNumber *sideloadedKitCode;

#pragma mark Kit lifecycle
- (void)start;
- (void)stop;

#pragma mark Application
- (nonnull MPKitExecStatus *)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray * _Nullable restorableObjects))restorationHandler;
- (nonnull MPKitExecStatus *)didUpdateUserActivity:(nonnull NSUserActivity *)userActivity;
- (nonnull MPKitExecStatus *)didBecomeActive;
- (nonnull MPKitExecStatus *)failedToRegisterForUserNotifications:(nullable NSError *)error;
- (nonnull MPKitExecStatus *)handleActionWithIdentifier:(nonnull NSString *)identifier forRemoteNotification:(nonnull NSDictionary *)userInfo;
- (nonnull MPKitExecStatus *)handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(nonnull NSDictionary *)userInfo withResponseInfo:(nonnull NSDictionary *)responseInfo;
- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url options:(nullable NSDictionary<NSString *, id> *)options;
- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nullable id)annotation;
- (nonnull MPKitExecStatus *)receivedUserNotification:(nonnull NSDictionary *)userInfo;
- (nonnull MPKitExecStatus *)setDeviceToken:(nonnull NSData *)deviceToken;

#pragma mark User Notifications
#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center willPresentNotification:(nonnull UNNotification *)notification API_AVAILABLE(ios(10.0));
- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response API_AVAILABLE(ios(10.0));
#endif

#pragma mark Location tracking
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
- (nonnull MPKitExecStatus *)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter;
- (nonnull MPKitExecStatus *)endLocationTracking;
- (nonnull MPKitExecStatus *)setLocation:(nonnull CLLocation *)location;
#endif
#endif

#pragma mark Session management
- (nonnull MPKitExecStatus *)beginSession;
- (nonnull MPKitExecStatus *)endSession;

#pragma mark User attributes and identities
- (nonnull MPKitExecStatus *)incrementUserAttribute:(nonnull NSString *)key byValue:(nonnull NSNumber *)value;
- (nonnull MPKitExecStatus *)removeUserAttribute:(nonnull NSString *)key;
- (nonnull MPKitExecStatus *)setUserAttribute:(nonnull NSString *)key value:(nonnull id)value;
- (nonnull MPKitExecStatus *)setUserAttribute:(nonnull NSString *)key values:(nonnull NSArray *)values;
- (nonnull MPKitExecStatus *)setUserIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType;
- (nonnull MPKitExecStatus *)setUserTag:(nonnull NSString *)tag;

- (nonnull MPKitExecStatus *)onIncrementUserAttribute:(nonnull FilteredMParticleUser *)user;
- (nonnull MPKitExecStatus *)onRemoveUserAttribute:(nonnull FilteredMParticleUser *)user;
- (nonnull MPKitExecStatus *)onSetUserAttribute:(nonnull FilteredMParticleUser *)user;
- (nonnull MPKitExecStatus *)onSetUserTag:(nonnull FilteredMParticleUser *)user;

- (nonnull MPKitExecStatus *)onIdentifyComplete:(nonnull FilteredMParticleUser *)user request:(nonnull FilteredMPIdentityApiRequest *)request;
- (nonnull MPKitExecStatus *)onLoginComplete:(nonnull FilteredMParticleUser *)user request:(nonnull FilteredMPIdentityApiRequest *)request;
- (nonnull MPKitExecStatus *)onLogoutComplete:(nonnull FilteredMParticleUser *)user request:(nonnull FilteredMPIdentityApiRequest *)request;
- (nonnull MPKitExecStatus *)onModifyComplete:(nonnull FilteredMParticleUser *)user request:(nonnull FilteredMPIdentityApiRequest *)request;

#pragma mark Consent state
- (nonnull MPKitExecStatus *)setConsentState:(nullable MPConsentState *)state;

#pragma mark e-Commerce
- (nonnull MPKitExecStatus *)logCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent __attribute__ ((deprecated));
- (nonnull MPKitExecStatus *)logLTVIncrease:(double)increaseAmount event:(nonnull MPEvent *)event;

#pragma mark Events
- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event;
- (nonnull MPKitExecStatus *)logEvent:(nonnull MPEvent *)event __attribute__ ((deprecated));
- (nonnull MPKitExecStatus *)logInstall;
- (nonnull MPKitExecStatus *)logout;
- (nonnull MPKitExecStatus *)logScreen:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)logUpdate;
- (nonnull MPKitExecStatus *)setATTStatus:(MPATTAuthorizationStatus)status withATTStatusTimestampMillis:(nullable NSNumber *)attStatusTimestampMillis;

#pragma mark Timed events
- (nonnull MPKitExecStatus *)beginTimedEvent:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)endTimedEvent:(nonnull MPEvent *)event;

#pragma mark Errors and exceptions
- (nonnull MPKitExecStatus *)leaveBreadcrumb:(nonnull MPEvent *)event;
- (nonnull MPKitExecStatus *)logError:(nullable NSString *)message eventInfo:(nullable NSDictionary *)eventInfo;
- (nonnull MPKitExecStatus *)logException:(nonnull NSException *)exception;

#pragma mark Assorted
- (nonnull MPKitExecStatus *)setKitAttribute:(nonnull NSString *)key value:(nullable id)value;
- (nonnull MPKitExecStatus *)setOptOut:(BOOL)optOut;
- (nullable NSString *)surveyURLWithUserAttributes:(nonnull NSDictionary *)userAttributes;
- (BOOL) shouldDelayMParticleUpload;
- (nonnull NSArray<MPForwardRecord *> *)logBatch:(nonnull NSDictionary *)batch;

#pragma mark First Party Kits
- (nonnull MPKitExecStatus *)executeWithViewName:(NSString * _Nullable)viewName
                                      attributes:(NSDictionary<NSString *, NSString *> * _Nonnull)attributes
                                      placements:(NSDictionary<NSString *, MPRoktEmbeddedView *> * _Nullable)placements
                                          config:(MPRoktConfig * _Nullable)config
                                       callbacks:(MPRoktEventCallback * _Nullable)callbacks
                                    filteredUser:(FilteredMParticleUser * _Nonnull)filteredUser;

@end

#endif

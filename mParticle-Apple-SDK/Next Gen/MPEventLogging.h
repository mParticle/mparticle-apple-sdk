//
//  MPEventLogging.h
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import <Foundation/Foundation.h>
#import "MPComponent.h"

@class MPEvent;
@class MPBaseEvent;
@class MPCommerceEvent;
@class MPNetworkPerformance;

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
    MPExecStatusNoConnectivity
};

NS_ASSUME_NONNULL_BEGIN

@interface MPEventLogging : NSObject <MPComponent>

@property (nonatomic, strong, nullable) NSMutableSet<MPEvent *> *eventSet;

- (void)leaveBreadcrumb:(nonnull MPEvent *)event completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)logError:(nullable NSString *)message exception:(nullable NSException *)exception topmostContext:(nullable id)topmostContext eventInfo:(nullable NSDictionary *)eventInfo completionHandler:(void (^ _Nonnull)(NSString * _Nullable message, MPExecStatus execStatus))completionHandler;
- (void)logCrash:(nullable NSString *)message stackTrace:(nullable NSString *)stackTrace plCrashReport:(nonnull NSString *)plCrashReport completionHandler:(void (^ _Nonnull)(NSString * _Nullable message, MPExecStatus execStatus)) completionHandler;
- (void)logBaseEvent:(nonnull MPBaseEvent *)event completionHandler:(void (^ _Nonnull)(MPBaseEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)logEvent:(nonnull MPEvent *)event completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)logCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent completionHandler:(void (^ _Nonnull)(MPCommerceEvent * _Nonnull commerceEvent, MPExecStatus execStatus))completionHandler;
- (void)logNetworkPerformanceMeasurement:(nonnull MPNetworkPerformance *)networkPerformance completionHandler:(void (^ _Nullable)(MPNetworkPerformance * _Nonnull networkPerformance, MPExecStatus execStatus))completionHandler;
- (void)logScreen:(nonnull MPEvent *)event completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (nullable MPEvent *)eventWithName:(nonnull NSString *)eventName;

@end

NS_ASSUME_NONNULL_END

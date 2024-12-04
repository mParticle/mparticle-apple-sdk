#import "MPEnums.h"
#import "MPIConstants.h"

#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    #import <CoreLocation/CoreLocation.h>
#endif
#endif

@class MPSession;
@class MPCommerceEvent;
@class MPUserAttributeChange;
@class MPUserIdentityChange_PRIVATE;
@class MPMessage;

@interface MPMessageBuilder : NSObject

@property (nonatomic, strong, readonly, nonnull) NSString *messageType;
@property (nonatomic, strong, readonly, nullable) MPSession *session;
@property (nonatomic, strong, readonly, nonnull) NSDictionary *messageInfo;
@property (nonatomic, readonly) NSTimeInterval timestamp;
@property (nonatomic, strong, readonly, nullable) NSString *dataPlanId;
@property (nonatomic, strong, readonly, nullable) NSNumber *dataPlanVersion;

+ (NSString *_Nullable)stringForMessageType:(MPMessageType)type;
+ (MPMessageType)messageTypeForString:(NSString *_Nonnull)string;
- (nullable instancetype)initWithMessageType:(MPMessageType)messageType
                                    session:(nullable MPSession *)session;
- (nullable instancetype)initWithMessageType:(MPMessageType)messageType
                                    session:(nullable MPSession *)session
                                messageInfo:(nullable NSDictionary<NSString *, id> *)messageInfo;
- (nullable instancetype)initWithMessageType:(MPMessageType)messageType
                                     session:(nullable MPSession *)session
                          userIdentityChange:(nonnull MPUserIdentityChange_PRIVATE *)userIdentityChange;
- (nullable instancetype)initWithMessageType:(MPMessageType)messageType
                                     session:(nonnull MPSession *)session
                         userAttributeChange:(nonnull MPUserAttributeChange *)userAttributeChange;

- (void)launchInfo:(nonnull NSDictionary *)launchInfo;
- (void)timestamp:(NSTimeInterval)timestamp;
- (void)stateTransition:(BOOL)sessionFinalized previousSession:(nullable MPSession *)previousSession;
- (nonnull MPMessage *)build;

#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
- (void)location:(nonnull CLLocation *)location;
#endif
#endif

@end

extern NSString * _Nonnull const launchInfoStringFormat;
extern NSString * _Nonnull const kMPHorizontalAccuracyKey;
extern NSString * _Nonnull const kMPLatitudeKey;
extern NSString * _Nonnull const kMPLongitudeKey;
extern NSString * _Nonnull const kMPVerticalAccuracyKey;
extern NSString * _Nonnull const kMPRequestedAccuracy;
extern NSString * _Nonnull const kMPDistanceFilter;
extern NSString * _Nonnull const kMPIsForegroung;

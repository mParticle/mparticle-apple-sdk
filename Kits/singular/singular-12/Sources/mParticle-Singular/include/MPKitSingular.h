#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
#else
    #import "mParticle.h"
#endif

#define SINGULAR_DEEPLINK_KEY @"singular_deeplink"
#define SINGULAR_PASSTHROUGH_KEY @"singular_passthrough"
#define SINGULAR_IS_DEFERRED_KEY @"singular_is_deferred"
#define SINGULAR_QUERY_PARAMS @"singular_query_params"

@interface MPKitSingular : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *userAttributes;
@property (nonatomic, strong, nullable) NSArray<NSDictionary<NSString *, id> *> *userIdentities;

+ (void)setSKANOptions:(BOOL)skAdNetworkEnabled isManualSkanConversionManagementMode:(BOOL)manualMode withWaitForTrackingAuthorizationWithTimeoutInterval:(NSNumber* _Nullable)waitTrackingAuthorizationWithTimeoutInterval withConversionValueUpdatedHandler:(void(^_Nullable)(NSInteger))conversionValueUpdatedHandler;

+ (void)setDeviceAttributionCallback:(void(^_Nullable)(NSDictionary*_Nullable))deviceAttributionHandler;

+ (void)setCustomSDID:(NSString *_Nullable)customSdid sdidReceivedHandler:(void(^_Nullable)(NSString *_Nullable))sdidReceivedHandler didSetSdidHandler:(void(^_Nullable)(NSString *_Nullable))setSdidHandler;

@end

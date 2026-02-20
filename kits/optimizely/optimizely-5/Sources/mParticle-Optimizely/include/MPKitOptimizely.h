#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
#else
    #import "mParticle.h"
#endif

@class OptimizelyClient;

extern NSString * _Nonnull const MPKitOptimizelyEventName;
extern NSString * _Nonnull const MPKitOptimizelyEventKeyValue;
extern NSString * _Nonnull const MPKitOptimizelyCustomUserId;

@interface MPKitOptimizely : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;

- (NSString *_Nullable)activateWithExperimentKey:(nonnull NSString *)key customUserId:(nullable NSString *)customUserID;
+ (OptimizelyClient *_Nullable)optimizelyClient;
+ (void)setOptimizelyClient:(OptimizelyClient *_Nullable)client;

@end

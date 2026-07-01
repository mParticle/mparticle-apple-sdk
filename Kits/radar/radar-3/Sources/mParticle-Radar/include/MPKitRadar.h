#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
@import mParticle_Apple_SDK;
#elif __has_feature(objc_modules)
@import mParticle_Apple_SDK_ObjC;
#else
#import <mParticle_Apple_SDK/mParticle.h>
#endif

@interface MPKitRadar : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *userAttributes;
@property (nonatomic, strong, nullable) NSArray<NSDictionary<NSString *, id> *> *userIdentities;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;

@end

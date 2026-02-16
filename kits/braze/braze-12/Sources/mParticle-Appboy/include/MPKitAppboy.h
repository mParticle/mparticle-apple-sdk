#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
#else
    #import "mParticle.h"
#endif

#if defined(__has_include) && __has_include(<BrazeKit/BrazeKit-Swift.h>)
    #import <BrazeKit/BrazeKit-Swift.h>
#else
    #import BrazeKit-Swift.h
#endif


@interface MPKitAppboy : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;

#if TARGET_OS_IOS
+ (void)setInAppMessageControllerDelegate:(nonnull id)delegate;
+ (void)setShouldDisableNotificationHandling:(BOOL)isDisabled;
#endif
+ (void)setURLDelegate:(nonnull id)delegate;
+ (void)setBrazeInstance:(nonnull id)instance;
+ (void)setBrazeLocationProvider:(nonnull id)instance;
+ (void)setBrazeTrackingPropertyAllowList:(nonnull NSSet<BRZTrackingProperty*> *)allowList;
@end

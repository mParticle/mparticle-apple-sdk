#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
#else
    #import "mParticle.h"
#endif

extern NSString * _Nonnull const MPKitAdjustAttributionResultKey;
extern NSString * _Nonnull const MPKitAdjustErrorKey;
extern NSString * _Nonnull const MPKitAdjustErrorDomain;

@interface MPKitAdjust : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;

+ (void)setDelegate:(id _Nonnull)delegate;

@end

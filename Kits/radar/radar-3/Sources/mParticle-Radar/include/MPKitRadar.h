#import <Foundation/Foundation.h>
@import mParticle_Apple_SDK_ObjC;

@interface MPKitRadar : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *userAttributes;
@property (nonatomic, strong, nullable) NSArray<NSDictionary<NSString *, id> *> *userIdentities;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;

@end

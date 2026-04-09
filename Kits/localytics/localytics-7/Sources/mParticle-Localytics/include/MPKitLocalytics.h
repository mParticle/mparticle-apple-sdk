#import <Foundation/Foundation.h>
@import mParticle_Apple_SDK_ObjC;

@interface MPKitLocalytics : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;

@end

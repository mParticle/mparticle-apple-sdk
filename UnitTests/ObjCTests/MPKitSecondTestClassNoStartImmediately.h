#import <Foundation/Foundation.h>
#import "MPKitProtocol.h"

@interface MPKitSecondTestClassNoStartImmediately : NSObject <MPKitProtocol>

@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *userAttributes;
@property (nonatomic, strong, nullable) NSArray<NSDictionary<NSString *, id> *> *userIdentities;

- (nonnull MPKitExecStatus *)didFinishLaunchingWithConfiguration:(nonnull NSDictionary *)configuration;
+ (nonnull NSNumber *)kitCode;

@end

#import <Foundation/Foundation.h>
#import "MPKitProtocol.h"

@interface MPKitTestClass : NSObject <MPKitProtocol>

@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *userAttributes;
@property (nonatomic, strong, nullable) NSArray<NSDictionary<NSString *, id> *> *userIdentities;
@property (nonatomic, strong, nonnull) NSDictionary *configuration;

- (nonnull MPKitExecStatus *)didFinishLaunchingWithConfiguration:(nonnull NSDictionary *)configuration;
+ (nonnull NSNumber *)kitCode;

@end

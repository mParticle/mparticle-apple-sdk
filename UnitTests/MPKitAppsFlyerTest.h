#import "MPKitExecStatus.h"
#import "MPKitProtocol.h"
#import <Foundation/Foundation.h>

@interface MPKitAppsFlyerTest : NSObject <MPKitProtocol>

@property(nonatomic, strong, nonnull) NSDictionary *configuration;
@property(nonatomic, unsafe_unretained, readonly) BOOL started;

@end

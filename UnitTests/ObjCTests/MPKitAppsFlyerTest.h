#import <Foundation/Foundation.h>
#import "MPKitExecStatus.h"
#import "MPKitProtocol.h"

@interface MPKitAppsFlyerTest : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (atomic, readonly) BOOL started;

@end

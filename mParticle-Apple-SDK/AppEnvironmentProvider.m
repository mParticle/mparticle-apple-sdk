#import "AppEnvironmentProvider.h"

@implementation AppEnvironmentProvider

- (BOOL)isAppExtension {
#if TARGET_OS_IOS == 1
    return [[NSBundle mainBundle].bundlePath hasSuffix:@".appex"];
#else
    return NO;
#endif
}
@end

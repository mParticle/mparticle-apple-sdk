#import "MPKitContainer.h"

@interface MPKitContainer_PRIVATE (MParticlePrivate)

- (nullable NSDictionary *)launchConfigurationForKitCode:(nonnull NSNumber *)kitCode;
- (void)reconfigureKits;

@end

#import "SettingsProvider.h"
#import "MPIConstants.h"
@import mParticle_Apple_SDK_Swift;

@interface SettingsProvider ()
@property (nonatomic, strong) MPSettingsProviderPRIVATE *implementation;
@end

@implementation SettingsProvider

- (instancetype)init {
    self = [super init];
    if (self) {
        _implementation = [[MPSettingsProviderPRIVATE alloc] init];
    }
    return self;
}

- (NSMutableDictionary *)configSettings {
    return [self.implementation loadConfigSettingsFromBundle:NSBundle.mainBundle
                                                resourceName:kMPConfigPlist];
}

- (void)setConfigSettings:(NSMutableDictionary *)configSettings {
    self.implementation.configSettings = configSettings;
}

@end

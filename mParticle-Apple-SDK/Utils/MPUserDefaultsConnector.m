#import "MPUserDefaultsConnector.h"
#import "MParticleSwift.h"
#import "mParticle.h"

@import mParticle_Apple_SDK_Swift;

@interface MParticle ()

@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end

@interface MPUserDefaultsConnector()<MPUserDefaultsConnectorProtocol>

@end

@implementation MPUserDefaultsConnector

- (MPStateMachine_PRIVATE*)stateMachine {
    return MParticle.sharedInstance.stateMachine;
}

- (MPBackendController_PRIVATE*)backendController {
    return MParticle.sharedInstance.backendController;
}

- (MPIdentityApi*)identity {
    return MParticle.sharedInstance.identity;
}

+ (MPUserDefaults*)userDefaults {
    MPUserDefaultsConnector* connector = [[MPUserDefaultsConnector alloc] init];
    return [MPUserDefaults standardUserDefaultsWithConnector:connector];
}

- (MPLog*)logger {
    MParticle* mparticle = MParticle.sharedInstance;
    MPLog* logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
    logger.customLogger = mparticle.customLogger;
    return logger;
}

- (void)configureKits:(NSArray<NSDictionary *> *)kitConfigurations {
    [MParticle.sharedInstance.kitContainer_PRIVATE configureKits:kitConfigurations];
}


- (NSArray<NSDictionary *> *)deferredKitConfiguration {
    return MParticle.sharedInstance.deferredKitConfiguration_PRIVATE;
}

- (void)setDeferredKitConfiguration:(NSArray<NSDictionary *> *)deferredKitConfiguration {
    MParticle.sharedInstance.deferredKitConfiguration_PRIVATE = deferredKitConfiguration;
}

@end

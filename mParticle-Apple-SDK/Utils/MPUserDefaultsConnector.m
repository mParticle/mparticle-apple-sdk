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

- (void)configureCustomModules:(nullable NSArray<NSDictionary *> *)customModuleSettings {
    [MParticle.sharedInstance.stateMachine configureCustomModules:customModuleSettings];
}

- (void)configureRampPercentage:(nullable NSNumber *)rampPercentage {
    [MParticle.sharedInstance.stateMachine configureRampPercentage:rampPercentage];
}

- (void)configureTriggers:(nullable NSDictionary *)triggerDictionary {
    [MParticle.sharedInstance.stateMachine configureTriggers:triggerDictionary];
}

- (void)configureAliasMaxWindow:(nullable NSNumber *)aliasMaxWindow {
    [MParticle.sharedInstance.stateMachine configureAliasMaxWindow:aliasMaxWindow];
}

- (void)configureDataBlocking:(nullable NSDictionary *)blockSettings {
    [MParticle.sharedInstance.stateMachine configureDataBlocking:blockSettings];
}

- (NSNumber* __nullable)userId {
    return MParticle.sharedInstance.identity.currentUser.userId;
}

- (void)setAllowASR:(BOOL)allowASR {
    MParticle.sharedInstance.stateMachine.allowASR = allowASR;
}

- (void)setEnableAudienceAPI:(BOOL)enableAudienceAPI {
    MParticle.sharedInstance.stateMachine.enableAudienceAPI = enableAudienceAPI;
}

- (void)setExceptionHandlingMode:(nullable NSString*)exceptionHandlingMode {
    MParticle.sharedInstance.stateMachine.exceptionHandlingMode = exceptionHandlingMode;
}

- (void)setSessionTimeout: (NSTimeInterval)sessionTimeout {
    MParticle.sharedInstance.backendController.sessionTimeout = sessionTimeout;
}

- (void)setPushNotificationMode:(nonnull NSString*)pushNotificationMode {
    MParticle.sharedInstance.stateMachine.pushNotificationMode = pushNotificationMode;
}

- (void)setCrashMaxPLReportLength:(nonnull NSNumber*)crashMaxPLReportLength {
    MParticle.sharedInstance.stateMachine.crashMaxPLReportLength = crashMaxPLReportLength;
}

- (BOOL)isAppExtension {
    return [MPStateMachine_PRIVATE isAppExtension];
}

- (void)registerForRemoteNotifications {
    UIApplication* app = [MPApplication_PRIVATE sharedUIApplication];
    [app registerForRemoteNotifications];
}

- (void)unregisterForRemoteNotifications {
    UIApplication* app = [MPApplication_PRIVATE sharedUIApplication];
    [app unregisterForRemoteNotifications];
}

- (BOOL)canCreateConfiguration {
    return MParticle.sharedInstance.stateMachine != nil && MParticle.sharedInstance.backendController != nil;
}

@end

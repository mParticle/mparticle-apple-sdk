#import "MPUserDefaultsConnector.h"
#import "mParticle.h"
#import "../Kits/MPKitContainer+MParticlePrivate.h"
#import "MPPersistenceUtilities.h"
#import "MPIConstants.h"
#import "MPConsentSerialization.h"
#import "MPConsentState.h"
#import "MPPersistenceAdapter.h"
#import "../Kits/MPDataPlanFilter.h"

@import mParticle_Apple_SDK_Swift;

@interface MParticle ()

@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong, readonly) MPPersistenceAdapter *persistenceAdapter;
@property (nonatomic, readwrite) MPDataPlanOptions *dataPlanOptions;
@property (nonatomic, readwrite) MPDataPlanFilter *dataPlanFilter;

@end

// Re-declared from the deleted MPStateMachine.m: -setIdentity:identityType: is private to
// MParticleUser and only reachable through a class extension.
@interface MParticleUser ()
- (void)setIdentity:(nullable NSString *)identityString identityType:(MPIdentity)identityType;
@end

@interface MPUserDefaultsConnector()<MPUserDefaultsConnectorProtocol>

@end

@implementation MPPersistenceUtilities

+ (NSNumber *)mpId {
    return MPUserDefaults.storedMpId;
}

+ (void)setMpid:(NSNumber *)mpId {
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    userDefaults[@"mpid"] = mpId;
    [userDefaults synchronize];
}

+ (MPConsentState *)consentStateForMpid:(NSNumber *)mpid {
    NSString *string = [MPUserDefaultsConnector.userDefaults mpObjectForKey:kMPConsentStateKey userId:mpid];
    return string ? [MPConsentSerialization consentStateFromString:string] : nil;
}

+ (void)setConsentState:(MPConsentState *)state forMpid:(NSNumber *)mpid {
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    if (!state) {
        [userDefaults removeMPObjectForKey:kMPConsentStateKey userId:mpid];
    } else {
        NSString *string = [MPConsentSerialization stringFromConsentState:state];
        if (!string) {
            return;
        }
        [userDefaults setMPObject:string forKey:kMPConsentStateKey userId:mpid];
    }
    [userDefaults synchronize];
}

+ (MPConsentState *)deviceConsentState {
    NSString *string = [MPUserDefaultsConnector.userDefaults mpObjectForKey:kMPConsentDeviceStateKey userId:@0];
    return string ? [MPConsentSerialization consentStateFromString:string] : nil;
}

+ (void)setDeviceConsentState:(MPConsentState *)state {
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    if (!state) {
        [userDefaults removeMPObjectForKey:kMPConsentDeviceStateKey userId:@0];
    } else {
        NSString *string = [MPConsentSerialization stringFromConsentState:state];
        if (!string) {
            return;
        }
        [userDefaults setMPObject:string forKey:kMPConsentDeviceStateKey userId:@0];
    }
    [userDefaults synchronize];
}

+ (MPConsentState *)effectiveConsentStateForMpid:(NSNumber *)mpid {
    return self.deviceConsentState
        ?: (mpid != nil ? [self consentStateForMpid:mpid] : nil);
}

+ (NSInteger)maxBytesPerEvent:(NSString *)messageType {
    return [MPPersistenceSchemaPRIVATE maxBytesPerEventForMessageType:messageType];
}

+ (NSInteger)maxBytesPerBatch:(NSString *)messageType {
    return [MPPersistenceSchemaPRIVATE maxBytesPerBatchForMessageType:messageType];
}

@end

@implementation MPUserDefaultsConnector

// Non-extractable: the ObjC implementation of the already-Swift `MPUserDefaultsConnectorProtocol` — every method is pure glue to `MParticle.sharedInstance` ObjC-module internals the Swift module cannot import. The Swift-facing boundary is the protocol itself. Per docs/swift-migration/CONVERSION-RECIPE.md hard constraint.

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

// The ramp decision itself is Swift (+dataRampedApplyingRampPercentage:deviceIdentifier:). What
// stays here is building the MPDevice that supplies the identifier, which needs the identity API.
- (void)configureRampPercentage:(nullable NSNumber *)rampPercentage {
    NSString *deviceIdentifier = nil;
    if (!MPIsNull(rampPercentage) && rampPercentage.integerValue != 0) {
        MPDevice *device = [[MPDevice alloc] initWithStateMachine:(id<MPStateMachineMPDeviceProtocol>)self.stateMachine
                                                     userDefaults:(id<MPIdentityApiMPUserDefaultsProtocol>)MPUserDefaultsConnector.userDefaults
                                                         identity:(id<MPIdentityApiMPDeviceProtocol>)self.identity
                                                           logger:self.logger];
        deviceIdentifier = device.deviceIdentifier;
    }

    self.stateMachine.dataRamped = [MPStateMachine_PRIVATE dataRampedApplyingRampPercentage:rampPercentage
                                                                          deviceIdentifier:deviceIdentifier];
}

- (void)configureTriggers:(nullable NSDictionary *)triggerDictionary {
    (void)[MParticle.sharedInstance.stateMachine applyTriggers:triggerDictionary];
}

- (void)configureAliasMaxWindow:(nullable NSNumber *)aliasMaxWindow {
    [MParticle.sharedInstance.stateMachine configureAliasMaxWindow:aliasMaxWindow];
}

// MPDataPlanOptions and MPDataPlanFilter are both permanently Objective-C, so the data-blocking
// decision cannot follow the rest of the state machine into Swift. It lives here, in the boundary
// glue, next to its only caller.
- (void)configureDataBlocking:(nullable NSDictionary *)blockSettings {
    if (MPIsNull(blockSettings)) {
        blockSettings = @{};
    }

    // These come straight off the configuration response, so the shape is not ours to trust:
    // MPIsNull only rejects nil and NSNull, and keyed subscripting a non-dictionary raises
    // -[__NSCFConstantString objectForKeyedSubscript:] / -[NSConstantArray objectForKeyedSubscript:].
    NSDictionary *dataPlanSettings = blockSettings[kMPRemoteConfigDataPlanning];
    if (![dataPlanSettings isKindOfClass:[NSDictionary class]]) {
        if (MParticle.sharedInstance.dataPlanOptions == nil) {
            MParticle.sharedInstance.dataPlanFilter = nil;
        }
        return;
    }

    NSDictionary *dataBlockSettings = dataPlanSettings[kMPRemoteConfigDataPlanningBlock];
    if (![dataBlockSettings isKindOfClass:[NSDictionary class]]) {
        dataBlockSettings = @{};
    }

    MPDataPlanOptions *dataPlanOptions = [[MPDataPlanOptions alloc] init];
    dataPlanOptions.blockEvents = [dataBlockSettings[kMPRemoteConfigDataPlanningBlockUnplannedEvents] boolValue];
    dataPlanOptions.blockEventAttributes = [dataBlockSettings[kMPRemoteConfigDataPlanningBlockUnplannedEventAttributes] boolValue];
    dataPlanOptions.blockUserAttributes = [dataBlockSettings[kMPRemoteConfigDataPlanningBlockUnplannedUserAttributes] boolValue];
    dataPlanOptions.blockUserIdentities = [dataBlockSettings[kMPRemoteConfigDataPlanningBlockUnplannedIdentities] boolValue];
    dataPlanOptions.dataPlan = dataPlanSettings[kMPRemoteConfigDataPlanningDataPlanVersionValue];

    if (MParticle.sharedInstance.dataPlanOptions == nil) {
        MParticle.sharedInstance.dataPlanFilter = [[MPDataPlanFilter alloc] initWithDataPlanOptions:dataPlanOptions];
    }
}

// The consumer info and advertiser-id seams: both need Objective-C contract types the Swift state
// machine cannot import, so it calls back through this protocol.
- (MPConsumerInfo *)fetchOrCreateConsumerInfo {
    MPPersistenceAdapter *persistence = MParticle.sharedInstance.persistenceAdapter;
    MPConsumerInfo *consumerInfo = [persistence fetchConsumerInfoForUserId:[MPPersistenceUtilities mpId]];

    if (!consumerInfo) {
        consumerInfo = [[MPConsumerInfo alloc] init];
        [persistence saveConsumerInfo:consumerInfo];
    }

    return consumerInfo;
}

- (void)clearAdvertiserIdForAllUsers {
    NSArray<MParticleUser *> *users = MParticle.sharedInstance.identity.getAllUsers;
    for (MParticleUser *user in users) {
        [user setIdentity:nil identityType:MPIdentityIOSAdvertiserId];
    }
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

- (nonnull NSNumber*)mpId {
    return [MPPersistenceUtilities mpId];
}

- (nullable NSNumber*)configMaxAgeSeconds {
    return MParticle.sharedInstance.configMaxAgeSeconds;
}

- (BOOL)compressConfigurationStorage {
    return MParticle.sharedInstance.compressConfigurationStorage;
}

@end

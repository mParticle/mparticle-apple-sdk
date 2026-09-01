#import "MPKitAPI.h"
#import "MPForwardRecord.h"
#import "MPKitContainer+MParticlePrivate.h"
#import "MPKitExecStatus.h"
#import "MPEnums.h"
#import "MPKitConfiguration.h"
#import <UIKit/UIKit.h>
#import "MPPersistenceController.h"
#import "MPILogger.h"
#import "MPKitFilter.h"
#import "MPEvent.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPEventProjection.h"
#import "MPAttributeProjection.h"
#import "MPPromotion.h"
#import "MPPromotion+Dictionary.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPConsumerInfo.h"
#import "MPTransactionAttributes.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "MPIntegrationAttributes.h"
#import "mParticle.h"
#import "MPIConstants.h"
#import "MPDataPlanFilter.h"
#import "MPCCPAConsent.h"
#import "MPGDPRConsent.h"
#import "MPUserDefaultsConnector.h"

@import mParticle_Apple_SDK_Swift;

#define DEFAULT_ALLOCATION_FOR_KITS 2

NSString *const kitFileExtension = @"eks";

@interface MParticle ()
@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong, nonnull) MParticleOptions *options;
@property (nonatomic, strong) MPDataPlanFilter *dataPlanFilter;
- (void)executeKitsInitializedBlocks;
@end

@interface MPKitContainerExecutionAdapter : NSObject
@property (nonatomic, copy) void (^attributionCompletionHandler)(MPAttributionResult *, NSError *);
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MPAttributionResult *> *attributionInfo;
@property (nonatomic, strong) NSArray<NSDictionary *> *originalConfig;
@property (nonatomic, strong) NSArray<MPSideloadedKit *> *sideloadedKits;
@property (nonatomic, strong) NSArray<NSNumber *> *disabledKits;
@property (nonatomic) BOOL kitsInitialized;
- (void)flushSerializedKits;
- (void)removeAllSideloadedKits;
- (void)removeKitsFromRegistryInvalidForWorkspaceSwitch;
- (NSArray<id<MPExtensionKitProtocol>> *)activeKitsRegistry;
- (NSArray<NSNumber *> *)configuredKitsRegistry;
- (void)configureKits:(NSArray<NSDictionary *> *)kitsConfiguration;
- (NSArray<NSNumber *> *)supportedKits;
- (void)initializeKits;
- (void)forwardCommerceEventCall:(MPCommerceEvent *)commerceEvent;
- (void)forwardSDKCall:(SEL)selector event:(MPBaseEvent *)event parameters:(MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType userInfo:(NSDictionary *)userInfo;
- (void)forwardSDKCall:(SEL)selector userAttributeKey:(NSString *)key value:(id)value kitHandler:(void (^)(id<MPKitProtocol>, MPKitConfiguration *))kitHandler;
- (void)forwardSDKCall:(SEL)selector userAttributes:(NSDictionary *)userAttributes kitHandler:(void (^)(id<MPKitProtocol>, NSDictionary *, MPKitConfiguration *))kitHandler;
- (void)forwardSDKCall:(SEL)selector userIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType kitHandler:(void (^)(id<MPKitProtocol>, MPKitConfiguration *))kitHandler;
- (void)forwardSDKCall:(SEL)selector consentState:(MPConsentState *)state kitHandler:(void (^)(id<MPKitProtocol>, MPConsentState *, MPKitConfiguration *))kitHandler;
- (void)forwardSDKCall:(SEL)selector batch:(NSDictionary *)batch kitHandler:(void (^)(id<MPKitProtocol>, NSDictionary *, MPKitConfiguration *))kitHandler;
- (void)forwardIdentitySDKCall:(SEL)selector kitHandler:(void (^)(id<MPKitProtocol>, MPKitConfiguration *))kitHandler;
- (NSDictionary<NSString *, NSString *> *)integrationAttributesForKit:(NSNumber *)integrationId;
- (BOOL)shouldDelayUpload:(NSTimeInterval)maxWaitTime;
- (BOOL)hasKitBatchingKits;
- (NSDictionary *)launchConfigurationForKitCode:(NSNumber *)kitCode;
- (void)reconfigureKits;
@end

#pragma mark - Swift container Objective-C execution boundary

@implementation MPKitContainer_PRIVATE (MParticlePrivate)

- (MPKitContainerExecutionAdapter *)mp_executionAdapter {
    return (MPKitContainerExecutionAdapter *)self.executionAdapter;
}

- (void (^)(MPAttributionResult *, NSError *))attributionCompletionHandler {
    return self.mp_executionAdapter.attributionCompletionHandler;
}

- (void)setAttributionCompletionHandler:(void (^)(MPAttributionResult *, NSError *))attributionCompletionHandler {
    self.mp_executionAdapter.attributionCompletionHandler = attributionCompletionHandler;
}

- (NSMutableDictionary<NSNumber *, MPAttributionResult *> *)attributionInfo {
    return self.mp_executionAdapter.attributionInfo;
}

- (void)setAttributionInfo:(NSMutableDictionary<NSNumber *, MPAttributionResult *> *)attributionInfo {
    self.mp_executionAdapter.attributionInfo = attributionInfo;
}

- (NSArray<NSDictionary *> *)originalConfig {
    return self.mp_executionAdapter.originalConfig;
}

- (void)setOriginalConfig:(NSArray<NSDictionary *> *)originalConfig {
    self.mp_executionAdapter.originalConfig = originalConfig;
}

- (NSArray<MPSideloadedKit *> *)sideloadedKits {
    return self.mp_executionAdapter.sideloadedKits;
}

- (void)setSideloadedKits:(NSArray<MPSideloadedKit *> *)sideloadedKits {
    self.mp_executionAdapter.sideloadedKits = sideloadedKits;
}

- (NSArray<NSNumber *> *)disabledKits {
    return self.mp_executionAdapter.disabledKits;
}

- (void)setDisabledKits:(NSArray<NSNumber *> *)disabledKits {
    self.mp_executionAdapter.disabledKits = disabledKits;
}

- (BOOL)kitsInitialized {
    return self.mp_executionAdapter.kitsInitialized;
}

- (void)setKitsInitialized:(BOOL)kitsInitialized {
    self.mp_executionAdapter.kitsInitialized = kitsInitialized;
}

- (void)flushSerializedKits {
    [self.mp_executionAdapter flushSerializedKits];
}

- (void)removeAllSideloadedKits {
    [self.mp_executionAdapter removeAllSideloadedKits];
}

- (void)removeKitsFromRegistryInvalidForWorkspaceSwitch {
    [self.mp_executionAdapter removeKitsFromRegistryInvalidForWorkspaceSwitch];
}

- (NSArray<id<MPExtensionKitProtocol>> *)activeKitsRegistry {
    return [self.mp_executionAdapter activeKitsRegistry];
}

- (NSArray<NSNumber *> *)configuredKitsRegistry {
    return [self.mp_executionAdapter configuredKitsRegistry];
}

- (void)configureKits:(NSArray<NSDictionary *> *)kitsConfiguration {
    [self.mp_executionAdapter configureKits:kitsConfiguration];
}

- (NSArray<NSNumber *> *)supportedKits {
    return [self.mp_executionAdapter supportedKits];
}

- (void)initializeKits {
    [self.mp_executionAdapter initializeKits];
}

- (void)forwardCommerceEventCall:(MPCommerceEvent *)commerceEvent {
    [self.mp_executionAdapter forwardCommerceEventCall:commerceEvent];
}

- (void)forwardSDKCall:(SEL)selector
                 event:(MPBaseEvent *)event
            parameters:(MPForwardQueueParameters *)parameters
           messageType:(MPMessageType)messageType
              userInfo:(NSDictionary *)userInfo {
    [self.mp_executionAdapter forwardSDKCall:selector
                                       event:event
                                  parameters:parameters
                                 messageType:messageType
                                    userInfo:userInfo];
}

- (void)forwardSDKCall:(SEL)selector
      userAttributeKey:(NSString *)key
                 value:(id)value
            kitHandler:(void (^)(id<MPKitProtocol>, MPKitConfiguration *))kitHandler {
    [self.mp_executionAdapter forwardSDKCall:selector userAttributeKey:key value:value kitHandler:kitHandler];
}

- (void)forwardSDKCall:(SEL)selector
        userAttributes:(NSDictionary *)userAttributes
            kitHandler:(void (^)(id<MPKitProtocol>, NSDictionary *, MPKitConfiguration *))kitHandler {
    [self.mp_executionAdapter forwardSDKCall:selector userAttributes:userAttributes kitHandler:kitHandler];
}

- (void)forwardSDKCall:(SEL)selector
          userIdentity:(NSString *)identityString
          identityType:(MPUserIdentity)identityType
            kitHandler:(void (^)(id<MPKitProtocol>, MPKitConfiguration *))kitHandler {
    [self.mp_executionAdapter forwardSDKCall:selector
                                userIdentity:identityString
                                identityType:identityType
                                  kitHandler:kitHandler];
}

- (void)forwardSDKCall:(SEL)selector
          consentState:(MPConsentState *)state
            kitHandler:(void (^)(id<MPKitProtocol>, MPConsentState *, MPKitConfiguration *))kitHandler {
    [self.mp_executionAdapter forwardSDKCall:selector consentState:state kitHandler:kitHandler];
}

- (void)forwardSDKCall:(SEL)selector
                 batch:(NSDictionary *)batch
            kitHandler:(void (^)(id<MPKitProtocol>, NSDictionary *, MPKitConfiguration *))kitHandler {
    [self.mp_executionAdapter forwardSDKCall:selector batch:batch kitHandler:kitHandler];
}

- (void)forwardIdentitySDKCall:(SEL)selector
                    kitHandler:(void (^)(id<MPKitProtocol>, MPKitConfiguration *))kitHandler {
    [self.mp_executionAdapter forwardIdentitySDKCall:selector kitHandler:kitHandler];
}

- (NSDictionary<NSString *, NSString *> *)integrationAttributesForKit:(NSNumber *)integrationId {
    return [self.mp_executionAdapter integrationAttributesForKit:integrationId];
}

- (BOOL)shouldDelayUpload:(NSTimeInterval)maxWaitTime {
    return [self.mp_executionAdapter shouldDelayUpload:maxWaitTime];
}

- (BOOL)hasKitBatchingKits {
    return [self.mp_executionAdapter hasKitBatchingKits];
}

- (NSDictionary *)launchConfigurationForKitCode:(NSNumber *)kitCode {
    return [self.mp_executionAdapter launchConfigurationForKitCode:kitCode];
}

- (void)reconfigureKits {
    [self.mp_executionAdapter reconfigureKits];
}

@end

@interface MPKitAPI ()
- (id)initWithKitCode:(NSNumber *)integrationId;
@end

@interface MPForwardRecord ()
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus stateFlag:(BOOL)stateFlag;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus kitFilter:(nullable MPKitFilter *)kitFilter originalEvent:(nullable MPBaseEvent *)originalEvent;
- (nullable NSData *)dataRepresentation;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus;
@end

@interface MPKitRegister ()
- (nullable instancetype)initWithInstance:(nonnull NSObject<MPKitProtocol> *)instance kitCode:(nonnull NSNumber *)kitCode;
@end

static const NSInteger sideloadedKitCodeStartValue = 1000000000;

@interface MPKitContainerExecutionAdapter () {
    dispatch_semaphore_t kitsSemaphore;
    NSMutableDictionary<NSNumber *, MPBracket *> *brackets;
    NSInteger sideloadedKitCodeNextValue;
}

- (nullable NSArray<id<MPExtensionKitProtocol>> *)activeKitsRegistryWhenLocked;
@property (nonatomic, strong) NSMutableArray<MPForwardQueueItem *> *forwardQueue;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MPKitConfiguration *> *kitConfigurations;
@property (nonatomic, strong) NSDate *initializedTime;
@property (nonatomic, strong) MPIHasher *hasher;
@property (nonatomic, strong) MPKitValueTransformer *valueTransformer;
@property (nonatomic, strong) MPKitFilterEngine *filterEngine;
@property (nonatomic, strong) MPKitProjectionEngine *projectionEngine;
@property (nonatomic, strong) MPKitSelectorInvoker *selectorInvoker;
@end


@implementation MPKitContainerExecutionAdapter

+ (void)load {
    // Keep the adapter reachable when the SDK is linked statically and discovers it by name.
}

@synthesize kitsInitialized = _kitsInitialized;

- (instancetype)init {
    self = [super init];
    if (self) {
        _kitsInitialized = NO;
        _attributionInfo = [NSMutableDictionary dictionary];
        NSMutableDictionary *linkInfo = _attributionInfo;
        _initializedTime = [NSDate date];
        kitsSemaphore = dispatch_semaphore_create(1);
        brackets = [[NSMutableDictionary alloc] init];
        sideloadedKitCodeNextValue = sideloadedKitCodeStartValue;
        MParticle* mparticle = MParticle.sharedInstance;
        MPLog* logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
        logger.customLogger = mparticle.customLogger;
        _hasher = [[MPIHasher alloc] initWithLogger:logger];
        _valueTransformer = [[MPKitValueTransformer alloc] initWithLogger:logger];
        _filterEngine = [[MPKitFilterEngine alloc] initWithHasher:_hasher];
        _projectionEngine = [[MPKitProjectionEngine alloc] initWithHasher:_hasher valueTransformer:_valueTransformer];
        _selectorInvoker = [[MPKitSelectorInvoker alloc] initWithLogger:logger];
        _attributionCompletionHandler = [^void(MPAttributionResult *_Nullable attributionResult, NSError * _Nullable error) {
            if (attributionResult && attributionResult.kitCode) {
                linkInfo[attributionResult.kitCode] = attributionResult;
            }
            if ([MParticle sharedInstance].options.onAttributionComplete) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MParticle sharedInstance].options.onAttributionComplete(attributionResult, error);
                });
                
            }
        } copy];
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidBecomeActive:)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidFinishLaunching:)
                                   name:UIApplicationDidFinishLaunchingNotification
                                 object:nil];
    }
    
    return self;
}

#pragma mark Notification handlers
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
        SEL didBecomeActiveSelector = @selector(didBecomeActive);
        
        for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
            if ([kitRegister.wrapperInstance respondsToSelector:didBecomeActiveSelector]) {
                [kitRegister.wrapperInstance didBecomeActive];
            }
        }
    });
}

- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
        stateMachine.launchOptions = [notification userInfo];
        SEL launchOptionsSelector = @selector(setLaunchOptions:);
        SEL startSelector = @selector(start);
        
        for (id<MPExtensionKitProtocol>kitRegister in [MPKitContainer_PRIVATE registeredKits]) {
            id<MPKitProtocol> kitInstance = kitRegister.wrapperInstance;
            
            if (kitInstance && ![kitInstance started]) {
                if ([kitInstance respondsToSelector:launchOptionsSelector]) {
                    [kitInstance setLaunchOptions:stateMachine.launchOptions];
                }
                
                if ([kitInstance respondsToSelector:startSelector]) {
                    @try {
                        [kitInstance start];
                    }
                    @catch (NSException *exception) {
                        MPILogError(@"Exception thrown while starting kit (%@): %@", kitInstance, exception);
                    }
                }
            }
        }
    });
}

#pragma mark Private accessors
- (NSMutableArray<MPForwardQueueItem *> *)forwardQueue {
    if (_forwardQueue) {
        return _forwardQueue;
    }
    
    _forwardQueue = [[NSMutableArray alloc] initWithCapacity:DEFAULT_ALLOCATION_FOR_KITS];
    return _forwardQueue;
}

- (BOOL)kitsInitialized {
    return _kitsInitialized;
}

- (void)setKitsInitialized:(BOOL)kitsInitialized {
    _kitsInitialized = kitsInitialized;
    MPILogDebug(@"kitsInitialized set to: %@", kitsInitialized ? @"YES" : @"NO");
    
    if (_kitsInitialized) {
        // Dispatch to main queue to ensure thread safety with forwardQueue access.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self replayQueuedItems];
        });
        [[MParticle sharedInstance] executeKitsInitializedBlocks];
    }
}

#pragma mark Private methods

- (NSDictionary *)launchConfigurationForKitCode:(NSNumber *)kitCode {
    dispatch_semaphore_wait(kitsSemaphore, DISPATCH_TIME_FOREVER);
    NSArray<NSDictionary *> *kitConfigurations = [self.originalConfig copy];
    dispatch_semaphore_signal(kitsSemaphore);

    for (NSDictionary *kitConfiguration in kitConfigurations) {
        if ([kitConfiguration[@"id"] integerValue] == kitCode.integerValue) {
            return [kitConfiguration copy];
        }
    }
    return nil;
}

- (void)reconfigureKits {
    dispatch_semaphore_wait(kitsSemaphore, DISPATCH_TIME_FOREVER);
    NSArray<NSDictionary *> *kitConfigurations = [self.originalConfig copy];
    dispatch_semaphore_signal(kitsSemaphore);

    if (kitConfigurations) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureKits:kitConfigurations];
        });
    }
}

- (MPBracket *)bracketForKit:(NSNumber *)integrationId {
    NSAssert(integrationId != nil, @"Required parameter. It cannot be nil.");
    
    return brackets[integrationId];
}

- (void)flushSerializedKits {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id<MPExtensionKitProtocol>kitRegister in [MPKitContainer_PRIVATE registeredKits]) {
            [self freeKit:kitRegister.code];
        }
    });
}

- (void)freeKit:(NSNumber *)integrationId {
    NSAssert(integrationId != nil, @"Required parameter. It cannot be nil.");
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", integrationId];
    id<MPExtensionKitProtocol>kitRegister = [[[MPKitContainer_PRIVATE registeredKits] filteredSetUsingPredicate:predicate] anyObject];
    
    if (kitRegister.wrapperInstance) {
        if ([kitRegister.wrapperInstance respondsToSelector:@selector(stop)]) {
            [kitRegister.wrapperInstance stop];
        }
        
        kitRegister.wrapperInstance = nil;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
        NSString *kitPath = [stateMachineDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"EmbeddedKit%@.%@", integrationId, kitFileExtension]];
        
        if ([fileManager fileExistsAtPath:kitPath]) {
            [fileManager removeItemAtPath:kitPath error:nil];
        }
        
        NSDictionary *userInfo = @{mParticleKitInstanceKey:integrationId};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeInactiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    }
}

- (void)registerSideloadedKits {
    for (MPSideloadedKit *sideloadedKit in self.sideloadedKits) {
        // Get kit code from sideloaded kits range and increment it for the next kit
        NSNumber *kitCode = @(sideloadedKitCodeNextValue);
        sideloadedKitCodeNextValue++;
        if ([sideloadedKit.kitInstance respondsToSelector:@selector(sideloadedKitCode)]) {
            sideloadedKit.kitInstance.sideloadedKitCode = kitCode;
        } else {
            NSString *message = @"Sideloaded kits must implement the sideloadedKitCode property or they will not receive callbacks";
            NSAssert(NO, message);
            MPILogError(@"%@", message);
        }
        
        // Call through to the main registration method so any listeners will receive a callback
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithInstance:sideloadedKit.kitInstance kitCode:kitCode];
        [MParticle registerExtension:kitRegister];
        
        // Create default kit configuration
        NSDictionary *remoteConfigDict = [sideloadedKit getKitFilters];
        NSDictionary *configDict = @{@"id": kitCode, @"as": @{}, kMPRemoteConfigKitHashesKey: remoteConfigDict};
        MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configDict];
        self.kitConfigurations[kitConfiguration.integrationId] = kitConfiguration;
        
        // Finish registering kit and call its callbacks
        [self startKitRegister:kitRegister configuration:kitConfiguration];
    }
}

- (void)initializeKits {
    if (self.kitsInitialized) {
        MPILogDebug(@"initializeKits - already initialized, skipping");
        return;
    }
    
    [self registerSideloadedKits];
    
    NSArray<NSNumber *> *supportedKits = [self supportedKits];
    BOOL anyKitsIncluded = supportedKits != nil && supportedKits.count > 0;
    
    MPILogDebug(@"initializeKits - supportedKits: %lu", (unsigned long)(supportedKits ? supportedKits.count : 0));
    
    if (!anyKitsIncluded) {
        MPILogDebug(@"initializeKits - no kits included, marking as initialized");
        self.kitsInitialized = YES;
        return;
    }
    
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    
    NSArray *directoryContents = [userDefaults getKitConfigurations];
    
    MPILogDebug(@"initializeKits - cached kit configurations: %lu", (unsigned long)directoryContents.count);
    
    for (NSDictionary *kitConfigurationDictionary in directoryContents) {
        MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:kitConfigurationDictionary];
        BOOL shouldStartKit = ![self.filterEngine isKitDisabledWithIsDisabledKit:[_disabledKits containsObject:kitConfiguration.integrationId]
                                                                consentFilter:nil
                                                                      consent:nil];
        if (shouldStartKit) {
            self.kitConfigurations[kitConfiguration.integrationId] = kitConfiguration;
            [self startKit:kitConfiguration.integrationId configuration:kitConfiguration];
        }
    }
    if (self.kitConfigurations.count > 0) {
        MPILogDebug(@"initializeKits - loaded %lu kit(s) from cache", (unsigned long)self.kitConfigurations.count);
        self.kitsInitialized = YES;
    }
    
    if (self.sideloadedKits.count > 0) {
        self.kitsInitialized = YES;
    }
    
    if (!self.kitsInitialized) {
        MPILogWarning(@"initializeKits - kits registered (%lu) but no cached configurations found, waiting for server config",
                      (unsigned long)supportedKits.count);
    }
    if ([MParticle sharedInstance].stateMachine.logLevel >= MPILogLevelVerbose) {
        if (anyKitsIncluded) {
            NSMutableString *listOfKits = [[NSMutableString alloc] initWithString:@"Included kits: {"];
            for (NSNumber *supportedKit in supportedKits) {
                [listOfKits appendFormat:@"%@, ", [self nameForKitCode:supportedKit]];
            }
            
            [listOfKits deleteCharactersInRange:NSMakeRange(listOfKits.length - 2, 2)];
            [listOfKits appendString:@"}"];
            
            MPILogVerbose(@"%@", listOfKits);
        }
    }
}

- (nullable NSString *)nameForKitCode:(nonnull NSNumber *)integrationId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", integrationId];
    id<MPExtensionKitProtocol>kitRegister = [[[MPKitContainer_PRIVATE registeredKits] filteredSetUsingPredicate:predicate] anyObject];
    return kitRegister.name;
}

- (void)replayQueuedItems {
    if (!_forwardQueue || _forwardQueue.count == 0) {
        MPILogDebug(@"replayQueuedItems - no items to replay");
        return;
    }

    MPILogDebug(@"replayQueuedItems - replaying %lu queued item(s)", (unsigned long)_forwardQueue.count);
    NSArray<MPForwardQueueItem *> *forwardQueueCopy = [_forwardQueue copy];
    [_forwardQueue removeAllObjects];
    
    for (MPForwardQueueItem *forwardQueueItem in forwardQueueCopy) {
        switch (forwardQueueItem.queueItemType) {
            case MPQueueItemTypeEvent: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self forwardSDKCall:forwardQueueItem.selector event:forwardQueueItem.event parameters:nil messageType:forwardQueueItem.messageType userInfo:nil];
                });
                break;
            }
                
            case MPQueueItemTypeEcommerce: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self forwardCommerceEventCall:forwardQueueItem.commerceEvent];
                });
                break;
            }
                
            case MPQueueItemTypeGeneralPurpose: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self forwardSDKCall:forwardQueueItem.selector event:nil parameters:forwardQueueItem.queueParameters messageType:forwardQueueItem.messageType userInfo:nil];
                });
                break;
            }
        }
    }
}

- (MPKitFilterConfigurationSnapshot *)filterSnapshotForConfiguration:(MPKitConfiguration *)configuration {
    return [[MPKitFilterConfigurationSnapshot alloc]
        initWithFilters:configuration.filters
        attributeValueFilteringIsActive:configuration.attributeValueFilteringIsActive
        attributeValueFilteringHashedAttribute:configuration.attributeValueFilteringHashedAttribute
        attributeValueFilteringHashedValue:configuration.attributeValueFilteringHashedValue
        attributeValueFilteringShouldIncludeMatches:configuration.attributeValueFilteringShouldIncludeMatches];
}

- (MPKitConsentSnapshot *)consentSnapshotForState:(MPConsentState *)state {
    if (!state) {
        return nil;
    }

    NSMutableDictionary<NSString *, NSNumber *> *gdprConsents;
    if (state.gdprConsentState) {
        gdprConsents = [[NSMutableDictionary alloc] initWithCapacity:state.gdprConsentState.count];
        [state.gdprConsentState enumerateKeysAndObjectsUsingBlock:^(NSString *purpose, MPGDPRConsent *consent, BOOL *stop) {
            gdprConsents[purpose] = @(consent.consented);
        }];
    }

    NSNumber *ccpaConsent = state.ccpaConsentState ? @(state.ccpaConsentState.consented) : nil;
    return [[MPKitConsentSnapshot alloc] initWithGdprConsents:gdprConsents ccpaConsent:ccpaConsent];
}

- (MPKitConsentFilterSnapshot *)consentFilterSnapshotForFilter:(MPConsentKitFilter *)filter {
    if (!filter) {
        return nil;
    }

    NSMutableArray<NSNumber *> *hashes = [[NSMutableArray alloc] initWithCapacity:filter.filterItems.count];
    NSMutableArray<NSNumber *> *consentedValues = [[NSMutableArray alloc] initWithCapacity:filter.filterItems.count];
    for (MPConsentKitFilterItem *item in filter.filterItems) {
        [hashes addObject:@(item.javascriptHash)];
        [consentedValues addObject:@(item.consented)];
    }

    return [[MPKitConsentFilterSnapshot alloc] initWithJavascriptHashes:hashes
                                                       consentedValues:consentedValues
                                                  shouldIncludeOnMatch:filter.shouldIncludeOnMatch];
}

- (BOOL)isDisabledByBracketConfiguration:(NSDictionary *)bracketConfiguration {
    int64_t mpId = [[MPPersistenceController_PRIVATE mpId] longLongValue];
    int16_t low = (int16_t)[bracketConfiguration[@"lo"] integerValue];
    int16_t high = (int16_t)[bracketConfiguration[@"hi"] integerValue];
    return [self.filterEngine isDisabledByBracketWithMpId:mpId
                                                      low:low
                                                     high:high
                                               hasBracket:bracketConfiguration != nil];
}

- (BOOL)isDisabledByConsentKitFilter:(MPConsentKitFilter *)kitFilter {
    MPConsentState *state = [MPPersistenceController_PRIVATE
        effectiveConsentStateForMpid:[MParticle sharedInstance].identity.currentUser.userId];
    return [self.filterEngine isDisabledByConsentFilter:[self consentFilterSnapshotForFilter:kitFilter]
                                                consent:[self consentSnapshotForState:state]];
}

- (BOOL)isKitDisabled:(NSNumber *)kitCode {
    MPConsentState *state = [MPPersistenceController_PRIVATE
        effectiveConsentStateForMpid:[MParticle sharedInstance].identity.currentUser.userId];
    return [self.filterEngine isKitDisabledWithIsDisabledKit:[_disabledKits containsObject:kitCode]
                                               consentFilter:[self consentFilterSnapshotForFilter:self.kitConfigurations[kitCode].consentKitFilter]
                                                     consent:[self consentSnapshotForState:state]];
}

- (id<MPKitProtocol>)startKit:(NSNumber *)integrationId configuration:(MPKitConfiguration *)kitConfiguration {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", integrationId];
    id<MPExtensionKitProtocol>kitRegister = [[[MPKitContainer_PRIVATE registeredKits] filteredSetUsingPredicate:predicate] anyObject];
    
    if (!kitRegister) {
        MPILogWarning(@"startKit - kit register not found for integrationId: %@", integrationId);
        return nil;
    }
    
    if (kitRegister.wrapperInstance) {
        return kitRegister.wrapperInstance;
    }
    
    [self startKitRegister:kitRegister configuration:kitConfiguration];
    
    return kitRegister.wrapperInstance;
}

- (void)startKitRegister:(nonnull id<MPExtensionKitProtocol>)kitRegister configuration:(nonnull MPKitConfiguration *)kitConfiguration {
    MPILogDebug(@"startKitRegister - kit: %@ (code: %@)", kitRegister.name, kitRegister.code);
    
    BOOL disabled = [self isDisabledByBracketConfiguration:kitConfiguration.bracketConfiguration];
    if (disabled) {
        MPILogDebug(@"startKitRegister - kit %@ disabled by bracket configuration", kitRegister.code);
        return;
    }
    
    disabled = [self isKitDisabled:kitRegister.code];
    if (disabled) {
        MPILogDebug(@"startKitRegister - kit %@ disabled by disabledKits list", kitRegister.code);
        kitRegister.wrapperInstance = nil;
        return;
    }
    
    NSDictionary * configuration = kitConfiguration.configuration;
    if (configuration.count > 0) {
        if (!kitRegister.wrapperInstance) {
            kitRegister.wrapperInstance = [[NSClassFromString(kitRegister.className) alloc] init];
            if (!kitRegister.wrapperInstance) {
                MPILogWarning(@"startKitRegister - failed to create instance for kit %@ (class: %@)", kitRegister.code, kitRegister.className);
            }
        }
        
        MPKitAPI *kitApi = [[MPKitAPI alloc] initWithKitCode:kitRegister.code];
        if ([kitRegister.wrapperInstance respondsToSelector:@selector(setKitApi:)]) {
            [kitRegister.wrapperInstance setKitApi:kitApi];
        }
        
        if ([kitRegister.wrapperInstance respondsToSelector:@selector(didFinishLaunchingWithConfiguration:)]) {
            MPILogDebug(@"startKitRegister - launching kit %@ with configuration", kitRegister.code);
            if ([NSThread isMainThread]) {
                [kitRegister.wrapperInstance didFinishLaunchingWithConfiguration:configuration];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [kitRegister.wrapperInstance didFinishLaunchingWithConfiguration:configuration];
                });
            }
        }
    }
}

- (void)updateBracketsWithConfiguration:(NSDictionary *)configuration integrationId:(NSNumber *)integrationId {
    NSAssert(integrationId != nil, @"Required parameter. It cannot be nil.");
    
    if (!configuration) {
        [brackets removeObjectForKey:integrationId];
        return;
    }
    
    long mpId = [[MPPersistenceController_PRIVATE mpId] longValue];
    short low = (short)[configuration[@"lo"] integerValue];
    short high = (short)[configuration[@"hi"] integerValue];
    
    MPBracket *bracket = brackets[integrationId];
    if (bracket) {
        bracket.mpId = mpId;
        bracket.low = low;
        bracket.high = high;
    } else {
        brackets[integrationId] = [[MPBracket alloc] initWithMpId:mpId low:low high:high];
    }
}

#pragma mark Public accessors
- (NSMutableDictionary<NSNumber *, MPKitConfiguration *> *)kitConfigurations {
    if (_kitConfigurations) {
        return _kitConfigurations;
    }
    
    _kitConfigurations = [[NSMutableDictionary alloc] initWithCapacity:DEFAULT_ALLOCATION_FOR_KITS];
    
    return _kitConfigurations;
}

#pragma mark Filtering methods
- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forCommerceEvent:(MPCommerceEvent *const)commerceEvent {
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    __block MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:commerceEvent shouldFilter:NO];
    MPKitFilterConfigurationSnapshot *configurationSnapshot = [self filterSnapshotForConfiguration:kitConfiguration];
    if (!configurationSnapshot) {
        return kitFilter;
    }

    MPCommerceEventKind commerceEventKind = [commerceEvent kind];
    MPKitCommerceFilterDecision *decision = [self.filterEngine
        filterCommerceEventWithType:(NSUInteger)commerceEvent.type
        kind:(NSInteger)commerceEventKind
        customAttributes:commerceEvent.customAttributes
        beautifiedAttributes:commerceEvent.beautifiedAttributes
        transactionAttributes:commerceEvent.transactionAttributes.beautifiedDictionaryRepresentation
        configuration:configurationSnapshot];
    if (decision.shouldFilter) {
        return [[MPKitFilter alloc] initWithCommerceEvent:commerceEvent shouldFilter:YES];
    }

    __block MPCommerceEvent *forwardCommerceEvent = [commerceEvent copy];
    switch (decision.entityAction) {
        case MPKitCommerceEntityActionRemoveProductsAndImpressions:
            [forwardCommerceEvent setProducts:nil];
            [forwardCommerceEvent setImpressions:nil];
            return [[MPKitFilter alloc] initWithCommerceEvent:forwardCommerceEvent shouldFilter:NO];

        case MPKitCommerceEntityActionRemovePromotions:
            [forwardCommerceEvent.promotionContainer setPromotions:nil];
            return [[MPKitFilter alloc] initWithCommerceEvent:forwardCommerceEvent shouldFilter:NO];

        case MPKitCommerceEntityActionReturnOriginalEvent:
            return [[MPKitFilter alloc] initWithCommerceEvent:commerceEvent shouldFilter:NO];

        case MPKitCommerceEntityActionContinueFiltering:
            break;
    }

    NSDictionary *appFamilyFilter = decision.appFamilyFilter;
    if (appFamilyFilter.count > 0) {
        switch (commerceEventKind) {
            case MPCommerceEventKindProduct: {
                NSMutableArray *products = [[NSMutableArray alloc] init];
                [commerceEvent.products enumerateObjectsUsingBlock:^(MPProduct *product, NSUInteger idx, BOOL *stop) {
                    MPProduct *filteredProduct = [product copyMatchingHashedProperties:appFamilyFilter];
                    if (filteredProduct) {
                        [products addObject:filteredProduct];
                    }
                }];
                if (products.count > 0) {
                    [forwardCommerceEvent setProducts:products];
                }
                break;
            }

            case MPCommerceEventKindImpression:
                forwardCommerceEvent.impressions = [commerceEvent copyImpressionsMatchingHashedProperties:appFamilyFilter];
                break;

            case MPCommerceEventKindPromotion:
                forwardCommerceEvent.promotionContainer = [commerceEvent.promotionContainer copyMatchingHashedProperties:appFamilyFilter];
                break;

            default:
                break;
        }
    }

    if (decision.hasAttributeFilters) {
        [forwardCommerceEvent setBeautifiedAttributes:[decision.filteredBeautifiedAttributes mutableCopy]];
        [forwardCommerceEvent setCustomAttributes:decision.filteredCustomAttributes];

        MPTransactionAttributes *source = forwardCommerceEvent.transactionAttributes;
        MPTransactionAttributes *filtered = [[MPTransactionAttributes alloc] init];
        NSSet<NSString *> *allowedKeys = decision.allowedTransactionAttributeKeys;
        if ([allowedKeys containsObject:kMPExpTAAffiliation]) {
            filtered.affiliation = source.affiliation;
        }
        if ([allowedKeys containsObject:kMPExpTAShipping]) {
            filtered.shipping = source.shipping;
        }
        if ([allowedKeys containsObject:kMPExpTATax]) {
            filtered.tax = source.tax;
        }
        if ([allowedKeys containsObject:kMPExpTARevenue]) {
            filtered.revenue = source.revenue;
        }
        if ([allowedKeys containsObject:kMPExpTATransactionId]) {
            filtered.transactionId = source.transactionId;
        }
        if ([allowedKeys containsObject:kMPExpTACouponCode]) {
            filtered.couponCode = source.couponCode;
        }
        forwardCommerceEvent.transactionAttributes = filtered;
    }

    [self project:kitRegister commerceEvent:forwardCommerceEvent completionHandler:^(NSArray<MPCommerceEvent *> *projectedCommerceEvents,
                                                                                     NSArray<MPEvent *> *projectedEvents,
                                                                                     NSArray<MPEventProjection *> *appliedProjections) {
        NSArray<MPEventProjection *> *appliedProjectionsArray = appliedProjections.count ? appliedProjections : nil;

        if (projectedEvents.count != 0) {
            for (MPEvent *projectedEvent in projectedEvents) {
                kitFilter = [[MPKitFilter alloc] initWithEvent:projectedEvent shouldFilter:NO appliedProjections:appliedProjectionsArray eventCopy:nil commerceEventCopy:commerceEvent];
                [self attemptToLogEventToKit:kitRegister kitFilter:kitFilter selector:@selector(logEvent:) parameters:nil messageType:MPMessageTypeEvent userInfo:[[NSDictionary alloc] init]];
            }
        }

        if (projectedCommerceEvents.count != 0) {
            for (MPCommerceEvent *projectedCommerceEvent in projectedCommerceEvents) {
                kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:projectedCommerceEvent shouldFilter:NO appliedProjections:appliedProjectionsArray];
                [self attemptToLogCommerceEventToKit:kitRegister kitFilter:kitFilter];
            }
        }

    }];

    return kitFilter;
}

- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forEvent:(MPEvent *const)event selector:(SEL)selector {
    return [self filter:kitRegister forEvent:event selector:selector parameters:nil];
}

- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister
                forEvent:(MPEvent *const)event
                selector:(SEL)selector
              parameters:(MPForwardQueueParameters *)parameters {
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    __block MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithEvent:event shouldFilter:NO];
    NSString *selectorString = NSStringFromSelector(selector);
    MPKitFilterConfigurationSnapshot *configurationSnapshot = [self filterSnapshotForConfiguration:kitConfiguration];
    if (!configurationSnapshot) {
        return kitFilter;
    }

    MPKitEventSnapshot *eventSnapshot = [[MPKitEventSnapshot alloc]
        initWithType:(NSUInteger)event.type
        name:event.name
        attributes:event.customAttributes
        selectorName:selectorString];
    MPKitEventFilterDecision *decision = [self.filterEngine filterEvent:eventSnapshot
                                                          configuration:configurationSnapshot];
    if (decision.shouldFilter) {
        return [[MPKitFilter alloc] initWithFilter:YES];
    }

    MPEvent *forwardEvent = [event copy];
    forwardEvent.customAttributes = decision.filteredAttributes;
    MPMessageType messageTypeCode = [MPEnum messageTypeFromNSString:decision.messageType];
    if (messageTypeCode != MPMessageTypeEvent && messageTypeCode != MPMessageTypeScreenView && messageTypeCode != MPMessageTypeMedia) {
        messageTypeCode = MPMessageTypeUnknown;
    }
    
    [self project:kitRegister event:forwardEvent messageType:messageTypeCode completionHandler:^(NSArray<MPEvent *> *projectedEvents, NSArray<MPEventProjection *> *appliedProjections) {
        NSArray<MPEventProjection *> *appliedProjectionsArray = appliedProjections.count > 0 ? appliedProjections : nil;
        
        for (MPEvent *projectedEvent in projectedEvents) {
            kitFilter = [[MPKitFilter alloc] initWithEvent:projectedEvent shouldFilter:NO appliedProjections:appliedProjectionsArray eventCopy:event commerceEventCopy:nil];
            SEL mutableSelector = selector;
            if (selector == @selector(logScreen:)) {
                for (NSUInteger i = 0; i < appliedProjectionsArray.count; i++) {
                    MPEventProjection *appliedProjection = appliedProjectionsArray[i];
                    if (appliedProjection.outboundMessageType == MPMessageTypeEvent) {
                        mutableSelector = @selector(logBaseEvent:);
                        break;
                    }
                }
            }
            [self attemptToLogEventToKit:kitRegister kitFilter:kitFilter selector:mutableSelector parameters:parameters messageType:messageTypeCode userInfo:[[NSDictionary alloc] init]];
        }
    }];
    
    return kitFilter;
}

- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forBaseEvent:(MPBaseEvent *const)event forSelector:(SEL)selector {
    MPKitFilter *kitFilter;
    if (event != nil) {
        kitFilter = [[MPKitFilter alloc] initWithEvent:event shouldFilter:NO];
    } else {
        kitFilter = [[MPKitFilter alloc] initWithFilter:NO];
    }
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    MPKitFilterConfigurationSnapshot *configurationSnapshot = [self filterSnapshotForConfiguration:kitConfiguration];
    if (configurationSnapshot &&
        [self.filterEngine shouldFilterBaseEventWithSelectorName:NSStringFromSelector(selector)
                                                  configuration:configurationSnapshot]) {
        return [[MPKitFilter alloc] initWithFilter:YES];
    }
    
    return kitFilter;
}

- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forUserAttributes:(NSDictionary *)userAttributes {
    if (!userAttributes) {
        return nil;
    }
    
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    NSDictionary *decisionAttributes = [self.filterEngine
        filterUserAttributes:userAttributes
        configuration:[self filterSnapshotForConfiguration:kitConfiguration]];
    if (decisionAttributes.count == 0) {
        return nil;
    }

    NSMutableDictionary *forwardAttributes = [[NSMutableDictionary alloc] initWithCapacity:decisionAttributes.count];
    [decisionAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        forwardAttributes[key] = [value copy];
    }];
    return [[MPKitFilter alloc] initWithFilter:YES filteredAttributes:forwardAttributes];
}

- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forUserAttributeKey:(NSString *)key value:(id)value {
    if (!key) {
        return nil;
    }
    
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    BOOL shouldFilter = [self.filterEngine
        shouldFilterUserAttributeWithKey:key
        configuration:[self filterSnapshotForConfiguration:kitConfiguration]];
    return shouldFilter ? [[MPKitFilter alloc] initWithFilter:YES] : nil;
}

- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forUserIdentityKey:(NSString *)key identityType:(MPUserIdentity)identityType {
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    BOOL shouldFilter = [self.filterEngine
        shouldFilterUserIdentityWithType:(NSUInteger)identityType
        configuration:[self filterSnapshotForConfiguration:kitConfiguration]];
    return shouldFilter ? [[MPKitFilter alloc] initWithFilter:YES] : nil;
}

- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forConsentState:(MPConsentState *)state {
    if (!state) {
        return nil;
    }
    
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    MPKitConsentDecision *decision = [self.filterEngine
        filterConsent:[self consentSnapshotForState:state]
        configuration:[self filterSnapshotForConfiguration:kitConfiguration]];
    switch (decision.action) {
        case MPKitConsentActionFilterAll:
            return [[MPKitFilter alloc] initWithFilter:YES];

        case MPKitConsentActionForwardCCPA: {
            MPConsentState *filteredState = [[MPConsentState alloc] init];
            [filteredState setCCPAConsentState:state.ccpaConsentState];
            return [[MPKitFilter alloc] initWithConsentState:filteredState shouldFilter:NO];
        }

        case MPKitConsentActionForwardGDPR: {
            NSMutableDictionary<NSString *, MPGDPRConsent *> *filteredGDPRState = [NSMutableDictionary dictionary];
            for (NSString *purpose in decision.allowedGDPRPurposes) {
                filteredGDPRState[purpose] = state.gdprConsentState[purpose];
            }
            MPConsentState *filteredState = [[MPConsentState alloc] init];
            [filteredState setGDPRConsentState:filteredGDPRState];
            return [[MPKitFilter alloc] initWithConsentState:filteredState shouldFilter:NO];
        }

        case MPKitConsentActionNoFilter:
            return nil;
    }
}

#pragma mark Projection methods

- (MPKitAttributeProjectionSnapshot *)projectionSnapshotForAttributeProjection:(MPAttributeProjection *)projection {
    return [[MPKitAttributeProjectionSnapshot alloc] initWithName:projection.name
                                                    projectedName:projection.projectedName
                                                        matchType:projection.matchType
                                                     propertyKind:projection.propertyKind
                                                         dataType:projection.dataType
                                                         required:projection.required];
}

- (MPKitProjectionSnapshot *)projectionSnapshotForProjection:(MPEventProjection *)projection {
    NSMutableArray<MPKitProjectionMatchSnapshot *> *matches = nil;
    if (projection.projectionMatches) {
        matches = [NSMutableArray arrayWithCapacity:projection.projectionMatches.count];
        for (MPProjectionMatch *match in projection.projectionMatches) {
            [matches addObject:[[MPKitProjectionMatchSnapshot alloc] initWithAttributeKey:match.attributeKey
                                                                          attributeValues:match.attributeValues]];
        }
    }

    NSMutableArray<MPKitAttributeProjectionSnapshot *> *attributeProjections =
        [NSMutableArray arrayWithCapacity:projection.attributeProjections.count];
    for (MPAttributeProjection *attributeProjection in projection.attributeProjections) {
        [attributeProjections addObject:[self projectionSnapshotForAttributeProjection:attributeProjection]];
    }

    return [[MPKitProjectionSnapshot alloc] initWithProjectionId:projection.projectionId
                                                            name:projection.name
                                                   projectedName:projection.projectedName
                                                       matchType:projection.matchType
                                                  projectionType:projection.projectionType
                                                    propertyKind:projection.propertyKind
                                               projectionMatches:matches
                                            attributeProjections:attributeProjections
                                                behaviorSelector:projection.behaviorSelector
                                                       eventType:projection.eventType
                                                     messageType:projection.messageType
                                             outboundMessageType:projection.outboundMessageType
                                             maxCustomParameters:projection.maxCustomParameters
                                                      appendAsIs:projection.appendAsIs];
}

- (NSArray<MPKitProjectionSnapshot *> *)projectionSnapshotsForProjections:(NSArray<MPEventProjection *> *)projections {
    NSMutableArray<MPKitProjectionSnapshot *> *snapshots = [NSMutableArray arrayWithCapacity:projections.count];
    for (MPEventProjection *projection in projections) {
        [snapshots addObject:[self projectionSnapshotForProjection:projection]];
    }
    return snapshots;
}

- (MPKitCommerceEntityProjectionSource *)projectionSourceForProduct:(MPProduct *)product {
    return [[MPKitCommerceEntityProjectionSource alloc]
        initWithFields:[[product beautifiedAttributes] transformValuesToString]
            attributes:[[product userDefinedAttributes] transformValuesToString]];
}

- (MPKitCommerceEntityProjectionSource *)projectionSourceForPromotion:(MPPromotion *)promotion {
    return [[MPKitCommerceEntityProjectionSource alloc]
        initWithFields:[[promotion beautifiedAttributes] transformValuesToString]
            attributes:nil];
}

- (MPKitCommerceProjectionSource *)projectionSourceForCommerceEvent:(MPCommerceEvent *)commerceEvent {
    NSMutableArray<MPKitCommerceEntityProjectionSource *> *products = [NSMutableArray array];
    for (MPProduct *product in commerceEvent.products) {
        [products addObject:[self projectionSourceForProduct:product]];
    }

    NSMutableArray<MPKitCommerceEntityProjectionSource *> *impressions = [NSMutableArray array];
    [commerceEvent.impressions enumerateKeysAndObjectsUsingBlock:^(NSString *listName, NSSet<MPProduct *> *productImpressions, BOOL *stop) {
        for (MPProduct *product in productImpressions) {
            [impressions addObject:[self projectionSourceForProduct:product]];
        }
    }];

    NSMutableArray<MPKitCommerceEntityProjectionSource *> *promotions = [NSMutableArray array];
    for (MPPromotion *promotion in commerceEvent.promotionContainer.promotions) {
        [promotions addObject:[self projectionSourceForPromotion:promotion]];
    }

    return [[MPKitCommerceProjectionSource alloc]
        initWithType:commerceEvent.type
                kind:commerceEvent.kind
         eventFields:[[commerceEvent beautifiedAttributes] transformValuesToString]
     eventAttributes:[[commerceEvent customAttributes] transformValuesToString]
originalCustomAttributes:commerceEvent.customAttributes
            products:products
         impressions:impressions
          promotions:promotions];
}

- (NSDictionary<NSNumber *, MPEventProjection *> *)projectionsByIdForConfiguration:(MPKitConfiguration *)configuration {
    NSMutableDictionary<NSNumber *, MPEventProjection *> *projectionsById = [NSMutableDictionary dictionary];
    for (MPEventProjection *projection in configuration.projections) {
        projectionsById[@(projection.projectionId)] = projection;
    }
    for (id projection in configuration.defaultProjections) {
        if (!MPIsNull(projection)) {
            MPEventProjection *eventProjection = projection;
            projectionsById[@(eventProjection.projectionId)] = eventProjection;
        }
    }
    return projectionsById;
}

- (void)project:(id<MPExtensionKitProtocol>)kitRegister
      commerceEvent:(MPCommerceEvent *const)commerceEvent
  completionHandler:(void (^)(NSArray<MPCommerceEvent *> *projectedCommerceEvents,
                              NSArray<MPEvent *> *projectedEvents,
                              NSArray<MPEventProjection *> *appliedProjections))completionHandler {
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    
    if (!kitConfiguration.configuredMessageTypeProjections ||
        !(kitConfiguration.configuredMessageTypeProjections.count > MPMessageTypeCommerceEvent) ||
        ![kitConfiguration.configuredMessageTypeProjections[MPMessageTypeCommerceEvent] boolValue])
    {
        NSMutableArray<MPCommerceEvent *> *projectedCommerceEvents = [NSMutableArray array];
        NSMutableArray<MPEvent *> *projectedEvents = [NSMutableArray array];
        NSMutableArray<MPEventProjection *> *appliedProjections = [NSMutableArray array];
        
        [projectedCommerceEvents addObject:commerceEvent];
        
        completionHandler(projectedCommerceEvents, projectedEvents, appliedProjections);
        
        return;
    }

    dispatch_semaphore_wait(kitsSemaphore, DISPATCH_TIME_FOREVER);
    NSArray<MPKitProjectionOutput *> *outputs = [self.projectionEngine
        projectCommerceEvent:[self projectionSourceForCommerceEvent:commerceEvent]
        projections:[self projectionSnapshotsForProjections:kitConfiguration.projections]];
    NSDictionary<NSNumber *, MPEventProjection *> *projectionsById =
        [self projectionsByIdForConfiguration:kitConfiguration];
    NSMutableArray<MPCommerceEvent *> *projectedCommerceEvents = [NSMutableArray array];
    NSMutableArray<MPEvent *> *projectedEvents = [NSMutableArray array];
    NSMutableArray<MPEventProjection *> *appliedProjections = [NSMutableArray array];

    for (MPKitProjectionOutput *output in outputs) {
        switch (output.kind) {
            case MPKitProjectionOutputKindOriginalCommerceEvent:
                [projectedCommerceEvents addObject:commerceEvent];
                break;

            case MPKitProjectionOutputKindProjectedCommerceEvent: {
                MPCommerceEvent *projectedCommerceEvent = [commerceEvent copy];
                if (output.attributes) {
                    projectedCommerceEvent.customAttributes = output.attributes;
                }
                [projectedCommerceEvents addObject:projectedCommerceEvent];
            }
                break;

            case MPKitProjectionOutputKindProjectedEvent: {
                MPEvent *projectedEvent = [[MPEvent alloc] initWithName:output.projectedName type:MPEventTypeTransaction];
                projectedEvent.customAttributes = output.attributes;
                [projectedEvents addObject:projectedEvent];
            }
                break;

            case MPKitProjectionOutputKindOriginalEvent:
                break;
        }

        if (output.projectionId != nil) {
            MPEventProjection *appliedProjection = projectionsById[output.projectionId];
            if (appliedProjection) {
                [appliedProjections addObject:appliedProjection];
            }
        }
    }

    dispatch_semaphore_signal(kitsSemaphore);
    completionHandler(projectedCommerceEvents, projectedEvents, appliedProjections);
}

- (void)project:(id<MPExtensionKitProtocol>)kitRegister
          event:(MPEvent *const)event
    messageType:(MPMessageType)messageType
completionHandler:(void (^)(NSArray<MPEvent *> *projectedEvents,
                            NSArray<MPEventProjection *> *appliedProjections))completionHandler {
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
    
    if (!kitConfiguration.configuredMessageTypeProjections ||
        !(kitConfiguration.configuredMessageTypeProjections.count > messageType) ||
        ![kitConfiguration.configuredMessageTypeProjections[messageType] boolValue])
    {
        NSMutableArray<MPEvent *> *projectedEvents = [NSMutableArray array];
        NSMutableArray<MPEventProjection *> *appliedProjections = [NSMutableArray array];
        if (event) {
            [projectedEvents addObject:event];
        }
        
        completionHandler(projectedEvents, appliedProjections);
        
        return;
    }

    dispatch_semaphore_wait(kitsSemaphore, DISPATCH_TIME_FOREVER);
    MPKitEventProjectionSource *source = [[MPKitEventProjectionSource alloc]
        initWithType:event.type
                name:event.name
          attributes:event.customAttributes
       attributeKeys:event.customAttributes.allKeys ?: @[]
  matchingAttributes:[event.customAttributes transformValuesToString]
         messageType:messageType];
    id defaultProjection = kitConfiguration.defaultProjections[messageType];
    MPKitProjectionSnapshot *defaultSnapshot = MPIsNull(defaultProjection)
        ? nil
        : [self projectionSnapshotForProjection:defaultProjection];
    NSArray<MPKitProjectionOutput *> *outputs = [self.projectionEngine
        projectEvent:source
        projections:[self projectionSnapshotsForProjections:kitConfiguration.projections]
        defaultProjection:defaultSnapshot];
    NSDictionary<NSNumber *, MPEventProjection *> *projectionsById =
        [self projectionsByIdForConfiguration:kitConfiguration];
    NSMutableArray<MPEvent *> *projectedEvents = [NSMutableArray arrayWithCapacity:outputs.count];
    NSMutableArray<MPEventProjection *> *appliedProjections = [NSMutableArray arrayWithCapacity:outputs.count];

    for (MPKitProjectionOutput *output in outputs) {
        if (output.kind == MPKitProjectionOutputKindOriginalEvent) {
            [projectedEvents addObject:event];
            continue;
        }

        MPEvent *projectedEvent = [event copy];
        projectedEvent.name = output.projectedName;
        projectedEvent.customAttributes = output.attributes;
        [projectedEvents addObject:projectedEvent];

        MPEventProjection *appliedProjection = projectionsById[output.projectionId];
        if (appliedProjection) {
            [appliedProjections addObject:appliedProjection];
        }
    }

    dispatch_semaphore_signal(kitsSemaphore);
    completionHandler(projectedEvents, appliedProjections);
}

- (nullable NSArray<NSNumber *> *)configuredKitsRegistry {
    BOOL anyKitsIncluded = self.supportedKits.count > 0;
    BOOL anyKitsConfigured = self.kitConfigurations.count > 0;
    if (!anyKitsIncluded || !anyKitsConfigured) {
        return nil;
    }
    NSMutableArray<NSNumber *> *configuredKits = [[NSMutableArray alloc] initWithCapacity:self.kitConfigurations.count];
    for (NSNumber *kitId in self.kitConfigurations.allKeys) {
        if ([self.supportedKits containsObject:kitId]) {
            [configuredKits addObject:kitId];
        }
    }
    return configuredKits;
}

#pragma mark Public methods

- (void)removeAllSideloadedKits {
    // Remove all sideloaded kits as new instances will be provided in the new MParticleOptions
    NSSet *kits = [MPKitContainer_PRIVATE registeredKits];
    for (id<MPExtensionKitProtocol>kitRegister in kits) {
        if ([kitRegister.wrapperInstance respondsToSelector:@selector(sideloadedKitCode)]) {
            [MPKitContainer_PRIVATE removeRegisteredKit:kitRegister];
        }
    }
}

- (void)removeKitsFromRegistryInvalidForWorkspaceSwitch {
    // Remove kits from registry that can't be freed so they won't receive new events
    // Leave any kit that was never used yet (i.e. was not used in the previous workspace)
    NSSet *kits = [MPKitContainer_PRIVATE registeredKits];
    for (id<MPExtensionKitProtocol>kitRegister in kits) {
        if (![kitRegister.wrapperInstance respondsToSelector:@selector(stop)] &&
            [self.kitConfigurations.allKeys containsObject:[kitRegister.wrapperInstance.class kitCode]]) {
            [MPKitContainer_PRIVATE removeRegisteredKit:kitRegister];
        }
    }
}

- (nullable NSArray<id<MPExtensionKitProtocol>> *)activeKitsRegistry {
    dispatch_semaphore_wait(kitsSemaphore, DISPATCH_TIME_FOREVER);
    NSArray<id<MPExtensionKitProtocol>> *result = [self activeKitsRegistryWhenLocked];
    dispatch_semaphore_signal(kitsSemaphore);
    return result;
}

- (nullable NSArray<id<MPExtensionKitProtocol>> *)activeKitsRegistryWhenLocked {
    NSSet *kitsRegistryCopy = [MPKitContainer_PRIVATE registeredKits];
    if (kitsRegistryCopy.count == 0) {
        return nil;
    }

    NSMutableArray<id<MPExtensionKitProtocol>> *activeKits = [[NSMutableArray alloc] initWithCapacity:kitsRegistryCopy.count];

    for (id<MPExtensionKitProtocol> kitRegister in kitsRegistryCopy) {
        if ([self isActiveAndNotDisabled:kitRegister]) {
            [activeKits addObject:kitRegister];
        }
    }

    return activeKits.count > 0 ? activeKits : nil;
}

- (BOOL)isActiveAndNotDisabled:(id<MPExtensionKitProtocol>)kitRegister {
    BOOL active = kitRegister.wrapperInstance ? [kitRegister.wrapperInstance started] : NO;
    MPBracket *bracket = [self bracketForKit:kitRegister.code];
    MParticleUser *currentUser = [MParticle sharedInstance].identity.currentUser;
    MPKitConfiguration *configuration = self.kitConfigurations[kitRegister.code];
    MPConsentState *state = [MPPersistenceController_PRIVATE effectiveConsentStateForMpid:currentUser.userId];

    return [self.filterEngine isKitActiveWithActive:active
                                              mpId:bracket.mpId
                                         bracketLow:bracket.low
                                        bracketHigh:bracket.high
                                         hasBracket:bracket != nil
                                       consentFilter:[self consentFilterSnapshotForFilter:configuration.consentKitFilter]
                                             consent:[self consentSnapshotForState:state]
                              excludesAnonymousUsers:configuration.excludeAnonymousUsers
                                         isLoggedIn:currentUser.isLoggedIn
                                      isDisabledKit:[_disabledKits containsObject:kitRegister.code]];
}

- (void)configureKits:(NSArray<NSDictionary *> *)kitConfigurations {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    MPILogDebug(@"configureKits - received %lu kit configuration(s) from server", (unsigned long)kitConfigurations.count);
    
    if (MPIsNull(kitConfigurations) || stateMachine.optOut) {
        MPILogDebug(@"configureKits - null config or opted out, flushing kits");
        [self flushSerializedKits];
        self.kitsInitialized = YES;
        
        return;
    }
    
    dispatch_semaphore_wait(kitsSemaphore, DISPATCH_TIME_FOREVER);
    
    self.originalConfig = kitConfigurations;
    
    NSPredicate *predicate;
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    NSDictionary *userAttributes = userDefaults[kMPUserAttributeKey];
    NSArray *userIdentities = userDefaults[kMPUserIdentityArrayKey];
    NSArray<NSNumber *> *supportedKits = [self supportedKits];
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistryWhenLocked];
    id<MPExtensionKitProtocol>kitRegister;
    id<MPKitProtocol> kitInstance;
    Class NSStringClass = [NSString class];
    Class NSNumberClass = [NSNumber class];
    Class NSArrayClass = [NSArray class];
    
    // Adds all currently configured kits to a list
    NSMutableArray<NSNumber *> *deactivateKits = [NSMutableArray array];
    for (kitRegister in activeKitsRegistry) {
        [deactivateKits addObject:kitRegister.code];
    }
    
    // Configure kits according to server instructions
    for (NSDictionary *kitConfigurationDictionary in kitConfigurations) {
        MPKitConfiguration *kitConfiguration = nil;
        
        NSNumber *integrationId = kitConfigurationDictionary[@"id"];
        
        predicate = [NSPredicate predicateWithFormat:@"SELF == %@", integrationId];
        BOOL isKitSupported = [supportedKits filteredArrayUsingPredicate:predicate].count > 0;
        
        if (isKitSupported) {
            predicate = [NSPredicate predicateWithFormat:@"code == %@", integrationId];
            kitRegister = [[[MPKitContainer_PRIVATE registeredKits] filteredSetUsingPredicate:predicate] anyObject];
            kitInstance = kitRegister.wrapperInstance;
            kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:kitConfigurationDictionary];
            self.kitConfigurations[integrationId] = kitConfiguration;
            
            MPILogDebug(@"configureKits - configuring kit %@ (existing instance: %@)", integrationId, kitInstance ? @"YES" : @"NO");
            
            BOOL disabled = [self isKitDisabled:kitRegister.code];

            if (kitInstance) {
                if (disabled) {
                    kitRegister.wrapperInstance = nil;
                } else {
                    [self updateBracketsWithConfiguration:kitConfiguration.bracketConfiguration integrationId:integrationId];
                    
                    NSDictionary *configuration = kitConfiguration.configuration;
                    if ([kitInstance respondsToSelector:@selector(setConfiguration:)]) {
                        [kitInstance setConfiguration:configuration];
                    }
                }
                
            } else {
                MPILogDebug(@"configureKits - starting new kit instance for kit %@", integrationId);
                [self startKitRegister:kitRegister configuration:kitConfiguration];
                kitInstance = kitRegister.wrapperInstance;
                
                if (kitInstance) {
                    [self updateBracketsWithConfiguration:kitConfiguration.bracketConfiguration integrationId:integrationId];
                }
                
                [self updateBracketsWithConfiguration:kitConfiguration.bracketConfiguration integrationId:integrationId];
            }
            
            if (kitInstance) {
                if (![kitInstance started] && !disabled) {
                    if ([kitInstance respondsToSelector:@selector(setLaunchOptions:)]) {
                        [kitInstance setLaunchOptions:stateMachine.launchOptions];
                    }
                    
                    if ([kitInstance respondsToSelector:@selector(start)]) {
                        @try {
                            [kitInstance start];
                        }
                        @catch (NSException *exception) {
                            MPILogError(@"Exception thrown while starting kit (%@): %@", kitInstance, exception);
                        }
                    }
                }
                
                NSArray *alreadySynchedUserAttributes = userDefaults[kMPSynchedUserAttributesKey];
                if (userAttributes && ![alreadySynchedUserAttributes containsObject:integrationId]) {
                    NSMutableArray *synchedUserAttributes = [[NSMutableArray alloc] initWithCapacity:alreadySynchedUserAttributes.count + 1];
                    [synchedUserAttributes addObjectsFromArray:alreadySynchedUserAttributes];
                    [synchedUserAttributes addObject:integrationId];
                    userDefaults[kMPSynchedUserAttributesKey] = synchedUserAttributes;
                    
                    NSEnumerator *attributeEnumerator = [userAttributes keyEnumerator];
                    NSString *key;
                    id value;
                    while ((key = [attributeEnumerator nextObject])) {
                        if (![MParticle.sharedInstance.dataPlanFilter isBlockedUserAttributeKey:key]) {
                            value = userAttributes[key];
                            MPKitFilter *kitFilter = [self filter:kitRegister forUserAttributeKey:key value:value];
                            if (!kitFilter.shouldFilter) {
                                FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:[[[MParticle sharedInstance] identity] currentUser] kitConfiguration:self.kitConfigurations[kitRegister.code]];
                                if ([kitInstance respondsToSelector:@selector(onSetUserAttribute:)] && filteredUser != nil) {
                                    [kitInstance onSetUserAttribute:filteredUser];
                                } else if ([kitInstance respondsToSelector:@selector(setUserAttribute:value:)] && [value isKindOfClass:NSStringClass]) {
                                    [kitInstance setUserAttribute:key value:value];
                                } else if ([kitInstance respondsToSelector:@selector(setUserAttribute:value:)] && [value isKindOfClass:NSNumberClass]) {
                                    value = [value stringValue];
                                    [kitInstance setUserAttribute:key value:value];
                                } else if ([kitInstance respondsToSelector:@selector(setUserAttribute:values:)] && [value isKindOfClass:NSArrayClass]) {
                                    [kitInstance setUserAttribute:key values:value];
                                }
                            }
                        }
                    }
                }
                
                if (userIdentities && [kitInstance respondsToSelector:@selector(setUserIdentity:identityType:)]) {
                    for (NSDictionary *userIdentity in userIdentities) {
                        MPUserIdentity identityType = (MPUserIdentity)[userIdentity[kMPUserIdentityTypeKey] intValue];
                        if (![MParticle.sharedInstance.dataPlanFilter isBlockedUserIdentityType:(MPIdentity)identityType]) {
                            NSString *identityString = userIdentity[kMPUserIdentityIdKey];
                            
                            [kitInstance setUserIdentity:identityString identityType:identityType];
                        }
                    }
                }
            }
        } else {
            MPILogWarning(@"SDK is trying to configure a kit (code = %@). However, it is not currently registered with the core SDK.", integrationId);
        }
        
        if (deactivateKits.count != 0) {
            for (NSUInteger i = 0; i < deactivateKits.count; i++) {
                if ([deactivateKits[i] isEqualToNumber:integrationId]) {
                    [deactivateKits removeObjectAtIndex:i];
                    break;
                }
            }
        }
    }
    
    // Remove currently configured kits that were not in the instructions from the server
    if (deactivateKits.count != 0) {
        for (NSNumber *ek in deactivateKits) {
            predicate = [NSPredicate predicateWithFormat:@"code == %@", ek];
            kitRegister = [[[MPKitContainer_PRIVATE registeredKits] filteredSetUsingPredicate:predicate] anyObject];
            [self freeKit:kitRegister.code];
        }
    }
    
    MPILogDebug(@"configureKits complete - marking kitsInitialized = YES, configured %lu kit(s)", (unsigned long)self.kitConfigurations.count);
    self.kitsInitialized = YES;
    
    dispatch_semaphore_signal(kitsSemaphore);
}

- (nullable NSArray<NSNumber *> *)supportedKits {
    NSSet *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    if (registeredKits.count == 0) {
        return nil;
    }
    
    NSMutableArray<NSNumber *> *supportedKits = [[NSMutableArray alloc] initWithCapacity:registeredKits.count];
    for (id<MPExtensionKitProtocol>kitRegister in registeredKits) {
        [supportedKits addObject:kitRegister.code];
    }
    
    return supportedKits;
}

#pragma mark Forward methods
- (void)forwardCommerceEventCall:(MPCommerceEvent *)commerceEvent {
    if (!self.kitsInitialized) {
        MPILogWarning(@"Kits not initialized - queueing commerce event");
        MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithCommerceEvent:commerceEvent];
        
        if (forwardQueueItem) {
            [self.forwardQueue addObject:forwardQueueItem];
        }
        
        return;
    }
    
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        [self filter:kitRegister forCommerceEvent:commerceEvent];
    }
}

- (void)attemptToLogCommerceEventToKit:(id<MPExtensionKitProtocol>)kitRegister kitFilter:(MPKitFilter *)kitFilter {
    __block NSNumber *lastKit = nil;
    
    if (kitFilter.shouldFilter && !kitFilter.filteredAttributes) {
        MPILogDebug(@"Kit filtered out event: %@", kitFilter.forwardCommerceEvent);
        return;
    }
    
    if (kitFilter.forwardCommerceEvent || kitFilter.forwardEvent) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MPKitExecStatus *execStatus = nil;
            
            id<MPKitProtocol> kit = kitRegister.wrapperInstance;
            SEL logBaseEventSelector = @selector(logBaseEvent:);
            SEL logCommerceEventSelector = @selector(logCommerceEvent:);
            SEL logEventSelector = @selector(logEvent:);
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            @try {
                if (kitFilter.forwardCommerceEvent) {
                    if ([kit respondsToSelector:logBaseEventSelector]) {
                        execStatus = [kit logBaseEvent:kitFilter.forwardCommerceEvent];
                    } else if ([kit respondsToSelector:logCommerceEventSelector]) {
                        execStatus = [kit logCommerceEvent:kitFilter.forwardCommerceEvent];
                    } else if ([kit respondsToSelector:logEventSelector]) {
                        NSArray *expandedInstructions = [kitFilter.forwardCommerceEvent expandedInstructions];
                        
                        for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
                            [kit logEvent:commerceEventInstruction.event];
                        }
                        
                        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[kit class] kitCode] returnCode:MPKitReturnCodeSuccess];
                    }
                }
                
                if (kitFilter.forwardEvent) {
                    if ([kit respondsToSelector:logEventSelector] && [kitFilter.forwardEvent isKindOfClass:[MPEvent class]]) {
                        execStatus = [kit logEvent:(MPEvent *)(kitFilter.forwardEvent)];
                    } else if ([kit respondsToSelector:@selector(logBaseEvent:)]) {
                        execStatus = [kit logBaseEvent:kitFilter.forwardEvent];
                    }
                }
            } @catch (NSException *e) {
                MPILogError(@"Kit handler threw an exception: %@", e);
            }
#pragma clang diagnostic pop
            
            if (execStatus.success) {
                MPILogDebug(@"Successfully forwarded commerce event to kit: %@ (code: %@)", kitRegister.name, kitRegister.code);
            } else {
                MPILogError(@"Failed to forward commerce event to kit: %@ (code: %@)", kitRegister.name, kitRegister.code);
            }
            
            NSNumber *currentKit = kitRegister.code;
            if (execStatus.success && ![lastKit isEqualToNumber:currentKit]) {
                lastKit = currentKit;
                
                [self forwardCommerceEventRecord:kitFilter execStatus:execStatus commerceEvent:kitFilter.originalCommerceEvent];
                MPILogDebug(@"Forwarded logCommerceEvent call to kit: %@", kitRegister.name);
            }
        });
    }
}

- (void)forwardSDKCall:(SEL)selector event:(MPBaseEvent *)event parameters:(MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType userInfo:(NSDictionary *)userInfo {
    if (!self.kitsInitialized) {
        if (messageType == MPMessageTypePushRegistration) {
            return;
        }
        
        MPForwardQueueItem *forwardQueueItem;
        if (event) {
            forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector event:event messageType:messageType];
            MPILogVerbose(@"Kits not initialized - queueing event message: %@", event);
        } else if (selector != @selector(logEvent:)) {
            forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector parameters:parameters messageType:messageType];
            MPILogVerbose(@"Kits not initialized - queueing message with selector: %@", NSStringFromSelector(selector));
        }
        
        if (forwardQueueItem) {
            [self.forwardQueue addObject:forwardQueueItem];
        }
        
        return;
    }
    
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    MPILogDebug(@"forwardSDKCall - selector: %@, activeKits: %lu", NSStringFromSelector(selector), (unsigned long)activeKitsRegistry.count);
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if (event && [event isMemberOfClass:[MPEvent class]]) {
            [self filter:kitRegister forEvent:(MPEvent *)event selector:selector parameters:parameters];
        } else {
            MPKitFilter *kitFilter = [self filter:kitRegister forBaseEvent:event forSelector:selector];
            [self attemptToLogEventToKit:kitRegister kitFilter:kitFilter selector:selector parameters:parameters messageType:messageType userInfo:userInfo];
        }
    }
}

- (void)attemptToLogEventToKit:(id<MPExtensionKitProtocol>)kitRegister kitFilter:(MPKitFilter *)kitFilter selector:(SEL)selector parameters:(nullable MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType userInfo:(NSDictionary *)userInfo {
    if (kitFilter.shouldFilter && !kitFilter.filteredAttributes) {
        MPILogDebug(@"Kit filtered out event: %@", kitFilter.forwardEvent.description);
        return;
    }
    
    __block NSNumber *lastKit = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([kitFilter.forwardEvent isKindOfClass:[MPEvent class]] && ((MPEvent *)kitFilter.forwardEvent).name != nil) {
            MPILogDebug(@"Forwarding %@ call to kit: %@", ((MPEvent *)kitFilter.forwardEvent).name, kitRegister.name);
        } else if (NSStringFromSelector(selector) != nil) {
            MPILogDebug(@"Forwarding %@ call to kit: %@", NSStringFromSelector(selector), kitRegister.name);
        }
        
        MPKitExecStatus *execStatus = nil;
        
        @try {
            id<MPKitProtocol> kit = kitRegister.wrapperInstance;
            SEL effectiveSelector = selector;

            if ([kit respondsToSelector:@selector(logBaseEvent:)] &&
                (selector == @selector(logEvent:) || selector == @selector(logBaseEvent:))) {
                effectiveSelector = @selector(logBaseEvent:);
            }

            id filteredUser = nil;
            if (effectiveSelector == @selector(selectPlacementsWithIdentifier:attributes:embeddedViews:config:onEvent:filteredUser:options:) ||
                effectiveSelector == @selector(selectShoppableAdsWithIdentifier:attributes:config:onEvent:filteredUser:)) {
                if (kitFilter.shouldFilter) {
                    MPILogDebug(@"%@ filtered out for kit: %@ - shouldFilter: YES",
                                NSStringFromSelector(effectiveSelector), kitRegister.name);
                    return;
                }

                MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
                MPILogVerbose(@"%@ - kit: %@, currentUser: %@", NSStringFromSelector(effectiveSelector),
                              kitRegister.name, currentUser ? currentUser.userId : @"nil");
                filteredUser = [[FilteredMParticleUser alloc]
                    initWithMParticleUser:currentUser
                         kitConfiguration:self.kitConfigurations[kitRegister.code]];
            }

            if ((effectiveSelector == @selector(logEvent:) || effectiveSelector == @selector(logScreen:)) &&
                ![kitFilter.forwardEvent isKindOfClass:[MPEvent class]]) {
                return;
            }
            if (effectiveSelector == @selector(logBaseEvent:) && !kitFilter.forwardEvent) {
                return;
            }

            MPKitInvocationResult *result = [self.selectorInvoker invoke:(id<MPKitDispatchTarget>)kit
                                                           selectorName:NSStringFromSelector(effectiveSelector)
                                                                  event:kitFilter.forwardEvent
                                                           filteredUser:filteredUser
                                                             parameters:parameters];

            switch (result.outcome) {
                case MPKitInvocationOutcomeReturnedStatus:
                    if ([result.returnedObject isKindOfClass:[MPKitExecStatus class]]) {
                        execStatus = (MPKitExecStatus *)result.returnedObject;
                    } else {
                        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:kitRegister.code
                                                                  returnCode:MPKitReturnCodeFail];
                    }
                    break;
                case MPKitInvocationOutcomeCompletedWithoutStatus:
                    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:kitRegister.code
                                                              returnCode:MPKitReturnCodeSuccess];
                    break;
                case MPKitInvocationOutcomeNotImplemented:
                    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:kitRegister.code
                                                              returnCode:MPKitReturnCodeFail];
                    MPILogError(@"Forwarded selector: %@ is not supported by this kit",
                                NSStringFromSelector(effectiveSelector));
                    break;
                case MPKitInvocationOutcomeMissingArguments:
                    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:kitRegister.code
                                                              returnCode:MPKitReturnCodeFail];
                    MPILogError(@"Forwarded selector: %@ is missing required arguments",
                                NSStringFromSelector(effectiveSelector));
                    break;
                case MPKitInvocationOutcomeUnknownSelector:
                    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:kitRegister.code
                                                              returnCode:MPKitReturnCodeFail];
                    break;
            }
            
            if (execStatus.success) {
                MPILogDebug(@"Successfully forwarded SDK call to kit: %@ (code: %@)", kitRegister.name, kitRegister.code);
            } else {
                MPILogError(@"Failed to forward SDK call to kit: %@ (code: %@)", kitRegister.name, kitRegister.code);
            }
        } @catch (NSException *e) {
            execStatus = [[MPKitExecStatus alloc] initWithSDKCode:kitRegister.code returnCode:MPKitReturnCodeFail];
            MPILogError(@"Kit handler threw an exception: %@", e);
        }
        
        NSNumber *currentKit = kitRegister.code;
        if (execStatus.success && ![lastKit isEqualToNumber:currentKit] && messageType != MPMessageTypeUnknown && messageType != MPMessageTypeMedia) {
            lastKit = currentKit;
            
            if (!kitFilter.appliedProjections) {
                [self forwardEventRecord:kitFilter messageType:messageType userInfo:userInfo execStatus:execStatus event:kitFilter.originalEvent];
            } else if (kitFilter.originalCommerceEventCopy) {
                [self forwardCommerceEventRecord:kitFilter execStatus:execStatus commerceEvent:kitFilter.originalCommerceEventCopy];
            } else if (kitFilter.originalEventCopy) {
                [self forwardEventRecord:kitFilter messageType:messageType userInfo:userInfo execStatus:execStatus event:kitFilter.originalEventCopy];
            }
        }
    });
}

- (void)forwardEventRecord:(MPKitFilter *)kitFilter messageType:(MPMessageType)messageType userInfo:(NSDictionary *)userInfo execStatus:(MPKitExecStatus*) execStatus event:(MPBaseEvent *)event{
    MPForwardRecord *forwardRecord = nil;
    
    if (messageType == MPMessageTypeOptOut || messageType == MPMessageTypePushRegistration) {
        forwardRecord = [[MPForwardRecord alloc] initWithMessageType:messageType
                                                          execStatus:execStatus
                                                           stateFlag:[userInfo[@"state"] boolValue]];
    } else {
        
        forwardRecord = [[MPForwardRecord alloc] initWithMessageType:messageType
                                                          execStatus:execStatus
                                                           kitFilter:kitFilter
                                                       originalEvent:event];
    }
    
    if (forwardRecord != nil) {
        dispatch_async([MParticle messageQueue], ^{
            [[MParticle sharedInstance].persistenceController saveForwardRecord:forwardRecord];
        });
    }
}

- (void)forwardCommerceEventRecord:(MPKitFilter *)kitFilter execStatus:(MPKitExecStatus*) execStatus commerceEvent:(MPCommerceEvent *)commerceEvent{
    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypeCommerceEvent
                                                                       execStatus:execStatus
                                                                        kitFilter:kitFilter
                                                                    originalEvent:commerceEvent];
    dispatch_async([MParticle messageQueue], ^{
        [[MParticle sharedInstance].persistenceController saveForwardRecord:forwardRecord];
    });
}

- (void)forwardSDKCall:(SEL)selector userAttributeKey:(NSString *)key value:(id)value kitHandler:(void (^)(id<MPKitProtocol> kit, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    SEL setUserAttributeSelector = @selector(setUserAttribute:value:);
    SEL setUserAttributeListSelector = @selector(setUserAttribute:values:);
    SEL otherUserAttributeSelector = NULL;
    
    if (selector == setUserAttributeListSelector) {
        otherUserAttributeSelector = setUserAttributeSelector;
    } else if (selector == setUserAttributeSelector) {
        otherUserAttributeSelector = setUserAttributeListSelector;
    }
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector] || (otherUserAttributeSelector && [kitRegister.wrapperInstance respondsToSelector:otherUserAttributeSelector])) {
            MPKitFilter *kitFilter = [self filter:kitRegister forUserAttributeKey:key value:value];
            
            if (!kitFilter.shouldFilter) {
                MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
                
                @try {
                    kitHandler(kitRegister.wrapperInstance, kitConfiguration);
                } @catch (NSException *e) {
                    MPILogError(@"Kit handler threw an exception: %@", e);
                }
                
                MPILogDebug(@"Forwarded user attribute key: %@ value: %@ to kit: %@", key, value, kitRegister.name);
            }
        }
    }
}

- (void)forwardSDKCall:(SEL)selector userAttributes:(NSDictionary *)userAttributes kitHandler:(void (^)(id<MPKitProtocol> kit, NSDictionary *forwardAttributes, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            MPKitFilter *kitFilter = [self filter:kitRegister forUserAttributes:userAttributes];
            
            MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
            
            @try {
                kitHandler(kitRegister.wrapperInstance, kitFilter.filteredAttributes, kitConfiguration);
            } @catch (NSException *e) {
                MPILogError(@"Kit handler threw an exception: %@", e);
            }
            
            MPILogDebug(@"Forwarded user attributes to kit: %@", kitRegister.name);
        }
    }
}

- (void)forwardSDKCall:(SEL)selector userIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType kitHandler:(void (^)(id<MPKitProtocol> kit, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            MPKitFilter *kitFilter = [self filter:kitRegister forUserIdentityKey:identityString identityType:identityType];
            
            if (!kitFilter.shouldFilter) {
                MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
                
                @try {
                    kitHandler(kitRegister.wrapperInstance, kitConfiguration);
                } @catch (NSException *e) {
                    MPILogError(@"Kit handler threw an exception: %@", e);
                }
                
                MPILogDebug(@"Forwarded setting user identity: %@ to kit: %@", identityString, kitRegister.name);
            }
        }
    }
}

- (void)forwardSDKCall:(SEL)selector consentState:(MPConsentState *)state kitHandler:(void (^)(id<MPKitProtocol> kit, MPConsentState *filteredConsentState, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            MPKitFilter *kitFilter = [self filter:kitRegister forConsentState:state];
            if (!kitFilter.shouldFilter) {
                MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
                
                @try {
                    kitHandler(kitRegister.wrapperInstance, kitFilter.forwardConsentState, kitConfiguration);
                } @catch (NSException *e) {
                    MPILogError(@"Kit handler threw an exception: %@", e);
                }
                
                MPILogDebug(@"Forwarded user attributes to kit: %@", kitRegister.name);
            }
        }
    }
}

- (void)forwardSDKCall:(SEL)selector errorMessage:(NSString *)errorMessage exception:(NSException *)exception eventInfo:(NSDictionary *)eventInfo kitHandler:(void (^)(id<MPKitProtocol> kit, MPKitExecStatus **execStatus))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithFilter:NO];
            
            if (!kitFilter.shouldFilter) {
                __block MPKitExecStatus *execStatus = nil;
                
                @try {
                    MPILogDebug(@"Forwarding %@ call to kit: %@", NSStringFromSelector(selector), kitRegister.name);
                    kitHandler(kitRegister.wrapperInstance, &execStatus);
                } @catch (NSException *e) {
                    MPILogError(@"Kit handler threw an exception: %@", e);
                }
            }
        }
    }
}

- (void)forwardIdentitySDKCall:(SEL)selector kitHandler:(void (^)(id<MPKitProtocol> kit, MPKitConfiguration *kitConfiguration))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
            
            MPILogDebug(@"Forwarding %@ call to kit: %@", NSStringFromSelector(selector), kitRegister.name);
            kitHandler(kitRegister.wrapperInstance, kitConfiguration);
        }
    }
}

- (void)forwardSDKCall:(SEL)selector batch:(NSDictionary *)batch kitHandler:(void (^)(id<MPKitProtocol> kit, NSDictionary *batch, MPKitConfiguration * _Nonnull kitConfiguration))kitHandler {
    NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
    
    for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
        if ([kitRegister.wrapperInstance respondsToSelector:selector]) {
            MPKitConfiguration *kitConfiguration = self.kitConfigurations[kitRegister.code];
            
            @try {
                kitHandler(kitRegister.wrapperInstance, batch, kitConfiguration);
            } @catch (NSException *e) {
                MPILogError(@"Kit handler threw an exception: %@", e);
            }
            
            MPILogDebug(@"Forwarded batch to kit: %@", kitRegister.name);
        }
    }
}


- (NSArray<NSDictionary<NSString *, id> *> *)userIdentitiesArrayForKit:(NSNumber *)integrationId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == %@", integrationId];
    id<MPExtensionKitProtocol>kitRegister = [[[MPKitContainer_PRIVATE registeredKits] filteredSetUsingPredicate:predicate] anyObject];
    if (!kitRegister) {
        return nil;
    }
    
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    NSArray<NSDictionary<NSString *, id> *> *userIdentities = userDefaults[kMPUserIdentityArrayKey];
    __block NSMutableArray *forwardUserIdentities = [[NSMutableArray alloc] initWithCapacity:userIdentities.count];
    
    [userIdentities enumerateObjectsUsingBlock:^(NSDictionary<NSString *,id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MPUserIdentity identityType = (MPUserIdentity)[obj[kMPUserIdentityTypeKey] integerValue];
        NSString *identityString = obj[kMPUserIdentityIdKey];
        MPKitFilter *kitFilter = [self filter:kitRegister forUserIdentityKey:identityString identityType:identityType];
        
        if (!kitFilter.shouldFilter) {
            [forwardUserIdentities addObject:obj];
        }
    }];
    return forwardUserIdentities;
}

- (nullable NSDictionary<NSString *, NSString *> *)integrationAttributesForKit:(nonnull NSNumber *)integrationId {
    NSArray<MPIntegrationAttributes *> *array = [[MParticle sharedInstance].persistenceController fetchIntegrationAttributes];
    __block NSDictionary<NSString *, NSString *> *dictionary = nil;
    [array enumerateObjectsUsingBlock:^(MPIntegrationAttributes * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.integrationId.intValue == integrationId.intValue) {
            dictionary = obj.attributes;
            *stop = YES;
        }
    }];
    return dictionary;
}


/*
 * Original intention of this method is to ensure that any kits that set
 * integration attributes have done so prior to the SDK's first upload.
 */
- (BOOL)shouldDelayUpload: (NSTimeInterval) maxWaitTime  {
    NSTimeInterval timeInterval = -1 * [_initializedTime timeIntervalSinceNow];
    if (timeInterval > maxWaitTime) {
        return NO;
    } else if (!self.kitsInitialized) {
        return YES;
    } else {
        NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
        for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
            if ([kitRegister.wrapperInstance respondsToSelector:@selector(shouldDelayMParticleUpload)] &&
                [kitRegister.wrapperInstance shouldDelayMParticleUpload]) {
                MPILogDebug(@"Delaying initial upload for kit: %@", kitRegister.name);
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)hasKitBatchingKits {
    static BOOL first = YES;
    static BOOL result = NO;
    if (first) {
        first = NO;
        
        NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [self activeKitsRegistry];
        for (id<MPExtensionKitProtocol>kitRegister in activeKitsRegistry) {
            if ([kitRegister.wrapperInstance respondsToSelector:@selector(logBatch:)]) {
                result = YES;
                break;
            }
        }
    }
    
    return result;
}

@end

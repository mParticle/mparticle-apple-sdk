#import "mParticle.h"
#import "MPILogger.h"
#import "MPAppNotificationHandler.h"
#import "MPConsumerInfo.h"
#import "MPForwardQueueParameters.h"
#import "MPForwardRecord.h"
#import "MPIConstants.h"
#import "MPIntegrationAttributes.h"
#import "MPKitActivity.h"
#import "MPKitFilter.h"
#import "MPNetworkPerformance.h"
#import "MPSession.h"
#import "MPIdentityApi.h"
#import "MPDataPlanFilter.h"
#import "MPUpload.h"
#import "MPKitContainer.h"
#import "MParticleSession+MParticlePrivate.h"
#import "MParticleOptions+MParticlePrivate.h"
#import "SettingsProvider.h"
#import "Executor.h"
#import "AppEnvironmentProvider.h"
#import "MPConvertJS.h"
#import "MPUserDefaultsConnector.h"
#import "SceneDelegateHandler.h"

@import mParticle_Apple_SDK_Swift;

static NSArray *eventTypeStrings = nil;
static MParticle *_sharedInstance = nil;
static dispatch_once_t predicate;

static MPWrapperSdk _wrapperSdk = MPWrapperSdkNone;
static NSString *_wrapperSdkVersion = nil;

static NSString *const kMPEventNameLogTransaction = @"Purchase";
static NSString *const kMPEventNameLTVIncrease = @"Increase LTV";
static NSString *const kMParticleFirstRun = @"firstrun";
static NSString *const kMPMethodName = @"$MethodName";
static NSString *const kMPStateKey = @"state";

@interface MPIdentityApi ()
- (void)identifyNoDispatch:(MPIdentityApiRequest *)identifyRequest completion:(nullable MPIdentityApiResultCallback)completion;
@end

@interface MPKitContainer_PRIVATE ()
- (BOOL)kitsInitialized;
@end

@interface MParticle() <MPBackendControllerDelegate
#if TARGET_OS_IOS == 1
, WKScriptMessageHandler
#endif
> {
    BOOL sdkInitialized;
}

@property (nonatomic, strong) id<MPPersistenceControllerProtocol> persistenceController;
@property (nonatomic, strong) MPDataPlanFilter *dataPlanFilter;
@property (nonatomic, strong) id<MPStateMachineProtocol> stateMachine;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;
@property (nonatomic, strong) id<MPKitContainerProtocol> kitContainer;
@property (nonatomic, strong) id<MPAppNotificationHandlerProtocol, OpenURLHandlerProtocol> appNotificationHandler;
@property (nonatomic, strong) SceneDelegateHandler *sceneDelegateHandler;
@property (nonatomic, strong, nonnull) id<MPBackendControllerProtocol> backendController;
@property (nonatomic, strong, nonnull) MParticleOptions *options;
@property (nonatomic, strong, nullable) MPKitActivity *kitActivity;
@property (nonatomic) BOOL initialized;
@property (nonatomic, strong, nonnull) NSMutableArray *kitsInitializedBlocks;
@property (nonatomic, readwrite, nullable) MPNetworkOptions *networkOptions;
@property (nonatomic, strong) MParticleWebViewPRIVATE *webView;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
@property (nonatomic, readwrite) MPDataPlanOptions *dataPlanOptions;
@property (nonatomic, readwrite) NSArray<NSNumber *> *disabledKits;

@property (nonatomic, strong) id<SettingsProviderProtocol> settingsProvider;
@property (nonatomic, strong, nonnull) id<MPNotificationControllerProtocol> notificationController;
@property (nonatomic, strong, nonnull) id<AppEnvironmentProviderProtocol> appEnvironmentProvider;
@end

@implementation MPDataPlanOptions
@end


@interface MPBackendController_PRIVATE ()

- (NSMutableArray<NSDictionary<NSString *, id> *> *)userIdentitiesForUserId:(NSNumber *)userId;

@end

#pragma mark - MParticle
@implementation MParticle

@synthesize identity = _identity;
@synthesize rokt = _rokt;
@synthesize optOut = _optOut;
@synthesize persistenceController = _persistenceController;
@synthesize stateMachine = _stateMachine;
@synthesize kitContainer_PRIVATE = _kitContainer_PRIVATE;
@synthesize kitContainer = _kitContainer;
@synthesize appNotificationHandler = _appNotificationHandler;
@synthesize settingsProvider = _settingsProvider;
static id<ExecutorProtocol> executor;
MPLog* logger;
@synthesize sceneDelegateHandler = _sceneDelegateHandler;

+ (void)initialize {
    if (self == [MParticle class]) {
        eventTypeStrings = @[@"Reserved - Not Used", @"Navigation", @"Location", @"Search", @"Transaction", @"UserContent", @"UserPreference", @"Social", @"Other"];
    }
}

- (MPLog*)getLogger {
    return logger;
}

+ (dispatch_queue_t)messageQueue {
    return executor.messageQueue;
}

+ (BOOL)isMessageQueue {
    return executor.isMessageQueue;
}

+ (void)executeOnMessage:(void(^)(void))block {
    [executor executeOnMessage: block];
}

+ (void)executeOnMessageSync:(void(^)(void))block {
    [executor executeOnMessageSync: block];
}

+ (void)executeOnMain:(void(^)(void))block {
    [executor executeOnMain: block];
}

+ (void)executeOnMainSync:(void(^)(void))block {
    [executor executeOnMainSync: block];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    executor = [[Executor alloc] init];
    sdkInitialized = NO;
    _initialized = NO;
    _settingsProvider = [[SettingsProvider alloc] init];
    _kitActivity = [[MPKitActivity alloc] init];
    _kitsInitializedBlocks = [NSMutableArray array];
    _collectUserAgent = YES;
    _collectSearchAdsAttribution = NO;
    _trackNotifications = YES;
    _automaticSessionTracking = YES;
    _appNotificationHandler = (id<MPAppNotificationHandlerProtocol, OpenURLHandlerProtocol>)[[MPAppNotificationHandler alloc] init];
    _stateMachine = [[MPStateMachine_PRIVATE alloc] init];
    _appEnvironmentProvider = [[AppEnvironmentProvider alloc] init];
    _notificationController = [[MPNotificationController_PRIVATE alloc] init];
    logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue: _stateMachine.logLevel]];
    _sceneDelegateHandler = [[SceneDelegateHandler alloc] initWithAppNotificationHandler:_appNotificationHandler];

    _webView = [[MParticleWebViewPRIVATE alloc] initWithMessageQueue:executor.messageQueue logger:logger sdkVersion:kMParticleSDKVersion];
    return self;
}

- (void)setExecutor: (id<ExecutorProtocol>)newExecutor {
    executor = newExecutor;
}

- (void)setKitContainer_PRIVATE:(MPKitContainer_PRIVATE*) kitContainer_PRIVATE {
    _kitContainer_PRIVATE = kitContainer_PRIVATE;
    _kitContainer = kitContainer_PRIVATE;
}

#pragma mark MPBackendControllerDelegate methods
- (void)sessionDidBegin:(MPSession *)session {
    [executor executeOnMain: ^{
        [self.kitContainer forwardSDKCall:@selector(beginSession)
                                    event:nil
                               parameters:nil
                              messageType:MPMessageTypeSessionStart
                                 userInfo:nil
        ];
    }];
}

- (void)sessionDidEnd:(MPSession *)session {
    [executor executeOnMain: ^{
        [self.kitContainer forwardSDKCall:@selector(endSession)
                                    event:nil
                               parameters:nil
                              messageType:MPMessageTypeSessionEnd
                                 userInfo:nil
        ];
    }];
}

#pragma mark MPBackendControllerDelegate methods
- (void)forwardLogInstall {
    [executor executeOnMain: ^{
        [self.kitContainer forwardSDKCall:_cmd
                                    event:nil
                               parameters:nil
                              messageType:MPMessageTypeUnknown
                                 userInfo:nil
        ];
    }];
}

- (void)forwardLogUpdate {
    [executor executeOnMain: ^{
        [self.kitContainer forwardSDKCall:_cmd
                                    event:nil
                               parameters:nil
                              messageType:MPMessageTypeUnknown
                                 userInfo:nil
        ];
    }];
}

#pragma mark - Public accessors and methods
- (MPIdentityApi *)identity {
    if (_identity) {
        return _identity;
    }
    
    _identity = [[MPIdentityApi alloc] init];
    return _identity;
}

- (MPRokt *)rokt {
    if (_rokt) {
        return _rokt;
    }
    
    _rokt = [[MPRokt alloc] init];
    return _rokt;
}

- (MPEnvironment)environment {
    return [MPStateMachine_PRIVATE environment];
}

- (MPILogLevel)logLevel {
    return self.stateMachine.logLevel;
}

- (void)setCustomLogger:(void (^)(NSString * _Nonnull))customLogger {
    _customLogger = customLogger;
    logger.customLogger = customLogger;
}

- (void)setLogLevel:(MPILogLevel)logLevel {
    logger.logLevel = [MPLog fromRawValue: logLevel];
    self.stateMachine.logLevel = logLevel;
}

- (BOOL)optOut {
    return self.stateMachine.optOut;
}

- (void)setOptOutCompletion:(MPExecStatus)execStatus optOut:(BOOL)optOut {
    if (execStatus == MPExecStatusSuccess) {
        NSString* message = [NSString stringWithFormat:@"Set Opt Out: %d", optOut];
        [logger debug:message];
    } else {
        NSString* message = [NSString stringWithFormat:@"Set Opt Out Failed: %lu", (unsigned long)execStatus];
        [logger debug:message];
    }
}

- (void)setOptOut:(BOOL)optOut {
    if (self.stateMachine.optOut == optOut) {
        return;
    }
    
    _optOut = optOut;
    self.stateMachine.optOut = optOut;
    
    // Forwarding calls to kits
    MPForwardQueueParameters *optOutParameters = [[MPForwardQueueParameters alloc] init];
    [optOutParameters addParameter:@(optOut)];
    
    [self.kitContainer forwardSDKCall:@selector(setOptOut:)
                                event:nil
                           parameters:optOutParameters
                          messageType:MPMessageTypeOptOut
                             userInfo:@{kMPStateKey:@(optOut)}
    ];
    
    __weak typeof(self) weakSelf = self;
    [self.backendController setOptOut:optOut
                    completionHandler:^(BOOL optOut, MPExecStatus execStatus) {
                        [weakSelf setOptOutCompletion:execStatus optOut:optOut];
                    }];
}

- (NSTimeInterval)sessionTimeout {
    return self.backendController.sessionTimeout;
}

- (NSString *)uniqueIdentifier {
    return self.stateMachine.consumerInfo.uniqueIdentifier;
}

- (void)setUploadInterval:(NSTimeInterval)uploadInterval {
    if (uploadInterval >= 1.0 && uploadInterval != self.backendController.uploadInterval) {
        [self upload];
        self.backendController.uploadInterval = uploadInterval;
    }
}

- (NSTimeInterval)uploadInterval {
    return self.backendController.uploadInterval;
}

- (NSDictionary<NSString *, id> *)userAttributesForUserId:(NSNumber *)userId {
    NSDictionary *userAttributes = [[self.backendController userAttributesForUserId:userId] copy];
    return userAttributes;
}

- (NSString *)version {
    return [kMParticleSDKVersion copy];
}

- (NSNumber *)configMaxAgeSeconds {
    return self.options.configMaxAgeSeconds;
}

- (NSNumber *)persistenceMaxAgeSeconds {
    return self.options.persistenceMaxAgeSeconds;
}

#pragma mark Initialization
+ (instancetype)sharedInstance {
    dispatch_once(&predicate, ^{
        _sharedInstance = [[MParticle alloc] init];
    });
    
    return _sharedInstance;
}

+ (void)setSharedInstance:(MParticle *)instance {
    predicate = 0; // resets the once_token so dispatch_once will run again
    _sharedInstance = instance;
}

- (void)identifyNoDispatchCallback:(MPIdentityApiResult * _Nullable)apiResult
                             error:(NSError * _Nullable)error
                           options:(MParticleOptions * _Nonnull)options {
    if (error) {
        NSString* message = [NSString stringWithFormat: @"Identify request failed with error: %@", error];
        [logger error:message];
    }
    
    NSArray<NSDictionary *> *deferredKitConfiguration = self.deferredKitConfiguration_PRIVATE;
    
    if (deferredKitConfiguration != nil && [deferredKitConfiguration isKindOfClass:[NSArray class]]) {
        MPILogDebug(@"Processing deferred kit configuration with %lu kit(s)", (unsigned long)deferredKitConfiguration.count);
        [executor executeOnMain: ^{
            [self.kitContainer configureKits:deferredKitConfiguration];
            self.deferredKitConfiguration_PRIVATE = nil;
        }];
    } else {
        MPILogDebug(@"No deferred kit configuration to process");
    }
    
    if (options.onIdentifyComplete) {
        MPILogDebug(@"Invoking onIdentifyComplete callback - result: %@, error: %@",
                    apiResult ? @"present" : @"nil", error ? error.localizedDescription : @"none");
        [executor executeOnMain: ^{
            options.onIdentifyComplete(apiResult, error);
        }];
    }
}

- (void)configureWithOptions:(MParticleOptions * _Nonnull)options {
    NSMutableDictionary* settings = self.settingsProvider.configSettings;
    MPILogDebug(@"configureWithOptions - settings present: %@", settings ? @"YES" : @"NO");
    if (settings) {
        if (settings[kMPConfigSessionTimeout] && !options.isSessionTimeoutSet) {
            self.backendController.sessionTimeout = [settings[kMPConfigSessionTimeout] doubleValue];
        }
        
        if (settings[kMPConfigUploadInterval] && !options.isUploadIntervalSet) {
            self.backendController.uploadInterval = [settings[kMPConfigUploadInterval] doubleValue];
        }
        
        if (settings[kMPConfigCustomUserAgent] && !options.customUserAgent) {
            self->_customUserAgent = settings[kMPConfigCustomUserAgent];
        }
        
        if (settings[kMPConfigCollectUserAgent] && !options.isCollectUserAgentSet) {
            self->_collectUserAgent = [settings[kMPConfigCollectUserAgent] boolValue];
        }
        
        if (settings[kMPConfigTrackNotifications] && !options.isTrackNotificationsSet) {
            self->_trackNotifications = [settings[kMPConfigTrackNotifications] boolValue];
        }
    }
}

- (void)startWithKeyCallback:(BOOL)firstRun
                     options:(MParticleOptions * _Nonnull)options
                userDefaults:(id<MPUserDefaultsProtocol>)userDefaults {
    MPILogDebug(@"SDK startWithKeyCallback - firstRun: %@", firstRun ? @"YES" : @"NO");

    MPIdentityApiRequest *identifyRequest = nil;
    if (options.identifyRequest) {
        identifyRequest = options.identifyRequest;
    } else {
        MParticleUser *user = [MParticle sharedInstance].identity.currentUser;
        identifyRequest = [MPIdentityApiRequest requestWithUser:user];
    }
    
    [self.identity identifyNoDispatch:identifyRequest completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
        [self identifyNoDispatchCallback:apiResult error:error options:options];
    }];
    
    if (firstRun) {
        [userDefaults setMPObject:@NO forKey:kMParticleFirstRun userId:[MPPersistenceController_PRIVATE mpId]];
        [userDefaults synchronize];
    }
    
    self->_optOut = self.stateMachine.optOut;
    
    MPILogDebug(@"Applying SDK configuration from options");
    [self configureWithOptions:options];
    
    self.initialized = YES;
    MPILogDebug(@"SDK initialization complete - initialized: YES");
    self.settingsProvider.configSettings = nil;
    [executor executeOnMain: ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleDidFinishInitializing
                                                            object:self
                                                          userInfo:nil];
    }];
}

- (void)startWithOptions:(MParticleOptions *)options {
    if (sdkInitialized) {
        return;
    }
    sdkInitialized = YES;
    
    MPILogDebug(@"SDK initialization starting - environment: %ld, logLevel: %lu",
                (long)options.environment, (unsigned long)options.logLevel);

    [self.webView startWithCustomUserAgent:options.customUserAgent shouldCollect:options.collectUserAgent defaultUserAgentOverride:options.defaultAgent];
    
    _backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:self];
    
    if (options.networkOptions) {
        self.networkOptions = options.networkOptions;
        MPILogDebug(@"Network options configured - pinningDisabled: %@, pinningDisabledInDevelopment: %@, configHost: %@",
                    options.networkOptions.pinningDisabled ? @"YES" : @"NO",
                    options.networkOptions.pinningDisabledInDevelopment ? @"YES" : @"NO",
                    options.networkOptions.configHost ?: @"default");
    }
    
    NSString *apiKey = options.apiKey;
    NSString *secret = options.apiSecret;

    NSAssert(apiKey && secret, @"mParticle SDK must be started with an apiKey and secret.");
    NSAssert([apiKey isKindOfClass:[NSString class]] && [secret isKindOfClass:[NSString class]], @"mParticle SDK apiKey and secret must be of type string.");
    NSAssert(apiKey.length > 0 && secret.length > 0, @"mParticle SDK apiKey and secret cannot be an empty string.");
    NSAssert((NSNull *)apiKey != [NSNull null] && (NSNull *)secret != [NSNull null], @"mParticle SDK apiKey and secret cannot be null.");
    
    self.options = options;
    
    self.dataPlanId = options.dataPlanId;
    if (self.dataPlanId != nil) {
        self.dataPlanVersion = options.dataPlanVersion;
    }
    
    self.dataPlanOptions = options.dataPlanOptions;
    if (self.dataPlanOptions != nil) {
        self.dataPlanFilter = [[MPDataPlanFilter alloc] initWithDataPlanOptions:self.dataPlanOptions];
    }
    
    MPInstallationType installationType = options.installType;
    MPEnvironment environment = options.environment;
    BOOL startKitsAsync = options.startKitsAsync;
    
    __weak MParticle *weakSelf = self;
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    BOOL firstRun = [userDefaults mpObjectForKey:kMParticleFirstRun userId:[MPPersistenceController_PRIVATE mpId]] == nil;
    if (firstRun) {
        NSDate *firstSeen = [NSDate date];
        NSNumber *firstSeenMs = @([firstSeen timeIntervalSince1970] * 1000.0);
        [userDefaults setMPObject:firstSeenMs forKey:kMPFirstSeenUser userId:[MPPersistenceController_PRIVATE mpId]];
    }
    
    _automaticSessionTracking = self.options.automaticSessionTracking;
    _shouldBeginSession = self.options.shouldBeginSession;
    _customUserAgent = self.options.customUserAgent;
    _collectUserAgent = self.options.collectUserAgent;
    _collectSearchAdsAttribution = self.options.collectSearchAdsAttribution;
    _trackNotifications = self.options.trackNotifications;
    self.backendController.uploadInterval = options.uploadInterval;
    self.backendController.sessionTimeout = options.sessionTimeout;
    self.logLevel = options.logLevel;
    self.customLogger = options.customLogger;
    
    MPConsentState *consentState = self.options.consentState;
    
    [userDefaults setSharedGroupIdentifier:self.options.sharedGroupID];

    if (environment == MPEnvironmentDevelopment) {
        [logger warning:@"SDK has been initialized in Development mode."];
    } else if (environment == MPEnvironmentProduction) {
        [logger warning:@"SDK has been initialized in Production Mode."];
    }
    
    [MPStateMachine_PRIVATE setEnvironment:environment];
    self.stateMachine.automaticSessionTracking = options.automaticSessionTracking;
    if (options.attStatus != nil) {
        [self setATTStatus:(MPATTAuthorizationStatus)options.attStatus.integerValue withATTStatusTimestampMillis:options.attStatusTimestampMillis];
    }
    
    if ([MParticle isOlderThanConfigMaxAgeSeconds]) {
        [MPUserDefaults deleteConfig];
    }
    
    _kitContainer_PRIVATE = [[MPKitContainer_PRIVATE alloc] init];
    _kitContainer_PRIVATE.sideloadedKits = options.sideloadedKits ?: [NSArray array];
    _kitContainer_PRIVATE.disabledKits = options.disabledKits;
    _kitContainer = _kitContainer_PRIVATE;
    
    NSUInteger sideLoadedKitsCount = _kitContainer_PRIVATE.sideloadedKits.count;
    MPILogDebug(@"Kit container created - sideloadedKits: %lu, disabledKits: %lu",
                (unsigned long)sideLoadedKitsCount, (unsigned long)options.disabledKits.count);
    [userDefaults setSideloadedKitsCount:sideLoadedKitsCount];

    [self.backendController startWithKey:apiKey
                                  secret:secret
                          networkOptions:options.networkOptions
                                firstRun:firstRun
                        installationType:installationType
                          startKitsAsync:startKitsAsync
                            consentState:consentState
                       completionHandler:^{
                           [weakSelf startWithKeyCallback:firstRun options:options userDefaults:userDefaults];
                       }];
}

- (MParticleSession *)currentSession {
    MParticleSession *session = self.backendController.tempSession;
    if (session != nil) {
        return session;
    }
    
    MPSession *sessionInternal = self.stateMachine.currentSession;
    
    if (sessionInternal) {
        session = [[MParticleSession alloc] initWithUUID:sessionInternal.uuid];
        session.startTime = MPMilliseconds(sessionInternal.startTime);
    }
    
    return session;
}

- (void)resetForSwitchingWorkspaces:(void (^)(void))completion {
    [executor executeOnMessage:^{
        // Remove any kits that can't be reconfigured
        [self.kitContainer removeKitsFromRegistryInvalidForWorkspaceSwitch];
        
        // Clean up kits
        [self.kitContainer flushSerializedKits];
        [self.kitContainer removeAllSideloadedKits];
        
        // Clean up persistence
        [MPUserDefaultsConnector.userDefaults resetDefaults];
        [self.persistenceController resetDatabaseForWorkspaceSwitching];
        
        // Clean up mParticle instance
        [executor executeOnMain:^{
            [MParticle setSharedInstance:nil];
            if (completion) {
                completion();
            }
        }];
    }];
}

- (void)switchWorkspaceWithOptions:(MParticleOptions *)options {
    void (^finishReset)(void) = ^void(void) {
        // Reset SDK (config, database--except uploads, user defaults, kits, etc)
        [self resetForSwitchingWorkspaces:^{
            // Start the SDK using the new options
            // NOTE: Explicitely calling sharedInstance here to generate a new one
            // as reset nil's out the old one and self may be deallocated
            [[MParticle sharedInstance] startWithOptions:options];
        }];
    };
    
    if (sdkInitialized) {
        // End session if we use automatic session tracking
        if (self.currentSession && self.automaticSessionTracking) {
            [self.backendController endSession];
        }
        
        // Batch any remaining messages into upload records
        [executor executeOnMessage:^{
            [self.backendController prepareBatchesForUpload:[MPUploadSettings currentUploadSettingsWithStateMachine:self.stateMachine networkOptions:self.networkOptions]];
            finishReset();
        }];
    } else {
        finishReset();
    }
}

#pragma mark Application notifications
#if TARGET_OS_IOS == 1
- (NSData *)pushNotificationToken {
    if (![self.appEnvironmentProvider isAppExtension]) {
        return [self.notificationController deviceToken];
    } else {
        return nil;
    }
}

- (void)setPushNotificationToken:(NSData *)pushNotificationToken {
    if (![self.appEnvironmentProvider isAppExtension]) {
        [self.notificationController setDeviceToken:pushNotificationToken];
    }
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if (![self.appEnvironmentProvider isAppExtension]) {
        [self.appNotificationHandler didReceiveRemoteNotification:userInfo];
    }
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (![self.appEnvironmentProvider isAppExtension]) {
        [self.appNotificationHandler didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if (![self.appEnvironmentProvider isAppExtension]) {
        [self.appNotificationHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    if (![self.appEnvironmentProvider isAppExtension]) {
        [self.appNotificationHandler handleActionWithIdentifier:identifier forRemoteNotification:userInfo];
    }
}

- (void)handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(nullable NSDictionary *)userInfo withResponseInfo:(nonnull NSDictionary *)responseInfo {
    if (![self.appEnvironmentProvider isAppExtension]) {
        [self.appNotificationHandler handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo];
    }
}

- (void)handleURLContext:(UIOpenURLContext *)urlContext API_AVAILABLE(ios(13.0)) {
    [self.sceneDelegateHandler handleWithUrlContext:urlContext];
}
#endif

- (void)handleUserActivity:(NSUserActivity *)userActivity {
    [self.sceneDelegateHandler handleUserActivity:userActivity];
}

#if TARGET_OS_IOS == 1
- (void)handleURLContext:(UIOpenURLContext *)urlContext API_AVAILABLE(ios(13.0)) {
    [self.sceneDelegateHandler handleWithUrlContext:urlContext];
}
#endif

- (void)handleUserActivity:(NSUserActivity *)userActivity {
    [self.sceneDelegateHandler handleUserActivity:userActivity];
}

- (void)reset:(void (^)(void))completion {
    [executor executeOnMessage:^{
        [self.kitContainer flushSerializedKits];
        [self.kitContainer removeAllSideloadedKits];
        [MPUserDefaultsConnector.userDefaults resetDefaults];
        [self.persistenceController resetDatabase];
        [executor executeOnMain:^{
            predicate = 0;
            _sharedInstance = nil;
            if (completion) {
                completion();
            }
        }];
    }];
}

- (void)reset {
    [executor executeOnMessageSync:^{
        [MPUserDefaultsConnector.userDefaults resetDefaults];
        [[MParticle sharedInstance].persistenceController resetDatabase];
        [MParticle setSharedInstance:nil];
    }];
}

#pragma mark Basic tracking
- (nullable NSSet *)activeTimedEvents {
    return self.backendController.eventSet;
}

- (void)beginTimedEventCompletionHandler:(MPEvent *)event execStatus:(MPExecStatus)execStatus {
    if (execStatus == MPExecStatusSuccess) {
        NSString *message = [NSString stringWithFormat:@"Began timed event: %@", event];
        [logger debug:message];
        
        MPEvent *kitEvent = self.dataPlanFilter != nil ? [self.dataPlanFilter transformEventForEvent:event] : event;
        if (kitEvent) {
            // Forwarding calls to kits
            [executor executeOnMain: ^{
                [self.kitContainer forwardSDKCall:@selector(beginTimedEvent:)
                                            event:kitEvent
                                       parameters:nil
                                      messageType:MPMessageTypeEvent
                                         userInfo:nil
                ];
            }];
        } else {
            NSString *message = [NSString stringWithFormat:@"Blocked timed event begin from kits: %@", event];
            [logger debug:message];
        }
    }
}

- (void)beginTimedEvent:(MPEvent *)event {
    [self.backendController beginTimedEvent:event
                          completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                              [self beginTimedEventCompletionHandler:event execStatus:execStatus];
                          }];
}

- (void)logEventCallback:(MPEvent *)event execStatus:(MPExecStatus)execStatus {
    if (execStatus == MPExecStatusSuccess) {
        MPEvent *kitEvent = self.dataPlanFilter != nil ? [self.dataPlanFilter transformEventForEvent:event] : event;
        if (kitEvent) {
            [executor executeOnMain: ^{
                // Forwarding calls to kits
                [self.kitContainer forwardSDKCall:@selector(endTimedEvent:)
                                            event:kitEvent
                                       parameters:nil
                                      messageType:MPMessageTypeEvent
                                         userInfo:nil
                ];
                
                [self.kitContainer forwardSDKCall:@selector(logEvent:)
                                            event:kitEvent
                                       parameters:nil
                                      messageType:MPMessageTypeEvent
                                         userInfo:nil
                ];
            }];
        } else {
            NSString *message = [NSString stringWithFormat:@"Blocked timed event end from kits: %@", event];
            [logger debug:message];
        }
    }
}

- (void)endTimedEvent:(MPEvent *)event {
    [event endTiming];
    [executor executeOnMessage: ^{
        [self.backendController logEvent:event
                       completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                            [self logEventCallback:event execStatus:execStatus];
                       }];
    }];
}

- (MPEvent *)eventWithName:(NSString *)eventName {
    return [self.backendController eventWithName:eventName];
}

- (void)logEvent:(MPBaseEvent *)event {
    if ([event isKindOfClass:[MPEvent class]]) {
        [self logCustomEvent:(MPEvent *)event];
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self logCommerceEvent:(MPCommerceEvent *)event];
#pragma clang diagnostic pop
    } else {
        [executor executeOnMessage: ^{
            [self.backendController logBaseEvent:event
                               completionHandler:^(MPBaseEvent *event, MPExecStatus execStatus) {
                               }];
            MPBaseEvent *kitEvent = self.dataPlanFilter != nil ? [self.dataPlanFilter transformEventForBaseEvent:event] : event;
            if (kitEvent) {
                // Forwarding calls to kits
                [executor executeOnMain: ^{
                    [self.kitContainer forwardSDKCall:@selector(logBaseEvent:)
                                                event:kitEvent
                                           parameters:nil
                                          messageType:kitEvent.messageType
                                             userInfo:nil
                    ];
                }];
            } else {
                NSString *message = [NSString stringWithFormat:@"Blocked base event from kits: %@", event];
                [logger debug:message];
            }
        }];
    }
}

- (void)logCustomEvent:(MPEvent *)event {
    if (event == nil) {
        [logger error:@"Cannot log nil event!"];
        return;
    }
    
    [event endTiming];
    
    [executor executeOnMessage: ^{
        [self.backendController logEvent:event
                       completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                       }];
        MPEvent *kitEvent = self.dataPlanFilter != nil ? [self.dataPlanFilter transformEventForEvent:event] : event;
        if (kitEvent) {
            // Forwarding calls to kits
            [executor executeOnMain: ^{
                [self.kitContainer forwardSDKCall:@selector(logEvent:)
                                            event:kitEvent
                                       parameters:nil
                                      messageType:MPMessageTypeEvent
                                         userInfo:nil
                ];
            }];
        } else {
            NSString *message = [NSString stringWithFormat:@"Blocked custom event from kits: %@", event];
            [logger debug:message];
        }
        
    }];
}

- (void)logKitBatch:(NSString *)batch {
    if (batch == nil) {
        [logger error:@"Cannot log nil batch!"];
        return;
    }
    
    [executor executeOnMessage: ^{
        dispatch_block_t block = ^{
            if (batch) {
                if ([self.kitContainer hasKitBatchingKits]) {
                    NSData *finalData = [[NSData alloc] initWithBytes:batch.UTF8String length:batch.length];
                    NSDictionary *kitBatch = [NSJSONSerialization JSONObjectWithData:finalData options:0 error:nil];
                    
                    // Forwarding calls to kits
                    [executor executeOnMain: ^{
                        [self.kitContainer forwardSDKCall:@selector(logBatch:)
                                                    batch:kitBatch
                                               kitHandler:^(id<MPKitProtocol>  _Nonnull kit, NSDictionary * _Nonnull kitBatch, MPKitConfiguration * _Nonnull kitConfiguration) {
                            NSArray<MPForwardRecord *> *forwardRecords = [kit logBatch:kitBatch];
                            if ([forwardRecords isKindOfClass:[NSArray class]]) {
                                for (MPForwardRecord *forwardRecord in forwardRecords) {
                                    [executor executeOnMessage: ^{
                                        [self.persistenceController saveForwardRecord:forwardRecord];
                                    }];
                                }
                            }
                        }];
                    }];
                }
            }
        };
        
        BOOL kitsInitialized = self.kitContainer.kitsInitialized;
        if (kitsInitialized) {
            block();
        } else {
            dispatch_block_t deferredBlock = ^{
                dispatch_block_t blockCopy = [block copy];
                [executor executeOnMessage:blockCopy];
            };
            [self.kitsInitializedBlocks addObject:[deferredBlock copy]];
        }
    }];
}

- (void)logEvent:(NSString *)eventName eventType:(MPEventType)eventType eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    MPEvent *event = [self.backendController eventWithName:eventName];
    if (event) {
        event.type = eventType;
    } else {
        event = [[MPEvent alloc] initWithName:eventName type:eventType];
    }
    
    event.customAttributes = eventInfo;
    [self logEvent:event];
}

- (void)logScreenCallback:(MPEvent *)event execStatus:(MPExecStatus)execStatus {
    if (execStatus == MPExecStatusSuccess) {
        NSString *message = [NSString stringWithFormat:@"Logged screen event: %@", event];
        [logger debug:message];

        MPEvent *kitEvent = self.dataPlanFilter != nil ? [self.dataPlanFilter transformEventForScreenEvent:event] : event;
        if (kitEvent) {
            [executor executeOnMain: ^{
                // Forwarding calls to kits
                [self.kitContainer forwardSDKCall:@selector(logScreen:)
                                            event:kitEvent
                                       parameters:nil
                                      messageType:MPMessageTypeScreenView
                                         userInfo:nil
                ];
            }];
        } else {
            NSString *message = [NSString stringWithFormat:@"Blocked screen event from kits: %@", event];
            [logger debug:message];
        }
    }
}

- (void)logScreenEvent:(MPEvent *)event {
    [executor executeOnMessage: ^{
        [self.backendController logScreen:event
                        completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                            [self logScreenCallback:event execStatus:execStatus];
                        }];
    }];
}

- (void)logScreen:(NSString *)screenName eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    [self logScreen:screenName eventInfo:eventInfo shouldUploadEvent:YES];
}

- (void)logScreen:(NSString *)screenName eventInfo:(NSDictionary<NSString *, id> *)eventInfo shouldUploadEvent:(BOOL)shouldUploadEvent {
    if (screenName.length == 0) {
        [logger error:@"Screen name is required."];
        return;
    }
    
    MPEvent *event = [self.backendController eventWithName:screenName];
    if (!event) {
        event = [[MPEvent alloc] initWithName:screenName type:MPEventTypeNavigation];
    }
    
    event.customAttributes = eventInfo;
    event.shouldUploadEvent = shouldUploadEvent;
    
    [self logScreenEvent:event];
}

- (void)setATTStatus:(MPATTAuthorizationStatus)status withATTStatusTimestampMillis:(NSNumber *)attStatusTimestampMillis {
    NSNumber *currentStatus = self.stateMachine.attAuthorizationStatus;
    if (currentStatus == nil || currentStatus.integerValue != status) {
        self.stateMachine.attAuthorizationStatus = @(status);
        if (attStatusTimestampMillis != nil) {
            self.stateMachine.attAuthorizationTimestamp = attStatusTimestampMillis;
        }
    }
    
    // Forward to kits
    [executor executeOnMain: ^{
        NSNumber *parameter0 = @(status);
        NSObject *parameter1 = attStatusTimestampMillis ?: [NSNull null];
        MPForwardQueueParameters *parameters = [[MPForwardQueueParameters alloc] initWithParameters:@[parameter0, parameter1]];
        [self.kitContainer forwardSDKCall:@selector(setATTStatus:withATTStatusTimestampMillis:)
                                    event:nil
                               parameters:parameters
                              messageType:MPMessageTypeUnknown
                                 userInfo:nil
        ];
    }];
}

#pragma mark Attribution
- (nullable NSDictionary<NSNumber *, MPAttributionResult *> *)attributionInfo {
    return [self.kitContainer.attributionInfo copy];
}

#pragma mark Error, Exception, and Crash Handling
- (void)leaveBreadcrumb:(NSString *)breadcrumbName {
    [self leaveBreadcrumb:breadcrumbName eventInfo:nil];
}

- (void)leaveBreadcrumbCallback:(MPEvent *)event execStatus:(MPExecStatus)execStatus {
    if (execStatus == MPExecStatusSuccess) {
        NSString *message = [NSString stringWithFormat:@"Left breadcrumb: %@", event];
        [logger debug:message];

        MPEvent *kitEvent = self.dataPlanFilter != nil ? [self.dataPlanFilter transformEventForEvent:event] : event;
        if (kitEvent) {
            [executor executeOnMain: ^{
                // Forwarding calls to kits
                [self.kitContainer forwardSDKCall:@selector(leaveBreadcrumb:)
                                            event:kitEvent
                                       parameters:nil
                                      messageType:MPMessageTypeBreadcrumb
                                         userInfo:nil
                ];
            }];
        } else {
            NSString *message = [NSString stringWithFormat:@"Blocked breadcrumb event from kits: %@", event];
            [logger debug:message];
        }
    }
}

- (void)leaveBreadcrumb:(NSString *)breadcrumbName eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    if (!breadcrumbName) {
        [logger error:@"Breadcrumb name is required."];
        return;
    }
    
    MPEvent *event = [self.backendController eventWithName:breadcrumbName];
    if (!event) {
        event = [[MPEvent alloc] initWithName:breadcrumbName type:MPEventTypeOther];
    }
    
    event.customAttributes = eventInfo;
    
    if (!event.timestamp) {
        event.timestamp = [NSDate date];
    }
    
    [executor executeOnMessage: ^{
        [self.backendController leaveBreadcrumb:event
                              completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
                                [self leaveBreadcrumbCallback:event execStatus:execStatus];
                              }];
    }];
}

- (void)logError:(NSString *)message {
    [self logError:message eventInfo:nil];
}

- (void)logErrorCallback:(NSDictionary<NSString *,id> * _Nullable)eventInfo execStatus:(MPExecStatus)execStatus message:(NSString *)message {
    if (execStatus == MPExecStatusSuccess) {
        NSString *debugMessage = [NSString stringWithFormat:@"Logged error with message: %@", message];
        [logger debug:debugMessage];
        
        // Forwarding calls to kits
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:message];
        [queueParameters addParameter:eventInfo];
        
        [self.kitContainer forwardSDKCall:@selector(logError:eventInfo:)
                                    event:nil
                               parameters:queueParameters
                              messageType:MPMessageTypeUnknown
                                 userInfo:nil
        ];
    }
}

- (void)logError:(NSString *)message eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    if ([message isEqual: @""]) {
        NSString *message = [NSString stringWithFormat:@"'message' is required for %@", NSStringFromSelector(_cmd)];
        [logger error:message];
        return;
    }
    
    [executor executeOnMessage: ^{
        [self.backendController logError:message
                               exception:nil
                          topmostContext:nil
                               eventInfo:eventInfo
                       completionHandler:^(NSString *message, MPExecStatus execStatus) {
                            [self logErrorCallback:eventInfo execStatus:execStatus message:message];
                       }];
    }];
}

- (void)logException:(NSException *)exception {
    [self logException:exception topmostContext:nil];
}

- (void)logExceptionCallback:(NSException * _Nonnull)exception execStatus:(MPExecStatus)execStatus message:(NSString *)message topmostContext:(id _Nullable)topmostContext {
    if (execStatus == MPExecStatusSuccess) {
        NSString *debugMessage = [NSString stringWithFormat:@"Logged exception name: %@, reason: %@, topmost context: %@", message, exception.reason, topmostContext];
        [logger debug:debugMessage];
        
        // Forwarding calls to kits
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:exception];
        
        [self.kitContainer forwardSDKCall:@selector(logException:)
                                    event:nil
                               parameters:queueParameters
                              messageType:MPMessageTypeUnknown
                                 userInfo:nil
        ];
    }
}

- (void)logException:(NSException *)exception topmostContext:(id)topmostContext {
    [executor executeOnMessage: ^{
        [self.backendController logError:nil
                               exception:exception
                          topmostContext:topmostContext
                               eventInfo:nil
                       completionHandler:^(NSString *message, MPExecStatus execStatus) {
                            [self logExceptionCallback:exception execStatus:execStatus message:message topmostContext:topmostContext];
                       }];
    }];
}

- (void)logCrashCallback:(MPExecStatus)execStatus message:(NSString * _Nullable)message {
    if (execStatus == MPExecStatusSuccess) {
        NSString *debugMessage = [NSString stringWithFormat:@"Logged crash with message: %@", message];
        [logger debug:debugMessage];
    }
}

- (void)logCrash:(nullable NSString *)message
      stackTrace:(nullable NSString *)stackTrace
   plCrashReport:(NSString *)plCrashReport
{
    if (!plCrashReport) {
        NSString *message = [NSString stringWithFormat:@"'plCrashReport' is required for %@", NSStringFromSelector(_cmd)];
        [logger error:message];
        return;
    }
    
    [executor executeOnMessage: ^{
        [self.backendController logCrash:message
                              stackTrace:stackTrace
                           plCrashReport:plCrashReport
                       completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {
            [self logCrashCallback:execStatus message:message];
        }];
    }];
}

#pragma mark eCommerce transactions
- (void)logCommerceEventCallback:(MPCommerceEvent *)commerceEvent execStatus:(MPExecStatus)execStatus {
    if (execStatus == MPExecStatusSuccess) {
    } else {
        NSString *message = [NSString stringWithFormat:@"Failed to log commerce event: %@", commerceEvent];
        [logger debug:message];
    }
}

- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    if (!commerceEvent.timestamp) {
        commerceEvent.timestamp = [NSDate date];
    }
    
    [executor executeOnMessage: ^{
        [self.backendController logCommerceEvent:commerceEvent
                               completionHandler:^(MPCommerceEvent *commerceEvent, MPExecStatus execStatus) {
            [self logCommerceEventCallback:commerceEvent execStatus:execStatus];
        }];
        
        MPCommerceEvent *kitEvent = self.dataPlanFilter != nil ? [self.dataPlanFilter transformEventForCommerceEvent:commerceEvent] : commerceEvent;
        if (kitEvent) {
            // Forwarding calls to kits
            [self.kitContainer forwardCommerceEventCall:kitEvent];
        } else {
            NSString *message = [NSString stringWithFormat:@"Blocked commerce event from kits: %@", commerceEvent];
            [logger debug:message];
        }
    }];
}

- (void)logLTVIncrease:(double)increaseAmount eventName:(NSString *)eventName {
    [self logLTVIncrease:increaseAmount eventName:eventName eventInfo:nil];
}

- (void)logLTVIncreaseCallback:(MPEvent *)event execStatus:(MPExecStatus)execStatus {
    if (execStatus == MPExecStatusSuccess) {
        MPEvent *kitEvent = self.dataPlanFilter != nil ? [self.dataPlanFilter transformEventForEvent:event] : event;
        if (kitEvent) {
            [executor executeOnMain: ^{
                // Forwarding calls to kits
                [self.kitContainer forwardSDKCall:@selector(logLTVIncrease:event:)
                                                                     event:nil
                                                                parameters:nil
                                                               messageType:MPMessageTypeUnknown
                                                                  userInfo:nil
                ];
            }];
        } else {
            NSString* message = [NSString stringWithFormat:@"Blocked LTV increase event from kits: %@", event];
            [logger debug:message];
        }
    }
}

- (void)logLTVIncrease:(double)increaseAmount eventName:(NSString *)eventName eventInfo:(NSDictionary<NSString *, id> *)eventInfo {
    NSMutableDictionary *eventDictionary = [@{@"$Amount":@(increaseAmount),
                                              kMPMethodName:@"LogLTVIncrease"}
                                            mutableCopy];
    
    if (eventInfo) {
        [eventDictionary addEntriesFromDictionary:eventInfo];
    }
    
    MPEvent *event = [[MPEvent alloc] initWithName:eventName type:MPEventTypeTransaction];
    event.customAttributes = eventDictionary;
    
    [self.backendController logEvent:event
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {
        [self logLTVIncreaseCallback:event execStatus:execStatus];
    }];
}

#pragma mark Extensions
+ (BOOL)registerExtension:(nonnull id<MPExtensionProtocol>)extension {
    NSAssert(extension != nil, @"Required parameter. It cannot be nil.");
    BOOL registrationSuccessful = NO;
    
    if ([extension conformsToProtocol:@protocol(MPExtensionKitProtocol)]) {
        registrationSuccessful = [MPKitContainer_PRIVATE registerKit:(id<MPExtensionKitProtocol>)extension];
    }
    
    return registrationSuccessful;
}

#pragma mark Integration attributes
- (nonnull MPKitExecStatus *)setIntegrationAttributes:(nonnull NSDictionary<NSString *, NSString *> *)attributes forKit:(nonnull NSNumber *)integrationId {
    __block MPKitReturnCode returnCode = MPKitReturnCodeSuccess;

    MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    
    if (integrationAttributes) {
        [executor executeOnMessage: ^{
            [[MParticle sharedInstance].persistenceController saveIntegrationAttributes:integrationAttributes];
        }];
        
    } else {
        returnCode = MPKitReturnCodeRequirementsNotMet;
    }
    
    return [[MPKitExecStatus alloc] initWithSDKCode:integrationId returnCode:returnCode forwardCount:0];
}

- (nonnull MPKitExecStatus *)clearIntegrationAttributesForKit:(nonnull NSNumber *)integrationId {
    [executor executeOnMessage: ^{
        [[MParticle sharedInstance].persistenceController deleteIntegrationAttributesForIntegrationId:integrationId];
    }];

    return [[MPKitExecStatus alloc] initWithSDKCode:integrationId returnCode:MPKitReturnCodeSuccess forwardCount:0];
}

- (nullable NSDictionary *)integrationAttributesForKit:(nonnull NSNumber *)integrationId {
    return [[MParticle sharedInstance].persistenceController fetchIntegrationAttributesForId:integrationId];
}

#pragma mark Kits

- (void)onKitsInitialized:(void(^)(void))block {
    BOOL kitsInitialized = self.kitContainer.kitsInitialized;
    if (kitsInitialized) {
        block();
    } else {
        [self.kitsInitializedBlocks addObject:[block copy]];
    }
}

- (void)executeKitsInitializedBlocks {
    [self.kitsInitializedBlocks enumerateObjectsUsingBlock:^(void (^block)(void), NSUInteger idx, BOOL * _Nonnull stop) {
        block();
    }];
    [self.kitsInitializedBlocks removeAllObjects];
}

- (BOOL)isKitActive:(nonnull NSNumber *)kitCode {
    return [self.kitActivity isKitActive:kitCode];
}

- (nullable id const)kitInstance:(nonnull NSNumber *)kitCode {
    return [self.kitActivity kitInstance:kitCode];
}

- (void)kitInstance:(NSNumber *)kitCode completionHandler:(void (^)(id _Nullable kitInstance))completionHandler {
    BOOL isValidKitCode = [kitCode isKindOfClass:[NSNumber class]];
    BOOL isValidCompletionHandler = completionHandler != nil;
    NSAssert(isValidKitCode, @"The value in kitCode is not valid. See MPKitInstance.");
    NSAssert(isValidCompletionHandler, @"The parameter completionHandler is required.");
    
    if (!isValidKitCode || !isValidCompletionHandler) {
        return;
    }
    
    [self.kitActivity kitInstance:kitCode withHandler:completionHandler];
}

- (void)logNetworkPerformanceCallback:(MPExecStatus)execStatus {
    if (execStatus == MPExecStatusSuccess) {
        [logger debug:@"Logged network performance measurement"];
    }
}

- (void)logNetworkPerformance:(NSString *)urlString httpMethod:(NSString *)httpMethod startTime:(NSTimeInterval)startTime duration:(NSTimeInterval)duration bytesSent:(NSUInteger)bytesSent bytesReceived:(NSUInteger)bytesReceived {
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    MPNetworkPerformance *networkPerformance = [[MPNetworkPerformance alloc] initWithURLRequest:urlRequest networkMeasurementMode:MPNetworkMeasurementModePreserveQuery];
    networkPerformance.httpMethod = httpMethod;
    networkPerformance.startTime = startTime;
    networkPerformance.elapsedTime = duration;
    networkPerformance.bytesOut = bytesSent;
    networkPerformance.bytesIn = bytesReceived;
    
    [executor executeOnMessage: ^{
        [self.backendController logNetworkPerformanceMeasurement:networkPerformance
                                               completionHandler:^(MPNetworkPerformance *networkPerformance, MPExecStatus execStatus) {
                                                    [self logNetworkPerformanceCallback:execStatus];
                                               }];
        
    }];
}

#pragma mark Session management
- (NSNumber *)incrementSessionAttribute:(NSString *)key byValue:(NSNumber *)value {
    [executor executeOnMessage: ^{
        NSNumber *newValue = [self.backendController incrementSessionAttribute:[MParticle sharedInstance].stateMachine.currentSession key:key byValue:value];
        NSString *message = [NSString stringWithFormat:@"Session attribute %@ incremented by %@. New value: %@", key, value, newValue];
        [logger debug:message];
    }];
    
    return @0;
}

- (void)setSessionAttribute:(NSString *)key value:(id)value {
    [executor executeOnMessage: ^{
        MPExecStatus execStatus = [self.backendController setSessionAttribute:[MParticle sharedInstance].stateMachine.currentSession key:key value:value];
        if (execStatus == MPExecStatusSuccess) {
            NSString *message = [NSString stringWithFormat:@"Set session attribute - %@:%@", key, value];
            [logger debug:message];
        } else {
            NSString *message = [NSString stringWithFormat:@"Could not set session attribute - %@:%@\n Reason: %@", key, value, [MPBackendController_PRIVATE execStatusDescription:execStatus]];
            [logger error:message];
        }
    }];
}

- (void)beginSession {
    if (self.backendController.tempSession != nil || self.backendController.session != nil) {
        return;
    }
    [self.backendController createTempSession];
    NSDate *date = [NSDate date];
    [executor executeOnMessage: ^{
        [self.backendController beginSessionWithIsManual:YES date:date];
    }];
}

- (void)endSession {
    [executor executeOnMessage: ^{
        if (self.backendController.session == nil) {
            return;
        }
        [self.backendController endSessionWithIsManual:YES];
    }];
}

- (void)upload {
    __weak MParticle *weakSelf = self;
    
    [executor executeOnMessage: ^{
        __strong MParticle *strongSelf = weakSelf;
        
        MPExecStatus execStatus = [strongSelf.backendController waitForKitsAndUploadWithCompletionHandler:nil];
        
        if (execStatus == MPExecStatusSuccess) {
            [logger debug:@"Forcing Upload"];
        } else {
            NSString *message = [NSString stringWithFormat:@"Could not upload data: %@", [MPBackendController_PRIVATE execStatusDescription:execStatus]];
            [logger error:message];
        }
    }];
}

#pragma mark Surveys
- (NSString *)surveyURL:(MPSurveyProvider)surveyProvider {
    NSMutableDictionary *userAttributes = nil;
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    NSDictionary *savedUserAttributes = userDefaults[kMPUserAttributeKey];
    if (savedUserAttributes) {
        userAttributes = [[NSMutableDictionary alloc] initWithCapacity:savedUserAttributes.count];
        NSEnumerator *attributeEnumerator = [savedUserAttributes keyEnumerator];
        NSString *key;
        id value;
        Class NSStringClass = [NSString class];
        
        while ((key = [attributeEnumerator nextObject])) {
            value = savedUserAttributes[key];
            
            if ([value isKindOfClass:NSStringClass]) {
                if (![savedUserAttributes[key] isEqualToString:kMPNullUserAttributeString]) {
                    userAttributes[key] = value;
                }
            } else {
                userAttributes[key] = value;
            }
        }
    }
    
    __block NSString *surveyURL = nil;
    [executor executeOnMain: ^{
        [self.kitContainer forwardSDKCall:@selector(surveyURLWithUserAttributes:)
                           userAttributes:userAttributes
                               kitHandler:^(id<MPKitProtocol> kit, NSDictionary *forwardAttributes, MPKitConfiguration *kitConfig) {
                FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:[[[MParticle sharedInstance] identity] currentUser] kitConfiguration:kitConfig];
                surveyURL = [kit surveyURLWithUserAttributes:filteredUser.userAttributes];
            }
        ];
    }];
    
    return surveyURL;
}

#pragma mark User Notifications
#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification {
    if (!notification.request.content.userInfo) {
        return;
    }
    [self.appNotificationHandler userNotificationCenter:center willPresentNotification:notification];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response {
    if (!response.notification.request.content.userInfo) {
        return;
    }
    [self.appNotificationHandler userNotificationCenter:center didReceiveNotificationResponse:response];
}
#endif

#pragma mark Web Views
- (BOOL)isValidBridgeName:(NSString *)bridgeName {
    if (bridgeName == nil || ![bridgeName isKindOfClass:[NSString class]] || bridgeName.length == 0) {
        return NO;
    }
    
    NSCharacterSet *alphanumericSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"];
    NSString *result = [bridgeName stringByTrimmingCharactersInSet:alphanumericSet];
    if (![result isEqualToString:@""]) {
        return NO;
    }
    
    return YES;
}

- (NSString *)webviewBridgeValueWithCustomerBridgeName:(NSString *)customerBridgeName {
    if ([self isValidBridgeName:customerBridgeName]) {
        return customerBridgeName;
    }
    
    NSString *kWorkspaceTokenKey = @"wst";
    NSString *serverProvidedValue = [MPUserDefaultsConnector.userDefaults getConfiguration][kWorkspaceTokenKey];
    if ([self isValidBridgeName:serverProvidedValue]) {
        return serverProvidedValue;
    }
    
    return nil;
}

- (NSString *)bridgeVersion {
    NSString *kBridgeVersion = @"2";
    return kBridgeVersion;
}

#if TARGET_OS_IOS == 1
- (void)initializeWKWebView:(WKWebView *)webView bridgeName:(NSString *)bridgeName {
    NSString *bridgeValue = [self webviewBridgeValueWithCustomerBridgeName:bridgeName];
    if (bridgeValue == nil) {
        [logger error:@"Unable to initialize webview due to missing or invalid bridgeName"];
        return;
    }
    NSString *bridgeVersion = [self bridgeVersion];
    NSString *handlerName = [NSString stringWithFormat:@"mParticle_%@_v%@", bridgeValue, bridgeVersion];
    WKUserContentController *contentController = webView.configuration.userContentController;
    [contentController addScriptMessageHandler:self name:handlerName];
}

// Updates isIOS flag in JS API to true via webview.
- (void)initializeWKWebView:(WKWebView *)webView {
    [self initializeWKWebView:webView bridgeName:nil];
}

// Process web log event that is raised in iOS hybrid apps that are using WKWebView
- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    NSString *body = message.body;
    if (body == nil || ![body isKindOfClass:[NSString class]]) {
        [logger error:@"Unexpected non-string body received from webview bridge"];
        return;
    }
    
    @try {
        NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
        if (bodyData == nil) {
            [logger error:@"Unable to create data from webview bridge body string"];
            return;
        }
        
        NSError *error = nil;
        NSDictionary *bodyDictionary = [NSJSONSerialization JSONObjectWithData:bodyData options:kNilOptions error:&error];
        if (error != nil || bodyDictionary == nil || ![bodyDictionary isKindOfClass:[NSDictionary class]]) {
            NSString *message = [NSString stringWithFormat:@"Unable to create dictionary from webview data. error=%@", error];
            [logger error:message];
            return;
        }
        
        NSString *kPathKey = @"path";
        NSString *path = bodyDictionary[kPathKey];
        if (path == nil || ![path isKindOfClass:[NSString class]]) {
            [logger error:@"Unable to retrieve path from webview dictionary"];
            return;
        }
        
        NSString *kValueKey = @"value";
        NSDictionary *value = bodyDictionary[kValueKey];
        if (value == nil || ![value isKindOfClass:[NSDictionary class]]) {
            [logger error:@"Unable to retrieve value from webview dictionary"];
            return;
        }
        
        [self handleWebviewCommand:path dictionary:value];
    } @catch (NSException *e) {
        NSString *message = [NSString stringWithFormat:@"Exception processing WKWebView event: %@", e.reason];
        [logger error:message];
    }
}

- (void)handleWebviewCommand:(NSString *)command dictionary:(NSDictionary *)dictionary {
    if (!command || ![command isKindOfClass:[NSString class]] || (dictionary && ![dictionary isKindOfClass:[NSDictionary class]])) {
        [logger error:@"Unexpected data received from embedded webview"];
        return;
    }
    
    if ([command hasPrefix:kMParticleWebViewPathLogEvent]) {
        NSNumber *eventDataType = dictionary[@"EventDataType"];
        if (eventDataType == nil || ![eventDataType isKindOfClass:[NSNumber class]]) {
            [logger error:@"Unexpected event data type received from embedded webview"];
            return;
        }
        MPJavascriptMessageType messageType = (MPJavascriptMessageType)[eventDataType integerValue];
        switch (messageType) {
            case MPJavascriptMessageTypePageEvent: {
                if ((NSNull *)dictionary[@"EventName"] != [NSNull null] && [dictionary[@"EventCategory"] isKindOfClass:[NSNumber class]]) {
                    MPEvent *event = [[MPEvent alloc] initWithName:dictionary[@"EventName"] type:(MPEventType)[dictionary[@"EventCategory"] integerValue]];
                    if ((NSNull *)dictionary[@"EventAttributes"] != [NSNull null]) {
                        event.customAttributes = dictionary[@"EventAttributes"];
                    }
                    if ((NSNull *)dictionary[@"CustomFlags"] != [NSNull null]) {
                        NSDictionary *customFlags = dictionary[@"CustomFlags"] ;
                        for (NSString *key in customFlags.allKeys) {
                            NSString *value = customFlags[key];
                            if ([value isKindOfClass:[NSArray class]]) {
                                [event addCustomFlags:(NSArray *)value withKey:key];
                            } else {
                                [event addCustomFlag:value withKey:key];
                            }
                        }
                    }
                    [self logEvent:event];
                }
            }
                break;
                
            case MPJavascriptMessageTypePageView: {
                if ((NSNull *)dictionary[@"EventName"] != [NSNull null]) {
                    MPEvent *event = [[MPEvent alloc] initWithName:dictionary[@"EventName"] type:MPEventTypeNavigation];
                    if ((NSNull *)dictionary[@"EventAttributes"] != [NSNull null]) {
                        event.customAttributes = dictionary[@"EventAttributes"];
                    }
                    if ((NSNull *)dictionary[@"CustomFlags"] != [NSNull null]) {
                        NSDictionary *customFlags = dictionary[@"CustomFlags"] ;
                        for (NSString *key in customFlags.allKeys) {
                            NSString *value = customFlags[key];
                            if ([value isKindOfClass:[NSArray class]]) {
                                [event addCustomFlags:(NSArray *)value withKey:key];
                            } else {
                                [event addCustomFlag:value withKey:key];
                            }
                        }
                    }
                    [self logScreenEvent:event];
                }
            }
                break;
                
            case MPJavascriptMessageTypeCommerce: {
                MPCommerceEvent *event = [MPConvertJS_PRIVATE commerceEvent:dictionary];
                if (event != nil) {
                    [self logEvent:event];
                }
            }
                break;
                
            case MPJavascriptMessageTypeOptOut:
                if ([dictionary[@"OptOut"] isKindOfClass:[NSNumber class]]) {
                    [self setOptOut:[dictionary[@"OptOut"] boolValue]];
                }
                break;
                
            case MPJavascriptMessageTypeSessionStart:
            case MPJavascriptMessageTypeSessionEnd:
            default:
                break;
        }
    } else if ([command hasPrefix:kMParticleWebViewPathIdentify]) {
        MPIdentityApiRequest *request = [MPConvertJS_PRIVATE identityApiRequest:dictionary];
        
        if (!request) {
            NSString *message = [NSString stringWithFormat:@"Unable to create identify request from webview JS dictionary: %@", dictionary];
            [logger error:message];
            return;
        }
        
        [[MParticle sharedInstance].identity identify:request completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
            
        }];
        
        
    } else if ([command hasPrefix:kMParticleWebViewPathLogin]) {
        MPIdentityApiRequest *request = [MPConvertJS_PRIVATE identityApiRequest:dictionary];
        
        if (!request) {
            NSString *message = [NSString stringWithFormat:@"Unable to create login request from webview JS dictionary: %@", dictionary];
            [logger error:message];
            return;
        }
        
        [[MParticle sharedInstance].identity login:request completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
            
        }];
    } else if ([command hasPrefix:kMParticleWebViewPathLogout]) {
        MPIdentityApiRequest *request = [MPConvertJS_PRIVATE identityApiRequest:dictionary];
        
        if (!request) {
            NSString *message = [NSString stringWithFormat:@"Unable to create logout request from webview JS dictionary: %@", dictionary];
            [logger error:message];
            return;
        }
        
        [[MParticle sharedInstance].identity logout:request completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
            
        }];
    } else if ([command hasPrefix:kMParticleWebViewPathModify]) {
        MPIdentityApiRequest *request = [MPConvertJS_PRIVATE identityApiRequest:dictionary];
        
        if (!request) {
            NSString *message = [NSString stringWithFormat:@"Unable to create modify request from webview JS dictionary: %@", dictionary];
            [logger error:message];
            return;
        }
        
        [[MParticle sharedInstance].identity modify:request completion:^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
            
        }];
    } else if ([command hasPrefix:kMParticleWebViewPathSetUserTag]) {
        if (dictionary[@"key"] && (NSNull *)dictionary[@"key"] != [NSNull null]) {
            [self.identity.currentUser setUserTag:dictionary[@"key"]];
        }
    } else if ([command hasPrefix:kMParticleWebViewPathRemoveUserTag]) {
        if (dictionary[@"key"] && (NSNull *)dictionary[@"key"] != [NSNull null]) {
            [self.identity.currentUser removeUserAttribute:dictionary[@"key"]];
        }
    } else if ([command hasPrefix:kMParticleWebViewPathSetUserAttribute]) {
        if (!dictionary[@"key"] || (NSNull *)dictionary[@"key"] == [NSNull null]) {
            [logger error:@"Unexpected user attribute data received from webview"];
            return;
        }
        if (!dictionary[@"value"]) {
            [self.identity.currentUser setUserTag:dictionary[@"key"]];
        } else if ((NSNull *)dictionary[@"value"] != [NSNull null]) {
            [self.identity.currentUser setUserAttribute:dictionary[@"key"] value:dictionary[@"value"]];
        }
    } else if ([command hasPrefix:kMParticleWebViewPathRemoveUserAttribute]) {
        if (dictionary[@"key"] && (NSNull *)dictionary[@"key"] != [NSNull null]) {
            [self.identity.currentUser removeUserAttribute:dictionary[@"key"]];
        }
    } else if ([command hasPrefix:kMParticleWebViewPathSetSessionAttribute]) {
        if (!dictionary[@"key"]) {
            [logger error:@"Unexpected session attribute data received from webview"];
            return;
        }
        if ((NSNull *)dictionary[@"key"] != [NSNull null] && (NSNull *)dictionary[@"value"] != [NSNull null]) {
            [self setSessionAttribute:dictionary[@"key"] value:dictionary[@"value"]];
        }
    }
}

#pragma mark - Manual Notification logging
/**
 Logs a Notification event for a notification that has been reviewed but not acted upon. This is a convenience method for manually logging Notification events; Set trackNotifications to false on MParticleOptions to disable automatic tracking of Notifications and only set Notification manually:
 */
- (void)logNotificationReceivedWithUserInfo:(nonnull NSDictionary *)userInfo {
    if (userInfo == nil) {
        return;
    }
    [self logNotificationWithUserInfo:userInfo behavior:MPUserNotificationBehaviorReceived andActionIdentifier:nil];
}

/**
 Logs a Notification event for a notification that has been reviewed and acted upon. This is a convenience method for manually logging Notification events; Set trackNotifications to false on MParticleOptions to disable automatic tracking of Notifications and only set Notification manually:
 */
- (void)logNotificationOpenedWithUserInfo:(nonnull NSDictionary *)userInfo andActionIdentifier:(nullable NSString *)actionIdentifier {
    if (userInfo == nil) {
        return;
    }
    [self logNotificationWithUserInfo:userInfo behavior:MPUserNotificationBehaviorRead | MPUserNotificationBehaviorDirectOpen andActionIdentifier:actionIdentifier];
}

/**
 Logs a Notification event. This is a convenience method for manually logging Notification events; Set trackNotifications to false on MParticleOptions to disable automatic tracking of Notifications and only submit Notification events manually:
 */
- (void)logNotificationWithUserInfo:(nonnull NSDictionary *)userInfo behavior:(MPUserNotificationBehavior)behavior andActionIdentifier:(nullable NSString *)actionIdentifier {
    UIApplicationState state = [MPApplication_PRIVATE sharedUIApplication].applicationState;
    
    NSString *stateString = state == UIApplicationStateActive ? kMPPushNotificationStateForeground : kMPPushNotificationStateBackground;
    
    MParticleUserNotification *userNotification = [[MParticleUserNotification alloc] initWithDictionary:userInfo
                                                                                                  state:stateString
                                                                                               behavior:behavior
                                                                                                   mode:MPUserNotificationModeRemote];
    userNotification.actionIdentifier = actionIdentifier;
    
    [self.backendController logUserNotification:userNotification];
}
#endif

#pragma mark - Wrapper SDK Information

/**
 Internal use only. Used by our wrapper SDKs to identify themselves during initialization.
 */
+ (void)_setWrapperSdk_internal:(MPWrapperSdk)wrapperSdk version:(nonnull NSString *)wrapperSdkVersion {
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        _wrapperSdk = wrapperSdk;
        _wrapperSdkVersion = wrapperSdkVersion;
    });
    
    [executor executeOnMain: ^{
        // Forwarding call to kits
        MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
        [queueParameters addParameter:@(wrapperSdk)];
        [queueParameters addParameter:wrapperSdkVersion];
        
        SEL roktSelector = @selector(setWrapperSdk:version:);
        [[MParticle sharedInstance].kitContainer_PRIVATE forwardSDKCall:roktSelector
                                                                  event:nil
                                                             parameters:queueParameters
                                                            messageType:MPMessageTypeUnknown
                                                               userInfo:nil
        ];
    }];
}

+ (BOOL)isOlderThanConfigMaxAgeSeconds {
    BOOL shouldConfigurationBeDeleted = NO;

    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    NSNumber *configProvisioned = userDefaults[kMPConfigProvisionedTimestampKey];
    NSNumber *maxAgeSeconds = [[MParticle sharedInstance] configMaxAgeSeconds];

    if (configProvisioned != nil && maxAgeSeconds != nil && [maxAgeSeconds doubleValue] > 0) {
        NSTimeInterval intervalConfigProvisioned = [configProvisioned doubleValue];
        NSTimeInterval intervalNow = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval delta = intervalNow - intervalConfigProvisioned;
        shouldConfigurationBeDeleted = delta > [maxAgeSeconds doubleValue];
    }

    if (shouldConfigurationBeDeleted) {
        [userDefaults deleteConfiguration];
    }

    return shouldConfigurationBeDeleted;
}

@end

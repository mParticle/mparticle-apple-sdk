#import "MPBackendController.h"
#import "MPPersistenceUtilities.h"
#import "MPIConstants.h"
#import "MPNetworkPerformance.h"
#import "MPAudience.h"
#import "MPEvent.h"
#import "MParticleUserNotification.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPConsentSerialization.h"
#import "MPILogger.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "Kits/MPKitContainer+MParticlePrivate.h"
#import "mParticle.h"
#import "MPNetworkCommunication.h"
#import "MPUserDefaultsConnector.h"
#import "MPUploadSettings.h"
#import "UploadSettingsUtils.h"
#if TARGET_OS_IOS == 1
    #import "MPNotificationController.h"
    #import <AdServices/AAAttribution.h>
#endif
@import mParticle_Apple_SDK_Swift;

const NSInteger kNilAttributeValue = 101;
const NSInteger kExceededAttributeValueMaximumLength = 104;
const NSInteger kExceededAttributeKeyMaximumLength = 105;
const NSInteger kInvalidDataType = 106;
const NSInteger kInvalidKey = 107;
const NSTimeInterval kMPMaximumKitWaitTimeSeconds = 5.0;
const NSTimeInterval kMPMaximumAgentWaitTimeSeconds = 5.0;
const NSTimeInterval kMPRemainingBackgroundTimeMinimumThreshold = 10.0;
 
@interface MParticleSession ()

@property (nonatomic, readwrite) NSNumber *startTime;
- (instancetype)initWithUUID:(NSString *)uuid;

@end

@interface MParticle ()

@property (nonatomic, strong) MPPersistenceStorePRIVATE *persistenceStore;
@property (nonatomic, strong) MParticleOptions *options;
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong) MParticleWebViewPRIVATE *webView;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
+ (dispatch_queue_t)messageQueue;
+ (void)executeOnMessage:(void(^)(void))block;
+ (void)executeOnMain:(void(^)(void))block;
- (MPLog *)getLogger;
- (void)initializePersistence;

@end

@interface MPBackendController_PRIVATE() {
    MParticleSession *tempSession;
}
@property NSTimeInterval nextCleanUpTime;
@property NSTimeInterval timeAppWentToBackground;
@property NSTimeInterval timeAppWentToBackgroundInCurrentSession;
@property NSTimeInterval timeOfLastEventInBackground;
@property dispatch_source_t uploadSource;
@property NSMutableSet<NSString *> *deletedUserAttributes;
@property NSNotification *didFinishLaunchingNotification;
@property UIBackgroundTaskIdentifier backendBackgroundTaskIdentifier;
@property NSOperationQueue *backgroundCheckQueue;
@property NSNumber *previousForegroundTime;
@property (nonatomic, strong) id<MPBackendPersistence> persistence;
@property (nonatomic, strong) MPBackendUploadCoordinator *uploadCoordinator;
@property (nonatomic, strong) MPBackendSessionState *sessionState;
@property (nonatomic, strong, nonnull) MPBackendSessionDependencies *sessionDependencies;
@property (nonatomic, strong) MPBackendMessageWriter *messageWriter;
@property (nonatomic, strong) MPBackendSessionCoordinator *sessionCoordinator;
@property (nonatomic, strong) MPBackendLifecycleCoordinator *lifecycleCoordinator;
@property (nonatomic, strong, nonnull) MPBackendSessionLifecycleDependencies *sessionLifecycleDependencies;
- (MPUploadBuilderContext *)uploadBuilderContext;
+ (MPUploadBuilderContext *)uploadBuilderContextWithPersistence:(id<MPUploadEnrichmentPersistence> (^)(void))persistence;

@end


@implementation MPBackendController_PRIVATE
@synthesize uploadInterval = _uploadInterval;

#if TARGET_OS_IOS == 1
@synthesize notificationController = _notificationController;
#endif

- (instancetype)init {
    self = [super init];
    if (self) {
        _sessionState = [[MPBackendSessionState alloc] init];
    }
    return self;
}

- (instancetype)initWithDelegate:(id<MPBackendControllerDelegate>)delegate {
    [[MParticle sharedInstance] initializePersistence];
    return [self initWithDelegate:delegate
                     persistence:[MParticle sharedInstance].persistenceStore];
}

- (instancetype)initWithDelegate:(id<MPBackendControllerDelegate>)delegate
                     persistence:(id<MPBackendPersistence>)persistence {
    self = [self init];
    if (self) {
        _persistence = persistence;
        _networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
#if TARGET_OS_IOS == 1
        _notificationController = [[MPNotificationController_PRIVATE alloc] init];
#endif
        _sessionTimeout = DEFAULT_SESSION_TIMEOUT;
        _sessionState.nextCleanUpTime = [[NSDate date] timeIntervalSince1970];
        _backendBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
        _delegate = delegate;
        _backgroundCheckQueue = [[NSOperationQueue alloc] init];
        _backgroundCheckQueue.maxConcurrentOperationCount = 1;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidEnterBackground:)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationWillEnterForeground:)
                                   name:UIApplicationWillEnterForegroundNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidFinishLaunching:)
                                   name:UIApplicationDidFinishLaunchingNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleNetworkPerformanceNotification:)
                                   name:kMPNetworkPerformanceMeasurementNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationDidBecomeActive:)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
        
#if TARGET_OS_IOS == 1
        [notificationCenter addObserver:self
                               selector:@selector(handleDeviceTokenNotification:)
                                   name:kMPRemoteNotificationDeviceTokenNotification
                                 object:nil];
#endif
    }
    
    return self;
}

- (void)dealloc {
    [self endUploadTimer];
}

#pragma mark Accessors

- (MPSession *)session {
    return self.sessionState.session;
}

- (void)setSession:(MPSession *)session {
    self.sessionState.session = session;
}

- (NSTimeInterval)timeOfLastEventInBackground {
    return self.sessionState.timeOfLastEventInBackground;
}

- (void)setTimeOfLastEventInBackground:(NSTimeInterval)timestamp {
    self.sessionState.timeOfLastEventInBackground = timestamp;
}

- (MPBackendSessionDependencies * _Nonnull)sessionDependencies {
    @synchronized (self) {
        if (!_sessionDependencies) {
            __weak MPBackendController_PRIVATE *weakSelf = self;
            _sessionDependencies = [[MPBackendSessionDependencies alloc]
                initWithPersistence:^{ return weakSelf.persistence; }
                stateMachine:^{ return MParticle.sharedInstance.stateMachine; }
                makeMessageContext:^{
                    return [weakSelf messageBuilderContext] ?: [[MPMessageBuilderContext alloc]
                        initWithDataPlanId:nil dataPlanVersion:nil logger:nil];
                }
                runningInBackground:^{ return MPStateMachine_PRIVATE.runningInBackground; }
                enqueueOnMessage:^(dispatch_block_t block) {
                    MPBackendController_PRIVATE *backend = weakSelf;
                    dispatch_async([MParticle messageQueue], ^{ if (backend) { block(); } });
                }
                upload:^(dispatch_block_t completion) { [weakSelf waitForKitsAndUploadWithCompletionHandler:completion]; }
                logger:^{ return [MParticle.sharedInstance getLogger]; }];
        }
        return _sessionDependencies;
    }
}

- (MPBackendMessageWriter *)messageWriter {
    @synchronized (self) {
        if (!_messageWriter) {
            _messageWriter = [[MPBackendMessageWriter alloc] initWithState:self.sessionState dependencies:self.sessionDependencies];
        }
        return _messageWriter;
    }
}

- (MPBackendSessionLifecycleDependencies * _Nonnull)sessionLifecycleDependencies {
    @synchronized (self) {
        if (!_sessionLifecycleDependencies) {
            __weak MPBackendController_PRIVATE *weakSelf = self;
            _sessionLifecycleDependencies = [[MPBackendSessionLifecycleDependencies alloc]
                initWithAutomaticSessionTracking:^{ return MParticle.sharedInstance.automaticSessionTracking; }
                sessionStartContext:^{
                    MParticle *mparticle = MParticle.sharedInstance;
                    return [[MPBackendSessionStartContext alloc]
                        initWithAutomaticSessionTracking:^{ return mparticle.automaticSessionTracking; }
                        stateMachine:^{ return mparticle.stateMachine; }];
                }
                currentUserID:^{ return [MPPersistenceUtilities mpId]; }
                applicationInfo:^{
                    MPApplication_PRIVATE *application = [[MPApplication_PRIVATE alloc]
                        initWithStateMachine:(id<MPApplicationStateMachineProtocol>)MParticle.sharedInstance.stateMachine
                        userDefaults:(id<MPApplicationMPUserDefaultsProtocol>)MPUserDefaultsConnector.userDefaults
                        environment:[MPStateMachine_PRIVATE environment]
                        deploymentTarget:__IPHONE_OS_VERSION_MIN_REQUIRED buildSDK:__IPHONE_OS_VERSION_MAX_ALLOWED];
                    return [application dictionaryRepresentation];
                }
                deviceInfo:^NSDictionary *(NSNumber *mpid) {
                    MParticle *mparticle = MParticle.sharedInstance;
                    MPDevice *device = [[MPDevice alloc]
                        initWithStateMachine:(id<MPStateMachineMPDeviceProtocol>)mparticle.stateMachine
                        userDefaults:(id<MPIdentityApiMPUserDefaultsProtocol>)MPUserDefaultsConnector.userDefaults
                        identity:(id<MPIdentityApiMPDeviceProtocol>)mparticle.identity logger:[mparticle getLogger]];
                    return [device dictionaryRepresentationWithMpid:mpid];
                }
                executeOnMessage:^(dispatch_block_t block) {
                    MPBackendController_PRIVATE *backend = weakSelf;
                    [MParticle executeOnMessage:^{ if (backend) { block(); } }];
                }
                schedule:^(NSTimeInterval delay, dispatch_block_t block) {
                    MPBackendController_PRIVATE *backend = weakSelf;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                                   [MParticle messageQueue], ^{ if (backend) { block(); } });
                }
                createPendingSession:^(NSString *uuid) {
                    MPBackendController_PRIVATE *backend = weakSelf;
                    if (backend) { backend->tempSession = [[MParticleSession alloc] initWithUUID:uuid]; }
                }
                setPendingSessionStartTime:^(double timestamp) {
                    MPBackendController_PRIVATE *backend = weakSelf;
                    if (backend) { backend->tempSession.startTime = @(timestamp); }
                }
                clearPendingSession:^{
                    MPBackendController_PRIVATE *backend = weakSelf;
                    if (backend) { backend->tempSession = nil; }
                }
                broadcastBegin:^(MPSession *session) { [weakSelf broadcastSessionDidBegin:session]; }
                broadcastEnd:^(MPSession *session) { [weakSelf broadcastSessionDidEnd:session]; }
                clearEmptyTimedEvents:^{
                    MPBackendController_PRIVATE *backend = weakSelf;
                    if (backend.eventSet.count == 0) { backend.eventSet = nil; }
                }];
        }
        return _sessionLifecycleDependencies;
    }
}

- (MPBackendSessionCoordinator *)sessionCoordinator {
    @synchronized (self) {
        if (!_sessionCoordinator) {
            _sessionCoordinator = [[MPBackendSessionCoordinator alloc] initWithState:self.sessionState
                dependencies:self.sessionDependencies lifecycle:self.sessionLifecycleDependencies writer:self.messageWriter];
        }
        return _sessionCoordinator;
    }
}

- (NSTimeInterval)nextCleanUpTime {
    return self.sessionState.nextCleanUpTime;
}

- (void)setNextCleanUpTime:(NSTimeInterval)value {
    self.sessionState.nextCleanUpTime = value;
}

- (NSTimeInterval)timeAppWentToBackground {
    return self.sessionState.timeAppWentToBackground;
}

- (void)setTimeAppWentToBackground:(NSTimeInterval)value {
    self.sessionState.timeAppWentToBackground = value;
}

- (NSTimeInterval)timeAppWentToBackgroundInCurrentSession {
    return self.sessionState.timeAppWentToBackgroundInCurrentSession;
}

- (void)setTimeAppWentToBackgroundInCurrentSession:(NSTimeInterval)value {
    self.sessionState.timeAppWentToBackgroundInCurrentSession = value;
}

- (NSNumber *)previousForegroundTime {
    return self.sessionState.previousForegroundTime;
}

- (void)setPreviousForegroundTime:(NSNumber *)value {
    self.sessionState.previousForegroundTime = value;
}

- (MPBackendLifecycleCoordinator *)lifecycleCoordinator {
    if (!_lifecycleCoordinator) {
        __weak MPBackendController_PRIVATE *weakSelf = self;
        MPBackendLifecycleDependencies *dependencies = [[MPBackendLifecycleDependencies alloc]
            initWithSessionTimeout:^{ return weakSelf.sessionTimeout; }
            persistenceMaxAge:^{ return MParticle.sharedInstance.persistenceMaxAgeSeconds; }
            setRunningInBackground:^(BOOL background) { [MPStateMachine_PRIVATE setRunningInBackground:background]; }
            clearIdentityCache:^{
                MPIdentityCaching *cache = [[MPIdentityCaching alloc] initWithUserDefaults:MPUserDefaultsConnector.userDefaults
                    logger:[MParticle.sharedInstance getLogger]];
                [cache clearExpiredCache];
            }
            requestConfig:^{ [weakSelf requestConfig:nil]; }
            beginBackgroundTask:^{ [weakSelf beginBackgroundTask]; }
            endBackgroundTask:^{ [weakSelf endBackgroundTask]; }
            beginUploadTimer:^{ [weakSelf beginUploadTimer]; }
            beginBackgroundTimeCheckLoop:^{ [weakSelf beginBackgroundTimeCheckLoop]; }
            cancelBackgroundTimeCheckLoop:^{ [weakSelf cancelBackgroundTimeCheckLoop]; }];
        _lifecycleCoordinator = [[MPBackendLifecycleCoordinator alloc] initWithState:self.sessionState
            dependencies:self.sessionDependencies sessionDependencies:self.sessionLifecycleDependencies
            lifecycle:dependencies sessions:self.sessionCoordinator writer:self.messageWriter];
    }
    return _lifecycleCoordinator;
}

- (NSMutableSet<MPEvent *> *)eventSet {
    if (_eventSet) {
        return _eventSet;
    }
    
    _eventSet = [[NSMutableSet alloc] initWithCapacity:1];
    return _eventSet;
}

- (NSMutableDictionary<NSString *, id> *)userAttributesForUserId:(NSNumber *)userId {
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    NSMutableDictionary *userAttributes = [[userDefaults mpObjectForKey:kMPUserAttributeKey userId:userId] mutableCopy];
    if (userAttributes) {
        return [[MPUserAttributeLogic attributesFromStorage:userAttributes nullSentinel:kMPNullUserAttributeString] mutableCopy];
    } else {
        return [NSMutableDictionary dictionary];
    }
}

- (NSMutableArray<NSDictionary<NSString *, id> *> *)identitiesForUserId:(NSNumber *)userId {
    
    NSMutableArray *userIdentities = [[NSMutableArray alloc] initWithCapacity:10];
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    NSArray *userIdentityArray = [userDefaults mpObjectForKey:kMPUserIdentityArrayKey userId:userId];
    if (userIdentityArray) {
        [userIdentities addObjectsFromArray:userIdentityArray];
    }
    
    NSNumber *currentStatus = [MParticle sharedInstance].stateMachine.attAuthorizationStatus;
    BOOL notAuthorized = currentStatus != nil && currentStatus.integerValue != MPATTAuthorizationStatusAuthorized;
    return [[MPUserIdentityLogic identities:userIdentities removingType:MPIdentityIOSAdvertiserId when:notAuthorized typeKey:kMPUserIdentityTypeKey] mutableCopy];
}

- (NSMutableArray<NSDictionary<NSString *, id> *> *)userIdentitiesForUserId:(NSNumber *)userId {

    NSMutableArray *identities = [[NSMutableArray alloc] initWithCapacity:10];
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    NSArray *identityArray = [userDefaults mpObjectForKey:kMPUserIdentityArrayKey userId:userId];
    if (identityArray) {
        [identities addObjectsFromArray:identityArray];
    }

    // Remove invalid identities
    return [[MPUserIdentityLogic validIdentities:identities typeKey:kMPUserIdentityTypeKey maxValidTypeExclusive:MPIdentityIOSAdvertiserId] mutableCopy];
}

#pragma mark Private methods

- (MPMessageBuilderContext *)messageBuilderContext {
    MParticle *mparticle = [MParticle sharedInstance];
    return [[MPMessageBuilderContext alloc] initWithDataPlanId:mparticle.dataPlanId
                                               dataPlanVersion:mparticle.dataPlanVersion
                                                        logger:[mparticle getLogger]];
}

- (MPBackendUploadCoordinator *)uploadCoordinator {
    if (!_uploadCoordinator) {
        __weak MPBackendController_PRIVATE *weakSelf = self;
        MPUploadBatchLimits *limits = [[MPUploadBatchLimits alloc]
            initWithMaxMessages:MAX_EVENTS_PER_BATCH maxBatchBytes:MAX_BYTES_PER_BATCH
            maxMessageBytes:MAX_BYTES_PER_EVENT crashBatchBytes:MAX_BYTES_PER_BATCH_CRASH
            crashMessageBytes:MAX_BYTES_PER_EVENT_CRASH];
        _uploadCoordinator = [[MPBackendUploadCoordinator alloc]
            initWithPersistence:^{ return weakSelf.persistence; }
            stateMachine:^{ return MParticle.sharedInstance.stateMachine; }
            makeContext:^{ return [weakSelf uploadBuilderContext]; }
            makeBuilder:^MPUploadBuilder *(MPUploadMessageGroup *group, NSArray<MPMessage *> *messages, NSObject *settings, MPUploadBuilderContext *context) {
                MPBackendController_PRIVATE *backend = weakSelf;
                if (!backend) { return nil; }
                MPUploadBuilder *builder = [[MPUploadBuilder alloc]
                    initWithMpid:group.mpid sessionId:group.sessionId messages:messages
                    sessionTimeout:backend.sessionTimeout uploadInterval:backend.uploadInterval
                    dataPlanId:group.dataPlanId dataPlanVersion:group.dataPlanVersion
                    uploadSettings:settings context:context];
                [builder withUserAttributes:[backend userAttributesForUserId:group.mpid]
                      deletedUserAttributes:backend.deletedUserAttributes];
                [builder withUserIdentities:[backend userIdentitiesForUserId:group.mpid]];
                return builder;
            }
            clearDeletedAttributes:^{ weakSelf.deletedUserAttributes = nil; }
            limits:limits
            dependencies:[self uploadDependencies]
            currentSettings:^{
                return [MPUploadSettings currentUploadSettingsWithStateMachine:MParticle.sharedInstance.stateMachine
                                                               networkOptions:MParticle.sharedInstance.networkOptions];
            }];
    }
    return _uploadCoordinator;
}

- (MPBackendUploadDependencies *)uploadDependencies {
    __weak MPBackendController_PRIVATE *weakSelf = self;
    return [[MPBackendUploadDependencies alloc]
        initWithNetwork:^{ return (id<MPBackendUploadNetworking>)weakSelf.networkCommunication; }
        shouldDelayForKits:^{
            return [MParticle.sharedInstance.kitContainer_PRIVATE shouldDelayUpload:kMPMaximumKitWaitTimeSeconds];
        }
        shouldDelayForWebView:^{
            return [MParticle.sharedInstance.webView shouldDelayUpload:kMPMaximumAgentWaitTimeSeconds];
        }
        schedule:^(NSTimeInterval delay, dispatch_block_t block) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                           [MParticle messageQueue], block);
        }
        logger:^{ return [MParticle.sharedInstance getLogger]; }];
}

// The upload builder cannot import the public Objective-C SDK. Keep identity, consent,
// build macros and customer callbacks at this composition boundary, with live providers.
- (MPUploadBuilderContext *)uploadBuilderContext {
    return [MPBackendController_PRIVATE uploadBuilderContextWithPersistence:^{ return self.persistence; }];
}

+ (MPUploadBuilderContext *)uploadBuilderContextWithPersistence:(id<MPUploadEnrichmentPersistence> (^)(void))persistence {
    return [[MPUploadBuilderContext alloc]
        initWithStateMachine:^{ return MParticle.sharedInstance.stateMachine; }
        lifetimeValue:^NSNumber *(NSNumber *mpid) {
            return [MPUserDefaultsConnector.userDefaults mpObjectForKey:kMPLifeTimeValueKey userId:mpid] ?: @0;
        }
        persistence:persistence
        applicationInfo:^NSDictionary *(MPStateMachine_PRIVATE *stateMachine) {
            MPApplication_PRIVATE *application = [[MPApplication_PRIVATE alloc]
                initWithStateMachine:(id<MPApplicationStateMachineProtocol>)stateMachine
                userDefaults:(id<MPApplicationMPUserDefaultsProtocol>)MPUserDefaultsConnector.userDefaults
                environment:[MPStateMachine_PRIVATE environment]
                deploymentTarget:__IPHONE_OS_VERSION_MIN_REQUIRED
                buildSDK:__IPHONE_OS_VERSION_MAX_ALLOWED];
            return [application dictionaryRepresentation];
        }
        deviceInfo:^NSDictionary *(NSNumber *mpid) {
            MParticle *mparticle = MParticle.sharedInstance;
            MPDevice *device = [[MPDevice alloc]
                initWithStateMachine:(id<MPStateMachineMPDeviceProtocol>)mparticle.stateMachine
                userDefaults:(id<MPIdentityApiMPUserDefaultsProtocol>)MPUserDefaultsConnector.userDefaults
                identity:(id<MPIdentityApiMPDeviceProtocol>)mparticle.identity
                logger:[mparticle getLogger]];
            return [device dictionaryRepresentationWithMpid:mpid];
        }
        advertiserID:^NSString *(NSNumber *mpid) {
            return [MParticle.sharedInstance.identity getUser:mpid].identities[@(MPIdentityIOSAdvertiserId)];
        }
        consent:^NSDictionary *(NSNumber *mpid) {
            MPConsentState *consent = [MPPersistenceUtilities effectiveConsentStateForMpid:mpid];
            return consent ? [MPConsentSerialization serverDictionaryFromConsentState:consent] : nil;
        }
        transformBatch:^id(NSDictionary *batch) {
            MParticle *mparticle = MParticle.sharedInstance;
            return mparticle.options.onCreateBatch ? mparticle.options.onCreateBatch(batch) : batch;
        }
        logger:^{ return [MParticle.sharedInstance getLogger]; }
        sdkVersion:kMParticleSDKVersion];
}

- (void)confirmEndSessionMessage:(MPSession *)session {
    [self.messageWriter confirmEndSessionMessage:session];
}

- (void)broadcastSessionDidBegin:(MPSession *)session {
    MParticleSession *mparticleSession = [[MParticleSession alloc] initWithUUID:session.uuid];
    [MParticle executeOnMain:^{
        [self.delegate sessionDidBegin:session];
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[mParticleSessionId] = mparticleSession.sessionID;
        userInfo[mParticleSessionUUID] = mparticleSession.UUID;
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleSessionDidBeginNotification
                                                            object:self.delegate
                                                          userInfo:userInfo];
    }];
}

- (void)broadcastSessionDidEnd:(MPSession *)session {
    MParticleSession *mparticleSession = [[MParticleSession alloc] initWithUUID:session.uuid];
    [MParticle executeOnMain:^{
        [self.delegate sessionDidEnd:session];
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[mParticleSessionId] = mparticleSession.sessionID;
        userInfo[mParticleSessionUUID] = mparticleSession.UUID;
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleSessionDidEndNotification
                                                            object:self.delegate
                                                          userInfo:userInfo];
    }];
}
                   
- (void)logUserAttributeChange:(MPUserAttributeChange *)userAttributeChange {
    if (!userAttributeChange) {
        return;
    }
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeUserAttributeChange
                                                                             session:self.session
                                                                 userAttributeChange:userAttributeChange context:self.messageBuilderContext];
    if (userAttributeChange.timestamp) {
        [messageBuilder timestamp:[userAttributeChange.timestamp timeIntervalSince1970]];
    }
    
    MPMessage *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:YES];
}

- (void)logUserIdentityChange:(MPUserIdentityChangePRIVATE *)userIdentityChange {
    if (!userIdentityChange) {
        return;
    }
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeUserIdentityChange
                                                                             session:self.session
                                                                  userIdentityChange:userIdentityChange context:self.messageBuilderContext];
    if (userIdentityChange.timestamp) {
        [messageBuilder timestamp:[userIdentityChange.timestamp timeIntervalSince1970]];
    }
    
    MPMessage *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:YES];
}

- (void)processDidFinishLaunching:(NSNotification *)notification {
    NSString *astType = kMPASTInitKey;
    NSMutableDictionary *messageInfo = [[NSMutableDictionary alloc] initWithCapacity:3];
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    BOOL isInstallOrUpgrade = NO;
    if (stateMachine.installationType == MPInstallationTypeKnownInstall) {
        messageInfo[kMPASTIsFirstRunKey] = @YES;
        [self.delegate forwardLogInstall];
        isInstallOrUpgrade = YES;
    } else if (stateMachine.installationType == MPInstallationTypeKnownUpgrade) {
        messageInfo[kMPASTIsUpgradeKey] = @YES;
        [self.delegate forwardLogUpdate];
        isInstallOrUpgrade = YES;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        NSUserActivity *userActivity = userInfo[UIApplicationLaunchOptionsUserActivityDictionaryKey][@"UIApplicationLaunchOptionsUserActivityKey"];
        
        if (userActivity.webpageURL) {
            MParticle* mparticle = MParticle.sharedInstance;
            MPLog* logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
            logger.customLogger = mparticle.customLogger;
            
            stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:userActivity.webpageURL options:nil logger:logger];
        }
    }
    
    messageInfo[kMPAppStateTransitionType] = astType;
    
    dispatch_async([MParticle messageQueue], ^{
        if (isInstallOrUpgrade && MParticle.sharedInstance.automaticSessionTracking) {
            [self beginSession];
        }
        MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeAppStateTransition session:self.session messageInfo:messageInfo context:self.messageBuilderContext];

        [messageBuilder stateTransition:YES previousSession:nil launchInfo:stateMachine.launchInfo];
        MPMessage *message = [messageBuilder build];
        
        [self saveMessage:message updateSession:YES];
    });
    
    [MPApplication_PRIVATE updateStoredVersionAndBuildNumbersWithUserDefaults:(id<MPApplicationMPUserDefaultsProtocol>)MPUserDefaultsConnector.userDefaults];

    self.didFinishLaunchingNotification = nil;
    
    MPILogVerbose(@"Application Did Finish Launching");
}

- (void)processOpenSessionsEndingCurrent:(BOOL)endCurrentSession completionHandler:(void (^)(void))completionHandler {
    [self.sessionCoordinator processOpenSessionsEndingCurrent:endCurrentSession completionHandler:completionHandler];
}

- (void)requestConfig:(void(^ _Nullable)(BOOL uploadBatch))completionHandler {
    [self.uploadCoordinator requestConfig:completionHandler];
}

- (void)setUserAttributeChange:(MPUserAttributeChange *)userAttributeChange completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    if ([MParticle sharedInstance].stateMachine.optOut) {
        if (completionHandler) {
            completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusOptOut);
        }
        
        return;
    }
    
    NSMutableDictionary *userAttributes = [self userAttributesForUserId:[MPPersistenceUtilities mpId]];
    NSString *localKey = [userAttributes caseInsensitiveKey:userAttributeChange.key];

    MPAttributeValidationResult validation = [MPBackendController_PRIVATE validateAndLogAttributeKey:localKey
                                                                                                value:userAttributeChange.value];

    switch ([MPUserAttributeLogic mutationForValidationResult:validation keyExists:userAttributes[localKey] != nil]) {
        case MPUserAttributeMutationStore:
            userAttributes[localKey] = userAttributeChange.value;
            break;

        case MPUserAttributeMutationDelete:
            userAttributeChange.deleted = YES;
            [userAttributes removeObjectForKey:localKey];

            if (!self.deletedUserAttributes) {
                self.deletedUserAttributes = [[NSMutableSet alloc] initWithCapacity:1];
            }
            [self.deletedUserAttributes addObject:userAttributeChange.key];
            break;

        case MPUserAttributeMutationReject:
            if (completionHandler) {
                completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusInvalidDataType);
            }
            return;
    }
    
    NSDictionary *userAttributesCopy = [MPUserAttributeLogic attributesForStorage:userAttributes nullSentinel:kMPNullUserAttributeString];

    if (userAttributeChange.changed) {
        userAttributeChange.valueToLog = [MPUserAttributeLogic valueToLogFor:userAttributeChange.value];
        [self logUserAttributeChange:userAttributeChange];
    }
    
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    userDefaults[kMPUserAttributeKey] = userAttributesCopy;
    [userDefaults synchronize];
    
    if (completionHandler) {
        completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusSuccess);
    }
}

- (NSArray *)batchMessageArraysFromMessageArray:(NSArray *)messages maxBatchMessages:(NSInteger)maxBatchMessages maxBatchBytes:(NSInteger)maxBatchBytes maxMessageBytes:(NSInteger)maxMessageBytes {
    MPUploadBatchLimits *limits = [[MPUploadBatchLimits alloc]
        initWithMaxMessages:maxBatchMessages maxBatchBytes:maxBatchBytes maxMessageBytes:maxMessageBytes
        crashBatchBytes:MAX_BYTES_PER_BATCH_CRASH crashMessageBytes:MAX_BYTES_PER_EVENT_CRASH];
    return [self.uploadCoordinator batchMessages:messages limits:limits];
}

- (void)skipNextUpload {
    [self.uploadCoordinator skipNextUpload];
}

- (void)prepareBatchesForUpload:(MPUploadSettings *)uploadSettings {
    [self.uploadCoordinator prepareBatchesForUpload:uploadSettings];
}

- (void)uploadBatchesWithCompletionHandler:(void(^)(BOOL success))completionHandler {
    [self.uploadCoordinator uploadBatchesWithCompletionHandler:completionHandler];
}

- (void)uploadOpenSessions:(NSMutableArray *)openSessions completionHandler:(void (^)(void))completionHandler {
    [self.sessionCoordinator uploadOpenSessions:openSessions completionHandler:completionHandler];
}

#pragma mark Notification handlers

- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification {
    self.didFinishLaunchingNotification = [notification copy];
}

- (void)handleNetworkPerformanceNotification:(NSNotification *)notification {
    if (!self.session) {
        return;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    MPNetworkPerformance *networkPerformance = userInfo[kMPNetworkPerformanceKey];
    
    [self logNetworkPerformanceMeasurement:networkPerformance completionHandler:nil];
}

#pragma mark Timers

// Timer blocks fire on message queue
- (dispatch_source_t)createSourceTimer:(uint64_t)interval eventHandler:(dispatch_block_t)eventHandler cancelHandler:(dispatch_block_t)cancelHandler {
    dispatch_source_t sourceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, [MParticle messageQueue]);

    if (sourceTimer) {
        dispatch_source_set_timer(sourceTimer, dispatch_walltime(NULL, 0), interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(sourceTimer, eventHandler);
        dispatch_source_set_cancel_handler(sourceTimer, cancelHandler);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), [MParticle messageQueue], ^{
            dispatch_resume(sourceTimer);
        });
    }
    
    return sourceTimer;
}

- (void)beginUploadTimer {
    @synchronized (self) {
        if (self.uploadSource) {
            dispatch_source_cancel(self.uploadSource);
            self.uploadSource = nil;
        }
        
        self.uploadSource = [self createSourceTimer:self.uploadInterval eventHandler:^{
            [self waitForKitsAndUploadWithCompletionHandler:nil];
        } cancelHandler:^{}];
    }
}

- (void)endUploadTimer {
    @synchronized (self) {
        if (self.uploadSource) {
            dispatch_source_cancel(self.uploadSource);
            self.uploadSource = nil;
        }
    }
}

#pragma mark Public accessors

- (void)setSessionTimeout:(NSTimeInterval)sessionTimeout {
    if (sessionTimeout == _sessionTimeout) {
        return;
    }

    _sessionTimeout = [MPSessionTimingPolicy clampedSessionTimeout:sessionTimeout minimum:MINIMUM_SESSION_TIMEOUT];
    MPILogDebug(@"Set Session Timeout: %.0f", _sessionTimeout);
}

- (NSTimeInterval)uploadInterval {
    if (_uploadInterval == 0.0) {
        _uploadInterval = [MPSessionTimingPolicy defaultUploadIntervalForDevelopment:[MPStateMachine_PRIVATE environment] == MPEnvironmentDevelopment
                                                                        debugInterval:DEFAULT_DEBUG_UPLOAD_INTERVAL
                                                                   productionInterval:DEFAULT_UPLOAD_INTERVAL];
    }

    // If running in an extension our processor time is extremely limited
    if ([MPStateMachine_PRIVATE isAppExtension]) {
        _uploadInterval = 1.0;
    }
    return _uploadInterval;
}

- (void)setUploadInterval:(NSTimeInterval)uploadInterval {
    if (uploadInterval == _uploadInterval) {
        return;
    }

    _uploadInterval = [MPSessionTimingPolicy clampedUploadInterval:uploadInterval tvOSCeiling:DEFAULT_UPLOAD_INTERVAL];

    if (self.uploadSource) {
        [self beginUploadTimer];
    }
}

- (void)createTempSession {
    [self.sessionCoordinator createTempSession];
}

- (MParticleSession *)tempSession {
    __block MParticleSession *pending;
    [self.sessionState withSessionLock:^{ pending = self->tempSession; }];
    return pending;
}

#pragma mark Public methods

- (void)beginSession {
    [self.sessionCoordinator beginSession];
}

- (void)endSession {
    [self.sessionCoordinator endSession];
}

- (void)beginSessionWithIsManual:(BOOL)isManual date:(NSDate *)date {
    [self.sessionCoordinator beginSessionWithIsManual:isManual date:date];
}

- (void)endSessionWithIsManual:(BOOL)isManual {
    [self.sessionCoordinator endSessionWithIsManual:isManual];
}

- (void)beginTimedEvent:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    [event beginTiming];
    [self.eventSet addObject:event];
    completionHandler(event, MPExecStatusSuccess);
}

// Validates a key/value pair and logs the matching console message. Logging stays here so the
// `MPILogError` level gate keeps deciding whether the offending value is ever interpolated.
+ (MPAttributeValidationResult)validateAndLogAttributeKey:(NSString *)key value:(id)value {
    id invalidArrayEntry = nil;
    MPAttributeValidationResult result = [MPAttributeValidator validateKey:key
                                                                     value:value
                                                            keyLengthLimit:LIMIT_ATTR_KEY_LENGTH
                                                          valueLengthLimit:LIMIT_ATTR_VALUE_LENGTH
                                                         invalidArrayEntry:&invalidArrayEntry];

    switch (result) {
        case MPAttributeValidationResultInvalidKey:
            MPILogError(@"Error while setting attribute key: the key parameter cannot be nil");
            break;
        case MPAttributeValidationResultKeyTooLong:
            MPILogError(@"Error while setting attribute key: the key parameter is longer than the maximum allowed length.");
            break;
        case MPAttributeValidationResultNilValue:
            // A nil value may just be treated as a removal, so no error is logged.
            break;
        case MPAttributeValidationResultInvalidType:
            MPILogError(@"Error while setting attribute value: must be an NSString or NSArray");
            break;
        case MPAttributeValidationResultValueTooLong:
            MPILogError(@"Error while setting attribute value: value is longer than the maximum allowed %@", value);
            break;
        case MPAttributeValidationResultInvalidArrayEntry:
            MPILogError(@"Error while setting attribute value list: all user attribute entries in the array must be of type string. Error entry: %@", invalidArrayEntry);
            break;
        case MPAttributeValidationResultArrayValueTooLong:
            MPILogError(@"Error while setting attribute value list: combined length of list values longer than the maximum alowed.");
            break;
        case MPAttributeValidationResultValid:
            break;
    }

    return result;
}

+ (NSInteger)errorCodeForValidationResult:(MPAttributeValidationResult)result {
    switch (result) {
        case MPAttributeValidationResultInvalidKey:
            return kInvalidKey;
        case MPAttributeValidationResultKeyTooLong:
            return kExceededAttributeKeyMaximumLength;
        case MPAttributeValidationResultNilValue:
            return kNilAttributeValue;
        case MPAttributeValidationResultValueTooLong:
        case MPAttributeValidationResultArrayValueTooLong:
            return kExceededAttributeValueMaximumLength;
        case MPAttributeValidationResultInvalidType:
        case MPAttributeValidationResultInvalidArrayEntry:
        case MPAttributeValidationResultValid:
            return kInvalidDataType;
    }
}

+ (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value error:(out NSError *__autoreleasing *)error  {
    static NSString *attributeValidationErrorDomain = @"Attribute Validation";
    MPAttributeValidationResult result = [self validateAndLogAttributeKey:key value:value];

    if (result == MPAttributeValidationResultValid) {
        return YES;
    }

    if (error) {
        *error = [NSError errorWithDomain:attributeValidationErrorDomain
                                     code:[self errorCodeForValidationResult:result]
                                 userInfo:nil];
    }

    return NO;
}

- (MPEvent *)eventWithName:(NSString *)eventName {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", eventName];
    MPEvent *event = [[self.eventSet filteredSetUsingPredicate:predicate] anyObject];
    
    return event;
}

- (MPExecStatus)fetchAudiencesWithCompletionHandler:(void (^ _Nonnull)(NSArray * _Nullable currentAudiences, NSError * _Nullable error))completionHandler {
    
    NSAssert(completionHandler != nil, @"completionHandler cannot be nil.");
        
    [self.networkCommunication requestAudiencesWithCompletionHandler:^(BOOL success, NSArray *currentAudiences, NSError *error) {
        if (success) {
            MPILogVerbose(@"Audiences Request Succesful: \nCurrent Audiences: %@", currentAudiences);
        } else {
            if (!error) {
                MPILogError(@"Audience request failed without error")
            } else {
                MPILogError(@"Audience request failed with error: %@", error)
            }
        }
        
        completionHandler(currentAudiences, error);
    }];
    
    return MPExecStatusSuccess;
}

+ (NSString *)execStatusDescription:(MPExecStatus)execStatus {
    return [MPExecStatusFormatter descriptionForExecStatus:execStatus];
}

- (NSNumber *)incrementSessionAttribute:(MPSession *)session key:(NSString *)key byValue:(NSNumber *)value {
    if (!session) {
        return nil;
    }
    
    NSString *localKey = [session.attributesDictionary caseInsensitiveKey:key];
    id currentValue = session.attributesDictionary[localKey];
    if (!currentValue && [value isKindOfClass:[NSNumber class]]) {
        [self setSessionAttribute:session key:localKey value:value];
        return value;
    }

    if (![currentValue isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    NSNumber *newValue = [MPUserAttributeLogic incrementedValueFrom:(NSNumber *)currentValue byValue:value];

    session.attributesDictionary[localKey] = newValue;
    
    dispatch_async([MParticle messageQueue], ^{
        [self.persistence updateSession:session];
    });
    
    return (NSNumber *)newValue;
}

- (NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    NSAssert([key isKindOfClass:[NSString class]], @"'key' must be a string.");
    NSAssert([value isKindOfClass:[NSNumber class]], @"'value' must be a number.");
    
    NSDate *timestamp = [NSDate date];
    NSString *localKey = [[self userAttributesForUserId:[MPPersistenceUtilities mpId]] caseInsensitiveKey:key];
    if (!localKey) {
        [self setUserAttribute:key value:value timestamp:timestamp completionHandler:nil];
        return value;
    }
    
    id currentValue = [self userAttributesForUserId:[MPPersistenceUtilities mpId]][localKey];
    if (currentValue && ![currentValue isKindOfClass:[NSNumber class]]) {
        return nil;
    } else if (MPIsNull(currentValue)) {
        currentValue = @0;
    }
    
    NSNumber *newValue = [MPUserAttributeLogic incrementedValueFrom:(NSNumber *)currentValue byValue:value];

    NSMutableDictionary *userAttributes = [self userAttributesForUserId:[MPPersistenceUtilities mpId]];
    userAttributes[localKey] = newValue;

    NSDictionary *userAttributesCopy = [MPUserAttributeLogic attributesForStorage:userAttributes nullSentinel:kMPNullUserAttributeString];
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[[self userAttributesForUserId:[MPPersistenceUtilities mpId]] copy] key:key value:newValue];
    userAttributeChange.timestamp = timestamp;
    [self setUserAttributeChange:userAttributeChange completionHandler:nil];
 
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    userDefaults[kMPUserAttributeKey] = userAttributesCopy;
    [userDefaults synchronize];
    
    return (NSNumber *)newValue;
}

- (void)leaveBreadcrumb:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    event.messageType = MPMessageTypeBreadcrumb;
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSDictionary *messageInfo = [event breadcrumbDictionaryRepresentation];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:event.messageType session:self.session messageInfo:messageInfo context:self.messageBuilderContext];
    if (event.timestamp) {
        [messageBuilder timestamp:[event.timestamp timeIntervalSince1970]];
    }
    MPMessage *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:YES];
    
    if ([self.eventSet containsObject:event]) {
        [_eventSet removeObject:event];
    }
    
    [self.session incrementCounter];
    
    execStatus = MPExecStatusSuccess;

    completionHandler(event, execStatus);
}

- (void)logError:(NSString *)message exception:(NSException *)exception topmostContext:(id)topmostContext eventInfo:(NSDictionary *)eventInfo completionHandler:(void (^)(NSString *message, MPExecStatus execStatus))completionHandler {
    NSString *execMessage = exception ? exception.name : message;
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSMutableDictionary *messageInfo = [@{kMPCrashWasHandled:@"true", kMPCrashingSeverity:@"error"} mutableCopy];
    if (exception) {
        messageInfo[kMPErrorMessage] = exception.reason;
        messageInfo[kMPCrashingClass] = exception.name;
        
        NSArray *callStack = [exception callStackSymbols];
        if (callStack) {
            messageInfo[kMPStackTrace] = [callStack componentsJoinedByString:@"\n"];
        }
        
        NSArray<MPBreadcrumb *> *fetchedbreadcrumbs = [self.persistence fetchBreadcrumbs];
        if (fetchedbreadcrumbs) {
            NSMutableArray *breadcrumbs = [[NSMutableArray alloc] initWithCapacity:fetchedbreadcrumbs.count];
            for (MPBreadcrumb *breadcrumb in fetchedbreadcrumbs) {
                [breadcrumbs addObject:[breadcrumb dictionaryRepresentation]];
            }
            
            NSString *messageTypeBreadcrumbKey = kMPMessageTypeStringBreadcrumb;
            messageInfo[messageTypeBreadcrumbKey] = breadcrumbs;
        }
    } else {
        messageInfo[kMPErrorMessage] = message;
    }
    
    if (topmostContext) {
        messageInfo[kMPTopmostContext] = [[topmostContext class] description];
    }
    
    if (eventInfo.count > 0) {
        messageInfo[kMPAttributesKey] = eventInfo;
    }
    
    NSDictionary *appImageInfo = [MPApplication_PRIVATE appImageInfo];
    if (appImageInfo) {
        [messageInfo addEntriesFromDictionary:appImageInfo];
    }
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeCrashReport session:self.session messageInfo:messageInfo context:self.messageBuilderContext];

    MPMessage *errorMessage = [messageBuilder build];
    
    [self saveMessage:errorMessage updateSession:YES];
    
    execStatus = MPExecStatusSuccess;
    
    completionHandler(execMessage, execStatus);
}

-  (void)logCrash:(NSString *)message stackTrace:(NSString *)stackTrace plCrashReport:(NSString *)plCrashReport completionHandler:(void (^)(NSString *message, MPExecStatus execStatus)) completionHandler
{
    NSString *execMessage = message ? message : @"Crash Report";
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSMutableDictionary *messageInfo = [@{
        kMPCrashingSeverity: @"fatal",
        kMPCrashWasHandled: @"false"
    } mutableCopy];
    
    if(message) {
        messageInfo[kMPErrorMessage] = message;
    }
    
    NSString *plCrashReportBase64 = [MPBackendMessageInfo base64CrashReport:plCrashReport maxBytes:[MParticle sharedInstance].stateMachine.crashMaxPLReportLength];
    if(plCrashReportBase64) {
        messageInfo[kMPPLCrashReport] = plCrashReportBase64;
    }
    
    id<MPBackendPersistence> persistence = self.persistence;
    NSArray<MPBreadcrumb *> *fetchedbreadcrumbs = [persistence fetchBreadcrumbs];
    if (fetchedbreadcrumbs) {
        NSMutableArray *breadcrumbs = [[NSMutableArray alloc] initWithCapacity:fetchedbreadcrumbs.count];
        for (MPBreadcrumb *breadcrumb in fetchedbreadcrumbs) {
            [breadcrumbs addObject:[breadcrumb dictionaryRepresentation]];
        }
        messageInfo[kMPMessageTypeLeaveBreadcrumbs] = breadcrumbs;
    }
    
    if(stackTrace) {
        messageInfo[kMPStackTrace] = stackTrace;
    }

    MPSession *crashSession = nil;
    NSArray<MPSession *> *sessions = [persistence fetchPossibleSessionsFromCrash];
    for (MPSession *session in sessions) {
        if (![session isEqual:self.session]) {
            crashSession = session;
            break;
        }
    }
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeCrashReport session:crashSession messageInfo:messageInfo context:self.messageBuilderContext];
    MPMessage *crashMessage = [messageBuilder build];
    
    NSNumber *bytesToRetain = [MPBackendMessageInfo crashReportBytesToRetainForMessageLength:crashMessage.messageData.length
                                                                                    maxBytes:[MPPersistenceUtilities maxBytesPerEvent:crashMessage.messageType]
                                                                          base64ReportLength:plCrashReportBase64.length];
    if (bytesToRetain != nil) {
        [crashMessage truncateMessageDataProperty:kMPPLCrashReport toLength:bytesToRetain.integerValue];
    }
    [persistence saveMessage:crashMessage];
    
    execStatus = MPExecStatusSuccess;
    completionHandler(execMessage, execStatus);
}

- (void)logBaseEvent:(MPBaseEvent *)event completionHandler:(void (^)(MPBaseEvent *event, MPExecStatus execStatus))completionHandler {
    if (event.shouldBeginSession) {
        NSDate *date = event.timestamp ?: [NSDate date];
        [self beginSessionWithIsManual:!MParticle.sharedInstance.automaticSessionTracking date:date];
    }
    if ([event isKindOfClass:[MPEvent class]] || [event isKindOfClass:[MPCommerceEvent class]]) {
        NSDictionary<NSString *, id> *messageInfo = [event dictionaryRepresentation];
            
            MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:event.messageType session:self.session messageInfo:messageInfo context:self.messageBuilderContext];
            if (event.timestamp) {
                [messageBuilder timestamp:[event.timestamp timeIntervalSince1970]];
            }

            MPMessage *message = [messageBuilder build];
            message.shouldUploadEvent = event.shouldUploadEvent;
            
            [self saveMessage:message updateSession:YES];
            
            [self.session incrementCounter];
            
            MPILogDebug(@"Logged event: %@", event.dictionaryRepresentation);
    }
    
    completionHandler(event, MPExecStatusSuccess);
}

- (void)logEvent:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
     event.messageType = MPMessageTypeEvent;

    [self logBaseEvent:event
     completionHandler:^(MPBaseEvent *baseEvent, MPExecStatus execStatus) {
         if ([self.eventSet containsObject:(MPEvent *)baseEvent]) {
             [self.eventSet removeObject:(MPEvent *)baseEvent];
         }

         completionHandler((MPEvent *)baseEvent, execStatus);
     }];
}

- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent completionHandler:(void (^)(MPCommerceEvent *commerceEvent, MPExecStatus execStatus))completionHandler {
    commerceEvent.messageType = MPMessageTypeCommerceEvent;
    
    [self logBaseEvent:commerceEvent
     completionHandler:^(MPBaseEvent *baseEvent, MPExecStatus execStatus) {
         completionHandler((MPCommerceEvent *)baseEvent, execStatus);
     }];
}

- (void)logNetworkPerformanceMeasurement:(MPNetworkPerformance *)networkPerformance completionHandler:(void (^)(MPNetworkPerformance *networkPerformance, MPExecStatus execStatus))completionHandler {
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSDictionary *messageInfo = [networkPerformance dictionaryRepresentation];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeNetworkPerformance session:self.session messageInfo:messageInfo context:self.messageBuilderContext];

    MPMessage *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:YES];
    
    execStatus = MPExecStatusSuccess;
    
    if (completionHandler) {
        completionHandler(networkPerformance, execStatus);
    }
}

- (void)logScreen:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    event.messageType = MPMessageTypeScreenView;

    MPExecStatus execStatus = MPExecStatusFail;

    [event endTiming];
    
    if (event.type != MPEventTypeNavigation) {
        event.type = MPEventTypeNavigation;
    }
    
    NSDictionary *messageInfo = [event screenDictionaryRepresentation];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:event.messageType session:self.session messageInfo:messageInfo context:self.messageBuilderContext];
    if (event.timestamp) {
        [messageBuilder timestamp:[event.timestamp timeIntervalSince1970]];
    }

    MPMessage *message = [messageBuilder build];
    message.shouldUploadEvent = event.shouldUploadEvent;
    
    [self saveMessage:message updateSession:YES];
    
    if ([self.eventSet containsObject:event]) {
        [_eventSet removeObject:event];
    }
    
    [self.session incrementCounter];
    
    execStatus = MPExecStatusSuccess;
    
    completionHandler(event, execStatus);
}

- (void)setOptOut:(BOOL)optOutStatus completionHandler:(void (^)(BOOL optOut, MPExecStatus execStatus))completionHandler {
    dispatch_async([MParticle messageQueue], ^{
        MPExecStatus execStatus = MPExecStatusFail;
        
        [MParticle sharedInstance].stateMachine.optOut = optOutStatus;
        
        MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeOptOut session:self.session messageInfo:@{kMPOptOutStatus:(optOutStatus ? @"true" : @"false")} context:self.messageBuilderContext];

        MPMessage *message = [messageBuilder build];
        
        [self saveMessage:message updateSession:YES];
        
        execStatus = MPExecStatusSuccess;
        
        completionHandler(optOutStatus, execStatus);
    });
}

- (MPExecStatus)setSessionAttribute:(MPSession *)session key:(NSString *)key value:(id)value {
    NSAssert(session != nil, @"session cannot be nil.");
    NSAssert([key isKindOfClass:[NSString class]], @"'key' must be a string.");
    NSAssert([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]], @"'value' must be a string or number.");
    
    if (!session) {
        return MPExecStatusMissingParam;
    } else if (![value isKindOfClass:[NSString class]] && ![value isKindOfClass:[NSNumber class]]) {
        return MPExecStatusInvalidDataType;
    }
    
    NSString *localKey = [session.attributesDictionary caseInsensitiveKey:key];
    NSError *error = nil;
    BOOL success = [MPBackendController_PRIVATE checkAttribute:session.attributesDictionary
                                    key:localKey
                                  value:value
                                  error:&error];
    if ((!success && error) || [session.attributesDictionary[localKey] isEqual:value]) {
        return MPExecStatusInvalidDataType;
    }
    
    session.attributesDictionary[localKey] = value;
    
    [self.persistence updateSession:session];
    
    return MPExecStatusSuccess;
}

- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret networkOptions:(nullable MPNetworkOptions *)networkOptions firstRun:(BOOL)firstRun installationType:(MPInstallationType)installationType startKitsAsync:(BOOL)startKitsAsync consentState:(MPConsentState *)consentState completionHandler:(dispatch_block_t)completionHandler {
    MPILogDebug(@"Backend controller starting - firstRun: %@, startKitsAsync: %@",
                firstRun ? @"YES" : @"NO", startKitsAsync ? @"YES" : @"NO");
    
    MPConsentState *storedConsentState = [MPPersistenceUtilities consentStateForMpid:[MPPersistenceUtilities mpId]];
    if (consentState != nil && storedConsentState == nil) {
        [MPPersistenceUtilities setConsentState:consentState forMpid:[MPPersistenceUtilities mpId]];
    }
    
    if (![MParticle sharedInstance].stateMachine.optOut) {
        MPILogDebug(@"Dispatching kit initialization to message queue");
        dispatch_async([MParticle messageQueue], ^{
            [[MParticle sharedInstance].kitContainer_PRIVATE initializeKits];
        });
    } else {
        MPILogWarning(@"Skipping kit initialization - SDK is opted out");
    }

    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    stateMachine.apiKey = apiKey;
    stateMachine.secret = secret;
    stateMachine.installationType = installationType;
    [MPStateMachine_PRIVATE setRunningInBackground:NO];
    
    BOOL shouldBeginSession = !stateMachine.optOut && MParticle.sharedInstance.shouldBeginSession;
    NSDate *date = nil;
    if (shouldBeginSession) {
        [self createTempSession];
        date = [NSDate date];
    }
    
    dispatch_async([MParticle messageQueue], ^{
        [[MParticle sharedInstance] initializePersistence];
        self.persistence = [MParticle sharedInstance].persistenceStore;

        // Check if we've switched workspaces on startup
        MPUploadSettings *lastUploadSettings = [UploadSettingsUtils lastUploadSettingsWithUserDefaults: MPUserDefaultsConnector.userDefaults];
        if (![lastUploadSettings.apiKey isEqualToString:apiKey]) {
            // Different workspace, so batch previous messages under old upload settings before starting
            [self prepareBatchesForUpload:lastUploadSettings];
            
            // Delete the cached config
            [MPUserDefaults deleteConfig];
        }
        
        // Cache the upload settings in case we switch workspaces on startup
        MPUploadSettings *uploadSettings = [[MPUploadSettings alloc] initWithApiKey:apiKey secret:secret networkOptions:networkOptions];
        [UploadSettingsUtils setLastUploadSettings:uploadSettings userDefaults: MPUserDefaultsConnector.userDefaults];
        
        // Restore cached config if exists
        (void)[MPUserDefaults restore];

        if (shouldBeginSession) {
            [self beginSessionWithIsManual:!MParticle.sharedInstance.automaticSessionTracking date:date];
        }
        
        MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeFirstRun session:self.session messageInfo:nil context:self.messageBuilderContext];
                
        [self processOpenSessionsEndingCurrent:NO completionHandler:^(void) {}];
        
        [self beginUploadTimer];
        
        if (firstRun) {
            MPMessage *message = [messageBuilder build];
            message.uploadStatus = MPUploadStatusBatch;
            
            [self saveMessage:message updateSession:YES];
            
            MPILogDebug(@"Application First Run");
        }
        
        // Single-shot: the attribution path and the global-timeout fallback below both hold this
        // block and the timeout is never cancelled, so whichever finishes first has to win.
        // -processDidFinishLaunching is not idempotent - running it twice forwards a second
        // install/update and emits a second app-state-transition message.
        void (^searchAdsCompletion)(void) = [self singleShotBlock:^{
            [self processDidFinishLaunching:self.didFinishLaunchingNotification];
            MPILogDebug(@"Initiating config request and upload cycle");
            [self waitForKitsAndUploadWithCompletionHandler:nil];
        }];
        
#if TARGET_OS_IOS == 1
        if (MParticle.sharedInstance.collectSearchAdsAttribution) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SEARCH_ADS_ATTRIBUTION_GLOBAL_TIMEOUT_SECONDS * NSEC_PER_SEC)), [MParticle messageQueue], searchAdsCompletion);
            [self requestAttributionDetailsWithBlock:searchAdsCompletion requestsCompleted:0];
        } else {
            searchAdsCompletion();
        }
#else
        searchAdsCompletion();
#endif
        
        MPILogDebug(@"SDK %@ has started", kMParticleSDKVersion);
        
        completionHandler();
    });
}

- (void)saveMessage:(MPMessage *)message updateSession:(BOOL)updateSession {
    [self.messageWriter saveMessage:message updateSession:updateSession];
}

- (MPExecStatus)waitForKitsAndUploadWithCompletionHandler:(void (^ _Nullable)(void))completionHandler {
    [self.uploadCoordinator waitForKitsAndUploadWithCompletionHandler:completionHandler];
    return MPExecStatusSuccess;
}

- (MPExecStatus)checkForKitsAndUploadWithCompletionHandler:(void (^ _Nullable)(BOOL didShortCircuit))completionHandler {
    [self.uploadCoordinator checkForKitsAndUploadWithCompletionHandler:completionHandler];
    return MPExecStatusSuccess;
}

- (void)setUserTag:(NSString *)key timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    NSString *keyCopy = [key mutableCopy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, nil, MPExecStatusMissingParam);
        }
        
        return;
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[[self userAttributesForUserId:[MPPersistenceUtilities mpId]] copy] key:keyCopy value:[NSNull null]];
    userAttributeChange.timestamp = timestamp;
    [self setUserAttributeChange:userAttributeChange completionHandler:completionHandler];
}

- (void)setUserAttribute:(NSString *)key value:(id)value timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    NSString *keyCopy = [key mutableCopy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, value, MPExecStatusMissingParam);
        }
        
        return;
    }
    
    if (![MPAttributeValidator isAcceptableScalarValue:value]) {
        if (completionHandler) {
            completionHandler(keyCopy, value, MPExecStatusInvalidDataType);
        }
        
        return;
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[[self userAttributesForUserId:[MPPersistenceUtilities mpId]] copy] key:keyCopy value:value];
    userAttributeChange.timestamp = timestamp;
    [self setUserAttributeChange:userAttributeChange completionHandler:completionHandler];
}

- (void)setUserAttribute:(nonnull NSString *)key values:(nullable NSArray<NSString *> *)values timestamp:(NSDate *)timestamp completionHandler:(void (^ _Nullable)(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus))completionHandler {
    NSString *keyCopy = [key mutableCopy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, values, MPExecStatusMissingParam);
        }
        
        return;
    }
    
    if (![MPAttributeValidator isAcceptableValueList:values]) {
        if (completionHandler) {
            completionHandler(keyCopy, values, MPExecStatusInvalidDataType);
        }
        
        return;
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[[self userAttributesForUserId:[MPPersistenceUtilities mpId]] copy] key:keyCopy value:values];
    userAttributeChange.isArray = YES;
    
    
    userAttributeChange.timestamp = timestamp;
    [self setUserAttributeChange:userAttributeChange completionHandler:completionHandler];
}

- (void)removeUserAttribute:(NSString *)key timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    NSString *keyCopy = [key mutableCopy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, nil, MPExecStatusMissingParam);
        }
        
        return;
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[[self userAttributesForUserId:[MPPersistenceUtilities mpId]] copy] key:keyCopy value:nil];
    userAttributeChange.timestamp = timestamp;
    [self setUserAttributeChange:userAttributeChange completionHandler:completionHandler];
}

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *identityString, MPUserIdentity identityType, MPExecStatus execStatus))completionHandler {
    
    NSAssert(completionHandler != nil, @"completionHandler cannot be nil.");
    
    if (MPIsNull(identityString)) {
        identityString = nil;
    }
    
    MPUserIdentityInstancePRIVATE *newUserIdentity = [[MPUserIdentityInstancePRIVATE alloc] initWithType:(MPUserIdentitySwift)identityType
                                                                                                     value:identityString];
    
    MPUserIdentityChangePRIVATE *userIdentityChange = [[MPUserIdentityChangePRIVATE alloc] initWithNewUserIdentity:newUserIdentity
                                                                                                      userIdentities:[self identitiesForUserId:[MPPersistenceUtilities mpId]]];
    
    userIdentityChange.timestamp = timestamp;
    
    NSMutableArray *userIdentities = [self userIdentitiesForUserId:[MPPersistenceUtilities mpId]];

    MPUserIdentityChangePlan *plan = [MPUserIdentityLogic planForIdentityType:@(userIdentityChange.newUserIdentity.type)
                                                                        value:userIdentityChange.newUserIdentity.value
                                                            currentIdentities:userIdentities
                                                                      typeKey:kMPUserIdentityTypeKey
                                                                        idKey:kMPUserIdentityIdKey
                                                              dateFirstSetKey:kMPDateUserIdentityWasFirstSet
                                                                          now:[NSDate date]];

    if (plan.kind == MPUserIdentityChangeKindUnchanged) {
        completionHandler(identityString, identityType, MPExecStatusFail);
        return;
    }

    BOOL persistUserIdentities = plan.kind != MPUserIdentityChangeKindNothingToRemove;

    switch (plan.kind) {
        case MPUserIdentityChangeKindRemove:
            userIdentityChange.oldUserIdentity = [[MPUserIdentityInstancePRIVATE alloc] initWithUserIdentityDictionary:plan.existingIdentity];
            userIdentityChange.newUserIdentity = nil;
            [userIdentities removeObjectAtIndex:plan.index];
            break;

        case MPUserIdentityChangeKindAdd:
            userIdentityChange.newUserIdentity.dateFirstSet = plan.dateFirstSet;
            userIdentityChange.newUserIdentity.isFirstTimeSet = plan.isFirstTimeSet;
            [userIdentities addObject:[userIdentityChange.newUserIdentity dictionaryRepresentation]];
            break;

        case MPUserIdentityChangeKindReplace:
            userIdentityChange.oldUserIdentity = [[MPUserIdentityInstancePRIVATE alloc] initWithUserIdentityDictionary:plan.existingIdentity];
            userIdentityChange.newUserIdentity.dateFirstSet = plan.dateFirstSet;
            userIdentityChange.newUserIdentity.isFirstTimeSet = plan.isFirstTimeSet;
            [userIdentities replaceObjectAtIndex:plan.index withObject:[userIdentityChange.newUserIdentity dictionaryRepresentation]];
            break;

        case MPUserIdentityChangeKindNothingToRemove:
        case MPUserIdentityChangeKindUnchanged:
            break;
    }

    if (persistUserIdentities) {
        if (userIdentityChange.changed) {
            [self logUserIdentityChange:userIdentityChange];
            
            MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
            [userDefaults setObject:userIdentities forKeyedSubscript:kMPUserIdentityArrayKey];
            [userDefaults synchronize];
        }
    }
    
    completionHandler(userIdentityChange.newUserIdentity.value, (MPUserIdentity)userIdentityChange.newUserIdentity.type, MPExecStatusSuccess);
}

- (void)clearUserAttributes {
    MPUserDefaults *defaults = MPUserDefaultsConnector.userDefaults;
    [defaults removeMPObjectForKey:@"ua"];
    [defaults synchronize];
}

#if TARGET_OS_IOS == 1

- (MPNotificationController_PRIVATE *)notificationController {
    return _notificationController;
}

- (void)setNotificationController:(MPNotificationController_PRIVATE *)notificationController {
    _notificationController = notificationController;
}

- (void)handleDeviceTokenNotification:(NSNotification *)notification {
    dispatch_async([MParticle messageQueue], ^{
        NSDictionary *userInfo = [notification userInfo];
        NSData *deviceToken = userInfo[kMPRemoteNotificationDeviceTokenKey];
        NSData *oldDeviceToken = userInfo[kMPRemoteNotificationOldDeviceTokenKey];
        
        MPPushRegistrationDecision *decision = [MPBackendMessageInfo pushRegistrationForDeviceToken:deviceToken oldDeviceToken:oldDeviceToken];
        if (!decision) {
            return;
        }

        NSData *logDeviceToken = decision.logToken;
        NSMutableDictionary *messageInfo = [@{kMPPushStatusKey:decision.status} mutableCopy];

        NSString *tokenString = [MPUserDefaults stringFromDeviceToken:logDeviceToken];
        if (tokenString) {
            messageInfo[kMPDeviceTokenKey] = tokenString;
        }
        
        if ([MParticle sharedInstance].stateMachine.deviceTokenType.length > 0) {
            messageInfo[kMPDeviceTokenTypeKey] = [MParticle sharedInstance].stateMachine.deviceTokenType;
        }
        
        MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypePushRegistration session:self.session messageInfo:messageInfo context:self.messageBuilderContext];
        MPMessage *message = [messageBuilder build];
        
        [self saveMessage:message updateSession:YES];
        
        if (deviceToken) {
            MPILogDebug(@"Set Device Token: %@", [MPUserDefaults stringFromDeviceToken:deviceToken]);
        } else {
            MPILogDebug(@"Reset Device Token: %@", [MPUserDefaults stringFromDeviceToken:oldDeviceToken]);
        }
    });
}

- (void)logUserNotification:(MParticleUserNotification *)userNotification {
    [MParticle executeOnMessage:^{
        NSMutableDictionary *messageInfo = [@{kMPPushNotificationStateKey:userNotification.state,
                                              kMPPushMessageProviderKey:kMPPushMessageProviderValue,
                                              kMPPushMessageTypeKey:userNotification.type}
                                            mutableCopy];
        
        NSString *tokenString = [MPUserDefaults stringFromDeviceToken:[self.notificationController deviceToken]];
        if (tokenString) {
            messageInfo[kMPDeviceTokenKey] = tokenString;
        }
                                 
        if (userNotification.redactedUserNotificationString) {
            messageInfo[kMPPushMessagePayloadKey] = userNotification.redactedUserNotificationString;
        }
        
        if (userNotification.actionTitle) {
            messageInfo[kMPPushNotificationActionTitleKey] = userNotification.actionTitle;
        }

        if (userNotification.actionIdentifier) {
            messageInfo[kMPPushNotificationActionIdentifierKey] = userNotification.actionIdentifier;
        }
    
        if (userNotification.behavior > 0) {
            messageInfo[kMPPushNotificationBehaviorKey] = @(userNotification.behavior);
        }
    
        MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypePushNotification session:self.session messageInfo:messageInfo context:self.messageBuilderContext];

        MPMessage *message = [messageBuilder build];
    
        [self saveMessage:message updateSession:(self.session != nil)];
    }];
}

#endif

#pragma mark - Background Handling -

#pragma mark Background Task

- (void)beginBackgroundTask {
    if ([MPStateMachine_PRIVATE isAppExtension]) {
        return;
    }
    
    [MParticle executeOnMain:^{
        if (self.backendBackgroundTaskIdentifier == UIBackgroundTaskInvalid) {
            self.backendBackgroundTaskIdentifier = [[MPApplication_PRIVATE sharedUIApplication] beginBackgroundTaskWithExpirationHandler:^{
                MPILogDebug(@"SDK has ended background activity together with the app.");
                [self cancelBackgroundTimeCheckLoop];
                [self endBackgroundTask];
            }];
        }
    }];
}

- (void)endBackgroundTask {
    if ([MPStateMachine_PRIVATE isAppExtension]) {
        return;
    }
    
    [MParticle executeOnMain:^{
        if (self.backendBackgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[MPApplication_PRIVATE sharedUIApplication] endBackgroundTask:self.backendBackgroundTaskIdentifier];
            self.backendBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
}

#pragma mark Session Handling

- (void)updateSessionBackgroundTime {
    [self.lifecycleCoordinator updateSessionBackgroundTime];
}

- (BOOL)shouldEndSession {
    return [self.lifecycleCoordinator shouldEndSession];
}

- (void)endSessionIfTimedOut {
    [self.lifecycleCoordinator endSessionIfTimedOut];
}

#pragma mark Application Lifecycle

- (void)cleanUp {
    [self.lifecycleCoordinator cleanUp];
}

- (void)cleanUp:(NSTimeInterval)currentTime {
    [self.lifecycleCoordinator cleanUp:currentTime];
}

- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    [self.lifecycleCoordinator applicationDidEnterBackground];
}

- (void)cancelBackgroundTimeCheckLoop {
    [self.backgroundCheckQueue cancelAllOperations];
}

- (void)beginBackgroundTimeCheckLoop {
    if ([MPStateMachine_PRIVATE isAppExtension]) {
        return;
    }
    
    // Cancel any existing background check loops
    [self cancelBackgroundTimeCheckLoop];
        
    NSBlockOperation *blockOperation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakBlockOperation = blockOperation;
    [blockOperation addExecutionBlock:^{
        // Reusable block to check application state on main thread
        UIApplicationState (^getApplicationState)(void) = ^UIApplicationState(void) {
            __block UIApplicationState appState;
            dispatch_sync(dispatch_get_main_queue(), ^{
                appState = [MPApplication_PRIVATE sharedUIApplication].applicationState;
            });
            return appState;
        };
        
        UIApplication *sharedApplication = [MPApplication_PRIVATE sharedUIApplication];
        UIApplicationState applicationState = getApplicationState();
        
        // Loop to check the background state and time remaining to decide when to upload
        while (applicationState == UIApplicationStateBackground) {
            [self endSessionIfTimedOut];
            
            // Perform cancellation check and backgroundTimeRemaining in a single
            // dispatch_sync to the main queue. This serializes with the expiration
            // handler and foreground handler (both fire on the main thread)
            __block BOOL cancelled = NO;
            __block NSTimeInterval timeRemaining = 0;
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSBlockOperation *strongOperation = weakBlockOperation;
                if (!strongOperation || strongOperation.isCancelled) {
                    cancelled = YES;
                    return;
                }
                timeRemaining = sharedApplication.backgroundTimeRemaining;
            });
            
            if (cancelled) {
                return;
            }
            
            if (timeRemaining <= kMPRemainingBackgroundTimeMinimumThreshold) {
                // Less than kMPRemainingBackgroundTimeMinimumThreshold seconds left in the background, upload the batch
                MPILogVerbose(@"Less than %f time remaining in background, uploading batch and ending background task", kMPRemainingBackgroundTimeMinimumThreshold);
                [MParticle executeOnMessage:^{
                    [self waitForKitsAndUploadWithCompletionHandler:^{
                        // Allow iOS to sleep the app
                        [self endUploadTimer];
                        [self endBackgroundTask];
                    }];
                }];
                return;
            }
            MPILogVerbose(@"Background time remaining %f", timeRemaining);
            
            // Short sleep to prevent burning CPU cycles
            [NSThread sleepForTimeInterval:1.0];
            applicationState = getApplicationState();
        }
        
        // The app is no longer in the background, so end the background task
        [self endBackgroundTask];
    }];
    [self.backgroundCheckQueue addOperation:blockOperation];
}

- (void)handleApplicationWillEnterForeground:(NSNotification *)notification {
    [self.lifecycleCoordinator applicationWillEnterForeground];
}

- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    [self.lifecycleCoordinator applicationDidBecomeActive];
}

// Wraps a block so it runs at most once however many callers hold it, from whatever queue. The
// attribution completion needs this because its two triggers - the request itself and the
// never-cancelled global timeout - fire on different queues.
- (dispatch_block_t)singleShotBlock:(dispatch_block_t)block {
    NSLock *lock = [[NSLock alloc] init];
    __block BOOL hasRun = NO;

    return ^{
        [lock lock];
        BOOL alreadyRan = hasRun;
        hasRun = YES;
        [lock unlock];

        if (!alreadyRan) {
            block();
        }
    };
}

#if TARGET_OS_IOS == 1
// Moved here from the deleted MPStateMachine_PRIVATE wrapper: this is its only production caller,
// and AdServices is already linked on the Objective-C side. The Swift state machine only receives
// the mapped result through its searchAdsInfo property.

// Separated so a test can substitute the session and assert the data task is resumed without
// reaching api-adservices.apple.com.
- (NSURLSession *)attributionURLSession {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 30;
    sessionConfiguration.timeoutIntervalForResource = 30;
    return [NSURLSession sessionWithConfiguration:sessionConfiguration
                                         delegate:nil
                                    delegateQueue:nil];
}

- (void)requestAttributionDetailsWithBlock:(void (^_Nonnull)(void))completionHandler requestsCompleted:(int)requestsCompleted {
    // The data task's completion handler runs on the URL session's delegate queue and the retry
    // hop runs on the main queue, but what the completion goes on to do - forwarding install/update
    // to the kits, starting the config request and the upload cycle - belongs on the SDK's serial
    // message queue, which is where the global-timeout fallback and every other caller invoke it.
    // -executeOnMessage: runs the block inline when already on that queue, so the paths that were
    // reachable before this method's data task was resumed keep their exact timing.
    void (^completion)(void) = ^{
        [MParticle executeOnMessage:completionHandler];
    };

    NSError *error;
    NSString *attributionToken = [AAAttribution attributionTokenWithError:&error];
    if (!attributionToken) {
        completion();
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api-adservices.apple.com/api/v1/"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[attributionToken dataUsingEncoding:NSUTF8StringEncoding]];

    // The existing retry policy, so the transport-error and unusable-response paths share one
    // definition of "try again or give up".
    void (^retryOrComplete)(void) = ^{
        if ((requestsCompleted + 1) > SEARCH_ADS_ATTRIBUTION_MAX_RETRIES) {
            completion();
            return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SEARCH_ADS_ATTRIBUTION_DELAY_BEFORE_RETRY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self requestAttributionDetailsWithBlock:completionHandler requestsCompleted:(requestsCompleted + 1)];
        });
    };

    NSURLSession *urlSession = [self attributionURLSession];
    dispatch_async([MParticle messageQueue], ^{
        NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *urlResponse, NSError *error) {
            if (error) {
                MPILogError(@"Failed requesting Ads Attribution with error: %@.", [error localizedDescription]);
                if (error.code == 1 /* ADClientErrorLimitAdTracking */) {
                    completion();
                } else {
                    retryOrComplete();
                }
                return;
            }

            // NSURLSession reports no error for a non-2xx response, so the status has to be checked
            // separately. Apple's endpoint answers 404 for a short window while a freshly minted
            // token becomes resolvable, which is exactly what the retry policy is for - before
            // -resume was added this branch was unreachable, so nothing ever exercised it.
            NSInteger statusCode = [urlResponse isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)urlResponse).statusCode : 0;
            if (statusCode < 200 || statusCode > 299) {
                MPILogError(@"Failed requesting Ads Attribution with HTTP status %ld.", (long)statusCode);
                retryOrComplete();
                return;
            }

            NSDictionary *adAttributionDictionary = nil;
            if (data) {
                id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                adAttributionDictionary = [parsed isKindOfClass:[NSDictionary class]] ? parsed : nil;
            }
            if (!adAttributionDictionary) {
                MPILogError(@"Ads Attribution response body was not a JSON object.");
                retryOrComplete();
                return;
            }

            NSDictionary *mapped = [MPStateMachine_PRIVATE searchAdsInfoFromAdAttribution:adAttributionDictionary];
            [MParticle sharedInstance].stateMachine.searchAdsInfo = mapped ?: @{};
            completion();
        }];
        // -dataTaskWithRequest:completionHandler: returns a suspended task. Without this the
        // request was never sent and the completion handler never ran.
        [task resume];
    });
}
#endif

@end

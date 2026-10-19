#import "MPBackendController.h"
#import "MPPersistenceUtilities.h"
#import "MPIConstants.h"
#import "MPNetworkPerformance.h"
#import "MPAudience.h"
#import "MPEvent.h"
#import "MParticleUserNotification.h"
#import "NSDictionary+MPCaseInsensitive.h"
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

// MPUserDefaultsConnector holds no state and reads MParticle.sharedInstance on every call.
static id<MPBackendHost> MPBackendHostInstance(void) {
    return (id<MPBackendHost>)[[MPUserDefaultsConnector alloc] init];
}

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
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
+ (dispatch_queue_t)messageQueue;
+ (void)executeOnMessage:(void(^)(void))block;
+ (void)executeOnMain:(void(^)(void))block;
- (void)initializePersistence;

@end

@interface MPBackendController_PRIVATE() <MPBackendAssemblyOwner> {
    MParticleSession *tempSession;
}
@property NSTimeInterval timeAppWentToBackgroundInCurrentSession;
@property NSTimeInterval timeOfLastEventInBackground;
@property NSNotification *didFinishLaunchingNotification;
@property UIBackgroundTaskIdentifier backendBackgroundTaskIdentifier;
@property NSOperationQueue *backgroundCheckQueue;
@property (nonatomic, strong) id<MPBackendPersistence> persistence;
@property (nonatomic, strong, readonly, nonnull) MPBackendSessionState *sessionState;
@property (nonatomic, strong, readonly, nonnull) MPBackendAssembly *assembly;
@property (nonatomic, readonly, nonnull) MPBackendSessionDependencies *sessionDependencies;
@property (nonatomic, readonly, nonnull) MPBackendMessageWriter *messageWriter;
@property (nonatomic, readonly, nonnull) MPBackendErrorReporter *errorReporter;
@property (nonatomic, readonly, nonnull) MPBackendUserAttributeWriter *userAttributeWriter;
@property (nonatomic, readonly, nonnull) MPBackendSessionCoordinator *sessionCoordinator;
@property (nonatomic, readonly, nonnull) MPBackendLifecycleCoordinator *lifecycleCoordinator;
@property (nonatomic, readonly, nonnull) MPBackendSessionLifecycleDependencies *sessionLifecycleDependencies;
@property (nonatomic, readonly, nonnull) MPBackendUploadCoordinator *uploadCoordinator;
- (MPUploadBuilderContext *)uploadBuilderContext;
+ (MPUploadBuilderContext *)uploadBuilderContextWithPersistence:(id<MPUploadEnrichmentPersistence> (^)(void))persistence;

@end


@implementation MPBackendController_PRIVATE
@synthesize sessionState = _sessionState;

#if TARGET_OS_IOS == 1
@synthesize notificationController = _notificationController;
#endif

- (instancetype)init {
    self = [super init];
    if (self) {
        _sessionState = [[MPBackendSessionState alloc] init];
        _assembly = [[MPBackendAssembly alloc] initWithState:_sessionState
                                                        host:MPBackendHostInstance()
                                                       owner:self
                                           validateAttribute:^MPAttributeValidationResult(NSString *key, id value) {
            return [MPBackendController_PRIVATE validateAndLogAttributeKey:key value:value];
        }];
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
        _sessionState.sessionTimeout = DEFAULT_SESSION_TIMEOUT;
        _sessionState.nextCleanUpTime = [[NSDate date] timeIntervalSince1970];
        self.lifecycleCoordinator.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        _delegate = delegate;
        self.lifecycleCoordinator.backgroundCheckQueue = [[NSOperationQueue alloc] init];
        self.lifecycleCoordinator.backgroundCheckQueue.maxConcurrentOperationCount = 1;
        
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

- (MPBackendSessionState *)sessionState {
    NSAssert(_sessionState != nil, @"Backend initializers must create session state before use");
    return _sessionState;
}

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

#pragma mark Collaborators

- (MPBackendSessionDependencies *)sessionDependencies {
    return self.assembly.sessionDependencies;
}

- (MPBackendMessageWriter *)messageWriter {
    return self.assembly.messageWriter;
}

- (MPBackendErrorReporter *)errorReporter {
    return self.assembly.errorReporter;
}

- (MPBackendUserAttributeWriter *)userAttributeWriter {
    return self.assembly.userAttributeWriter;
}

- (MPBackendSessionCoordinator *)sessionCoordinator {
    return self.assembly.sessionCoordinator;
}

- (MPBackendLifecycleCoordinator *)lifecycleCoordinator {
    return self.assembly.lifecycleCoordinator;
}

- (MPBackendSessionLifecycleDependencies *)sessionLifecycleDependencies {
    return self.assembly.sessionLifecycleDependencies;
}

- (MPBackendUploadCoordinator *)uploadCoordinator {
    return self.assembly.uploadCoordinator;
}

- (NSTimeInterval)timeAppWentToBackgroundInCurrentSession {
    return self.sessionState.timeAppWentToBackgroundInCurrentSession;
}

- (void)setTimeAppWentToBackgroundInCurrentSession:(NSTimeInterval)value {
    self.sessionState.timeAppWentToBackgroundInCurrentSession = value;
}

- (NSMutableSet<MPEvent *> *)eventSet {
    if (_eventSet) {
        return _eventSet;
    }
    
    _eventSet = [[NSMutableSet alloc] initWithCapacity:1];
    return _eventSet;
}

- (NSMutableDictionary<NSString *, id> *)userAttributesForUserId:(NSNumber *)userId {
    return [self.userAttributeWriter userAttributesForUserId:userId];
}

- (NSMutableArray<NSDictionary<NSString *, id> *> *)userIdentitiesForUserId:(NSNumber *)userId {
    return [self.assembly.identityWriter userIdentitiesForUserId:userId];
}

#pragma mark Private methods

- (MPMessageBuilderContext *)messageBuilderContext {
    return [[MPMessageBuilderContext alloc] initWithHost:MPBackendHostInstance()];
}

- (MPUploadBuilderContext *)uploadBuilderContext {
    return [MPBackendController_PRIVATE uploadBuilderContextWithPersistence:^{ return self.persistence; }];
}

+ (MPUploadBuilderContext *)uploadBuilderContextWithPersistence:(id<MPUploadEnrichmentPersistence> (^)(void))persistence {
    return [[MPUploadBuilderContext alloc] initWithHost:MPBackendHostInstance() persistence:persistence];
}

#pragma mark MPBackendAssemblyOwner

- (void)uploadFromBackendWithCompletionHandler:(dispatch_block_t)completionHandler {
    [self waitForKitsAndUploadWithCompletionHandler:completionHandler];
}

- (void)requestConfigFromBackend {
    [self requestConfig:nil];
}

- (id<MPBackendUploadNetworking>)uploadNetworking {
    return (id<MPBackendUploadNetworking>)self.networkCommunication;
}

- (void)createPendingSessionWithUUID:(NSString *)uuid {
    tempSession = [[MParticleSession alloc] initWithUUID:uuid];
}

- (void)setPendingSessionStartTime:(double)timestamp {
    tempSession.startTime = @(timestamp);
}

- (void)clearPendingSession {
    tempSession = nil;
}

- (void)clearEmptyTimedEvents {
    if (self.eventSet.count == 0) {
        self.eventSet = nil;
    }
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

- (void)beginUploadTimer {
    [self.lifecycleCoordinator beginUploadTimer];
}

- (void)endUploadTimer {
    [self.assembly.lifecycleCoordinator endUploadTimer];
}

#pragma mark Public accessors

- (NSTimeInterval)sessionTimeout {
    return self.lifecycleCoordinator.sessionTimeout;
}

- (void)setSessionTimeout:(NSTimeInterval)sessionTimeout {
    self.lifecycleCoordinator.sessionTimeout = sessionTimeout;
}

- (NSTimeInterval)uploadInterval {
    return self.lifecycleCoordinator.uploadInterval;
}

- (void)setUploadInterval:(NSTimeInterval)uploadInterval {
    self.lifecycleCoordinator.uploadInterval = uploadInterval;
}

- (NSOperationQueue *)backgroundCheckQueue {
    return self.lifecycleCoordinator.backgroundCheckQueue;
}

- (void)setBackgroundCheckQueue:(NSOperationQueue *)queue {
    self.lifecycleCoordinator.backgroundCheckQueue = queue;
}

- (UIBackgroundTaskIdentifier)backendBackgroundTaskIdentifier {
    return self.lifecycleCoordinator.backgroundTaskIdentifier;
}

- (void)setBackendBackgroundTaskIdentifier:(UIBackgroundTaskIdentifier)identifier {
    self.lifecycleCoordinator.backgroundTaskIdentifier = identifier;
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

    return [self.userAttributeWriter incrementUserAttribute:key byValue:value];
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
    NSString *topmostContextDescription = topmostContext ? [[topmostContext class] description] : nil;
    NSString *execMessage = [self.errorReporter logErrorWithMessage:message
                                                          exception:exception
                                          topmostContextDescription:topmostContextDescription
                                                          eventInfo:eventInfo];
    completionHandler(execMessage, MPExecStatusSuccess);
}

-  (void)logCrash:(NSString *)message stackTrace:(NSString *)stackTrace plCrashReport:(NSString *)plCrashReport completionHandler:(void (^)(NSString *message, MPExecStatus execStatus)) completionHandler
{
    NSString *execMessage = [self.errorReporter logCrashWithMessage:message
                                                         stackTrace:stackTrace
                                                      plCrashReport:plCrashReport];
    completionHandler(execMessage, MPExecStatusSuccess);
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

    if (!session) {
        return MPExecStatusMissingParam;
    } else if (![key isKindOfClass:[NSString class]]) {
        // A caller behind an untyped bridge can pass a number or a null where the signature says a string;
        // the case-insensitive lookup below hands the key to Swift as a String, where another type is a
        // crash rather than an exception, so the type is checked at runtime, not only by an assertion a
        // release build drops.
        return MPExecStatusInvalidDataType;
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
    
    // Weak, so that once nothing else holds a controller a reset or workspace switch replaced, it is
    // released rather than starting up against the instance that replaced it.
    __weak MPBackendController_PRIVATE *weakSelf = self;
    dispatch_async([MParticle messageQueue], ^{
        MPBackendController_PRIVATE *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [[MParticle sharedInstance] initializePersistence];
        strongSelf.persistence = [MParticle sharedInstance].persistenceStore;

        // Check if we've switched workspaces on startup
        MPUploadSettings *lastUploadSettings = [UploadSettingsUtils lastUploadSettingsWithUserDefaults: MPUserDefaultsConnector.userDefaults];
        if (![lastUploadSettings.apiKey isEqualToString:apiKey]) {
            // Different workspace, so batch previous messages under old upload settings before starting
            [strongSelf prepareBatchesForUpload:lastUploadSettings];
            
            // Delete the cached config
            [MPUserDefaults deleteConfig];
        }
        
        // Cache the upload settings in case we switch workspaces on startup
        MPUploadSettings *uploadSettings = [[MPUploadSettings alloc] initWithApiKey:apiKey secret:secret networkOptions:networkOptions];
        [UploadSettingsUtils setLastUploadSettings:uploadSettings userDefaults: MPUserDefaultsConnector.userDefaults];
        
        // Restore cached config if exists
        (void)[MPUserDefaults restore];

        if (shouldBeginSession) {
            [strongSelf beginSessionWithIsManual:!MParticle.sharedInstance.automaticSessionTracking date:date];
        }
        
        MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeFirstRun session:strongSelf.session messageInfo:nil context:strongSelf.messageBuilderContext];
                
        [strongSelf processOpenSessionsEndingCurrent:NO completionHandler:^(void) {}];
        
        [strongSelf beginUploadTimer];
        
        if (firstRun) {
            MPMessage *message = [messageBuilder build];
            message.uploadStatus = MPUploadStatusBatch;
            
            [strongSelf saveMessage:message updateSession:YES];
            
            MPILogDebug(@"Application First Run");
        }
        
        // Single-shot: the attribution path and the global-timeout fallback below both hold this
        // block and the timeout is never cancelled, so whichever finishes first has to win.
        // -processDidFinishLaunching is not idempotent - running it twice forwards a second
        // install/update and emits a second app-state-transition message. The timeout holds the block
        // for 30 seconds, so it captures the controller weakly.
        void (^searchAdsCompletion)(void) = [strongSelf singleShotBlock:^{
            MPBackendController_PRIVATE *backend = weakSelf;
            if (!backend) {
                return;
            }
            [backend processDidFinishLaunching:backend.didFinishLaunchingNotification];
            MPILogDebug(@"Initiating config request and upload cycle");
            [backend waitForKitsAndUploadWithCompletionHandler:nil];
        }];
        
#if TARGET_OS_IOS == 1
        if (MParticle.sharedInstance.collectSearchAdsAttribution) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SEARCH_ADS_ATTRIBUTION_GLOBAL_TIMEOUT_SECONDS * NSEC_PER_SEC)), [MParticle messageQueue], searchAdsCompletion);
            [strongSelf requestAttributionDetailsWithBlock:searchAdsCompletion requestsCompleted:0];
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
    MPBackendUserAttributeOutcome *outcome = [self.userAttributeWriter setUserTag:key timestamp:timestamp];
    if (completionHandler) {
        completionHandler(outcome.key, outcome.value, outcome.status);
    }
}

- (void)setUserAttribute:(NSString *)key value:(id)value timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    MPBackendUserAttributeOutcome *outcome = [self.userAttributeWriter setUserAttribute:key value:value timestamp:timestamp];
    if (completionHandler) {
        completionHandler(outcome.key, outcome.value, outcome.status);
    }
}

- (void)setUserAttribute:(nonnull NSString *)key values:(nullable NSArray<NSString *> *)values timestamp:(NSDate *)timestamp completionHandler:(void (^ _Nullable)(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus))completionHandler {
    MPBackendUserAttributeOutcome *outcome = [self.userAttributeWriter setUserAttribute:key values:values timestamp:timestamp];
    if (completionHandler) {
        completionHandler(outcome.key, outcome.value, outcome.status);
    }
}

- (void)removeUserAttribute:(NSString *)key timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    MPBackendUserAttributeOutcome *outcome = [self.userAttributeWriter removeUserAttribute:key timestamp:timestamp];
    if (completionHandler) {
        completionHandler(outcome.key, outcome.value, outcome.status);
    }
}

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *identityString, MPUserIdentity identityType, MPExecStatus execStatus))completionHandler {
    NSAssert(completionHandler != nil, @"completionHandler cannot be nil.");

    MPBackendIdentityOutcome *outcome = [self.assembly.identityWriter setUserIdentity:identityString
                                                                         identityType:(MPUserIdentitySwift)identityType
                                                                            timestamp:timestamp];
    completionHandler(outcome.value, (MPUserIdentity)outcome.type, outcome.status);
}

- (void)clearUserAttributes {
    [self.userAttributeWriter clearUserAttributes];
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
    [self.lifecycleCoordinator beginBackgroundTask];
}

- (void)endBackgroundTask {
    [self.lifecycleCoordinator endBackgroundTask];
}

#pragma mark Session Handling

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
    [self.lifecycleCoordinator cancelBackgroundTimeCheckLoop];
}

- (void)beginBackgroundTimeCheckLoop {
    [self.lifecycleCoordinator beginBackgroundTimeCheckLoop];
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

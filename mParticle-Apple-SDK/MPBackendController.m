#import "MPBackendController.h"
#import "MPPersistenceUtilities.h"
#import "MPIConstants.h"
#import "MPNetworkPerformance.h"
#import "MPAudience.h"
#import "MPEvent.h"
#import "MParticleUserNotification.h"
#import "MPILogger.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "Kits/MPKitContainer+MParticlePrivate.h"
#import "mParticle.h"
#import "MPNetworkCommunication.h"
#import "MPUserDefaultsConnector.h"
#import "MPUploadSettings.h"
@import mParticle_Apple_SDK_Swift;

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
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
- (void)initializePersistence;

@end

@interface MPBackendController_PRIVATE() <MPBackendAssemblyOwner> {
    MParticleSession *tempSession;
}
@property NSTimeInterval timeAppWentToBackgroundInCurrentSession;
@property NSTimeInterval timeOfLastEventInBackground;
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

- (instancetype)init {
    self = [super init];
    if (self) {
        _sessionState = [[MPBackendSessionState alloc] init];
        _assembly = [[MPBackendAssembly alloc] initWithState:_sessionState host:MPBackendHostInstance() owner:self];
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

- (id<MPBackendControllerDelegate>)backendDelegate {
    return self.delegate;
}

- (void)prepareBatchesForUploadSettings:(NSObject *)settings {
    [self prepareBatchesForUpload:(MPUploadSettings *)settings];
}

- (void)processDidFinishLaunching:(NSNotification *)notification {
    [self.assembly.startupCoordinator processDidFinishLaunching:notification];
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
    self.assembly.startupCoordinator.didFinishLaunchingNotification = notification;
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

+ (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value error:(out NSError *__autoreleasing *)error  {
    return [MPBackendAttributeValidation checkKey:key value:value host:MPBackendHostInstance() error:error];
}

- (MPEvent *)eventWithName:(NSString *)eventName {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", eventName];
    MPEvent *event = [[self.eventSet filteredSetUsingPredicate:predicate] anyObject];
    
    return event;
}

- (MPExecStatus)fetchAudiencesWithCompletionHandler:(void (^ _Nonnull)(NSArray * _Nullable currentAudiences, NSError * _Nullable error))completionHandler {
    NSAssert(completionHandler != nil, @"completionHandler cannot be nil.");

    [self.assembly.messageLogger fetchAudiencesWithCompletionHandler:completionHandler];
    return MPExecStatusSuccess;
}

- (NSNumber *)incrementSessionAttribute:(MPSession *)session key:(NSString *)key byValue:(NSNumber *)value {
    return [self.assembly.sessionAttributeWriter incrementSessionAttribute:session key:key byValue:value];
}

- (NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    NSAssert([key isKindOfClass:[NSString class]], @"'key' must be a string.");
    NSAssert([value isKindOfClass:[NSNumber class]], @"'value' must be a number.");

    return [self.userAttributeWriter incrementUserAttribute:key byValue:value];
}

- (void)leaveBreadcrumb:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    event.messageType = MPMessageTypeBreadcrumb;
    [self.assembly.eventLogger saveEventMessageOfType:event.messageType
                                          messageInfo:[event breadcrumbDictionaryRepresentation]
                                            timestamp:event.timestamp
                                    shouldUploadEvent:YES];

    if ([self.eventSet containsObject:event]) {
        [_eventSet removeObject:event];
    }

    completionHandler(event, MPExecStatusSuccess);
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
        [self.assembly.eventLogger beginSessionForEventAtDate:event.timestamp];
    }
    if ([event isKindOfClass:[MPEvent class]] || [event isKindOfClass:[MPCommerceEvent class]]) {
        [self.assembly.eventLogger saveEventMessageOfType:event.messageType
                                              messageInfo:[event dictionaryRepresentation]
                                                timestamp:event.timestamp
                                        shouldUploadEvent:event.shouldUploadEvent];
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
    [self.assembly.messageLogger logNetworkPerformanceMeasurement:networkPerformance completionHandler:completionHandler];
}

- (void)logScreen:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    event.messageType = MPMessageTypeScreenView;
    [event endTiming];
    if (event.type != MPEventTypeNavigation) {
        event.type = MPEventTypeNavigation;
    }

    [self.assembly.eventLogger saveEventMessageOfType:event.messageType
                                          messageInfo:[event screenDictionaryRepresentation]
                                            timestamp:event.timestamp
                                    shouldUploadEvent:event.shouldUploadEvent];

    if ([self.eventSet containsObject:event]) {
        [_eventSet removeObject:event];
    }

    completionHandler(event, MPExecStatusSuccess);
}

- (void)setOptOut:(BOOL)optOutStatus completionHandler:(void (^)(BOOL optOut, MPExecStatus execStatus))completionHandler {
    [self.assembly.messageLogger setOptOut:optOutStatus completionHandler:completionHandler];
}

- (MPExecStatus)setSessionAttribute:(MPSession *)session key:(NSString *)key value:(id)value {
    NSAssert(session != nil, @"session cannot be nil.");

    return [self.assembly.sessionAttributeWriter setSessionAttribute:session key:key value:value];
}

- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret networkOptions:(nullable MPNetworkOptions *)networkOptions firstRun:(BOOL)firstRun installationType:(MPInstallationType)installationType startKitsAsync:(BOOL)startKitsAsync consentState:(MPConsentState *)consentState completionHandler:(dispatch_block_t)completionHandler {
    MPConsentState *storedConsentState = [MPPersistenceUtilities consentStateForMpid:[MPPersistenceUtilities mpId]];
    if (consentState != nil && storedConsentState == nil) {
        [MPPersistenceUtilities setConsentState:consentState forMpid:[MPPersistenceUtilities mpId]];
    }

    [self.assembly.startupCoordinator startWithKey:apiKey
                                            secret:secret
                                    networkOptions:networkOptions
                                          firstRun:firstRun
                                  installationType:(MPInstallationTypeSwift)installationType
                                    startKitsAsync:startKitsAsync
                                 completionHandler:completionHandler];
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

- (void)handleDeviceTokenNotification:(NSNotification *)notification {
    [self.assembly.messageLogger handleDeviceTokenNotification:notification];
}

- (void)logUserNotification:(MParticleUserNotification *)userNotification {
    [self.assembly.messageLogger logUserNotification:userNotification];
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

- (dispatch_block_t)singleShotBlock:(dispatch_block_t)block {
    return [MPSearchAdsAttribution singleShotBlock:block];
}

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

#if TARGET_OS_IOS == 1
- (void)requestAttributionDetailsWithBlock:(void (^_Nonnull)(void))completionHandler requestsCompleted:(int)requestsCompleted {
    [self.assembly.searchAdsAttribution requestAttributionDetailsWithCompletion:completionHandler requestsCompleted:requestsCompleted];
}
#endif

@end

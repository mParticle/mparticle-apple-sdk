#import "MPBackendController.h"
#import "MPAppDelegateProxy.h"
#import "MPPersistenceController.h"
#import "MPMessage.h"
#import "MPSession.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "MPNetworkPerformance.h"
#import "MPIUserDefaults.h"
#import "MPBreadcrumb.h"
#import "MPUpload.h"
#import "MPApplication.h"
#import "MPCustomModule.h"
#import "MPMessageBuilder.h"
#import "MPEvent.h"
#import "MParticleUserNotification.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPHasher.h"
#import "MPUploadBuilder.h"
#import "MPILogger.h"
#import "MPResponseEvents.h"
#import "MPConsumerInfo.h"
#import "MPResponseConfig.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPKitContainer.h"
#import "MPUserAttributeChange.h"
#import "MPUserIdentityChange.h"
#import "MPSearchAdsAttribution.h"
#import "MPURLRequestBuilder.h"
#import "MPArchivist.h"
#import "MPListenerController.h"
#import "MParticleWebView.h"
#import "MPDevice.h"

#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
#import "MPLocationManager.h"
#endif
#endif

const NSInteger kNilAttributeValue = 101;
const NSInteger kExceededAttributeCountLimit = 103;
const NSInteger kExceededAttributeValueMaximumLength = 104;
const NSInteger kExceededAttributeKeyMaximumLength = 105;
const NSInteger kInvalidDataType = 106;
const NSInteger kInvalidKey = 107;
const NSTimeInterval kMPMaximumKitWaitTimeSeconds = 5;
const NSTimeInterval kMPMaximumAgentWaitTimeSeconds = 5;

static NSArray *execStatusDescriptions;
static BOOL appBackgrounded = NO;
 
@interface MParticleSession ()

@property (nonatomic, readwrite) NSNumber *startTime;
- (instancetype)initWithUUID:(NSString *)uuid;

@end

@interface MParticle ()

@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *deferredKitConfiguration;
@property (nonatomic, strong) MPPersistenceController *persistenceController;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong) MPKitContainer *kitContainer;
@property (nonatomic, strong) MParticleWebView *webView;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
+ (dispatch_queue_t)messageQueue;
+ (void)executeOnMessage:(void(^)(void))block;

@end

@interface MPBackendController() {
    MPAppDelegateProxy *appDelegateProxy;
    NSMutableSet<NSString *> *deletedUserAttributes;
    NSNotification *didFinishLaunchingNotification;
    NSTimeInterval nextCleanUpTime;
    NSTimeInterval timeAppWentToBackground;
    dispatch_source_t backgroundSource;
    dispatch_source_t uploadSource;
    UIBackgroundTaskIdentifier backendBackgroundTaskIdentifier;
    dispatch_semaphore_t backendSemaphore;
    dispatch_queue_t messageQueue;
    BOOL originalAppDelegateProxied;
    BOOL resignedActive;
    MParticleSession *tempSession;
}

@end


@implementation MPBackendController
@synthesize session = _session;
@synthesize uploadInterval = _uploadInterval;

#if TARGET_OS_IOS == 1
@synthesize notificationController = _notificationController;
#endif

+ (void)initialize {
    if (self == [MPBackendController class]) {
        execStatusDescriptions = @[@"Success", @"Fail", @"Missing Parameter", @"Feature Disabled Remotely", @"Feature Enabled Remotely", @"User Opted Out of Tracking", @"Data Already Being Fetched",
                                   @"Invalid Data Type", @"Data is Being Uploaded", @"Server is Busy", @"Item Not Found", @"Feature is Disabled in Settings", @"There is no network connectivity"];
    }
}

- (instancetype)initWithDelegate:(id<MPBackendControllerDelegate>)delegate {
    self = [super init];
    if (self) {
        messageQueue = [MParticle messageQueue];
        _networkCommunication = [[MPNetworkCommunication alloc] init];
#if TARGET_OS_IOS == 1
        _notificationController = [[MPNotificationController alloc] init];
#endif
        _sessionTimeout = DEFAULT_SESSION_TIMEOUT;
        nextCleanUpTime = [[NSDate date] timeIntervalSince1970];
        backendBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
        _delegate = delegate;
        resignedActive = NO;
        backgroundSource = nil;
        uploadSource = nil;
        originalAppDelegateProxied = NO;
        backendSemaphore = dispatch_semaphore_create(1);
        timeAppWentToBackground = 0;
        
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
        
        [notificationCenter addObserver:self
                               selector:@selector(handleApplicationWillResignActive:)
                                   name:UIApplicationWillResignActiveNotification
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
- (NSMutableSet<MPEvent *> *)eventSet {
    if (_eventSet) {
        return _eventSet;
    }
    
    _eventSet = [[NSMutableSet alloc] initWithCapacity:1];
    return _eventSet;
}

- (MPSession *)session {
    @synchronized (self) {
        return _session;
    }
}

- (void)setSession:(MPSession *)session {
    @synchronized (self) {
        if ([_session isEqual:session]) {
            return;
        }
        [self willChangeValueForKey:@"session"];
        _session = session;
        [self didChangeValueForKey:@"session"];
    }
}

- (NSMutableDictionary<NSString *, id> *)userAttributesForUserId:(NSNumber *)userId {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSMutableDictionary *userAttributes = [[userDefaults mpObjectForKey:kMPUserAttributeKey userId:userId] mutableCopy];
    if (userAttributes) {
        Class NSStringClass = [NSString class];
        for (NSString *key in [userAttributes allKeys]) {
            if ([userAttributes[key] isKindOfClass:NSStringClass]) {
                userAttributes[key] = ![userAttributes[key] isEqualToString:kMPNullUserAttributeString] ? userAttributes[key] : [NSNull null];
            }
        }
        return userAttributes;
    } else {
        return [NSMutableDictionary dictionary];
    }
}

- (NSMutableArray<NSDictionary<NSString *, id> *> *)userIdentitiesForUserId:(NSNumber *)userId {
    
    NSMutableArray *userIdentities = [[NSMutableArray alloc] initWithCapacity:10];
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSArray *userIdentityArray = [userDefaults mpObjectForKey:kMPUserIdentityArrayKey userId:userId];
    if (userIdentityArray) {
        [userIdentities addObjectsFromArray:userIdentityArray];
    }
    
    BOOL (^objectTester)(id, NSUInteger, BOOL *) = ^(id obj, NSUInteger idx, BOOL *stop) {
        NSNumber *currentIdentityType = obj[kMPUserIdentityTypeKey];
        BOOL foundMatch = [currentIdentityType isEqualToNumber:@(MPIdentityIOSAdvertiserId)];
        
        if (foundMatch) {
            *stop = YES;
        }
        
        return foundMatch;
    };
    
    NSUInteger existingEntryIndex = [userIdentities indexOfObjectPassingTest:objectTester];
    NSNumber *currentStatus = [MParticle sharedInstance].stateMachine.attAuthorizationStatus;
    if (existingEntryIndex != NSNotFound && currentStatus != nil && currentStatus.integerValue != MPATTAuthorizationStatusAuthorized) {
        [userIdentities removeObjectAtIndex:existingEntryIndex];
    }

    return userIdentities;
}

#pragma mark Private methods
- (void)beginBackgroundTask {
    __weak MPBackendController *weakSelf = self;
    
    if (backendBackgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        backendBackgroundTaskIdentifier = [[MPApplication sharedUIApplication] beginBackgroundTaskWithExpirationHandler:^{
            [weakSelf backgroundTaskBlock];
        }];
        
        if (MParticle.sharedInstance.automaticSessionTracking) {
            [self beginBackgroundTimer];
        }
        
    }
}

- (void)backgroundTaskBlock {
    MPILogDebug(@"SDK has ended background activity together with the app.");
    
    __strong MPBackendController *strongSelf = self;
    
    if (strongSelf) {
        [strongSelf endBackgroundTimer];
        [strongSelf endBackgroundTask];
    }
    
    [MPStateMachine setRunningInBackground:NO];
    [[MParticle sharedInstance].persistenceController purgeMemory];
}

- (void)confirmEndSessionMessage:(MPSession *)session {
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    MPMessage *message = [persistence fetchSessionEndMessageInSession:session];
    if (!message) {
        NSMutableDictionary *messageInfo = [@{kMPSessionLengthKey:MPMilliseconds(session.foregroundTime), kMPSessionTotalLengthKey:MPMilliseconds(session.length), kMPEventCounterKey:@(session.eventCounter)}
                                            mutableCopy];
        
        NSDictionary *sessionAttributesDictionary = [session.attributesDictionary transformValuesToString];
        if (sessionAttributesDictionary) {
            messageInfo[kMPAttributesKey] = sessionAttributesDictionary;
        }
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeSessionEnd session:session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
        messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
#endif
#endif
        message = [[messageBuilder withTimestamp:session.endTime] build];
        
        [self saveMessage:message updateSession:NO];
        MPILogVerbose(@"Session Ended: %@", session.uuid);
    }
}

- (void)endBackgroundTask {
    if (backendBackgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[MPApplication sharedUIApplication] endBackgroundTask:backendBackgroundTaskIdentifier];
        backendBackgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
}

- (void)broadcastSessionDidBegin:(MPSession *)session {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate sessionDidBegin:session];
    });
    
    __weak MPBackendController *weakSelf = self;
    MParticleSession *mparticleSession = [[MParticleSession alloc] initWithUUID:session.uuid];
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MPBackendController *strongSelf = weakSelf;
        
        if (strongSelf) {
            NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionary];
            if (mparticleSession.sessionID != nil) {
                mutableInfo[mParticleSessionId] = mparticleSession.sessionID;
            }
            if (mparticleSession.UUID) {
                mutableInfo[mParticleSessionUUID] = mparticleSession.UUID;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleSessionDidBeginNotification
                                                                object:strongSelf.delegate
                                                              userInfo:[mutableInfo copy]];
        }
    });
}

- (void)broadcastSessionDidEnd:(MPSession *)session {
    [self.delegate sessionDidEnd:session];
    
    __weak MPBackendController *weakSelf = self;
    MParticleSession *mparticleSession = [[MParticleSession alloc] initWithUUID:session.uuid];
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MPBackendController *strongSelf = weakSelf;
        
        if (strongSelf) {
            NSMutableDictionary *mutableInfo = [NSMutableDictionary dictionary];
            if (mparticleSession.sessionID != nil) {
                mutableInfo[mParticleSessionId] = mparticleSession.sessionID;
            }
            if (mparticleSession.UUID) {
                mutableInfo[mParticleSessionUUID] = mparticleSession.UUID;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleSessionDidEndNotification
                                                                object:strongSelf.delegate
                                                              userInfo:[mutableInfo copy]];
        }
    });
}

- (void)cleanUp {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (nextCleanUpTime < currentTime) {
        MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
        [persistence deleteRecordsOlderThan:(currentTime - NINETY_DAYS)];
        nextCleanUpTime = currentTime + TWENTY_FOUR_HOURS;
    }
}
                   
- (void)logUserAttributeChange:(MPUserAttributeChange *)userAttributeChange {
    if (!userAttributeChange) {
        return;
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeUserAttributeChange
                                                                           session:self.session
                                                               userAttributeChange:userAttributeChange];
    if (userAttributeChange.timestamp) {
        [messageBuilder withTimestamp:[userAttributeChange.timestamp timeIntervalSince1970]];
    }
    
    MPMessage *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:YES];
}

- (void)logUserIdentityChange:(MPUserIdentityChange *)userIdentityChange {
    if (!userIdentityChange) {
        return;
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeUserIdentityChange
                                                                           session:self.session
                                                                userIdentityChange:userIdentityChange];
    if (userIdentityChange.timestamp) {
        [messageBuilder withTimestamp:[userIdentityChange.timestamp timeIntervalSince1970]];
    }
    
    MPMessage *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:YES];
}

- (NSNumber *)previousSessionSuccessfullyClosed {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *previousSessionStateFile = [stateMachineDirectoryPath stringByAppendingPathComponent:kMPPreviousSessionStateFileName];
    NSNumber *previousSessionSuccessfullyClosed = nil;
    if ([fileManager fileExistsAtPath:previousSessionStateFile]) {
        NSDictionary *previousSessionStateDictionary = [NSDictionary dictionaryWithContentsOfFile:previousSessionStateFile];
        previousSessionSuccessfullyClosed = previousSessionStateDictionary[kMPASTPreviousSessionSuccessfullyClosedKey];
    }
    
    if (previousSessionSuccessfullyClosed == nil) {
        previousSessionSuccessfullyClosed = @YES;
    }
    
    return previousSessionSuccessfullyClosed;
}

- (void)setPreviousSessionSuccessfullyClosed:(NSNumber *)previousSessionSuccessfullyClosed {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *previousSessionStateFile = [stateMachineDirectoryPath stringByAppendingPathComponent:kMPPreviousSessionStateFileName];
    NSDictionary *previousSessionStateDictionary = @{kMPASTPreviousSessionSuccessfullyClosedKey:previousSessionSuccessfullyClosed};
    
    if (![fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
        [fileManager createDirectoryAtPath:stateMachineDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    } else if ([fileManager fileExistsAtPath:previousSessionStateFile]) {
        [fileManager removeItemAtPath:previousSessionStateFile error:nil];
    }
    
    [previousSessionStateDictionary writeToFile:previousSessionStateFile atomically:YES];
}

- (void)processDidFinishLaunching:(NSNotification *)notification {
    NSString *astType = kMPASTInitKey;
    NSMutableDictionary *messageInfo = [[NSMutableDictionary alloc] initWithCapacity:3];
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    
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
    
    messageInfo[kMPASTPreviousSessionSuccessfullyClosedKey] = [self previousSessionSuccessfullyClosed];
    
    NSDictionary *userInfo = [notification userInfo];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        NSUserActivity *userActivity = userInfo[UIApplicationLaunchOptionsUserActivityDictionaryKey][@"UIApplicationLaunchOptionsUserActivityKey"];
        
        if (userActivity) {
            stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:userActivity.webpageURL options:nil];
        }
    }
    
    messageInfo[kMPAppStateTransitionType] = astType;
    
    dispatch_async([MParticle messageQueue], ^{
        if (isInstallOrUpgrade && MParticle.sharedInstance.automaticSessionTracking) {
            [self beginSession];
        }
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:self.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
        messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
#endif
#endif
        messageBuilder = [messageBuilder withStateTransition:YES previousSession:nil];
        MPMessage *message = [messageBuilder build];
        
        [self saveMessage:message updateSession:YES];
    });
    
    [MPApplication updateStoredVersionAndBuildNumbers];

    didFinishLaunchingNotification = nil;
    
    MPILogVerbose(@"Application Did Finish Launching");
}

- (void)processOpenSessionsEndingCurrent:(BOOL)endCurrentSession completionHandler:(void (^)(void))completionHandler {
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    NSMutableArray<MPSession *> *sessions = [persistence fetchSessions];
    if (endCurrentSession) {
        MPILogVerbose(@"Session Ending: %@", _session.uuid);
        _session = nil;
        [MParticle sharedInstance].stateMachine.currentSession = nil;
        if (self.eventSet.count == 0) {
            self.eventSet = nil;
        }
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sessionId == %ld", self.session.sessionId];
        MPSession *currentSession = [[sessions filteredArrayUsingPredicate:predicate] lastObject];
        [sessions removeObject:currentSession];
    }
    
    for (MPSession *openSession in sessions) {
        [self broadcastSessionDidEnd:openSession];
    }
    
    [self uploadOpenSessions:sessions completionHandler:completionHandler];
}

- (void)processPendingArchivedMessages {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *crashLogsDirectoryPath = CRASH_LOGS_DIRECTORY_PATH;
    NSString *archivedMessagesDirectoryPath = ARCHIVED_MESSAGES_DIRECTORY_PATH;
    NSArray *directoryPaths = @[crashLogsDirectoryPath, archivedMessagesDirectoryPath];
    NSArray *fileExtensions = @[@".log", @".arcmsg"];
    
    [directoryPaths enumerateObjectsUsingBlock:^(NSString *directoryPath, NSUInteger idx, BOOL *stop) {
        if (![fileManager fileExistsAtPath:directoryPath]) {
            return;
        }
        
        NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:directoryPath error:nil];
        NSString *predicateFormat = [NSString stringWithFormat:@"self ENDSWITH '%@'", fileExtensions[idx]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
        directoryContents = [directoryContents filteredArrayUsingPredicate:predicate];
        
        for (NSString *fileName in directoryContents) {
            NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
            @try {
                MPMessage *message = [MPArchivist unarchiveObjectOfClass:[MPMessage class] withFile:filePath error:nil];

                if (message) {
                    [self saveMessage:message updateSession:NO];
                }
            } @catch (NSException* ex) {
                MPILogError(@"Failed To retrieve crash messages from archive: %@", ex);
            } @finally {
                [fileManager removeItemAtPath:filePath error:nil];
            }
        }
    }];
}

- (void)proxyOriginalAppDelegate {
    if (originalAppDelegateProxied && !appDelegateProxy) {
        return;
    }
    
    // Add our proxy object to hook calls to the app delegate
    UIApplication *application = [MPApplication sharedUIApplication];
    appDelegateProxy = [[MPAppDelegateProxy alloc] initWithOriginalAppDelegate:application.delegate];
    application.delegate = appDelegateProxy;
    
    originalAppDelegateProxied = YES;
}

/**
NOTE: This static variable is used to retain the app delegate after unproxying. Removing this will cause a crash when calling the MParticle "reset" method.

The reason for this is that when an iOS app is first launched, the app delegate is implicitly retained. However, after we proxy it and call the setter for the UIApplication delegate property, the system no longer "magically" retains the app delegate. Because the property is marked with "assign", setting the original  delegate object back to the UIApplication delegate property will not cause it to be retained again by UIApplication, causing it to be deallocated as soon as our appDelegateProxy object is deallocated as it is the only thing still holding a reference. There is no real downside to doing this as app delegates are meant to live for the life of the application anyway. We're just using this reference in place of the "magic" reference/retain that iOS does when first launching the app.
*/
static id unproxiedAppDelegateReference = nil;

- (void)unproxyOriginalAppDelegate {
    if (!originalAppDelegateProxied && appDelegateProxy) {
        return;
    }
        
    UIApplication *application = [MPApplication sharedUIApplication];
    if (application.delegate != appDelegateProxy) {
        MPILogWarning(@"Tried to unproxy the app delegate, but our proxy is no longer in place, application.delegate: %@", application.delegate);
        return;
    }
    
    // Hold a strong reference to the app delegate to prevent it from being deallocated
    unproxiedAppDelegateReference = appDelegateProxy.originalAppDelegate;
    
    // Return the app delegate to it's original state and remove our proxy object
    application.delegate = appDelegateProxy.originalAppDelegate;
    appDelegateProxy = nil;
    
    originalAppDelegateProxied = NO;
}

- (void)requestConfig:(void(^ _Nullable)(BOOL uploadBatch))completionHandler {
    [self.networkCommunication requestConfig:nil withCompletionHandler:^(BOOL success) {
        if (completionHandler) {
            completionHandler(success);
        }
    }];
}

- (void)setUserAttributeChange:(MPUserAttributeChange *)userAttributeChange completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:userAttributeChange];
    
    if ([MParticle sharedInstance].stateMachine.optOut) {
        if (completionHandler) {
            completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusOptOut);
        }
        
        return;
    }
    
    NSMutableDictionary *userAttributes = [self userAttributesForUserId:[MPPersistenceController mpId]];
    id<NSObject> userAttributeValue = nil;
    NSString *localKey = [userAttributes caseInsensitiveKey:userAttributeChange.key];
    
    NSError *error = nil;
    BOOL success = [MPBackendController checkAttribute:userAttributeChange.userAttributes
                     key:localKey
                   value:userAttributeChange.value
                   error:&error];
    
    if ((!success && error) && error.code == kInvalidDataType) {
        if (completionHandler) {
            completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusInvalidDataType);
        }
        return;
    }
    
    if (userAttributeChange.isArray) {
        userAttributeValue = userAttributeChange.value;
        userAttributeChange.deleted = error.code == kNilAttributeValue && userAttributes[localKey];
    } else {
        userAttributeValue = userAttributeChange.value;
        
        userAttributeChange.deleted = error.code == kNilAttributeValue && userAttributes[localKey];
    }
    
    if (!error) {
        userAttributes[localKey] = userAttributeValue;
    } else if (userAttributeChange.deleted) {
        [userAttributes removeObjectForKey:localKey];
        
        if (!deletedUserAttributes) {
            deletedUserAttributes = [[NSMutableSet alloc] initWithCapacity:1];
        }
        [deletedUserAttributes addObject:userAttributeChange.key];
    } else {
        if (completionHandler) {
            completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusInvalidDataType);
        }
        
        return;
    }
    
    NSMutableDictionary *userAttributesCopy = [[NSMutableDictionary alloc] initWithCapacity:userAttributes.count];
    NSEnumerator *attributeEnumerator = [userAttributes keyEnumerator];
    NSString *aKey;
    
    while ((aKey = [attributeEnumerator nextObject])) {
        if ((NSNull *)userAttributes[aKey] == [NSNull null]) {
            userAttributesCopy[aKey] = kMPNullUserAttributeString;
        } else {
            userAttributesCopy[aKey] = userAttributes[aKey];
        }
    }
    
    if (userAttributeChange.changed) {
        if ([userAttributeValue isKindOfClass:[NSNumber class]]) {
            userAttributeChange.valueToLog = [(NSNumber *)userAttributeValue stringValue];
        } else {
            userAttributeChange.valueToLog = userAttributeValue;
        }
        [self logUserAttributeChange:userAttributeChange];
    }
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    userDefaults[kMPUserAttributeKey] = userAttributesCopy;
    [userDefaults synchronize];
    
    if (completionHandler) {
        completionHandler(userAttributeChange.key, userAttributeChange.value, MPExecStatusSuccess);
    }
}

- (NSArray *)batchMessageArraysFromMessageArray:(NSArray *)messages maxBatchMessages:(NSInteger)maxBatchMessages maxBatchBytes:(NSInteger)maxBatchBytes maxMessageBytes:(NSInteger)maxMessageBytes {
    NSMutableArray *batchMessageArrays = [NSMutableArray array];
    int batchMessageCount = 0;
    int batchByteCount = 0;
    
    NSMutableArray *batchMessages = [NSMutableArray array];
    
    for (int i = 0; i < messages.count; i += 1) {
        MPMessage *message = messages[i];
        
        NSInteger iterationMaxBatchBytes = maxBatchBytes;
        NSInteger iterationMaxMessageBytes = maxMessageBytes;
        bool isCrashReport = [message.messageType isEqualToString:kMPMessageTypeStringCrashReport];
        if(isCrashReport) {
            iterationMaxBatchBytes = MAX_BYTES_PER_BATCH_CRASH;
            iterationMaxMessageBytes = MAX_BYTES_PER_EVENT_CRASH;
        }
        
        if (message.messageData.length > iterationMaxMessageBytes) continue;
        
        if (batchMessageCount + 1 > maxBatchMessages || batchByteCount + message.messageData.length > iterationMaxBatchBytes) {
            
            [batchMessageArrays addObject:[batchMessages copy]];
            
            batchMessages = [NSMutableArray array];
            batchMessageCount = 0;
            batchByteCount = 0;
            
        }
        [batchMessages addObject:message];
        batchMessageCount += 1;
        batchByteCount += message.messageData.length;
    }
    
    if (batchMessages.count > 0) {
        [batchMessageArrays addObject:[batchMessages copy]];
    }
    return [batchMessageArrays copy];
}

static BOOL skipNextUpload = NO;

- (void)skipNextUpload {
    skipNextUpload = YES;
}

- (void)uploadBatchesWithCompletionHandler:(void(^)(BOOL success))completionHandler {
    const void (^completionHandlerCopy)(BOOL) = [completionHandler copy];
    __weak MPBackendController *weakSelf = self;
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    //Fetch all stored messages (1)
    NSDictionary *mpidMessages = [persistence fetchMessagesForUploading];
    if (mpidMessages && mpidMessages.count != 0) {
        [mpidMessages enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull mpid, NSMutableDictionary *  _Nonnull sessionMessages, BOOL * _Nonnull stop) {
            [sessionMessages enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull sessionId, NSMutableDictionary *  _Nonnull dataPlanMessages, BOOL * _Nonnull stop) {
                [dataPlanMessages enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull dataPlanId, NSMutableDictionary *  _Nonnull versionMessages, BOOL * _Nonnull stop) {
                    [versionMessages enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull dataPlanVersion, NSArray *  _Nonnull messages, BOOL * _Nonnull stop) {
                        //In batches broken up by mpid and then sessionID create the Uploads (2)
                        __strong MPBackendController *strongSelf = weakSelf;
                        NSNumber *nullableSessionID = (sessionId.integerValue == -1) ? nil : sessionId;
                        NSString *nullableDataPlanId = [dataPlanId isEqualToString:@"0"] ? nil : dataPlanId;
                        NSNumber *nullableDataPlanVersion = (dataPlanVersion.integerValue == 0) ? nil : dataPlanVersion;
                        
                        //Within a session, within a data plan ID, within a version, we also break up based on limits for messages per batch and (approximately) bytes per batch
                        NSArray *batchMessageArrays = [self batchMessageArraysFromMessageArray:messages maxBatchMessages:MAX_EVENTS_PER_BATCH maxBatchBytes:MAX_BYTES_PER_BATCH maxMessageBytes:MAX_BYTES_PER_EVENT];
                        
                        for (int i = 0; i < batchMessageArrays.count; i += 1) {
                            NSArray *limitedMessages = batchMessageArrays[i];
                            MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithMpid: mpid sessionId:nullableSessionID messages:limitedMessages sessionTimeout:strongSelf.sessionTimeout uploadInterval:strongSelf.uploadInterval dataPlanId:nullableDataPlanId dataPlanVersion:nullableDataPlanVersion];
                            
                            if (!uploadBuilder || !strongSelf) {
                                completionHandlerCopy(YES);
                                return;
                            }
                            
                            [uploadBuilder withUserAttributes:[strongSelf userAttributesForUserId:mpid] deletedUserAttributes:self->deletedUserAttributes];
                            [uploadBuilder withUserIdentities:[strongSelf userIdentitiesForUserId:mpid]];
                            [uploadBuilder build:^(MPUpload *upload) {
                                //Save the Upload to the Database (3)
                                [persistence saveUpload:upload];
                            }];
                        }
                        
                        //Delete all messages associated with the batches (4)
                        [persistence deleteMessages:messages];
                        
                        self->deletedUserAttributes = nil;
                    }];
                }];
            }];
        }];
    }
    
    //Fetch all sessions and delete them if inactive (5)
    [persistence deleteAllSessionsExcept:[MParticle sharedInstance].stateMachine.currentSession];
    
    if (skipNextUpload) {
        skipNextUpload = NO;
        completionHandler(YES);
        return;
    }
    
    // Fetch all Uploads (6)
    NSArray<MPUpload *> *uploads = [persistence fetchUploads];
    
    if (!uploads || uploads.count == 0) {
        completionHandlerCopy(YES);
        return;
    }
    
    if ([MParticle sharedInstance].stateMachine.dataRamped) {
        for (MPUpload *upload in uploads) {
            [persistence deleteUpload:upload];
        }
        
        [persistence deleteNetworkPerformanceMessages];
        return;
    }
    
    //Send all Uploads to the backend (7)
    __strong MPBackendController *strongSelf = weakSelf;
    [strongSelf.networkCommunication upload:uploads completionHandler:^{
        completionHandlerCopy(YES);
    }];
}

- (void)uploadOpenSessions:(NSMutableArray *)openSessions completionHandler:(void (^)(void))completionHandler {
    
    void (^invokeCompletionHandler)(void) = ^(void) {
        [MParticle executeOnMessage:^{
            completionHandler();
        }];
    };
    
    if (!openSessions || openSessions.count == 0) {
        invokeCompletionHandler();
        return;
    }
    
    for (MPSession *originalSession in openSessions) {
        __block MPSession *session = [originalSession copy];
        [self confirmEndSessionMessage:session];
    }
    
    [self waitForKitsAndUploadWithCompletionHandler:^{
        invokeCompletionHandler();
    }];
}

#pragma mark Notification handlers
- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    if (appBackgrounded || [MPStateMachine runningInBackground]) {
        return;
    }
    
    MPILogVerbose(@"Application Did Enter Background");
    
    appBackgrounded = YES;
    [MPStateMachine setRunningInBackground:YES];
    
    timeAppWentToBackground = [[NSDate date] timeIntervalSince1970];
    
    if (![MPStateMachine isAppExtension]) {
        [self beginBackgroundTask];
    }
    
    [self endUploadTimer];
    
    dispatch_async(messageQueue, ^{
        
        [self setPreviousSessionSuccessfullyClosed:@YES];
        [self cleanUp];
        
        NSMutableDictionary *messageInfo = [@{kMPAppStateTransitionType:kMPASTBackgroundKey} mutableCopy];
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:self.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
        if ([MPLocationManager trackingLocation] && ![MParticle sharedInstance].stateMachine.locationManager.backgroundLocationTracking) {
            [[MParticle sharedInstance].stateMachine.locationManager.locationManager stopUpdatingLocation];
        }
        messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
#endif
#endif
        MPMessage *message = [messageBuilder build];
        
        [self.session suspendSession];
        [self saveMessage:message updateSession:YES];
        
        if (![MPStateMachine isAppExtension]) {
                [self waitForKitsAndUploadWithCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!MParticle.sharedInstance.automaticSessionTracking) {
                            [self endBackgroundTask];
                        }
                    });
                }];
        }
    });
}

- (BOOL)shouldEndSession {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval backgroundTime = self->timeAppWentToBackground;
    if (backgroundTime == 0) {
        return NO;
    }
    NSTimeInterval timeInBackground = currentTime - backgroundTime;
    
    return timeInBackground >= self.sessionTimeout;
}

- (void)handleApplicationWillEnterForeground:(NSNotification *)notification {
    [self endBackgroundTimer];
    
    appBackgrounded = NO;
    [MPStateMachine setRunningInBackground:NO];
    resignedActive = NO;
    
    if (![MPStateMachine isAppExtension]) {
        [self endBackgroundTask];
    }
    
    if (MParticle.sharedInstance.automaticSessionTracking) {
        if (self.session != nil && [self shouldEndSession]) {
            self.session.endTime = self->timeAppWentToBackground;
            
            dispatch_async(messageQueue, ^{
                [[MParticle sharedInstance].persistenceController updateSession:self.session];
                [self skipNextUpload];
                [self processOpenSessionsEndingCurrent:YES
                                     completionHandler:^(void) {
                    MPILogDebug(@"SDK has ended background activity.");
                    [self beginSession];
                    [self waitForKitsAndUploadWithCompletionHandler:nil];
                }];
            });
        } else {
            [self beginSession];
        }
    }
    
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    if ([MPLocationManager trackingLocation] && ![MParticle sharedInstance].stateMachine.locationManager.backgroundLocationTracking) {
        [[MParticle sharedInstance].stateMachine.locationManager.locationManager startUpdatingLocation];
    }
#endif
#endif
    
    dispatch_async(messageQueue, ^{
        [self requestConfig:nil];
    });
}

- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification {
    didFinishLaunchingNotification = [notification copy];
}

- (void)handleNetworkPerformanceNotification:(NSNotification *)notification {
    if (!_session) {
        return;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    MPNetworkPerformance *networkPerformance = userInfo[kMPNetworkPerformanceKey];
    
    [self logNetworkPerformanceMeasurement:networkPerformance completionHandler:nil];
}

- (void)handleApplicationDidBecomeActive:(NSNotification *)notification {
    if ([MParticle sharedInstance].stateMachine.optOut) {
        return;
    }
    
    if (resignedActive) {
        resignedActive = NO;
        return;
    }
    [self beginUploadTimer];
    dispatch_async(messageQueue, ^{
        
        BOOL sessionExpired = self->_session == nil;
        if (!sessionExpired) {
            NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
            if (self->timeAppWentToBackground > 0) {
                self->_session.backgroundTime += currentTime - self->timeAppWentToBackground;
            }
            self->timeAppWentToBackground = 0.0;
            self->_session.endTime = currentTime;
            [[MParticle sharedInstance].persistenceController updateSession:self->_session];
        }
        
        if (MParticle.sharedInstance.automaticSessionTracking) {
            [self beginSession];
        }
        
        static NSNumber *previousForegroundTime = nil;
        NSMutableDictionary *messageDictionary = @{kMPAppStateTransitionType:kMPASTForegroundKey}.mutableCopy;
        if (previousForegroundTime != nil) {
            messageDictionary[kMPAppForePreviousForegroundTime] = previousForegroundTime;
        }
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeAppStateTransition session:self.session messageInfo:messageDictionary];
        previousForegroundTime = MPCurrentEpochInMilliseconds;
        messageBuilder = [messageBuilder withStateTransition:sessionExpired previousSession:nil];
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
        messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
#endif
#endif
        MPMessage *message = [messageBuilder build];
        [self saveMessage:message updateSession:YES];
        
        MPILogVerbose(@"Application Did Become Active");
    });
}

- (void)handleApplicationWillResignActive:(NSNotification *)notification {
    resignedActive = YES;
}

#pragma mark Timers
- (void)beginBackgroundTimer {
    __weak MPBackendController *weakSelf = self;
    
    backgroundSource = [self createSourceTimer:(self.sessionTimeout)
                                  eventHandler:^{
        dispatch_async([MParticle messageQueue], ^{
            __strong MPBackendController *strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            
            [strongSelf endBackgroundTimer];
            
            strongSelf.session.endTime = self->timeAppWentToBackground;
            [[MParticle sharedInstance].persistenceController updateSession:strongSelf.session];
            
            [strongSelf processOpenSessionsEndingCurrent:YES
                                       completionHandler:^(void) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MPStateMachine setRunningInBackground:NO];
                    
                    MPILogDebug(@"SDK has ended background activity.");
                    [strongSelf endBackgroundTask];
                });
                
            }];
        });
    } cancelHandler:^{
        dispatch_async([MParticle messageQueue], ^{
            __strong MPBackendController *strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf->backgroundSource = nil;
            }
        });
    }];
}

- (void)beginUploadTimer {
    __weak MPBackendController *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MPBackendController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        if (strongSelf->uploadSource) {
            dispatch_source_cancel(strongSelf->uploadSource);
            strongSelf->uploadSource = nil;
        }
        
        strongSelf->uploadSource = [strongSelf createSourceTimer:strongSelf.uploadInterval
                                                    eventHandler:^{
                                                        dispatch_async([MParticle messageQueue], ^{
                                                            __strong MPBackendController *strongSelf = weakSelf;
                                                            if (!strongSelf) {
                                                                return;
                                                            }
                                                            [strongSelf waitForKitsAndUploadWithCompletionHandler:nil];
                                                        });
                                                        
                                                    } cancelHandler:^{
                                                        
                                                    }];
    });
}

- (dispatch_source_t)createSourceTimer:(uint64_t)interval eventHandler:(dispatch_block_t)eventHandler cancelHandler:(dispatch_block_t)cancelHandler {
    dispatch_source_t sourceTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    
    if (sourceTimer) {
        dispatch_source_set_timer(sourceTimer, dispatch_walltime(NULL, 0), interval * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(sourceTimer, eventHandler);
        dispatch_source_set_cancel_handler(sourceTimer, cancelHandler);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_resume(sourceTimer);
        });
    }
    
    return sourceTimer;
}

- (void)endBackgroundTimer {
    if (backgroundSource) {
        dispatch_source_cancel(backgroundSource);
    }
}

- (void)endUploadTimer {
    if (uploadSource) {
        dispatch_source_cancel(uploadSource);
        uploadSource = nil;
    }
}

#pragma mark Public accessors
- (void)setSessionTimeout:(NSTimeInterval)sessionTimeout {
    if (sessionTimeout == _sessionTimeout) {
        return;
    }
    
    _sessionTimeout = MIN(MAX(sessionTimeout, MINIMUM_SESSION_TIMEOUT), MAXIMUM_SESSION_TIMEOUT);
    MPILogDebug(@"Set Session Timeout: %.0f", _sessionTimeout);
}

- (NSTimeInterval)uploadInterval {
    if (_uploadInterval == 0.0) {
        _uploadInterval = [MPStateMachine environment] == MPEnvironmentDevelopment ? DEFAULT_DEBUG_UPLOAD_INTERVAL : DEFAULT_UPLOAD_INTERVAL;
    }
    
    // If running in an extension our processor time is extremely limited
    if ([[[NSBundle mainBundle] executablePath] containsString:@".appex/"]) {
        _uploadInterval = 1.0;
    }
    return _uploadInterval;
}

- (void)setUploadInterval:(NSTimeInterval)uploadInterval {
    if (uploadInterval == _uploadInterval) {
        return;
    }
    
    _uploadInterval = MAX(uploadInterval, 1.0);
    
#if TARGET_OS_TV == 1
    _uploadInterval = MIN(_uploadInterval, DEFAULT_UPLOAD_INTERVAL);
#endif
    
    if (uploadSource) {
        [self beginUploadTimer];
    }
}

- (void)createTempSession {
    tempSession = [[MParticleSession alloc] initWithUUID:[NSUUID UUID].UUIDString];
    
    MPSession *mpSession = [[MPSession alloc] init];
    mpSession.uuid = tempSession.UUID;
    
    tempSession.startTime = MPMilliseconds(mpSession.startTime);
    
    [self broadcastSessionDidBegin:mpSession];
    
    MPILogVerbose(@"New Session Has Begun: %@", tempSession.UUID);
}

- (MParticleSession *)tempSession {
    return tempSession;
}

#pragma mark Public methods
- (void)beginSession {
    NSDate *date = [NSDate date];
    [MParticle executeOnMessage:^{
        [self beginSessionWithIsManual:NO date:date];
    }];
}

- (void)endSession {
    [MParticle executeOnMessage:^{
        [self endSessionWithIsManual:NO];
    }];
}

- (void)beginSessionWithIsManual:(BOOL)isManual date:(NSDate *)date {
    if (!isManual && !MParticle.sharedInstance.automaticSessionTracking) {
        return;
    }
    
    @synchronized (self) {
        if (_session != nil || [MParticle sharedInstance].stateMachine.optOut) {
            return;
        }
        
        MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
        MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
        
        NSNumber *mpId = [MPPersistenceController mpId];
        date = date ?: [NSDate date];
        if (tempSession) {
            self.session = [[MPSession alloc] initWithStartTime:[date timeIntervalSince1970] userId:mpId uuid:tempSession.UUID];
        } else {
            self.session = [[MPSession alloc] initWithStartTime:[date timeIntervalSince1970] userId:mpId];
        }
        
        // Set the app and device info dicts if they weren't already created
        if (!_session.appInfo) {
            _session.appInfo = [[[MPApplication alloc] init] dictionaryRepresentation];
        }
        if (!_session.deviceInfo) {
            _session.deviceInfo = [[[MPDevice alloc] init] dictionaryRepresentationWithMpid:mpId];
        }
        
        [persistence saveSession:_session];
        
        MPSession *previousSession = [persistence fetchPreviousSession];
        NSMutableDictionary *messageInfo = [[NSMutableDictionary alloc] initWithCapacity:2];
        NSInteger previousSessionLength = 0;
        if (previousSession) {
            previousSessionLength = trunc(previousSession.length);
            messageInfo[kMPPreviousSessionIdKey] = previousSession.uuid;
            messageInfo[kMPPreviousSessionStartKey] = MPMilliseconds(previousSession.startTime);
        }
        
        messageInfo[kMPPreviousSessionLengthKey] = @(previousSessionLength);
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeSessionStart session:_session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
        messageBuilder = [messageBuilder withLocation:stateMachine.location];
#endif
#endif
        MPMessage *message = [[messageBuilder withTimestamp:_session.startTime] build];
        
        [self saveMessage:message updateSession:YES];
        
        stateMachine.currentSession = _session;
        
        if (tempSession) {
            tempSession = nil;
        } else {
            [self broadcastSessionDidBegin:self->_session];
            
            MPILogVerbose(@"New Session Has Begun: %@", _session.uuid);
        }
    }
}

- (void)endSessionWithIsManual:(BOOL)isManual {
    if (!isManual && !MParticle.sharedInstance.automaticSessionTracking) {
        return;
    }
    
    @synchronized (self) {
        if ((_session == nil && tempSession == nil) || [MParticle sharedInstance].stateMachine.optOut) {
            return;
        }
        if (_session == nil && tempSession != nil) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), messageQueue, ^{
                [self endSessionWithIsManual:isManual];
            });
            return;
        }
        
        MPSession *sessionToEnd = [_session copy];
        [self confirmEndSessionMessage:sessionToEnd];
        
        [[MParticle sharedInstance].persistenceController archiveSession:sessionToEnd];
        [self broadcastSessionDidEnd:sessionToEnd];
        _session = nil;
        [MParticle sharedInstance].stateMachine.currentSession = nil;
        MPILogVerbose(@"Session Ended: %@", sessionToEnd.uuid);
    }
}

- (void)beginTimedEvent:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    [event beginTiming];
    [self.eventSet addObject:event];
    completionHandler(event, MPExecStatusSuccess);
}

+ (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value error:(out NSError *__autoreleasing *)error  {
    static NSString *attributeValidationErrorDomain = @"Attribute Validation";
    if (attributesDictionary.count >= LIMIT_ATTR_COUNT) {
        if (error) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededAttributeCountLimit userInfo:nil];
        }
        MPILogError(@"Error while setting attribute: there are more attributes than the maximum number allowed.");
        return NO;
    }
    
    if (MPIsNull(key)) {
        if (error) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kInvalidKey userInfo:nil];
        }
        MPILogError(@"Error while setting attribute key: the key parameter cannot be nil");
        return NO;
    }
    
    if (key.length > LIMIT_ATTR_KEY_LENGTH) {
        if (error) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededAttributeKeyMaximumLength userInfo:nil];
        }
        MPILogError(@"Error while setting attribute key: the key parameter is longer than the maximum allowed length.");
        return NO;
    }
    
    if (!value) {
        //don't log an error here, as this may just be treated as a removal.
        if (error) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kNilAttributeValue userInfo:nil];
        }
        return NO;
    }
    
    BOOL isStringValue = [value isKindOfClass:[NSString class]];
    BOOL isArrayValue = [value isKindOfClass:[NSArray class]];
    BOOL isNumberValue = [value isKindOfClass:[NSNumber class]];
    BOOL isNSNullValue = [value isKindOfClass:[NSNull class]];
    
    if (!isStringValue && !isArrayValue && !isNumberValue && !isNSNullValue) {
        if (error) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kInvalidDataType userInfo:nil];
        }
        MPILogError(@"Error while setting attribute value: must be an NSString or NSArray");
        return NO;
    }
    
    if (isStringValue) {
        if (((NSString *)value).length > LIMIT_ATTR_VALUE_LENGTH) {
            if (error) {
                *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededAttributeValueMaximumLength userInfo:nil];
            }
            MPILogError(@"Error while setting attribute value: value is longer than the maximum allowed %@", value);
            return NO;
        }
    }
    
    if (isArrayValue) {
        Class stringClass = [NSString class];
        NSArray *values = (NSArray *)value;
        NSInteger totalValueLength = 0;
        for (id entryValue in values) {
            if (![entryValue isKindOfClass:stringClass]) {
                if (error) {
                    *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kInvalidDataType userInfo:nil];
                }
                MPILogError(@"Error while setting attribute value list: all user attribute entries in the array must be of type string. Error entry: %@", entryValue);
                return NO;
            }
            totalValueLength += ((NSString *)entryValue).length;
        }
        if (totalValueLength > LIMIT_ATTR_VALUE_LENGTH) {
            if (error) {
                *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededAttributeValueMaximumLength userInfo:nil];
            }
            MPILogError(@"Error while setting attribute value list: combined length of list values longer than the maximum alowed.");
            return NO;
        }
    }
    
    return YES;
}

- (MPEvent *)eventWithName:(NSString *)eventName {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", eventName];
    MPEvent *event = [[self.eventSet filteredSetUsingPredicate:predicate] anyObject];
    
    return event;
}

- (NSString *)execStatusDescription:(MPExecStatus)execStatus {
    if (execStatus >= execStatusDescriptions.count) {
        return nil;
    }
    
    NSString *description = execStatusDescriptions[execStatus];
    return description;
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
    
    NSDecimalNumber *incrementValue = [[NSDecimalNumber alloc] initWithString:[value stringValue]];
    NSDecimalNumber *newValue = [[NSDecimalNumber alloc] initWithString:[(NSNumber *)currentValue stringValue]];
    newValue = [newValue decimalNumberByAdding:incrementValue];
    
    session.attributesDictionary[localKey] = newValue;
    
    dispatch_async(messageQueue, ^{
        [[MParticle sharedInstance].persistenceController updateSession:session];
    });
    
    return (NSNumber *)newValue;
}

- (NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    [MPListenerController.sharedInstance onAPICalled:_cmd  parameter1:key parameter2:value];
    
    NSAssert([key isKindOfClass:[NSString class]], @"'key' must be a string.");
    NSAssert([value isKindOfClass:[NSNumber class]], @"'value' must be a number.");
    
    NSDate *timestamp = [NSDate date];
    NSString *localKey = [[self userAttributesForUserId:[MPPersistenceController mpId]] caseInsensitiveKey:key];
    if (!localKey) {
        [self setUserAttribute:key value:value timestamp:timestamp completionHandler:nil];
        return value;
    }
    
    id currentValue = [self userAttributesForUserId:[MPPersistenceController mpId]][localKey];
    if (currentValue && ![currentValue isKindOfClass:[NSNumber class]]) {
        return nil;
    } else if (MPIsNull(currentValue)) {
        currentValue = @0;
    }
    
    NSDecimalNumber *incrementValue = [[NSDecimalNumber alloc] initWithString:[value stringValue]];
    NSDecimalNumber *newValue = [[NSDecimalNumber alloc] initWithString:[(NSNumber *)currentValue stringValue]];
    newValue = [newValue decimalNumberByAdding:incrementValue];
    
    NSMutableDictionary *userAttributes = [self userAttributesForUserId:[MPPersistenceController mpId]];
    userAttributes[localKey] = newValue;
    
    NSMutableDictionary *userAttributesCopy = [[NSMutableDictionary alloc] initWithCapacity:userAttributes.count];
    NSEnumerator *attributeEnumerator = [userAttributes keyEnumerator];
    NSString *aKey;
    
    while ((aKey = [attributeEnumerator nextObject])) {
        if ((NSNull *)userAttributes[aKey] == [NSNull null]) {
            userAttributesCopy[aKey] = kMPNullUserAttributeString;
        } else {
            userAttributesCopy[aKey] = userAttributes[aKey];
        }
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[[self userAttributesForUserId:[MPPersistenceController mpId]] copy] key:key value:newValue];
    userAttributeChange.timestamp = timestamp;
    [self setUserAttributeChange:userAttributeChange completionHandler:nil];
 
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    userDefaults[kMPUserAttributeKey] = userAttributesCopy;
    [userDefaults synchronize];
    
    return (NSNumber *)newValue;
}

- (void)leaveBreadcrumb:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd  parameter1:event];
    
    event.messageType = MPMessageTypeBreadcrumb;
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSDictionary *messageInfo = [event breadcrumbDictionaryRepresentation];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:event.messageType session:self.session messageInfo:messageInfo];
    if (event.timestamp) {
        [messageBuilder withTimestamp:[event.timestamp timeIntervalSince1970]];
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
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:message parameter2:exception parameter3:topmostContext parameter4:eventInfo];
    
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
        
        NSArray<MPBreadcrumb *> *fetchedbreadcrumbs = [[MParticle sharedInstance].persistenceController fetchBreadcrumbs];
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
    
    NSDictionary *appImageInfo = [MPApplication appImageInfo];
    if (appImageInfo) {
        [messageInfo addEntriesFromDictionary:appImageInfo];
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeCrashReport session:self.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
#endif
#endif
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
    
    NSData* data = [plCrashReport dataUsingEncoding:NSUTF8StringEncoding];
    NSNumber *maxPLCrashBytesNumber = [MParticle sharedInstance].stateMachine.crashMaxPLReportLength;
    if (maxPLCrashBytesNumber != nil) {
        NSInteger maxPLCrashBytes = maxPLCrashBytesNumber.integerValue;
        if (data.length > maxPLCrashBytes) {
            NSInteger bytesToTruncate = data.length - maxPLCrashBytes;
            NSInteger bytesRemaining = data.length - bytesToTruncate;
            data = [data subdataWithRange:NSMakeRange(0, bytesRemaining)];
        }
    }
    NSString *plCrashReportBase64 = [data base64EncodedStringWithOptions:0];
    if(plCrashReportBase64) {
        messageInfo[kMPPLCrashReport] = plCrashReportBase64;
    }
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
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
    NSArray<MPSession *> *sessions = [[MParticle sharedInstance].persistenceController fetchPossibleSessionsFromCrash];
    for (MPSession *session in sessions) {
        if (![session isEqual:_session]) {
            crashSession = session;
            break;
        }
    }
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeCrashReport session:crashSession messageInfo:messageInfo];
    MPMessage *crashMessage = [messageBuilder build];
    
    NSInteger maxBytes = [MPPersistenceController maxBytesPerEvent:crashMessage.messageType];
    if(crashMessage.messageData.length > maxBytes) {
        NSInteger bytesToTruncate = crashMessage.messageData.length - maxBytes;
        NSInteger bytesToRetain = plCrashReportBase64.length - bytesToTruncate;
        [crashMessage truncateMessageDataProperty:kMPPLCrashReport toLength:bytesToRetain];
    }
    [persistence saveMessage:crashMessage];
    
    execStatus = MPExecStatusSuccess;
    completionHandler(execMessage, execStatus);
}

- (void)logBaseEvent:(MPBaseEvent *)event completionHandler:(void (^)(MPBaseEvent *event, MPExecStatus execStatus))completionHandler {
    if (![MPStateMachine canWriteMessagesToDB]) {
        MPILogError(@"Not saving message for event to prevent excessive local database growth because API Key appears to be invalid based on server response");
        completionHandler(event, MPExecStatusFail);
        return;
    }
    
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];
    
    if (event.shouldBeginSession) {
        NSDate *date = event.timestamp ?: [NSDate date];
        [self beginSessionWithIsManual:!MParticle.sharedInstance.automaticSessionTracking date:date];
    }
    if ([event isKindOfClass:[MPEvent class]] || [event isKindOfClass:[MPCommerceEvent class]]) {
        NSDictionary<NSString *, id> *messageInfo = [event dictionaryRepresentation];
            
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:event.messageType session:self.session messageInfo:messageInfo];
            if (event.timestamp) {
                [messageBuilder withTimestamp:[event.timestamp timeIntervalSince1970]];
            }
        #if TARGET_OS_IOS == 1
        #ifndef MPARTICLE_LOCATION_DISABLE
            messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
        #endif
        #endif
            MPMessage *message = [messageBuilder build];
            message.shouldUploadEvent = event.shouldUploadEvent;
            
            [self saveMessage:message updateSession:YES];
            
            [self.session incrementCounter];
            
            MPILogDebug(@"Logged event: %@", event.dictionaryRepresentation);
    }
    
    completionHandler(event, MPExecStatusSuccess);
}

- (void)logEvent:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];
    
     event.messageType = MPMessageTypeEvent;

    [self logBaseEvent:event
     completionHandler:^(MPBaseEvent *baseEvent, MPExecStatus execStatus) {
         if ([self.eventSet containsObject:(MPEvent *)baseEvent]) {
             [self->_eventSet removeObject:(MPEvent *)baseEvent];
         }

         completionHandler((MPEvent *)baseEvent, execStatus);
     }];
}

- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent completionHandler:(void (^)(MPCommerceEvent *commerceEvent, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd  parameter1:commerceEvent];
    
    commerceEvent.messageType = MPMessageTypeCommerceEvent;
    
    [self logBaseEvent:commerceEvent
     completionHandler:^(MPBaseEvent *baseEvent, MPExecStatus execStatus) {
         completionHandler((MPCommerceEvent *)baseEvent, execStatus);
     }];
}

- (void)logNetworkPerformanceMeasurement:(MPNetworkPerformance *)networkPerformance completionHandler:(void (^)(MPNetworkPerformance *networkPerformance, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:networkPerformance];
    
    MPExecStatus execStatus = MPExecStatusFail;
    
    NSDictionary *messageInfo = [networkPerformance dictionaryRepresentation];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeNetworkPerformance session:self.session messageInfo:messageInfo];
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
#endif
#endif
    MPMessage *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:YES];
    
    execStatus = MPExecStatusSuccess;
    
    if (completionHandler) {
        completionHandler(networkPerformance, execStatus);
    }
}

- (void)logScreen:(MPEvent *)event completionHandler:(void (^)(MPEvent *event, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:event];
    
    event.messageType = MPMessageTypeScreenView;

    MPExecStatus execStatus = MPExecStatusFail;

    [event endTiming];
    
    if (event.type != MPEventTypeNavigation) {
        event.type = MPEventTypeNavigation;
    }
    
    NSDictionary *messageInfo = [event screenDictionaryRepresentation];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:event.messageType session:self.session messageInfo:messageInfo];
    if (event.timestamp) {
        [messageBuilder withTimestamp:[event.timestamp timeIntervalSince1970]];
    }
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
#endif
#endif
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
    dispatch_async(messageQueue, ^{
        [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:@(optOutStatus)];
        
        MPExecStatus execStatus = MPExecStatusFail;
        
        [MParticle sharedInstance].stateMachine.optOut = optOutStatus;
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeOptOut session:self.session messageInfo:@{kMPOptOutStatus:(optOutStatus ? @"true" : @"false")}];
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
        messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
#endif
#endif
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
    BOOL success = [MPBackendController checkAttribute:session.attributesDictionary
                                    key:localKey
                                  value:value
                                  error:&error];
    if ((!success && error) || [session.attributesDictionary[localKey] isEqual:value]) {
        return MPExecStatusInvalidDataType;
    }
    
    session.attributesDictionary[localKey] = value;
    
    [[MParticle sharedInstance].persistenceController updateSession:session];
    
    return MPExecStatusSuccess;
}

- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret firstRun:(BOOL)firstRun installationType:(MPInstallationType)installationType proxyAppDelegate:(BOOL)proxyAppDelegate startKitsAsync:(BOOL)startKitsAsync consentState:(MPConsentState *)consentState completionHandler:(dispatch_block_t)completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:apiKey parameter2:secret parameter3:@(firstRun) parameter4:consentState];
    
    if (![MPStateMachine isAppExtension]) {
        if (proxyAppDelegate) {
            [self proxyOriginalAppDelegate];
        }
    }
    
    MPConsentState *storedConsentState = [MPPersistenceController consentStateForMpid:[MPPersistenceController mpId]];
    if (consentState != nil && storedConsentState == nil) {
        [MPPersistenceController setConsentState:consentState forMpid:[MPPersistenceController mpId]];
    }
    
    if (![MParticle sharedInstance].stateMachine.optOut) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[MParticle sharedInstance].kitContainer initializeKits];
        });
    }

    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    stateMachine.apiKey = apiKey;
    stateMachine.secret = secret;
    stateMachine.installationType = installationType;
    [MPStateMachine setRunningInBackground:NO];
    
    BOOL shouldBeginSession = !stateMachine.optOut && MParticle.sharedInstance.shouldBeginSession;
    NSDate *date = nil;
    if (shouldBeginSession) {
        [self createTempSession];
        date = [NSDate date];
    }
    
    __weak MPBackendController *weakSelf = self;
    dispatch_async(messageQueue, ^{
        [MParticle sharedInstance].persistenceController = [[MPPersistenceController alloc] init];

        if (shouldBeginSession) {
            [self beginSessionWithIsManual:!MParticle.sharedInstance.automaticSessionTracking date:date];
        }
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeFirstRun session:self.session messageInfo:nil];
        
        __strong MPBackendController *strongSelf = weakSelf;
        
        [strongSelf processOpenSessionsEndingCurrent:NO completionHandler:^(void) {}];
        [strongSelf waitForKitsAndUploadWithCompletionHandler:nil];
        
        [strongSelf beginUploadTimer];
        
        if (firstRun) {
            MPMessage *message = [messageBuilder build];
            message.uploadStatus = MPUploadStatusBatch;
            
            [strongSelf saveMessage:message updateSession:YES];
            
            MPILogDebug(@"Application First Run");
        }
        
        void (^searchAdsCompletion)(void) = ^{
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                [strongSelf processDidFinishLaunching:strongSelf->didFinishLaunchingNotification];
                [strongSelf waitForKitsAndUploadWithCompletionHandler:nil];
            });
        };
        
        if (MParticle.sharedInstance.collectSearchAdsAttribution) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SEARCH_ADS_ATTRIBUTION_GLOBAL_TIMEOUT_SECONDS * NSEC_PER_SEC)), [MParticle messageQueue], searchAdsCompletion);
            [stateMachine.searchAttribution requestAttributionDetailsWithBlock:searchAdsCompletion requestsCompleted:0];
        } else {
            searchAdsCompletion();
        }
        
        [strongSelf processPendingArchivedMessages];
        
        [MPResponseConfig restore];
        [self requestConfig:nil];
        MPILogDebug(@"SDK %@ has started", kMParticleSDKVersion);
        
        completionHandler();
    });
}

- (void)saveMessage:(MPMessage *)message updateSession:(BOOL)updateSession {
    if (![MPStateMachine canWriteMessagesToDB]) {
        MPILogError(@"Not saving message for event to prevent excessive local database growth because API Key appears to be invalid based on server response");
        return;
    }
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    MPMessageType messageTypeCode = [MPMessageBuilder messageTypeForString:message.messageType];
    
    if ([MParticle sharedInstance].stateMachine.optOut && (messageTypeCode != MPMessageTypeOptOut)) {
        return;
    }
    
    [persistence saveMessage:message];
    
    if (messageTypeCode == MPMessageTypeBreadcrumb) {
        [persistence saveBreadcrumb:message];
    }
    
    MPILogVerbose(@"Source Event Id: %@", message.uuid);
    
    MPSession *session = self.session;
    if (updateSession && session) {
        
        session.endTime = message.timestamp != 0 ? message.timestamp : [[NSDate date] timeIntervalSince1970];
        
        if (session.persisted) {
            [persistence updateSession:session];
        } else {
            [persistence saveSession:session];
        }
    }
    
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    BOOL shouldUpload = [stateMachine.triggerMessageTypes containsObject:message.messageType];
    
    if (!shouldUpload && stateMachine.triggerEventTypes) {
        NSError *error = nil;
        NSDictionary *messageDictionary = [message dictionaryRepresentation];
        NSString *eventName = messageDictionary[kMPEventNameKey];
        NSString *eventType = messageDictionary[kMPEventTypeKey];
        
        if (!error && eventName && eventType) {
            NSString *hashedEvent = [NSString stringWithCString:mParticle::Hasher::hashEvent([eventName cStringUsingEncoding:NSUTF8StringEncoding], [eventType cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                                       encoding:NSUTF8StringEncoding];
            
            shouldUpload = [stateMachine.triggerEventTypes containsObject:hashedEvent];
        }
    }
    
    if (shouldUpload) {
        dispatch_async(self->messageQueue, ^{
            [self waitForKitsAndUploadWithCompletionHandler:nil];
        });
    }
}

- (MPExecStatus)waitForKitsAndUploadWithCompletionHandler:(void (^ _Nullable)())completionHandler {
    [self checkForKitsAndUploadWithCompletionHandler:^(BOOL didShortCircuit) {
        if (!didShortCircuit) {
            if (completionHandler) {
                completionHandler();
            }
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), [MParticle messageQueue], ^{
                [self waitForKitsAndUploadWithCompletionHandler:completionHandler];
            });
        }
    }];
    return MPExecStatusSuccess;
}

- (MPExecStatus)checkForKitsAndUploadWithCompletionHandler:(void (^ _Nullable)(BOOL didShortCircuit))completionHandler {
    __weak MPBackendController *weakSelf = self;

    [self requestConfig:^(BOOL uploadBatch) {
        if (!uploadBatch) {
            if (completionHandler) {
                completionHandler(NO);
            }
            
            return;
        }
        __strong MPBackendController *strongSelf = weakSelf;
        MPKitContainer *kitContainer = [MParticle sharedInstance].kitContainer;
        BOOL shouldDelayUploadForKits = kitContainer && [kitContainer shouldDelayUpload:kMPMaximumKitWaitTimeSeconds];
        BOOL shouldDelayUpload = shouldDelayUploadForKits || [MParticle.sharedInstance.webView shouldDelayUpload:kMPMaximumAgentWaitTimeSeconds];
        if (shouldDelayUpload) {
            if (completionHandler) {
                completionHandler(YES);
            }
            
            return;
        }
        
        [strongSelf uploadBatchesWithCompletionHandler:^(BOOL success) {
            if (completionHandler) {
                completionHandler(NO);
            }
        }];
        
    }];
    
    return MPExecStatusSuccess;
}

- (void)setUserTag:(NSString *)key timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:key parameter2:timestamp];
    
    NSString *keyCopy = [key mutableCopy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, nil, MPExecStatusMissingParam);
        }
        
        return;
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[[self userAttributesForUserId:[MPPersistenceController mpId]] copy] key:keyCopy value:[NSNull null]];
    userAttributeChange.timestamp = timestamp;
    [self setUserAttributeChange:userAttributeChange completionHandler:completionHandler];
}

- (void)setUserAttribute:(NSString *)key value:(id)value timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:key parameter2:value parameter3:timestamp];
    
    NSString *keyCopy = [key mutableCopy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, value, MPExecStatusMissingParam);
        }
        
        return;
    }
    
    if (!(([value isKindOfClass:[NSString class]] && ((NSString *)value).length > 0) || [value isKindOfClass:[NSNumber class]]) && value != nil) {
        if (completionHandler) {
            completionHandler(keyCopy, value, MPExecStatusInvalidDataType);
        }
        
        return;
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[[self userAttributesForUserId:[MPPersistenceController mpId]] copy] key:keyCopy value:value];
    userAttributeChange.timestamp = timestamp;
    [self setUserAttributeChange:userAttributeChange completionHandler:completionHandler];
}

- (void)setUserAttribute:(nonnull NSString *)key values:(nullable NSArray<NSString *> *)values timestamp:(NSDate *)timestamp completionHandler:(void (^ _Nullable)(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:key parameter2:values parameter3:timestamp];

    NSString *keyCopy = [key mutableCopy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, values, MPExecStatusMissingParam);
        }
        
        return;
    }
    
    if (!([values isKindOfClass:[NSArray class]] && values.count > 0)) {
        if (completionHandler) {
            completionHandler(keyCopy, values, MPExecStatusInvalidDataType);
        }
        
        return;
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[[self userAttributesForUserId:[MPPersistenceController mpId]] copy] key:keyCopy value:values];
    userAttributeChange.isArray = YES;
    
    
    userAttributeChange.timestamp = timestamp;
    [self setUserAttributeChange:userAttributeChange completionHandler:completionHandler];
}

- (void)removeUserAttribute:(NSString *)key timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *key, id value, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:key parameter2:timestamp];
    
    NSString *keyCopy = [key mutableCopy];
    BOOL validKey = !MPIsNull(keyCopy) && [keyCopy isKindOfClass:[NSString class]];
    if (!validKey) {
        if (completionHandler) {
            completionHandler(keyCopy, nil, MPExecStatusMissingParam);
        }
        
        return;
    }
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:[[self userAttributesForUserId:[MPPersistenceController mpId]] copy] key:keyCopy value:nil];
    userAttributeChange.timestamp = timestamp;
    [self setUserAttributeChange:userAttributeChange completionHandler:completionHandler];
}

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType timestamp:(NSDate *)timestamp completionHandler:(void (^)(NSString *identityString, MPUserIdentity identityType, MPExecStatus execStatus))completionHandler {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:identityString parameter2:@(identityType) parameter3:timestamp];
    
    NSAssert(completionHandler != nil, @"completionHandler cannot be nil.");
    
    MPUserIdentityInstance *userIdentityNew = [[MPUserIdentityInstance alloc] initWithType:identityType
                                                                                     value:identityString];
    
    MPUserIdentityChange *userIdentityChange = [[MPUserIdentityChange alloc] initWithNewUserIdentity:userIdentityNew
                                                                                      userIdentities:[self userIdentitiesForUserId:[MPPersistenceController mpId]]];
    
    userIdentityChange.timestamp = timestamp;
    
    NSNumber *identityTypeNumber = @(userIdentityChange.userIdentityNew.type);
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF[%@] == %@", kMPUserIdentityTypeKey, identityTypeNumber];
    NSDictionary *currentIdentities = [[[self userIdentitiesForUserId:[MPPersistenceController mpId]] filteredArrayUsingPredicate:predicate] lastObject];
    
    BOOL oldIdentityIsValid = currentIdentities && !MPIsNull(currentIdentities[kMPUserIdentityIdKey]);
    BOOL newIdentityIsValid = !MPIsNull(userIdentityChange.userIdentityNew.value);
    
    if (oldIdentityIsValid
        && newIdentityIsValid
        && [currentIdentities[kMPUserIdentityIdKey] isEqualToString:userIdentityChange.userIdentityNew.value]) {
        completionHandler(identityString, identityType, MPExecStatusFail);
        return;
    }
    
    BOOL (^objectTester)(id, NSUInteger, BOOL *) = ^(id obj, NSUInteger idx, BOOL *stop) {
        NSNumber *currentIdentityType = obj[kMPUserIdentityTypeKey];
        BOOL foundMatch = [currentIdentityType isEqualToNumber:identityTypeNumber];
        
        if (foundMatch) {
            *stop = YES;
        }
        
        return foundMatch;
    };
    
    NSMutableDictionary<NSString *, id> *identityDictionary;
    NSUInteger existingEntryIndex;
    BOOL persistUserIdentities = NO;
    
    NSMutableArray *userIdentities = [self userIdentitiesForUserId:[MPPersistenceController mpId]];
    
    if (userIdentityChange.userIdentityNew.value == nil || (NSNull *)userIdentityChange.userIdentityNew.value == [NSNull null] || [userIdentityChange.userIdentityNew.value isEqualToString:@""]) {
        existingEntryIndex = [userIdentities indexOfObjectPassingTest:objectTester];
        
        if (existingEntryIndex != NSNotFound) {
            identityDictionary = [userIdentities[existingEntryIndex] mutableCopy];
            userIdentityChange.userIdentityOld = [[MPUserIdentityInstance alloc] initWithUserIdentityDictionary:identityDictionary];
            userIdentityChange.userIdentityNew = nil;
            
            [userIdentities removeObjectAtIndex:existingEntryIndex];
            persistUserIdentities = YES;
        }
    } else {
        existingEntryIndex = [userIdentities indexOfObjectPassingTest:objectTester];
        
        if (existingEntryIndex == NSNotFound) {
            userIdentityChange.userIdentityNew.dateFirstSet = [NSDate date];
            userIdentityChange.userIdentityNew.isFirstTimeSet = YES;
            
            identityDictionary = [userIdentityChange.userIdentityNew dictionaryRepresentation];
            
            [userIdentities addObject:identityDictionary];
        } else {
            currentIdentities = userIdentities[existingEntryIndex];
            userIdentityChange.userIdentityOld = [[MPUserIdentityInstance alloc] initWithUserIdentityDictionary:currentIdentities];
            
            NSNumber *timeIntervalMilliseconds = currentIdentities[kMPDateUserIdentityWasFirstSet];
            userIdentityChange.userIdentityNew.dateFirstSet = timeIntervalMilliseconds != nil ? [NSDate dateWithTimeIntervalSince1970:([timeIntervalMilliseconds doubleValue] / 1000.0)] : [NSDate date];
            userIdentityChange.userIdentityNew.isFirstTimeSet = NO;
            
            identityDictionary = [userIdentityChange.userIdentityNew dictionaryRepresentation];
            
            [userIdentities replaceObjectAtIndex:existingEntryIndex withObject:identityDictionary];
        }
        
        persistUserIdentities = YES;
    }
    
    if (persistUserIdentities) {
        if (userIdentityChange.changed) {
            [self logUserIdentityChange:userIdentityChange];
            
            MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
            [userDefaults setObject:userIdentities forKeyedSubscript:kMPUserIdentityArrayKey];
            [userDefaults synchronize];
        }
    }
    
    completionHandler(userIdentityChange.userIdentityNew.value, userIdentityChange.userIdentityNew.type, MPExecStatusSuccess);
}

- (void)clearUserAttributes {
    [MPListenerController.sharedInstance onAPICalled:_cmd];
    
    [[MPIUserDefaults standardUserDefaults] removeMPObjectForKey:@"ua"];
    [[MPIUserDefaults standardUserDefaults] synchronize];
}

#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
- (MPExecStatus)beginLocationTrackingWithAccuracy:(CLLocationAccuracy)accuracy distanceFilter:(CLLocationDistance)distance authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest {
    [MPListenerController.sharedInstance onAPICalled:_cmd parameter1:@(accuracy) parameter2:@(distance) parameter3:@(authorizationRequest)];
    
    if ([[MParticle sharedInstance].stateMachine.locationTrackingMode isEqualToString:kMPRemoteConfigForceFalse]) {
        return MPExecStatusDisabledRemotely;
    }
    
    MPLocationManager *locationManager = [[MPLocationManager alloc] initWithAccuracy:accuracy distanceFilter:distance authorizationRequest:authorizationRequest];
    [MParticle sharedInstance].stateMachine.locationManager = locationManager ? : nil;
    
    return MPExecStatusSuccess;
}

- (MPExecStatus)endLocationTracking {
    [MPListenerController.sharedInstance onAPICalled:_cmd];

    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    if ([stateMachine.locationTrackingMode isEqualToString:kMPRemoteConfigForceTrue]) {
        return MPExecStatusEnabledRemotely;
    }
    
    [stateMachine.locationManager endLocationTracking];
    stateMachine.locationManager = nil;
    
    return MPExecStatusSuccess;
}
#endif

- (MPNotificationController *)notificationController {
    return _notificationController;
}

- (void)setNotificationController:(MPNotificationController *)notificationController {
    _notificationController = notificationController;
}

- (void)handleDeviceTokenNotification:(NSNotification *)notification {
    dispatch_async(messageQueue, ^{
        NSDictionary *userInfo = [notification userInfo];
        NSData *deviceToken = userInfo[kMPRemoteNotificationDeviceTokenKey];
        NSData *oldDeviceToken = userInfo[kMPRemoteNotificationOldDeviceTokenKey];
        
        if ((!deviceToken && !oldDeviceToken) || [deviceToken isEqualToData:oldDeviceToken]) {
            return;
        }
        
        NSData *logDeviceToken;
        NSString *status;
        BOOL pushNotificationsEnabled = deviceToken != nil;
        if (pushNotificationsEnabled) {
            logDeviceToken = deviceToken;
            status = @"true";
        } else if (!pushNotificationsEnabled && oldDeviceToken) {
            logDeviceToken = oldDeviceToken;
            status = @"false";
        }
        NSMutableDictionary *messageInfo = [@{kMPPushStatusKey:status}
        mutableCopy];
        
        NSString *tokenString = [MPIUserDefaults stringFromDeviceToken:logDeviceToken];
        if (tokenString) {
            messageInfo[kMPDeviceTokenKey] = tokenString;
        }
        
        if ([MParticle sharedInstance].stateMachine.deviceTokenType.length > 0) {
            messageInfo[kMPDeviceTokenTypeKey] = [MParticle sharedInstance].stateMachine.deviceTokenType;
        }
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypePushRegistration session:self.session messageInfo:messageInfo];
        MPMessage *message = [messageBuilder build];
        
        [self saveMessage:message updateSession:YES];
        
        if (deviceToken) {
            MPILogDebug(@"Set Device Token: %@", [MPIUserDefaults stringFromDeviceToken:deviceToken]);
        } else {
            MPILogDebug(@"Reset Device Token: %@", [MPIUserDefaults stringFromDeviceToken:oldDeviceToken]);
        }
    });
}

- (void)logUserNotification:(MParticleUserNotification *)userNotification {
    NSMutableDictionary *messageInfo = [@{kMPPushNotificationStateKey:userNotification.state,
                                          kMPPushMessageProviderKey:kMPPushMessageProviderValue,
                                          kMPPushMessageTypeKey:userNotification.type}
                                        mutableCopy];
    
    NSString *tokenString = [MPIUserDefaults stringFromDeviceToken:[MPNotificationController deviceToken]];
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
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypePushNotification session:_session messageInfo:messageInfo];
#ifndef MPARTICLE_LOCATION_DISABLE
    messageBuilder = [messageBuilder withLocation:[MParticle sharedInstance].stateMachine.location];
#endif
    MPMessage *message = [messageBuilder build];
    
    [self saveMessage:message updateSession:(_session != nil)];
}

#endif

@end

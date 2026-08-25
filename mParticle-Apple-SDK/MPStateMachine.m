#import "MPStateMachine.h"
#import "MPIConstants.h"
#import "MPApplication.h"
#import "MPNotificationController.h"
#import "MPILogger.h"
#import "MPConsumerInfo.h"
#import "MPPersistenceController.h"
#import "MPKitContainer.h"
#import <UIKit/UIKit.h>
#import "MPDataPlanFilter.h"
#import "MParticleReachability.h"
#import "MPUserDefaultsConnector.h"

#if TARGET_OS_IOS == 1
#import <AdServices/AAAttribution.h>
#endif
@import mParticle_Apple_SDK_Swift;

@interface MParticle ()
+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, readwrite) MPDataPlanOptions *dataPlanOptions;
@property (nonatomic, readwrite) MPDataPlanFilter *dataPlanFilter;
@end

@interface MParticleUser ()
- (void)setIdentity:(NSString *)identityString identityType:(MPIdentity)identityType;
@end

@interface MPStateMachine_PRIVATE () <MPStateMachineMPDeviceProtocol> {
    dispatch_queue_t messageQueue;
}

@property (nonatomic, strong) MPStateMachinePRIVATE *implementation;
@property (nonatomic) MParticleNetworkStatus networkStatus;
@property (nonatomic, strong) MParticleReachability *reachability;
@property (nonatomic) MPUploadStatus uploadStatus;

@end

@implementation MPStateMachine_PRIVATE

@synthesize consumerInfo = _consumerInfo;
@synthesize networkStatus = _networkStatus;

- (instancetype)init {
    self = [super init];
    if (self) {
        messageQueue = [MParticle messageQueue];
        _implementation = [[MPStateMachinePRIVATE alloc] initWithUserDefaults:MPUserDefaultsConnector.userDefaults];
        _uploadStatus = MPUploadStatusBatch;

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.implementation persistStoredSDKVersion:kMParticleSDKVersion];

            [self.reachability startNotifier];
            self.networkStatus = [self.reachability currentReachabilityStatus];

            [notificationCenter addObserver:self
                                   selector:@selector(handleApplicationDidEnterBackground:)
                                       name:UIApplicationDidEnterBackgroundNotification
                                     object:nil];

            [notificationCenter addObserver:self
                                   selector:@selector(handleApplicationWillEnterForeground:)
                                       name:UIApplicationWillEnterForegroundNotification
                                     object:nil];

            [notificationCenter addObserver:self
                                   selector:@selector(handleApplicationWillTerminate:)
                                       name:UIApplicationWillTerminateNotification
                                     object:nil];

            [notificationCenter addObserver:self
                                   selector:@selector(handleReachabilityChanged:)
                                       name:MParticleReachabilityChangedNotification
                                     object:nil];

            [MPApplication_PRIVATE markInitialLaunchTime];
            [MPApplication_PRIVATE updateLaunchCountsAndDates];
        });
    }

    return self;
}

- (void)dealloc {
    if (_reachability != nil) {
        [_reachability stopNotifier];
    }
}

#pragma mark Private accessors
- (MParticleReachability *)reachability {
    if (_reachability) {
        return _reachability;
    }

    [self willChangeValueForKey:@"reachability"];
    _reachability = [MParticleReachability reachabilityForInternetConnection];
    [self didChangeValueForKey:@"reachability"];

    return _reachability;
}

- (MParticleNetworkStatus)networkStatus {
    @synchronized (self) {
        return _networkStatus;
    }
}

- (void)setNetworkStatus:(MParticleNetworkStatus)networkStatus {
    @synchronized (self) {
        _networkStatus = networkStatus;
    }
}

#pragma mark Notification handlers
- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    NSDate *launchDate = self.implementation.launchDate;
    dispatch_async(messageQueue, ^{
        [MPApplication_PRIVATE updateLastUseDate:launchDate];
    });
    self.implementation.backgrounded = YES;
    self.implementation.launchInfo = nil;
}

- (void)handleApplicationWillEnterForeground:(NSNotification *)notification {
    self.implementation.backgrounded = NO;
}

- (void)handleApplicationWillTerminate:(NSNotification *)notification {
    [MPApplication_PRIVATE updateLastUseDate:self.implementation.launchDate];
}

- (void)handleReachabilityChanged:(NSNotification *)notification {
    self.networkStatus = [self.reachability currentReachabilityStatus];
}

- (void)resetRampPercentage {
    if (self.implementation.dataRamped) {
        [self willChangeValueForKey:@"dataRamped"];
        self.implementation.dataRamped = NO;
        [self didChangeValueForKey:@"dataRamped"];
    }
}

- (void)resetTriggers {
    if (self.implementation.triggerEventTypes) {
        [self willChangeValueForKey:@"triggerEventTypes"];
        self.implementation.triggerEventTypes = nil;
        [self didChangeValueForKey:@"triggerEventTypes"];
    }

    if (self.implementation.triggerMessageTypes) {
        [self willChangeValueForKey:@"triggerMessageTypes"];
        self.implementation.triggerMessageTypes = nil;
        [self didChangeValueForKey:@"triggerMessageTypes"];
    }
}

#pragma mark Class methods
+ (MPEnvironment)environment {
    return (MPEnvironment)[MPStateMachinePRIVATE environment];
}

+ (void)setEnvironment:(MPEnvironment)environment {
    [MPStateMachinePRIVATE setEnvironment:(NSUInteger)environment];
}

+ (NSString *)provisioningProfileString {
    return [MPStateMachinePRIVATE provisioningProfileString];
}

+ (BOOL)runningInBackground {
    return [MPStateMachinePRIVATE runningInBackground];
}

+ (void)setRunningInBackground:(BOOL)background {
    [MPStateMachinePRIVATE setRunningInBackground:background];
}

+ (BOOL)isAppExtension {
    return [MPStateMachinePRIVATE isAppExtension];
}

#pragma mark Public accessors
- (NSString *)apiKey {
    @synchronized (self) {
        return self.implementation.apiKey;
    }
}

- (void)setApiKey:(NSString *)apiKey {
    @synchronized (self) {
        self.implementation.apiKey = apiKey;
    }
}

- (NSString *)secret {
    @synchronized (self) {
        return self.implementation.secret;
    }
}

- (void)setSecret:(NSString *)secret {
    @synchronized (self) {
        self.implementation.secret = secret;
    }
}

- (MPConsumerInfo *)consumerInfo {
    if (_consumerInfo) {
        return _consumerInfo;
    }

    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    _consumerInfo = [persistence fetchConsumerInfoForUserId:[MPPersistenceController_PRIVATE mpId]];

    if (!_consumerInfo) {
        _consumerInfo = [[MPConsumerInfo alloc] init];
        [persistence saveConsumerInfo:_consumerInfo];
    }

    return _consumerInfo;
}

- (void)setLogLevel:(MPILogLevel)logLevel {
    @synchronized (self) {
        self.implementation.logLevel = (NSUInteger)logLevel;
    }
}

- (MPILogLevel)logLevel {
    @synchronized (self) {
        return (MPILogLevel)self.implementation.logLevel;
    }
}

- (NSString *)exceptionHandlingMode {
    return self.implementation.exceptionHandlingMode;
}

- (void)setExceptionHandlingMode:(NSString *)exceptionHandlingMode {
    self.implementation.exceptionHandlingMode = exceptionHandlingMode;
}

- (NSNumber *)crashMaxPLReportLength {
    return self.implementation.crashMaxPLReportLength;
}

- (void)setCrashMaxPLReportLength:(NSNumber *)crashMaxPLReportLength {
    self.implementation.crashMaxPLReportLength = crashMaxPLReportLength;
}

- (NSDictionary *)launchOptions {
    return self.implementation.launchOptions;
}

- (void)setLaunchOptions:(NSDictionary *)launchOptions {
    self.implementation.launchOptions = launchOptions;
}

- (NSString *)networkPerformanceMeasuringMode {
    return self.implementation.networkPerformanceMeasuringMode;
}

- (void)setNetworkPerformanceMeasuringMode:(NSString *)networkPerformanceMeasuringMode {
    self.implementation.networkPerformanceMeasuringMode = networkPerformanceMeasuringMode;
}

- (MPLaunchInfo *)launchInfo {
    return self.implementation.launchInfo;
}

- (void)setLaunchInfo:(MPLaunchInfo *)launchInfo {
    self.implementation.launchInfo = launchInfo;
}

- (NSDate *)launchDate {
    return self.implementation.launchDate;
}

- (BOOL)backgrounded {
    return self.implementation.backgrounded;
}

- (BOOL)dataRamped {
    return self.implementation.dataRamped;
}

- (BOOL)automaticSessionTracking {
    return self.implementation.automaticSessionTracking;
}

- (void)setAutomaticSessionTracking:(BOOL)automaticSessionTracking {
    self.implementation.automaticSessionTracking = automaticSessionTracking;
}

- (BOOL)allowASR {
    return self.implementation.allowASR;
}

- (void)setAllowASR:(BOOL)allowASR {
    self.implementation.allowASR = allowASR;
}

- (BOOL)enableAudienceAPI {
    return self.implementation.enableAudienceAPI;
}

- (void)setEnableAudienceAPI:(BOOL)enableAudienceAPI {
    self.implementation.enableAudienceAPI = enableAudienceAPI;
}

- (BOOL)enableIdentityCaching {
    return self.implementation.enableIdentityCaching;
}

- (void)setEnableIdentityCaching:(BOOL)enableIdentityCaching {
    self.implementation.enableIdentityCaching = enableIdentityCaching;
}

- (NSNumber *)aliasMaxWindow {
    return self.implementation.aliasMaxWindow;
}

- (void)setAliasMaxWindow:(NSNumber *)aliasMaxWindow {
    self.implementation.aliasMaxWindow = aliasMaxWindow;
}

- (NSDictionary *)searchAdsInfo {
    return self.implementation.searchAdsInfo;
}

- (void)setSearchAdsInfo:(NSDictionary *)searchAdsInfo {
    self.implementation.searchAdsInfo = searchAdsInfo;
}

- (NSString *)deviceTokenType {
    if (self.implementation.deviceTokenType) {
        return self.implementation.deviceTokenType;
    }

    [self willChangeValueForKey:@"deviceTokenType"];
    self.implementation.deviceTokenType = [MPStateMachinePRIVATE deviceTokenTypeFromProvisioningProfile:[MPStateMachinePRIVATE provisioningProfileString]];
    [self didChangeValueForKey:@"deviceTokenType"];

    return self.implementation.deviceTokenType;
}

- (NSNumber *)firstSeenInstallation {
    NSNumber *firstSeenInstallation = self.implementation.firstSeenInstallation;
    return firstSeenInstallation == nil ? @NO : firstSeenInstallation;
}

- (MPInstallationType)installationType {
    if (self.implementation.installationType != MPInstallationTypeAutodetect) {
        return (MPInstallationType)self.implementation.installationType;
    }

    [self willChangeValueForKey:@"installationType"];

    MPApplication_PRIVATE *application = [[MPApplication_PRIVATE alloc] init];
    if (application.storedVersion || application.storedBuild) {
        if (![application.version isEqualToString:application.storedVersion] || ![application.build isEqualToString:application.storedBuild]) {
            self.implementation.installationType = MPInstallationTypeKnownUpgrade;
        } else {
            self.implementation.installationType = MPInstallationTypeKnownSameVersion;
        }
    } else {
        self.implementation.installationType = MPInstallationTypeKnownInstall;
        self.implementation.firstSeenInstallation = @YES;
    }

    [self didChangeValueForKey:@"installationType"];

    return (MPInstallationType)self.implementation.installationType;
}

- (void)setInstallationType:(MPInstallationType)installationType {
    [self willChangeValueForKey:@"installationType"];
    self.implementation.installationType = installationType;
    [self didChangeValueForKey:@"installationType"];

    self.implementation.firstSeenInstallation = @(installationType == MPInstallationTypeKnownInstall);
}

- (NSDate *)minUploadDateForUploadType:(MPUploadType)uploadType {
    return [self.implementation minUploadDateForUploadType:(NSUInteger)uploadType];
}

- (void)setMinUploadDate:(NSDate *)minUploadDate uploadType:(MPUploadType)uploadType {
    [self.implementation setMinUploadDate:minUploadDate uploadType:(NSUInteger)uploadType];
}

- (BOOL)optOut {
    return [self.implementation optOut];
}

- (void)setOptOut:(BOOL)optOut {
    [self.implementation setOptOut:optOut];
}

- (NSNumber *)attAuthorizationStatus {
    return [self.implementation loadAttAuthorizationStatus];
}

- (NSNumber *)attAuthorizationTimestamp {
    return [self.implementation loadAttAuthorizationTimestamp];
}

- (void)setAttAuthorizationStatus:(NSNumber *)authorizationState {
    BOOL shouldClearAdvertiserId = [self.implementation persistAttAuthorizationStatus:authorizationState];
    if (shouldClearAdvertiserId) {
        NSArray<MParticleUser *> *users = [MParticle sharedInstance].identity.getAllUsers;
        for (MParticleUser *user in users) {
            [user setIdentity:nil identityType:MPIdentityIOSAdvertiserId];
        }
    }
}

- (void)setAttAuthorizationTimestamp:(NSNumber *)timestamp {
    [self.implementation persistAttAuthorizationTimestamp:timestamp];
}

- (NSString *)pushNotificationMode {
    NSString *current = self.implementation.pushNotificationModeValue;
    if (current) {
        return current;
    }

    [self willChangeValueForKey:@"pushNotificationMode"];
    NSString *mode = [self.implementation pushNotificationMode];
    [self didChangeValueForKey:@"pushNotificationMode"];
    return mode;
}

- (void)setPushNotificationMode:(NSString *)pushNotificationMode {
    if ([self.implementation.pushNotificationModeValue isEqualToString:pushNotificationMode]) {
        return;
    }

    [self willChangeValueForKey:@"pushNotificationMode"];
    [self.implementation setPushNotificationMode:pushNotificationMode];
    [self didChangeValueForKey:@"pushNotificationMode"];
}

- (NSDate *)startTime {
    NSDate *startTime = self.implementation.startTime;
    if (startTime) {
        return startTime;
    }

    [self willChangeValueForKey:@"startTime"];
    self.implementation.startTime = [NSDate dateWithTimeIntervalSinceNow:-1];
    [self didChangeValueForKey:@"startTime"];

    return self.implementation.startTime;
}

- (void)setStartTime:(NSDate *)startTime {
    self.implementation.startTime = startTime;
}

- (NSArray *)triggerEventTypes {
    return self.implementation.triggerEventTypes;
}

- (NSArray *)triggerMessageTypes {
    return self.implementation.triggerMessageTypes;
}

#pragma mark Public methods
- (void)configureCustomModules:(NSArray<NSDictionary *> *)customModuleSettings {
    if (MPIsNull(customModuleSettings)) {
        return;
    }

    // MPUserDefaultsConnector declares its MPUserDefaultsConnectorProtocol conformance in a class
    // extension inside its own .m, so it is not visible here. MPNetworkCommunication casts at the
    // call site for the same reason.
    id<MPUserDefaultsConnectorProtocol> connector = (id<MPUserDefaultsConnectorProtocol>)[[MPUserDefaultsConnector alloc] init];
    NSMutableArray<MPCustomModule *> *localCustomModules = [[NSMutableArray alloc] initWithCapacity:customModuleSettings.count];
    MPCustomModule *customModule;
    for (NSDictionary *customModuleDictionary in customModuleSettings) {
        customModule = [[MPCustomModule alloc] initWithDictionary:customModuleDictionary connector:connector];
        if (customModule) {
            [localCustomModules addObject:customModule];
        }
    }

    if (localCustomModules.count == 0) {
        localCustomModules = nil;
    }

    self.customModules = [localCustomModules copy];
}

- (void)configureRampPercentage:(NSNumber *)rampPercentage {
    NSString *deviceIdentifier = nil;
    if (!MPIsNull(rampPercentage) && rampPercentage.integerValue != 0) {
        MParticle *mparticle = MParticle.sharedInstance;
        MPLog *logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
        logger.customLogger = mparticle.customLogger;
        MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
        MPDevice *device = [[MPDevice alloc] initWithStateMachine:mparticle.stateMachine
                                                     userDefaults:(id<MPIdentityApiMPUserDefaultsProtocol>)userDefaults
                                                         identity:(id<MPIdentityApiMPDeviceProtocol>)mparticle.identity
                                                           logger:logger];
        deviceIdentifier = device.deviceIdentifier;
    }

    BOOL dataRamped = [MPStateMachinePRIVATE dataRampedApplyingRampPercentage:rampPercentage deviceIdentifier:deviceIdentifier];
    if (self.implementation.dataRamped != dataRamped) {
        [self willChangeValueForKey:@"dataRamped"];
        self.implementation.dataRamped = dataRamped;
        [self didChangeValueForKey:@"dataRamped"];
    }
}

- (void)configureTriggers:(NSDictionary *)triggerDictionary {
    BOOL applied = [self.implementation applyTriggers:triggerDictionary];
    if (!applied) {
        return;
    }

    [self willChangeValueForKey:@"triggerEventTypes"];
    [self didChangeValueForKey:@"triggerEventTypes"];
    [self willChangeValueForKey:@"triggerMessageTypes"];
    [self didChangeValueForKey:@"triggerMessageTypes"];
}

- (void)configureAliasMaxWindow:(NSNumber *)aliasMaxWindow {
    [self.implementation configureAliasMaxWindow:aliasMaxWindow];
}

- (void)configureDataBlocking:(nullable NSDictionary *)blockSettings {
    if (MPIsNull(blockSettings)) {
        blockSettings = @{};
    }
    if (!MPIsNull(blockSettings[kMPRemoteConfigDataPlanning])) {
        NSDictionary *dataPlanSettings = blockSettings[kMPRemoteConfigDataPlanning];
        NSDictionary *dataBlockSettings = dataPlanSettings[kMPRemoteConfigDataPlanningBlock];

        self.dataPlanOptions = [[MPDataPlanOptions alloc] init];
        self.dataPlanOptions.blockEvents = [dataBlockSettings[kMPRemoteConfigDataPlanningBlockUnplannedEvents] boolValue];
        self.dataPlanOptions.blockEventAttributes = [dataBlockSettings[kMPRemoteConfigDataPlanningBlockUnplannedEventAttributes] boolValue];
        self.dataPlanOptions.blockUserAttributes = [dataBlockSettings[kMPRemoteConfigDataPlanningBlockUnplannedUserAttributes] boolValue];
        self.dataPlanOptions.blockUserIdentities = [dataBlockSettings[kMPRemoteConfigDataPlanningBlockUnplannedIdentities] boolValue];
        self.dataPlanOptions.dataPlan = dataPlanSettings[kMPRemoteConfigDataPlanningDataPlanVersionValue];
        if (MParticle.sharedInstance.dataPlanOptions == nil) {
            MParticle.sharedInstance.dataPlanFilter = [[MPDataPlanFilter alloc] initWithDataPlanOptions:self.dataPlanOptions];
        }
    } else {
        if (MParticle.sharedInstance.dataPlanOptions == nil) {
            MParticle.sharedInstance.dataPlanFilter = nil;
        }
    }
}

- (void)requestAttributionDetailsWithBlock:(void (^_Nonnull)(void))completionHandler requestsCompleted:(int)requestsCompleted {
#if TARGET_OS_IOS == 1
    NSError *error;
    NSString *attributionToken = [AAAttribution attributionTokenWithError:&error];
    if (!attributionToken) {
        completionHandler();
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api-adservices.apple.com/api/v1/"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[attributionToken dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 30;
    sessionConfiguration.timeoutIntervalForResource = 30;
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                             delegate:nil
                                                        delegateQueue:nil];
    dispatch_async([MParticle messageQueue], ^{
        [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *urlResponse, NSError *error) {
            if (error) {
                MPILogError(@"Failed requesting Ads Attribution with error: %@.", [error localizedDescription]);
                if (error.code == 1 /* ADClientErrorLimitAdTracking */) {
                    completionHandler();
                } else if ((requestsCompleted + 1) > SEARCH_ADS_ATTRIBUTION_MAX_RETRIES) {
                    completionHandler();
                } else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SEARCH_ADS_ATTRIBUTION_DELAY_BEFORE_RETRY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self requestAttributionDetailsWithBlock:completionHandler requestsCompleted:(requestsCompleted + 1)];
                    });
                }
            } else {
                NSDictionary *adAttributionDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                self.implementation.searchAdsInfo = [MPStateMachinePRIVATE searchAdsInfoFromAdAttribution:adAttributionDictionary];
                completionHandler();
            }
        }];
    });
#endif
}

@end

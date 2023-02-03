#import "MPStateMachine.h"
#import "MPIUserDefaults.h"
#import "MPIConstants.h"
#import "MPApplication.h"
#import "MPCustomModule.h"
#import "MPDevice.h"
#include <sys/sysctl.h>
#import "MPNotificationController.h"
#import "MPDateFormatter.h"
#import "MPHasher.h"
#import "MPILogger.h"
#import "MPConsumerInfo.h"
#import "MPPersistenceController.h"
#ifndef MPARTICLE_LOCATION_DISABLE
#import "MPLocationManager.h"
#endif
#import "MPKitContainer.h"
#import "MPSearchAdsAttribution.h"
#import <UIKit/UIKit.h>
#import "MPForwardQueueParameters.h"
#import "MPDataPlanFilter.h"

#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    #import <CoreLocation/CoreLocation.h>
#endif
#endif

NSString *const kCookieDateKey = @"e";
NSString *const kMinUploadDateKey = @"MinUploadDate";
NSString *const kMinAliasDateKey = @"MinAliasDate";
NSString *const kMPStateKey = @"state";

static MPEnvironment runningEnvironment = MPEnvironmentAutoDetect;
static BOOL runningInBackground = NO;
static BOOL _canWriteMessagesToDB = YES;

@interface MParticle ()
+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong, readonly) MPPersistenceController *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine *stateMachine;
@property (nonatomic, strong, readonly) MPKitContainer *kitContainer;
@property (nonatomic, readwrite) MPDataPlanOptions *dataPlanOptions;
@property (nonatomic, readwrite) MPDataPlanFilter *dataPlanFilter;

@end

@interface MParticleUser ()
- (void)setIdentity:(NSString *)identityString identityType:(MPIdentity)identityType;

@end

@interface MPStateMachine() {
    BOOL optOutSet;
    dispatch_queue_t messageQueue;
}

@property (nonatomic) MParticleNetworkStatus networkStatus;
@property (nonatomic, strong) NSString *storedSDKVersion;
@property (nonatomic, strong) MParticleReachability *reachability;

@end


@implementation MPStateMachine

@synthesize consumerInfo = _consumerInfo;
@synthesize deviceTokenType = _deviceTokenType;
@synthesize firstSeenInstallation = _firstSeenInstallation;
@synthesize installationType = _installationType;
@synthesize locationTrackingMode = _locationTrackingMode;
@synthesize logLevel = _logLevel;
@synthesize optOut = _optOut;
@synthesize attAuthorizationStatus = _attAuthorizationStatus;
@synthesize attAuthorizationTimestamp = _attAuthorizationTimestamp;
@synthesize pushNotificationMode = _pushNotificationMode;
@synthesize storedSDKVersion = _storedSDKVersion;
@synthesize triggerEventTypes = _triggerEventTypes;
@synthesize triggerMessageTypes = _triggerMessageTypes;
@synthesize automaticSessionTracking = _automaticSessionTracking;
@synthesize allowASR = _allowASR;
@synthesize networkStatus = _networkStatus;

#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
@synthesize location = _location;
#endif
#endif

- (instancetype)init {
    self = [super init];
    if (self) {
        messageQueue = [MParticle messageQueue];
        optOutSet = NO;
        _exceptionHandlingMode = kMPRemoteConfigExceptionHandlingModeAppDefined;
        _crashMaxPLReportLength = nil;
        _networkPerformanceMeasuringMode = kMPRemoteConfigAppDefined;
        _uploadStatus = MPUploadStatusBatch;
        _startTime = [NSDate dateWithTimeIntervalSinceNow:-1];
        _backgrounded = NO;
        _dataRamped = NO;
        _installationType = MPInstallationTypeAutodetect;
        _launchDate = [NSDate date];
        _launchOptions = nil;
        _logLevel = MPILogLevelNone;
        _searchAttribution = [[MPSearchAdsAttribution alloc] init];
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        __weak MPStateMachine *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong MPStateMachine *strongSelf = weakSelf;
            
            strongSelf.storedSDKVersion = kMParticleSDKVersion;
            
            [strongSelf.reachability startNotifier];
            strongSelf.networkStatus = [strongSelf.reachability currentReachabilityStatus];
            
            [notificationCenter addObserver:strongSelf
                                   selector:@selector(handleApplicationDidEnterBackground:)
                                       name:UIApplicationDidEnterBackgroundNotification
                                     object:nil];
            
            [notificationCenter addObserver:strongSelf
                                   selector:@selector(handleApplicationWillEnterForeground:)
                                       name:UIApplicationWillEnterForegroundNotification
                                     object:nil];
            
            [notificationCenter addObserver:strongSelf
                                   selector:@selector(handleApplicationWillTerminate:)
                                       name:UIApplicationWillTerminateNotification
                                     object:nil];
            
            [notificationCenter addObserver:strongSelf
                                   selector:@selector(handleReachabilityChanged:)
                                       name:MParticleReachabilityChangedNotification
                                     object:nil];
            
            [MPApplication markInitialLaunchTime];
            [MPApplication updateLaunchCountsAndDates];
            [MPApplication updateBadgeNumber];
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
    @synchronized(self) {
        return _networkStatus;
    }
}

- (void)setNetworkStatus:(MParticleNetworkStatus)networkStatus {
    @synchronized(self) {
        _networkStatus = networkStatus;
    }
}

- (NSString *)storedSDKVersion {
    if (_storedSDKVersion) {
        return _storedSDKVersion;
    }
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    _storedSDKVersion = userDefaults[@"storedSDKVersion"];
    
    return _storedSDKVersion;
}

- (void)setStoredSDKVersion:(NSString *)storedSDKVersion {
    if (self.storedSDKVersion && storedSDKVersion && [_storedSDKVersion isEqualToString:storedSDKVersion]) {
        return;
    }

    _storedSDKVersion = storedSDKVersion;

    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];

    if (MPIsNull(_storedSDKVersion)) {
        [userDefaults removeMPObjectForKey:@"storedSDKVersion"];
    } else {
        userDefaults[@"storedSDKVersion"] = _storedSDKVersion;
    }
}

#pragma mark Private methods
+ (MPEnvironment)getEnvironment {
    MPEnvironment environment;
    
#if !TARGET_OS_SIMULATOR
    int numberOfBytes = 4;
    int *name = new int[numberOfBytes];
    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID;
    name[3] = getpid();
    
    struct kinfo_proc info;
    size_t infoSize = sizeof(info);
    info.kp_proc.p_flag = 0;
    
    sysctl(name, numberOfBytes, &info, &infoSize, NULL, 0);
    delete[] name;
    BOOL isDebuggerRunning = (info.kp_proc.p_flag & P_TRACED) != 0;
    
    if (isDebuggerRunning) {
        environment = MPEnvironmentDevelopment;
    } else {
        NSString *provisioningProfileString = [MPStateMachine provisioningProfileString];
        environment = provisioningProfileString ? MPEnvironmentDevelopment : MPEnvironmentProduction;
    }
#else
    environment = MPEnvironmentDevelopment;
#endif
    
    return environment;
}

- (void)resetRampPercentage {
    if (_dataRamped) {
        [self willChangeValueForKey:@"dataRamped"];
        _dataRamped = NO;
        [self didChangeValueForKey:@"dataRamped"];
    }
}

- (void)resetTriggers {
    if (_triggerEventTypes) {
        [self willChangeValueForKey:@"triggerEventTypes"];
        _triggerEventTypes = nil;
        [self didChangeValueForKey:@"triggerEventTypes"];
    }
    
    if (_triggerMessageTypes) {
        [self willChangeValueForKey:@"triggerMessageTypes"];
        _triggerMessageTypes = nil;
        [self didChangeValueForKey:@"triggerMessageTypes"];
    }
}

#pragma mark Notification handlers
- (void)handleApplicationDidEnterBackground:(NSNotification *)notification {
    [MPApplication updateLastUseDate:_launchDate];
    _backgrounded = YES;

    __weak MPStateMachine *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MPStateMachine *strongSelf = weakSelf;
        strongSelf.launchInfo = nil;
        [MPApplication updateBadgeNumber];
    });
}

- (void)handleApplicationWillEnterForeground:(NSNotification *)notification {
    __weak MPStateMachine *weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong MPStateMachine *strongSelf = weakSelf;
        strongSelf->_backgrounded = NO;
        [MPApplication updateBadgeNumber];
    });
}

- (void)handleApplicationWillTerminate:(NSNotification *)notification {
    [MPApplication updateLastUseDate:_launchDate];
}

- (void)handleReachabilityChanged:(NSNotification *)notification {
    self.networkStatus = [self.reachability currentReachabilityStatus];
}

#pragma mark Class methods
+ (MPEnvironment)environment {
    @synchronized(self) {
        if (runningEnvironment != MPEnvironmentAutoDetect) {
            return runningEnvironment;
        }
        
        runningEnvironment = [MPStateMachine getEnvironment];
        
        return runningEnvironment;
    }
}

+ (void)setEnvironment:(MPEnvironment)environment {
    @synchronized(self) {
        runningEnvironment = environment;
    }
}

+ (NSString *)provisioningProfileString {
    NSString *provisioningProfilePath = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
    
    if (!provisioningProfilePath) {
        return nil;
    }
    
    NSData *provisioningProfileData = [NSData dataWithContentsOfFile:provisioningProfilePath];
    NSUInteger dataLength = provisioningProfileData.length;
    const char *provisioningProfileBytes = (const char *)[provisioningProfileData bytes];
    NSMutableString *provisioningProfileString = [[NSMutableString alloc] initWithCapacity:provisioningProfileData.length];
    
    for (NSUInteger i = 0; i < dataLength; ++i) {
        [provisioningProfileString appendFormat:@"%c", provisioningProfileBytes[i]];
    }
    
    NSString *singleLineProvisioningProfileString = [[provisioningProfileString componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] componentsJoinedByString:@""];
    
    return singleLineProvisioningProfileString;
}

+ (BOOL)runningInBackground {
    @synchronized(self) {
        return runningInBackground;
    }
}

+ (void)setRunningInBackground:(BOOL)background {
    @synchronized(self) {
        runningInBackground = background;
    }
}

+ (BOOL)isAppExtension {
#if TARGET_OS_IOS == 1
    return [[NSBundle mainBundle].bundlePath hasSuffix:@".appex"];
#else
    return NO;
#endif
}

+ (BOOL)canWriteMessagesToDB {
    @synchronized(self) {
        return _canWriteMessagesToDB;
    }
}

+ (void)setCanWriteMessagesToDB:(BOOL)canWriteMessagesToDB {
    @synchronized(self) {
        _canWriteMessagesToDB = canWriteMessagesToDB;
    }
}

#pragma mark Public accessors
- (MPConsumerInfo *)consumerInfo {
    if (_consumerInfo) {
        return _consumerInfo;
    }
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    _consumerInfo = [persistence fetchConsumerInfoForUserId:[MPPersistenceController mpId]];
    
    if (!_consumerInfo) {
        _consumerInfo = [[MPConsumerInfo alloc] init];
        [persistence saveConsumerInfo:_consumerInfo];
    }

    return _consumerInfo;
}

- (void)setLogLevel:(MPILogLevel)logLevel {
    @synchronized(self) {
        _logLevel = logLevel;
    }
    
}

- (NSString *)deviceTokenType {
    if (_deviceTokenType) {
        return _deviceTokenType;
    }
    
    [self willChangeValueForKey:@"deviceTokenType"];

    _deviceTokenType = @"";
    NSString *provisioningProfileString = [MPStateMachine provisioningProfileString];
    
    if (provisioningProfileString) {
        NSRange range = [provisioningProfileString rangeOfString:@"<key>aps-environment</key><string>production</string>"];
        if (range.location != NSNotFound) {
            _deviceTokenType = kMPDeviceTokenTypeProduction;
        } else {
            range = [provisioningProfileString rangeOfString:@"<key>aps-environment</key><string>development</string>"];
            
            if (range.location != NSNotFound) {
                _deviceTokenType = kMPDeviceTokenTypeDevelopment;
            }
        }
    }

    [self didChangeValueForKey:@"deviceTokenType"];
    
    return _deviceTokenType;
}

- (NSNumber *)firstSeenInstallation {
    if (_firstSeenInstallation != nil) {
        return _firstSeenInstallation;
    }
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSNumber *firstSeenInstallation = userDefaults[kMPAppFirstSeenInstallationKey];
    if (firstSeenInstallation != nil) {
        _firstSeenInstallation = firstSeenInstallation;
    } else {
        [self willChangeValueForKey:@"firstSeenInstallation"];
        _firstSeenInstallation = @YES;
        [self didChangeValueForKey:@"firstSeenInstallation"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            userDefaults[kMPAppFirstSeenInstallationKey] = self->_firstSeenInstallation;
        });
    }
    
    return _firstSeenInstallation;
}

- (void)setFirstSeenInstallation:(NSNumber *)firstSeenInstallation {
    if (_firstSeenInstallation != nil) {
        return;
    }
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSNumber *fsi = userDefaults[kMPAppFirstSeenInstallationKey];
    if (fsi == nil) {
        [self willChangeValueForKey:@"firstSeenInstallation"];
        _firstSeenInstallation = firstSeenInstallation;
        [self didChangeValueForKey:@"firstSeenInstallation"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            userDefaults[kMPAppFirstSeenInstallationKey] = self->_firstSeenInstallation;
        });
    }
}

- (MPInstallationType)installationType {
    if (_installationType != MPInstallationTypeAutodetect) {
        return _installationType;
    }
    
    [self willChangeValueForKey:@"installationType"];

    MPApplication *application = [[MPApplication alloc] init];
    if (application.storedVersion || application.storedBuild) {
        if (![application.version isEqualToString:application.storedVersion] || ![application.build isEqualToString:application.storedBuild]) {
            _installationType = MPInstallationTypeKnownUpgrade;
        } else {
            _installationType = MPInstallationTypeKnownSameVersion;
        }
    } else {
        _installationType = MPInstallationTypeKnownInstall;
    }
    
    [self didChangeValueForKey:@"installationType"];
    
    return _installationType;
}

- (void)setInstallationType:(MPInstallationType)installationType {
    [self willChangeValueForKey:@"installationType"];
    _installationType = installationType;
    [self didChangeValueForKey:@"installationType"];
    
    self.firstSeenInstallation = installationType != MPInstallationTypeKnownUpgrade ? @YES : @NO;
}

#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
- (CLLocation *)location {
    if ([MPLocationManager trackingLocation]) {
        return self.locationManager.location;
    } else {
        return _location;
    }
}

- (void)setLocation:(CLLocation *)location {
    if ([MPLocationManager trackingLocation]) {
        if (self.locationManager) {
            self.locationManager.location = location;
        }
        
        _location = nil;
    } else {
        _location = location;
    }
}
#endif
#endif

- (NSString *)locationTrackingMode {
    if (_locationTrackingMode) {
        return _locationTrackingMode;
    }
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSString *locationTrackingMode = userDefaults[kMPRemoteConfigLocationModeKey];
    
    [self willChangeValueForKey:@"locationTrackingMode"];
    
    if (locationTrackingMode) {
        _locationTrackingMode = locationTrackingMode;
    } else {
        _locationTrackingMode = kMPRemoteConfigAppDefined;
    }
    
    [self didChangeValueForKey:@"locationTrackingMode"];
    
    return _locationTrackingMode;
}

- (void)setLocationTrackingMode:(NSString *)locationTrackingMode {
    if ([_locationTrackingMode isEqualToString:locationTrackingMode]) {
        return;
    }
    
    [self willChangeValueForKey:@"locationTrackingMode"];
    _locationTrackingMode = locationTrackingMode;
    [self didChangeValueForKey:@"locationTrackingMode"];
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    userDefaults[kMPRemoteConfigLocationModeKey] = _locationTrackingMode;
}

- (NSString *)minDefaultsKeyForUploadType:(MPUploadType)uploadType {
    NSString *defaultsKey = nil;
    if (uploadType == MPUploadTypeMessage) {
        defaultsKey = kMinUploadDateKey;
    } else if (uploadType == MPUploadTypeAlias) {
        defaultsKey = kMinAliasDateKey;
    }
    return defaultsKey;
}

- (NSDate *)minUploadDateForUploadType:(MPUploadType)uploadType {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSString *defaultsKey = [self minDefaultsKeyForUploadType:uploadType];
    NSDate *minUploadDate = userDefaults[defaultsKey];
    if (minUploadDate) {
        if ([minUploadDate compare:[NSDate date]] == NSOrderedDescending) {
            return minUploadDate;
        } else {
            return [NSDate distantPast];
        }
    }
    
    return [NSDate distantPast];
}

- (void)setMinUploadDate:(NSDate *)minUploadDate uploadType:(MPUploadType)uploadType {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSString *defaultsKey = [self minDefaultsKeyForUploadType:uploadType];
    if ([minUploadDate compare:[NSDate date]] == NSOrderedDescending) {
        userDefaults[defaultsKey] = minUploadDate;
    } else if (userDefaults[defaultsKey]) {
        [userDefaults removeMPObjectForKey:defaultsKey];
    }
}

- (BOOL)optOut {
    if (optOutSet) {
        return _optOut;
    }
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSNumber *optOutNumber = userDefaults[kMPOptOutStatus];
    if (optOutNumber != nil) {
        _optOut = [optOutNumber boolValue];
    } else {
        _optOut = NO;
        userDefaults[kMPOptOutStatus] = @(_optOut);
    }
    optOutSet = YES;
        
    return _optOut;
}

- (void)setOptOut:(BOOL)optOut {
    _optOut = optOut;
    optOutSet = YES;

    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    userDefaults[kMPOptOutStatus] = @(_optOut);
}

- (NSNumber *)attAuthorizationStatus {
    if (_attAuthorizationStatus  != nil) {
        return _attAuthorizationStatus;
    }

    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSNumber *authorizationState = userDefaults[kMPATT];
    
    if (authorizationState.integerValue >= 0 && authorizationState.integerValue <= 3) {
        _attAuthorizationStatus = authorizationState;
    }
        
    return _attAuthorizationStatus;
}

- (NSNumber *)attAuthorizationTimestamp {
    if (_attAuthorizationTimestamp != nil) {
        return _attAuthorizationTimestamp;
    }

    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSNumber *authorizationStateTimestamp = userDefaults[kMPATTTimestamp];
    
    _attAuthorizationTimestamp = authorizationStateTimestamp;
        
    return _attAuthorizationTimestamp;
}

- (void)setAttAuthorizationStatus:(NSNumber *)authorizationState {
    if (authorizationState.integerValue >= 0 && authorizationState.integerValue <= 3 && (_attAuthorizationStatus == nil || authorizationState.integerValue != _attAuthorizationStatus.integerValue)) {
        _attAuthorizationStatus = authorizationState;
        _attAuthorizationTimestamp = MPCurrentEpochInMilliseconds;
        
        MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
        userDefaults[kMPATT] = _attAuthorizationStatus;
        userDefaults[kMPATTTimestamp] = _attAuthorizationTimestamp;
        
        if (authorizationState.integerValue != MPATTAuthorizationStatusAuthorized) {
            NSArray<MParticleUser *> *users = [MParticle sharedInstance].identity.getAllUsers;
            for (MParticleUser *user in users) {
                [user setIdentity:NULL identityType:MPIdentityIOSAdvertiserId];
            }
        }
    }
}

- (void)setAttAuthorizationTimestamp:(NSNumber *)timestamp {
    if (timestamp.doubleValue != _attAuthorizationTimestamp.doubleValue) {
        _attAuthorizationTimestamp = timestamp;
        
        MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
        userDefaults[kMPATTTimestamp] = _attAuthorizationTimestamp;
    }
}

- (NSString *)pushNotificationMode {
    if (_pushNotificationMode) {
        return _pushNotificationMode;
    }
    
    [self willChangeValueForKey:@"pushNotificationMode"];
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSString *pushNotificationMode = userDefaults[kMPRemoteConfigPushNotificationModeKey];
    if (pushNotificationMode) {
        _pushNotificationMode = pushNotificationMode;
    } else {
        _pushNotificationMode = kMPRemoteConfigAppDefined;
    }
    
    [self didChangeValueForKey:@"pushNotificationMode"];
    
    return _pushNotificationMode;
}

- (void)setPushNotificationMode:(NSString *)pushNotificationMode {
    if ([_pushNotificationMode isEqualToString:pushNotificationMode]) {
        return;
    }
    
    [self willChangeValueForKey:@"pushNotificationMode"];
    _pushNotificationMode = pushNotificationMode;
    [self didChangeValueForKey:@"pushNotificationMode"];
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    userDefaults[kMPRemoteConfigPushNotificationModeKey] = _pushNotificationMode;
}

- (NSDate *)startTime {
    if (_startTime) {
        return _startTime;
    }
    
    [self willChangeValueForKey:@"startTime"];
    _startTime = [NSDate dateWithTimeIntervalSinceNow:-1];
    [self didChangeValueForKey:@"startTime"];
    
    return _startTime;
}

- (NSArray *)triggerEventTypes {
    return _triggerEventTypes;
}

- (NSArray *)triggerMessageTypes {
    return _triggerMessageTypes;
}

#pragma mark Public methods
- (void)configureCustomModules:(NSArray<NSDictionary *> *)customModuleSettings {
    if (MPIsNull(customModuleSettings)) {
        return;
    }
    
    NSMutableArray<MPCustomModule *> *localCustomModules = [[NSMutableArray alloc] initWithCapacity:customModuleSettings.count];
    MPCustomModule *customModule;
    for (NSDictionary *customModuleDictionary in customModuleSettings) {
        customModule = [[MPCustomModule alloc] initWithDictionary:customModuleDictionary];
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
    if (MPIsNull(rampPercentage)) {
        [self resetRampPercentage];
        
        return;
    }
    
    BOOL dataRamped = YES;
    if (rampPercentage.integerValue != 0) {
        MPDevice *device = [[MPDevice alloc] init];
        NSData *rampData = [device.deviceIdentifier dataUsingEncoding:NSUTF8StringEncoding];
        
        uint64_t rampHash = mParticle::Hasher::hashFNV1a((const char *)[rampData bytes], (int)[rampData length]);
        NSUInteger modRampHash = rampHash % 100;
        
        dataRamped = modRampHash > [rampPercentage integerValue];
    }
    
    if (_dataRamped != dataRamped) {
        [self willChangeValueForKey:@"dataRamped"];
        _dataRamped = dataRamped;
        [self didChangeValueForKey:@"dataRamped"];
    }
}

- (void)configureTriggers:(NSDictionary *)triggerDictionary {
    // When configured, triggerMessageTypes will at least have one item: MPMessageTypeCommerceEvent,
    // so if there the received configuration is nil and there are more than 1 trigger configured,
    // then reset the configuration and let commerce event be configured as trigger. Otherwise returns
    if (MPIsNull(triggerDictionary)) {
        if (_triggerMessageTypes.count > 1) {
            [self resetTriggers];
        } else if (_triggerMessageTypes.count == 1) {
            return;
        }
        
        triggerDictionary = nil;
    }
    
    NSArray *eventTypes = triggerDictionary[kMPRemoteConfigTriggerEventsKey];
    if (MPIsNull(eventTypes)) {
        [self willChangeValueForKey:@"triggerEventTypes"];
        _triggerEventTypes = nil;
        [self didChangeValueForKey:@"triggerEventTypes"];
    } else {
        if (![_triggerEventTypes isEqualToArray:eventTypes]) {
            [self willChangeValueForKey:@"triggerEventTypes"];
            _triggerEventTypes = eventTypes;
            [self didChangeValueForKey:@"triggerEventTypes"];
        }
    }
    
    NSString *messageTypeCommerceEventKey = kMPMessageTypeStringCommerceEvent;
    NSMutableArray *messageTypes = [@[messageTypeCommerceEventKey] mutableCopy];
    NSArray *configMessageTypes = triggerDictionary[kMPRemoteConfigTriggerMessageTypesKey];
    
    if (!MPIsNull(configMessageTypes)) {
        [messageTypes addObjectsFromArray:configMessageTypes];
    }
    
    [self willChangeValueForKey:@"triggerMessageTypes"];
    _triggerMessageTypes = (NSArray *)messageTypes;
    [self didChangeValueForKey:@"triggerMessageTypes"];
}

- (void)configureAliasMaxWindow:(NSNumber *)aliasMaxWindow {
    if (MPIsNull(aliasMaxWindow)) {
        aliasMaxWindow = @90;
    }
    self.aliasMaxWindow = aliasMaxWindow;
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

@end

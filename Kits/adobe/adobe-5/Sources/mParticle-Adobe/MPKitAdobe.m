#import "MPKitAdobe.h"
#import "MPIAdobe.h"
#import <os/lock.h>

static NSString *const marketingCloudIdIntegrationAttributeKey = @"mid";
static NSString *const blobIntegrationAttributeKey = @"aamb";
static NSString *const locationHintIntegrationAttributeKey = @"aamlh";
static NSString *const organizationIdConfigurationKey = @"organizationID";
static NSString *const audienceManagerServerConfigurationKey = @"audienceManagerServer";


#pragma mark - MPIAdobeApi
@implementation MPIAdobeApi

@synthesize marketingCloudID;

@end

#pragma mark - MPKitAdobe
@interface MPKitAdobe ()

@property (nonatomic) NSString *organizationId;
@property (nonatomic) MPIAdobe *adobe;
@property (nonatomic) BOOL hasSetMCID;
@property (nonatomic) NSString *pushToken;
@property (nonatomic) NSString *audienceManagerServer;

@end

@interface NSURLSession (SessionProtocol) <SessionProtocol>
@end

@implementation MPKitAdobe

static NSString *_midOverride = nil;
static BOOL _willOverrideMid = NO;
static os_unfair_lock _midOverrideLock = OS_UNFAIR_LOCK_INIT;

// Thread-safe accessors for the file-scope statics above.
// Direct reads/writes of `_midOverride` from multiple threads race on the
// ARC-managed retain/release of the static, which can cause a value that is
// about to be released to be captured into an NSDictionary and later trigger
// a use-after-free when the dictionary is serialized on the mParticle
// message queue.
static NSString * _Nullable MPKitAdobeCopyMidOverride(void) {
    os_unfair_lock_lock(&_midOverrideLock);
    NSString *snapshot = _midOverride;
    os_unfair_lock_unlock(&_midOverrideLock);
    return snapshot;
}

static void MPKitAdobeSetMidOverride(NSString * _Nullable value) {
    NSString *copied = [value copy];
    os_unfair_lock_lock(&_midOverrideLock);
    _midOverride = copied;
    os_unfair_lock_unlock(&_midOverrideLock);
}

static BOOL MPKitAdobeGetWillOverrideMid(void) {
    os_unfair_lock_lock(&_midOverrideLock);
    BOOL value = _willOverrideMid;
    os_unfair_lock_unlock(&_midOverrideLock);
    return value;
}

static void MPKitAdobeSetWillOverrideMid(BOOL value) {
    os_unfair_lock_lock(&_midOverrideLock);
    _willOverrideMid = value;
    os_unfair_lock_unlock(&_midOverrideLock);
}

+ (NSNumber *)kitCode {
    return @124;
}


+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Adobe"
                                                           className:NSStringFromClass(self)];
    [MParticle registerExtension:kitRegister];
}

static __weak MPKitAdobe *_sharedInstance = nil;
+ (void)overrideMarketingCloudId:(NSString *)mid {
    NSString *midSnapshot = [mid copy];
    MPKitAdobeSetMidOverride(midSnapshot);
    if (midSnapshot) {
        [[MParticle sharedInstance] setIntegrationAttributes:@{marketingCloudIdIntegrationAttributeKey: midSnapshot} forKit:[[self class] kitCode]];
    }
    [_sharedInstance performSelectorOnMainThread:@selector(sendNetworkRequest) withObject:nil waitUntilDone:NO];
}

+ (void)willOverrideMarketingCloudId:(BOOL)willOverrideMid {
    MPKitAdobeSetWillOverrideMid(willOverrideMid);
}

#pragma mark MPKitInstanceProtocol methods

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    _sharedInstance = self;
    MPKitExecStatus *execStatus = nil;
    
    _organizationId = [configuration[organizationIdConfigurationKey] copy];
    if (!_organizationId.length) {
        NSLog(@"mParticle -> Adobe config wasn't received yet.");
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }
    _audienceManagerServer = [configuration[audienceManagerServerConfigurationKey] copy];
    
    _configuration = configuration;
    _started       = YES;
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    _adobe         = [[MPIAdobe alloc] initWithSession: session];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self sendNetworkRequest];
        NSDictionary *userInfo = @{ mParticleKitInstanceKey: [[self class] kitCode] };
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
    NSLog(@"mParticle -> Adobe configured");
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (id)providerKitInstance {
    MPIAdobeApi *adobeApi = [[MPIAdobeApi alloc] init];
    adobeApi.marketingCloudID = [self marketingCloudIdFromIntegrationAttributes];
    return adobeApi;
}

- (NSString *)marketingCloudIdFromIntegrationAttributes {
    NSDictionary *dictionary = _kitApi.integrationAttributes;
    return dictionary[marketingCloudIdIntegrationAttributeKey];
}

- (NSString *)advertiserId {
    NSString *advertiserId = nil;
    Class MPIdentifierManager = NSClassFromString(@"ASIdentifierManager");
    
    if (MPIdentifierManager) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString(@"sharedManager");
        id<NSObject> adIdentityManager = [MPIdentifierManager performSelector:selector];
        
        selector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL advertisingTrackingEnabled = (BOOL)[adIdentityManager performSelector:selector];
        if (advertisingTrackingEnabled) {
            selector = NSSelectorFromString(@"advertisingIdentifier");
            advertiserId = [[adIdentityManager performSelector:selector] UUIDString];
        }
#pragma clang diagnostic pop
#pragma clang diagnostic pop
    }
    
    return advertiserId;
}

- (NSString *)pushToken {
    return _pushToken;
}

- (void)sendNetworkRequest {
    NSString *midOverrideSnapshot = MPKitAdobeCopyMidOverride();
    if (MPKitAdobeGetWillOverrideMid() && !midOverrideSnapshot) {
        return;
    }
    
    NSString *marketingCloudId = midOverrideSnapshot;
    if (!marketingCloudId) {
        marketingCloudId = [self marketingCloudIdFromIntegrationAttributes];
        if (!marketingCloudId) {
            marketingCloudId = [_adobe marketingCloudIdFromUserDefaults];
            if (marketingCloudId.length) {
                [[MParticle sharedInstance] setIntegrationAttributes:@{marketingCloudIdIntegrationAttributeKey: marketingCloudId} forKit:[[self class] kitCode]];
                _hasSetMCID = YES;
            }
        }
    }
    
    NSString *advertiserId = [self advertiserId];
    NSString *pushToken = [self pushToken];
    FilteredMParticleUser *user = [self currentUser];
    NSDictionary *userIdentities = user.userIdentities;
    [_adobe sendRequestWithMarketingCloudId:marketingCloudId
                               advertiserId:advertiserId
                                  pushToken:pushToken
                             organizationId:_organizationId
                             userIdentities:userIdentities
                      audienceManagerServer:_audienceManagerServer
                                 completion:^(NSString *marketingCloudId, NSString *locationHint, NSString *blob, NSError *error) {
        if (error) {
            NSLog(@"mParticle -> Adobe kit request failed with error: %@", error);
            return;
        }
        
        NSString *midOverrideForCompletion = MPKitAdobeCopyMidOverride();
        NSMutableDictionary *integrationAttributes = [NSMutableDictionary dictionary];
        if (marketingCloudId.length) {
            [integrationAttributes setObject:(midOverrideForCompletion ?: marketingCloudId) forKey:marketingCloudIdIntegrationAttributeKey];
        }
        if (locationHint.length) {
            [integrationAttributes setObject:locationHint forKey:locationHintIntegrationAttributeKey];
        }
        if (blob.length) {
            [integrationAttributes setObject:blob forKey:blobIntegrationAttributeKey];
        }
        
        if (integrationAttributes.count) {
            [[MParticle sharedInstance] setIntegrationAttributes:integrationAttributes forKit:[[self class] kitCode]];
            self->_hasSetMCID = YES;
        }
    }];
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    _pushToken = [[NSString alloc] initWithData:deviceToken encoding:NSUTF8StringEncoding];
    [self sendNetworkRequest];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    [self sendNetworkRequest];
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)didBecomeActive {
    [self sendNetworkRequest];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAdobe) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (void)didEnterBackground:(NSNotification *)notification {
    [self sendNetworkRequest];
}

- (void)willTerminate:(NSNotification *)notification {
    [self sendNetworkRequest];
}

- (BOOL)shouldDelayMParticleUpload {
    return !_hasSetMCID;
}

- (MPKitAPI *)kitApi {
    if (_kitApi == nil) {
        _kitApi = [[MPKitAPI alloc] init];
    }
    
    return _kitApi;
}

#pragma helper methods

- (FilteredMParticleUser *)currentUser {
    return [[self kitApi] getCurrentUserWithKit:self];
}

@end

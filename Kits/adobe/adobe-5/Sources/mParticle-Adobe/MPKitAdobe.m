#import "MPKitAdobe.h"
#import "MPIAdobe.h"

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
    _midOverride = mid;
    if (mid) {
        [[MParticle sharedInstance] setIntegrationAttributes:@{marketingCloudIdIntegrationAttributeKey: mid} forKit:[[self class] kitCode]];
    }
    [_sharedInstance performSelectorOnMainThread:@selector(sendNetworkRequest) withObject:nil waitUntilDone:NO];
}

+ (void)willOverrideMarketingCloudId:(BOOL)willOverrideMid {
    _willOverrideMid = willOverrideMid;
}

#pragma mark MPKitInstanceProtocol methods

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    _sharedInstance = self;
    MPKitExecStatus *execStatus = nil;
    
    _organizationId = [configuration[organizationIdConfigurationKey] copy];
    if (!_organizationId.length) {
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
    if (_willOverrideMid && !_midOverride) {
        return;
    }
    
    NSString *marketingCloudId = _midOverride;
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
        
        NSMutableDictionary *integrationAttributes = [NSMutableDictionary dictionary];
        if (marketingCloudId.length) {
            [integrationAttributes setObject:(_midOverride ?: marketingCloudId) forKey:marketingCloudIdIntegrationAttributeKey];
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

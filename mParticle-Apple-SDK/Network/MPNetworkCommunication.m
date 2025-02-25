#import "MPNetworkCommunication.h"
#import "MPMessage.h"
#import "MPSession.h"
#import <UIKit/UIKit.h>
#import "MPConnector.h"
#import "MPUpload.h"
#import "MPApplication.h"
#import "MPAudience.h"
#import "MPIConstants.h"
#import "MPURLRequestBuilder.h"
#import "MParticleReachability.h"
#import "MPILogger.h"
#import "MPConsumerInfo.h"
#import "MPPersistenceController.h"
#import "MParticleSwift.h"
#import "MPIdentityApiRequest.h"
#import "mParticle.h"
#import "MPEnums.h"
#import "MPIdentityDTO.h"
#import "MPIConstants.h"
#import "MPAliasResponse.h"
#import "MPURL.h"
#import "MPConnectorFactoryProtocol.h"
#import "MPIdentityCaching.h"
#import "MParticleSwift.h"
#import "MPNetworkCommunication.h"

NSString *const urlFormat = @"%@://%@/%@/%@%@"; // Scheme, URL Host, API Version, API key, path
NSString *const urlFormatOverride = @"%@://%@/%@%@"; // Scheme, URL Host, API key, path

NSString *const audienceFormat = @"%@://%@/%@/%@"; // Scheme, URL Host, API Version, API key, path
NSString *const audienceFormatOverride = @"%@://%@/%@"; // Scheme, URL Host, API key, path

NSString *const identityURLFormat = @"%@://%@/%@/%@"; // Scheme, URL Host, API Version, path
NSString *const identityURLFormatOverride = @"%@://%@/%@"; // Scheme, URL Host, path

NSString *const modifyURLFormat = @"%@://%@/%@/%@/%@"; // Scheme, URL Host, API Version, mpid, path
NSString *const modifyURLFormatOverride = @"%@://%@/%@/%@"; // Scheme, URL Host, mpid, path

NSString *const aliasURLFormat = @"%@://%@/%@/%@/%@/%@"; // Scheme, URL Host, API Version, identity, API key, path
NSString *const aliasURLFormatOverride = @"%@://%@/%@/%@"; // Scheme, URL Host, API key, path

NSString *const kMPConfigVersion = @"v4";
NSString *const kMPConfigURL = @"/config";
NSString *const kMPEventsVersion = @"v2";
NSString *const kMPEventsURL = @"/events";
NSString *const kMPAudienceVersion = @"v1";
NSString *const kMPAudienceURL = @"/audience";
NSString *const kMPIdentityVersion = @"v1";
NSString *const kMPIdentityURL = @"";
NSString *const kMPIdentityKey = @"identity";

NSString *const kMPURLScheme = @"https";
NSString *const kMPURLHostConfig = @"config2.mparticle.com";
NSString *const kMPURLHostEventSubdomain = @"nativesdks";
NSString *const kMPURLHostIdentitySubdomain = @"identity";
NSString *const kMPURLHostEventTrackingSubdomain = @"tracking-nativesdks";
NSString *const kMPURLHostIdentityTrackingSubdomain = @"tracking-identity";

NSString *const kMPIdentityCachingMaxAgeHeader = @"X-MP-Max-Age";

static NSObject<MPConnectorFactoryProtocol> *factory = nil;

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, readonly) MPBackendController_PRIVATE *backendController;

- (void)logKitBatch:(NSString *)batch;

@end

@interface MPIdentityApiRequest ()

- (NSDictionary<NSString *, id> *)dictionaryRepresentation;

@end


@interface MPIdentityHTTPErrorResponse ()

- (instancetype)initWithJsonObject:(nullable NSDictionary *)dictionary httpCode:(NSInteger) httpCode;
- (instancetype)initWithCode:(MPIdentityErrorResponseCode) code message: (NSString *) message error:(NSError *) error;

@end

@interface MPNetworkCommunication_PRIVATE()

@property (nonatomic, strong) NSString *context;
@property (nonatomic) BOOL identifying;

@end

@implementation MPNetworkCommunication_PRIVATE

@synthesize audienceURL = _audienceURL;
@synthesize configURL = _configURL;
@synthesize eventURL = _eventURL;
@synthesize identifyURL = _identifyURL;
@synthesize loginURL = _loginURL;
@synthesize logoutURL = _logoutURL;
@synthesize modifyURL = _modifyURL;
@synthesize aliasURL = _aliasURL;
@synthesize identifying = _identifying;

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.identifying = NO;
    
    return self;
}

#pragma mark Private accessors

- (NSString *)defaultHostWithSubdomain:(NSString *)subdomain apiKey:(NSString *)apiKey enableDirectRouting:(BOOL)enableDirectRouting {
    if (enableDirectRouting) {
        NSArray *splitKey = [apiKey componentsSeparatedByString:@"-"];
        if (splitKey.count <= 1) {
            // Handle case with no prefix, default to US1 (old keys)
            return [NSString stringWithFormat:@"%@.us1.mparticle.com", subdomain];
        }
        return [NSString stringWithFormat:@"%@.%@.mparticle.com", subdomain, splitKey[0]];
    }
    
    // Handle feature flag disabled (old behavior)
    return [NSString stringWithFormat:@"%@.mparticle.com", subdomain];
}

- (NSString *)defaultEventHost {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    if (stateMachine.attAuthorizationStatus.integerValue == MPATTAuthorizationStatusAuthorized) {
        return [self defaultHostWithSubdomain:kMPURLHostEventTrackingSubdomain apiKey:stateMachine.apiKey enableDirectRouting:stateMachine.enableDirectRouting];
    } else {
        return [self defaultHostWithSubdomain:kMPURLHostEventSubdomain apiKey:stateMachine.apiKey enableDirectRouting:stateMachine.enableDirectRouting];
    }
}

- (NSString *)defaultIdentityHost {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    if (stateMachine.attAuthorizationStatus.integerValue == MPATTAuthorizationStatusAuthorized) {
        return [self defaultHostWithSubdomain:kMPURLHostIdentityTrackingSubdomain apiKey:stateMachine.apiKey enableDirectRouting:stateMachine.enableDirectRouting];
    } else {
        return [self defaultHostWithSubdomain:kMPURLHostIdentitySubdomain apiKey:stateMachine.apiKey enableDirectRouting:stateMachine.enableDirectRouting];
    }
}

- (MPURL *)configURL {
    if (_configURL) {
        return _configURL;
    }
    
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    MPApplication_PRIVATE *application = [[MPApplication_PRIVATE alloc] init];
    NSString *configHost = [MParticle sharedInstance].networkOptions.configHost ?: kMPURLHostConfig;
    
    NSString *dataPlanConfigString;
    NSString *dataPlanId = MParticle.sharedInstance.dataPlanId;
    if (dataPlanId != nil) {
        NSNumber *dataPlanVersion = MParticle.sharedInstance.dataPlanVersion;
        if (dataPlanVersion != nil && ([dataPlanVersion intValue] > 1000 || [dataPlanVersion intValue] < 1)) {
            MPILogWarning(@"Data plan version of %i is out of range and will not be used to fetch remote data plan. Version must be between 1 and 1000.", [dataPlanVersion intValue]);
            dataPlanVersion = nil;
        }
        if (dataPlanVersion != nil) {
            dataPlanConfigString = [NSString stringWithFormat:@"&plan_id=%@&plan_version=%@", dataPlanId, dataPlanVersion];
        } else {
            dataPlanConfigString = [NSString stringWithFormat:@"&plan_id=%@", dataPlanId];
        }
    }
    NSString *configURLFormat = [urlFormat stringByAppendingString:@"?av=%@&sv=%@"];
    NSString *urlString = [NSString stringWithFormat:configURLFormat, kMPURLScheme, kMPURLHostConfig, kMPConfigVersion, stateMachine.apiKey, kMPConfigURL, [application.version percentEscape], kMParticleSDKVersion];
    NSURL *defaultURL = [NSURL URLWithString:urlString];

    urlString = [NSString stringWithFormat:configURLFormat, kMPURLScheme, configHost, kMPConfigVersion, stateMachine.apiKey, kMPConfigURL, [application.version percentEscape], kMParticleSDKVersion];
    
    if ([MParticle sharedInstance].networkOptions.overridesConfigSubdirectory) {
        NSString *configURLFormat = [urlFormatOverride stringByAppendingString:@"?av=%@&sv=%@"];
        urlString = [NSString stringWithFormat:configURLFormat, kMPURLScheme, configHost, stateMachine.apiKey, kMPConfigURL, [application.version percentEscape], kMParticleSDKVersion];
    }
    if (dataPlanConfigString) {
        urlString = [NSString stringWithFormat:@"%@%@", urlString, dataPlanConfigString];
    }
    
    NSURL *modifiedURL = [NSURL URLWithString:urlString];
    if (modifiedURL && defaultURL) {
        _configURL = [[MPURL alloc] initWithURL:modifiedURL defaultURL:defaultURL];
    }

    return _configURL;
}

- (MPURL *)eventURLForUpload:(MPUpload *)mpUpload {
    NSString *eventHost;
    if (mpUpload.uploadSettings.eventsTrackingHost && [MParticle sharedInstance].stateMachine.attAuthorizationStatus.integerValue == MPATTAuthorizationStatusAuthorized) {
        eventHost = mpUpload.uploadSettings.eventsTrackingHost;
    } else {
        eventHost = mpUpload.uploadSettings.eventsHost ?: self.defaultEventHost;
    }
    NSString *urlString = [NSString stringWithFormat:urlFormat, kMPURLScheme, self.defaultEventHost, kMPEventsVersion, mpUpload.uploadSettings.apiKey, kMPEventsURL];
    NSURL *defaultURL = [NSURL URLWithString:urlString];
    
    if (mpUpload.uploadSettings.overridesEventsSubdirectory) {
        urlString = [NSString stringWithFormat:urlFormatOverride, kMPURLScheme, eventHost, mpUpload.uploadSettings.apiKey, kMPEventsURL];
    } else {
        urlString = [NSString stringWithFormat:urlFormat, kMPURLScheme, eventHost, kMPEventsVersion, mpUpload.uploadSettings.apiKey, kMPEventsURL];
    }
    
    NSURL *modifiedURL = [NSURL URLWithString:urlString];
    MPURL *eventURL;
    if (modifiedURL && defaultURL) {
        eventURL = [[MPURL alloc] initWithURL:modifiedURL defaultURL:defaultURL];
    }
    return eventURL;
}

- (MPURL *)audienceURL {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSString *eventHost = [MParticle sharedInstance].networkOptions.eventsHost ?: self.defaultEventHost;
    NSString *audienceURLFormat = [audienceFormat stringByAppendingString:@"?mpid=%@"];
    NSString *urlString = [NSString stringWithFormat:audienceURLFormat, kMPURLScheme, self.defaultEventHost, kMPAudienceVersion, stateMachine.apiKey, kMPAudienceURL, [MPPersistenceController_PRIVATE mpId]];
    NSURL *defaultURL = [NSURL URLWithString:urlString];

    if ([MParticle sharedInstance].networkOptions.overridesEventsSubdirectory) {
        audienceURLFormat = [urlFormatOverride stringByAppendingString:@"?mpid=%@"];
        urlString = [NSString stringWithFormat:audienceURLFormat, kMPURLScheme, eventHost, kMPAudienceVersion, stateMachine.apiKey, kMPAudienceURL, [MPPersistenceController_PRIVATE mpId]];
    } else {
        audienceURLFormat = [urlFormat stringByAppendingString:@"?mpid=%@"];
        urlString = [NSString stringWithFormat:audienceURLFormat, kMPURLScheme, eventHost, kMPAudienceVersion, stateMachine.apiKey, kMPAudienceURL, [MPPersistenceController_PRIVATE mpId]];
    }
    
    NSURL *modifiedURL = [NSURL URLWithString:urlString];
    defaultURL.accessibilityHint = @"audience";
    modifiedURL.accessibilityHint = @"audience";
    
    MPURL *audienceURL;
    if (modifiedURL && defaultURL) {
        audienceURL = [[MPURL alloc] initWithURL:modifiedURL defaultURL:defaultURL];
    }
    
    return audienceURL;
}

- (MPURL *)identifyURL {
    if (_identifyURL) {
        return _identifyURL;
    }
    
    _identifyURL = [self identityURL:@"identify"];
    
    return _identifyURL;
}

- (MPURL *)loginURL {
    if (_loginURL) {
        return _loginURL;
    }
    
    _loginURL = [self identityURL:@"login"];
    
    return _loginURL;
}

- (MPURL *)logoutURL {
    if (_logoutURL) {
        return _logoutURL;
    }
    
    _logoutURL = [self identityURL:@"logout"];
    
    return _logoutURL;
}

- (MPURL *)identityURL:(NSString *)pathComponent {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    NSString *identityHost;
    if ([MParticle sharedInstance].networkOptions.identityTrackingHost && stateMachine.attAuthorizationStatus.integerValue == MPATTAuthorizationStatusAuthorized) {
        identityHost = [MParticle sharedInstance].networkOptions.identityTrackingHost;
    } else {
        identityHost = [MParticle sharedInstance].networkOptions.identityHost ?: self.defaultIdentityHost;
    }
    NSString *urlString = [NSString stringWithFormat:identityURLFormat, kMPURLScheme, self.defaultIdentityHost, kMPIdentityVersion, pathComponent];
    NSURL *defaultURL = [NSURL URLWithString:urlString];
    
    if ([MParticle sharedInstance].networkOptions.overridesIdentitySubdirectory) {
        urlString = [NSString stringWithFormat:identityURLFormatOverride, kMPURLScheme, identityHost, pathComponent];
    } else {
        urlString = [NSString stringWithFormat:identityURLFormat, kMPURLScheme, identityHost, kMPIdentityVersion, pathComponent];
    }
    
    NSURL *modifiedURL = [NSURL URLWithString:urlString];
    defaultURL.accessibilityHint = @"identity";
    modifiedURL.accessibilityHint = @"identity";
    
    MPURL *identityURL;
    if (modifiedURL && defaultURL) {
        identityURL = [[MPURL alloc] initWithURL:modifiedURL defaultURL:defaultURL];
    }
    
    return identityURL;
}

- (MPURL *)modifyURL {
    NSString *pathComponent = @"modify";
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    NSString *identityHost;
    if ([MParticle sharedInstance].networkOptions.identityTrackingHost && stateMachine.attAuthorizationStatus.integerValue == MPATTAuthorizationStatusAuthorized) {
        identityHost = [MParticle sharedInstance].networkOptions.identityTrackingHost;
    } else {
        identityHost = [MParticle sharedInstance].networkOptions.identityHost ?: self.defaultIdentityHost;
    }
    NSString *urlString = [NSString stringWithFormat:modifyURLFormat, kMPURLScheme, self.defaultIdentityHost, kMPIdentityVersion, [MPPersistenceController_PRIVATE mpId],  pathComponent];
    NSURL *defaultURL = [NSURL URLWithString:urlString];

    if ([MParticle sharedInstance].networkOptions.overridesIdentitySubdirectory) {
        urlString = [NSString stringWithFormat:modifyURLFormatOverride, kMPURLScheme, identityHost, [MPPersistenceController_PRIVATE mpId], pathComponent];
    } else {
        urlString = [NSString stringWithFormat:modifyURLFormat, kMPURLScheme, identityHost, kMPIdentityVersion, [MPPersistenceController_PRIVATE mpId], pathComponent];
    }

    NSURL *modifiedURL = [NSURL URLWithString:urlString];
    defaultURL.accessibilityHint = @"identity";
    modifiedURL.accessibilityHint = @"identity";
    
    MPURL *modifyURL;
    if (modifiedURL && defaultURL) {
        modifyURL = [[MPURL alloc] initWithURL:modifiedURL defaultURL:defaultURL];
    }
        
    return modifyURL;
}

- (MPURL *)aliasURLForUpload:(MPUpload *)mpUpload {
    NSString *pathComponent = @"alias";
    
    NSString *eventHost;
    if (mpUpload.uploadSettings.aliasTrackingHost && [MParticle sharedInstance].stateMachine.attAuthorizationStatus.integerValue == MPATTAuthorizationStatusAuthorized) {
        eventHost = mpUpload.uploadSettings.aliasTrackingHost;
    } else {
        eventHost = mpUpload.uploadSettings.aliasHost ?: self.defaultEventHost;
    }
    NSString *urlString = [NSString stringWithFormat:aliasURLFormat, kMPURLScheme, self.defaultEventHost, kMPIdentityVersion, kMPIdentityKey, mpUpload.uploadSettings.apiKey, pathComponent];
    NSURL *defaultURL = [NSURL URLWithString:urlString];
    
    BOOL overrides = mpUpload.uploadSettings.overridesAliasSubdirectory;
    if (!mpUpload.uploadSettings.eventsOnly && !mpUpload.uploadSettings.aliasHost) {
        eventHost = mpUpload.uploadSettings.eventsHost ?: self.defaultEventHost;
        overrides = mpUpload.uploadSettings.overridesEventsSubdirectory;
    }
    
    if (overrides) {
        urlString = [NSString stringWithFormat:aliasURLFormatOverride, kMPURLScheme, eventHost, mpUpload.uploadSettings.apiKey, pathComponent];
    } else {
        urlString = [NSString stringWithFormat:aliasURLFormat, kMPURLScheme, eventHost, kMPIdentityVersion, kMPIdentityKey, mpUpload.uploadSettings.apiKey, pathComponent];
    }
    
    NSURL *modifiedURL = [NSURL URLWithString:urlString];
    defaultURL.accessibilityHint = @"identity";
    modifiedURL.accessibilityHint = @"identity";
    
    MPURL *aliasURL;
    if (modifiedURL && defaultURL) {
        aliasURL = [[MPURL alloc] initWithURL:modifiedURL defaultURL:defaultURL];
    }
    
    return aliasURL;
}


- (BOOL)identifying {
    @synchronized(self) {
        return _identifying;
    }
}

- (void)setIdentifying:(BOOL)identifying {
    @synchronized(self) {
        _identifying = identifying;
    }
}

#pragma mark Private methods
- (void)throttleWithHTTPResponse:(NSHTTPURLResponse *)httpResponse uploadType:(MPUploadType)uploadType {
    NSDate *now = [NSDate date];
    NSDictionary *httpHeaders = [httpResponse allHeaderFields];
    NSTimeInterval retryAfter = 7200; // Default of 2 hours
    NSTimeInterval maxRetryAfter = 86400; // Maximum of 24 hours
    id suggestedRetryAfter = httpHeaders[@"Retry-After"];
    
    if (!MPIsNull(suggestedRetryAfter)) {
        if ([suggestedRetryAfter isKindOfClass:[NSString class]]) {
            if ([suggestedRetryAfter containsString:@":"]) { // Date
                NSDate *retryAfterDate = [MPDateFormatter dateFromStringRFC1123:(NSString *)suggestedRetryAfter];
                if (retryAfterDate) {
                    retryAfter = MIN(([retryAfterDate timeIntervalSince1970] - [now timeIntervalSince1970]), maxRetryAfter);
                    retryAfter = retryAfter > 0 ? retryAfter : 7200;
                } else {
                    MPILogError(@"Invalid 'Retry-After' date: %@", suggestedRetryAfter);
                }
            } else { // Number of seconds
                @try {
                    retryAfter = MIN([(NSString *)suggestedRetryAfter doubleValue], maxRetryAfter);
                } @catch (NSException *exception) {
                    retryAfter = 7200;
                    MPILogError(@"Invalid 'Retry-After' value: %@", suggestedRetryAfter);
                }
            }
        } else if ([suggestedRetryAfter isKindOfClass:[NSNumber class]]) {
            retryAfter = MIN([(NSNumber *)suggestedRetryAfter doubleValue], maxRetryAfter);
        }
    }
    
    NSDate *minUploadDate = [MParticle.sharedInstance.stateMachine minUploadDateForUploadType:uploadType];
    if ([minUploadDate compare:now] == NSOrderedAscending) {
        [MParticle.sharedInstance.stateMachine setMinUploadDate:[now dateByAddingTimeInterval:retryAfter] uploadType:uploadType];
        if (uploadType == MPUploadTypeMessage) {
            MPILogDebug(@"Throttling uploads for %.0f seconds", retryAfter);
        } else if (uploadType == MPUploadTypeAlias) {
            MPILogDebug(@"Throttling alias requests for %.0f seconds", retryAfter);
        }
    }
}

- (NSNumber *)maxAgeForCache:(nonnull NSString *)cache {
    NSNumber *maxAge;
    cache = cache.lowercaseString;
    
    if ([cache containsString: @"max-age="]) {
        NSArray *maxAgeComponents = [cache componentsSeparatedByString:@"max-age="];
        NSString *beginningOfMaxAgeString = [maxAgeComponents objectAtIndex:1];
        NSArray *components = [beginningOfMaxAgeString componentsSeparatedByString:@","];
        NSString *maxAgeValue = [components objectAtIndex:0];
        
        maxAge = [NSNumber numberWithDouble:MIN([maxAgeValue doubleValue], CONFIG_REQUESTS_MAX_EXPIRATION_AGE)];
    }
    
    return maxAge;
}

#pragma mark Public methods
- (NSObject<MPConnectorProtocol> *_Nonnull)makeConnector {
    if (MPNetworkCommunication_PRIVATE.connectorFactory) {
        return [MPNetworkCommunication_PRIVATE.connectorFactory createConnector];
    }
    return [[MPConnector alloc] init];
}

- (void)requestConfig:(nullable NSObject<MPConnectorProtocol> *)connector withCompletionHandler:(void(^)(BOOL success))completionHandler {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    BOOL shouldSendRequest = [userDefaults isConfigurationExpired];
    
    if (!shouldSendRequest) {
        completionHandler(YES);
        return;
    }
        
    MPILogVerbose(@"Starting config request");
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    if (![MPStateMachine_PRIVATE isAppExtension]) {
        backgroundTaskIdentifier = [[MPApplication_PRIVATE sharedUIApplication] beginBackgroundTaskWithExpirationHandler:^{
            if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                [[MPApplication_PRIVATE sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
                backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }
        }];
    }
    
    [MPListenerController.sharedInstance onNetworkRequestStarted:MPEndpointConfig url:self.configURL.url.absoluteString body:@[]];
    
    connector = connector ? connector : [self makeConnector];
    NSObject<MPConnectorResponseProtocol> *response = [connector responseFromGetRequestToURL:self.configURL];
    NSData *data = response.data;
    NSHTTPURLResponse *httpResponse = response.httpResponse;
    
    NSString *cacheControl = httpResponse.allHeaderFields[kMPHTTPCacheControlHeaderKey];
    NSString *ageString = httpResponse.allHeaderFields[kMPHTTPAgeHeaderKey];
    NSNumber *maxAge = [self maxAgeForCache:cacheControl];
    
    if (![MPStateMachine_PRIVATE isAppExtension]) {
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[MPApplication_PRIVATE sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }
    
    NSInteger responseCode = [httpResponse statusCode];
    MPILogVerbose(@"Config Response Code: %ld, Execution Time: %.2fms", (long)responseCode, ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
        
    if (responseCode == HTTPStatusCodeNotModified) {
        MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
        [userDefaults setConfiguration:[userDefaults getConfiguration] eTag:userDefaults[kMPHTTPETagHeaderKey] requestTimestamp:[[NSDate date] timeIntervalSince1970] currentAge:ageString.doubleValue maxAge:maxAge];
        
        completionHandler(YES);
        [MPListenerController.sharedInstance onNetworkRequestFinished:MPEndpointConfig url:self.configURL.url.absoluteString body:[NSDictionary dictionary] responseCode:responseCode];
        return;
    }
    
    BOOL success = responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted;
    
    if (!data && success) {
        completionHandler(NO);
        MPILogWarning(@"Failed config request");
        [MPListenerController.sharedInstance onNetworkRequestFinished:MPEndpointConfig url:self.configURL.url.absoluteString body:[NSDictionary dictionary] responseCode:HTTPStatusCodeNoContent];
        return;
    }
    
    success = success && [data length] > 0;

    NSDictionary *configurationDictionary = nil;
    if (success) {
        @try {
            NSError *serializationError = nil;
            configurationDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            success = serializationError == nil && [configurationDictionary[kMPMessageTypeKey] isEqualToString:kMPMessageTypeConfig];
        } @catch (NSException *exception) {
            success = NO;
            responseCode = HTTPStatusCodeNoContent;
        }
    }
    
    [MPListenerController.sharedInstance onNetworkRequestFinished:MPEndpointConfig url:self.configURL.url.absoluteString body:configurationDictionary responseCode:responseCode];
    if (success && configurationDictionary) {
        NSDictionary *headersDictionary = [httpResponse allHeaderFields];
        NSString *eTag = headersDictionary[kMPHTTPETagHeaderKey];
        if (!MPIsNull(eTag)) {
            MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configurationDictionary dataReceivedFromServer:YES stateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController];
            MPILogDebug(@"MPResponseConfig init: %@", responseConfig.description);

            MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
            [userDefaults setConfiguration:configurationDictionary eTag:eTag requestTimestamp:[[NSDate date] timeIntervalSince1970] currentAge:ageString.doubleValue maxAge:maxAge];
        }
        
        completionHandler(success);
    } else {
        completionHandler(NO);
    }
}

- (void)requestAudiencesWithCompletionHandler:(MPAudienceResponseHandler)completionHandler {
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    if (![MPStateMachine_PRIVATE isAppExtension]) {
        backgroundTaskIdentifier = [[MPApplication_PRIVATE sharedUIApplication] beginBackgroundTaskWithExpirationHandler:^{
            if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                [[MPApplication_PRIVATE sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
                backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }
        }];
    }
    
    __weak MPNetworkCommunication_PRIVATE *weakSelf = self;
    NSObject<MPConnectorProtocol> *connector = [self makeConnector];

    NSObject<MPConnectorResponseProtocol> *response = [connector responseFromGetRequestToURL:self.audienceURL];
    NSData *data = response.data;
    NSHTTPURLResponse *httpResponse = response.httpResponse;
    __strong MPNetworkCommunication_PRIVATE *strongSelf = weakSelf;
    if (!strongSelf) {
        completionHandler(NO, nil, nil);
        return;
    }
    
    if (![MPStateMachine_PRIVATE isAppExtension]) {
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[MPApplication_PRIVATE sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }
    
    if (!data) {
        NSError *audienceError = [NSError errorWithDomain:@"mParticle Audiences"
                                                     code:httpResponse.statusCode
                                       userInfo:@{@"message":@"Audiences may not be enabled for this org."}];
        completionHandler(NO, nil, audienceError);
        return;
    }
    
    NSMutableArray<MPAudience *> *currentAudiences = nil;
    BOOL success = NO;
    
    NSArray *audiencesList = nil;
    NSInteger responseCode = [httpResponse statusCode];
    success = (responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted) && [data length] > 0;
    
    if (success) {
        NSError *serializationError = nil;
        NSDictionary *audiencesDictionary = nil;
        
        @try {
            audiencesDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            success = serializationError == nil;
        } @catch (NSException *exception) {
            audiencesDictionary = nil;
            success = NO;
            MPILogError(@"Audiences Error: %@", [exception reason]);
        }
        
        if (success) {
            audiencesList = audiencesDictionary[kMPAudienceMembershipKey];
        }
        
        if (audiencesList.count > 0) {
            currentAudiences = [[NSMutableArray alloc] init];
            
            for (NSDictionary *audienceDictionary in audiencesList) {
                MPAudience *audience = [[MPAudience alloc] initWithAudienceId:audienceDictionary[kMPAudienceIdKey]];
                [currentAudiences addObject:audience];
            }
            
            MPILogVerbose(@"Audiences Response Code: %ld", (long)responseCode);
        } else {
            MPILogWarning(@"Audiences Error - Response Code: %ld", (long)responseCode);
        }
    }
    
    if (currentAudiences.count == 0) {
        currentAudiences = nil;
    }
    
    NSError *audienceError = nil;

    if (responseCode == HTTPStatusCodeForbidden) {
        audienceError = [NSError errorWithDomain:@"mParticle Audiences"
                                           code:responseCode
                                       userInfo:@{@"message":@"Audiences not enabled for this org."}];
    }
    
    completionHandler(success, currentAudiences, audienceError);
}

- (BOOL)performMessageUpload:(MPUpload *)upload {
    NSDate *minUploadDate = [MParticle.sharedInstance.stateMachine minUploadDateForUploadType:MPUploadTypeMessage];
    if ([minUploadDate compare:[NSDate date]] == NSOrderedDescending) {
        return YES;  //stop upload loop
    }
    
    MPURL *eventURL = [self eventURLForUpload:upload];
    
    NSString *uploadString = [upload serializedString];
    NSObject<MPConnectorProtocol> *connector = [self makeConnector];
    
    MPILogVerbose(@"Beginning upload for upload ID: %@", upload.uuid);
    
    NSData *zipUploadData;
    NSNumber *authTimestamp = [MParticle sharedInstance].stateMachine.attAuthorizationTimestamp;
    NSNumber *authStatus = [MParticle sharedInstance].stateMachine.attAuthorizationStatus;
    
    if (authStatus != nil && authTimestamp != nil) {
        NSDictionary *uploadDictionary = [NSJSONSerialization JSONObjectWithData:upload.uploadData options:0 error:nil];
        NSMutableDictionary *uploadDict = [uploadDictionary mutableCopy];
        
        NSMutableDictionary *deviceDict = [uploadDict[kMPDeviceInformationKey] mutableCopy];
        
        switch (authStatus.integerValue) {
            case MPATTAuthorizationStatusNotDetermined:
                deviceDict[kMPATT] = @"not_determined";
                [deviceDict removeObjectForKey:kMPDeviceAdvertiserIdKey];
                break;
            case MPATTAuthorizationStatusRestricted:
                deviceDict[kMPATT] = @"restricted";
                [deviceDict removeObjectForKey:kMPDeviceAdvertiserIdKey];
                break;
            case MPATTAuthorizationStatusDenied:
                deviceDict[kMPATT] = @"denied";
                [deviceDict removeObjectForKey:kMPDeviceAdvertiserIdKey];
                break;
            case MPATTAuthorizationStatusAuthorized:
                deviceDict[kMPATT] = @"authorized";
                break;
            default:
                break;
        }
        
        deviceDict[kMPATTTimestamp] = authTimestamp;
        
        uploadDict[kMPDeviceInformationKey] = [deviceDict copy];
        
        NSData *updatedData = [NSJSONSerialization dataWithJSONObject:[uploadDict copy] options:0 error:nil];
        uploadString = [[NSString alloc] initWithData:updatedData encoding:NSUTF8StringEncoding];

        zipUploadData = [MPZip_PRIVATE compressedDataFromData:updatedData];
    } else {
        zipUploadData = [MPZip_PRIVATE compressedDataFromData:upload.uploadData];
    }
    
    if (zipUploadData == nil || zipUploadData.length <= 0) {
        [[MParticle sharedInstance].persistenceController deleteUpload:upload];
        return NO;
    }
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    [MPListenerController.sharedInstance onNetworkRequestStarted:MPEndpointEvents url:eventURL.url.absoluteString body:@[uploadString, zipUploadData]];
    
    NSObject<MPConnectorResponseProtocol> *response = [connector responseFromPostRequestToURL:eventURL
                                                                                      message:uploadString
                                                                             serializedParams:zipUploadData
                                                                                       secret:upload.uploadSettings.secret];
    NSData *data = response.data;
    NSHTTPURLResponse *httpResponse = response.httpResponse;
    
    NSInteger responseCode = [httpResponse statusCode];
    MPILogVerbose(@"Upload response code: %ld", (long)responseCode);
    BOOL isSuccessCode = responseCode >= 200 && responseCode < 300;
    BOOL isInvalidCode = responseCode != 429 && responseCode >= 400 && responseCode < 500;
    if (isSuccessCode || isInvalidCode) {
        [[MParticle sharedInstance].persistenceController deleteUpload:upload];
        if (isSuccessCode && uploadString.length) {
            [[MParticle sharedInstance] logKitBatch:uploadString];
        }
    }
    
    BOOL success = isSuccessCode && data && [data length] > 0;
    [MPListenerController.sharedInstance onNetworkRequestFinished:MPEndpointEvents url:eventURL.url.absoluteString body:response.data responseCode:responseCode];
    if (success) {
        @try {
            NSError *serializationError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            if (responseDictionary &&
                serializationError == nil &&
                [responseDictionary[kMPMessageTypeKey] isEqualToString:kMPMessageTypeResponseHeader]) {
                [MPNetworkCommunication_PRIVATE parseConfiguration:responseDictionary];
            }
            MPILogVerbose(@"Upload complete: %@\n", uploadString);
            
        } @catch (NSException *exception) {
            MPILogError(@"Upload error: %@", [exception reason]);
        }
    }
    
    MPILogVerbose(@"Upload execution time: %.2fms", ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
    
    // 429, 503
    if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
        [self throttleWithHTTPResponse:httpResponse uploadType:MPUploadTypeMessage];
        return YES;
    }
    
    //5xx, 0, 999, -1, etc
    if (!isSuccessCode && !isInvalidCode) {
        return YES;
    }
    
    return NO;
}

- (BOOL)performAliasUpload:(MPUpload *)upload {
    NSDate *minUploadDate = [MParticle.sharedInstance.stateMachine minUploadDateForUploadType:MPUploadTypeAlias];
    if ([minUploadDate compare:[NSDate date]] == NSOrderedDescending) {
        return YES; //stop upload loop
    }
    
    MPURL *aliasURL = [self aliasURLForUpload:upload];
    
    NSString *uploadString = [upload serializedString];
    NSObject<MPConnectorProtocol> *connector = [self makeConnector];
    
    MPILogVerbose(@"Beginning alias request with upload ID: %@", upload.uuid);
    
    if (upload.uploadData == nil || upload.uploadData.length <= 0) {
        [[MParticle sharedInstance].persistenceController deleteUpload:upload];
        return NO;
    }
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    MPILogVerbose(@"Alias request:\nURL: %@ \nBody:%@", aliasURL.url, uploadString);
    [MPListenerController.sharedInstance onNetworkRequestStarted:MPEndpointAlias url:aliasURL.url.absoluteString body:@[uploadString, upload.uploadData]];
    
    NSObject<MPConnectorResponseProtocol> *response = [connector responseFromPostRequestToURL:aliasURL
                                                                                      message:uploadString
                                                                             serializedParams:upload.uploadData
                                                                                       secret:upload.uploadSettings.secret];
    NSData *data = response.data;
    NSHTTPURLResponse *httpResponse = response.httpResponse;
    
    NSInteger responseCode = [httpResponse statusCode];
    MPILogVerbose(@"Alias response code: %ld", (long)responseCode);
    
    BOOL isSuccessCode = responseCode >= 200 && responseCode < 300;
    BOOL isInvalidCode = responseCode != 429 && responseCode >= 400 && responseCode < 500;
    if (isSuccessCode || isInvalidCode) {
        [[MParticle sharedInstance].persistenceController deleteUpload:upload];
    }
    
    [MPListenerController.sharedInstance onNetworkRequestFinished:MPEndpointAlias url:aliasURL.url.absoluteString body:response.data responseCode:responseCode];
    
    NSString *responseString = [[NSString alloc] initWithData:response.data encoding:NSUTF8StringEncoding];
    if (responseString != nil && responseString.length > 0) {
        MPILogVerbose(@"Alias response:\n%@", responseString);
    }
    
    MPAliasResponse *aliasResponse = [[MPAliasResponse alloc] init];
    aliasResponse.responseCode = responseCode;
    aliasResponse.willRetry = NO;
    
    NSDictionary *requestDictionary = [NSJSONSerialization JSONObjectWithData:upload.uploadData options:0 error:nil];
    NSNumber *sourceMPID = requestDictionary[@"source_mpid"];
    NSNumber *destinationMPID = requestDictionary[@"destination_mpid"];
    NSNumber *startTimeNumber = requestDictionary[@"start_unixtime_ms"];
    NSNumber *endTimeNumber = requestDictionary[@"end_unixtime_ms"];
    NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:startTimeNumber.doubleValue/1000];
    NSDate *endTime = [NSDate dateWithTimeIntervalSince1970:endTimeNumber.doubleValue/1000];
    aliasResponse.requestID = requestDictionary[@"request_id"];
    aliasResponse.request = [MPAliasRequest requestWithSourceMPID:sourceMPID destinationMPID:destinationMPID startTime:startTime endTime:endTime];
    
    if (!isSuccessCode && data && data.length > 0) {
        @try {
            NSError *serializationError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            if (responseDictionary != nil && serializationError == nil) {
                NSString *message = responseDictionary[@"message"];
                NSNumber *code = responseDictionary[@"code"];
                MPILogError(@"Alias request failed - %@ %@", code, message);
                aliasResponse.errorResponse = message;
            }
        } @catch (NSException *exception) {
            MPILogError(@"Alias error: %@", [exception reason]);
        }
    }
    
    MPILogVerbose(@"Alias execution time: %.2fms", ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
    
    // 429, 503
    if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
        aliasResponse.willRetry = YES;
        [MPListenerController.sharedInstance onAliasRequestFinished:aliasResponse];
        [self throttleWithHTTPResponse:httpResponse uploadType:upload.uploadType];
        return YES;
    }
    
    //5xx, 0, 999, -1, etc
    if (!isSuccessCode && !isInvalidCode) {
        [MPListenerController.sharedInstance onAliasRequestFinished:aliasResponse];
        return YES;
    }
    
    [MPListenerController.sharedInstance onAliasRequestFinished:aliasResponse];
    return NO;
}

- (void)upload:(NSArray<MPUpload *> *)uploads completionHandler:(MPUploadsCompletionHandler)completionHandler {
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    if (![MPStateMachine_PRIVATE isAppExtension]) {
        backgroundTaskIdentifier = [[MPApplication_PRIVATE sharedUIApplication] beginBackgroundTaskWithExpirationHandler:^{
            if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                [[MPApplication_PRIVATE sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
                backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }
        }];
    }
    
    for (int index = 0; index < uploads.count; index++) {
        @autoreleasepool {
            MPUpload *upload = uploads[index];
            BOOL shouldStop = NO;
            if (upload.uploadType == MPUploadTypeMessage) {
                shouldStop = [self performMessageUpload:upload];
            } else if (upload.uploadType == MPUploadTypeAlias) {
                shouldStop = [self performAliasUpload:upload];
            }
            if (shouldStop){
                break;
            }
        }
    }
    
    if (![MPStateMachine_PRIVATE isAppExtension]) {
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[MPApplication_PRIVATE sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }
    completionHandler();
}

- (void)identityApiRequestWithURL:(NSURL*)url identityRequest:(MPIdentityHTTPBaseRequest *_Nonnull)identityRequest blockOtherRequests: (BOOL) blockOtherRequests completion:(nullable MPIdentityApiManagerCallback)completion {
    
    if (self.identifying) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:mParticleIdentityErrorDomain code:MPIdentityErrorResponseCodeRequestInProgress userInfo:@{mParticleIdentityErrorKey:@"Identity API request in progress."}]);
        }
        return;
    }
    
    if ([MParticle sharedInstance].stateMachine.optOut) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:mParticleIdentityErrorDomain code:MPIdentityErrorResponseCodeOptOut userInfo:@{mParticleIdentityErrorKey:@"Opt Out Enabled."}]);
        }
        return;
    }
    
    if (blockOtherRequests) {
        self.identifying = YES;
    }
    
    MPEndpoint endpointType;
    MPURL *mpURL;
    if ([self.identifyURL.url.absoluteString isEqualToString:url.absoluteString]) {
        endpointType = MPEndpointIdentityIdentify;
        mpURL = self.identifyURL;
    } else if ([self.loginURL.url.absoluteString isEqualToString:url.absoluteString ]) {
        endpointType = MPEndpointIdentityLogin;
        mpURL = self.loginURL;
    } else if ([self.logoutURL.url.absoluteString isEqualToString:url.absoluteString]) {
        endpointType = MPEndpointIdentityLogout;
        mpURL = self.logoutURL;
    } else {
        endpointType = MPEndpointIdentityModify;
        mpURL = self.modifyURL;
    }
    
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSDictionary *dictionary = [identityRequest dictionaryRepresentation];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *jsonRequest = [[NSString alloc] initWithData:data
                                                  encoding:NSUTF8StringEncoding];
    
    MPILogVerbose(@"Identity request:\nURL: %@ \nBody:%@", url, jsonRequest);
    
    
    [MPListenerController.sharedInstance onNetworkRequestStarted:endpointType url:url.absoluteString body:data];
    
    BOOL success = NO;
    NSError *error = nil;
    NSDictionary *responseDictionary = nil;
    NSString *responseString = nil;
    NSInteger responseCode = 0;
    
    BOOL enableIdentityCaching = MParticle.sharedInstance.stateMachine.enableIdentityCaching;
    BOOL usedCachedResponse = NO;
        
    // Try to use the cache if enabled
    if (enableIdentityCaching) {
        MPIdentityCachedResponse *cachedResponse = [MPIdentityCaching getCachedIdentityResponseForEndpoint:endpointType identityRequest:identityRequest];
        if (cachedResponse) {
            @try {
                NSError *serializationError = nil;
                responseString = [[NSString alloc] initWithData:cachedResponse.bodyData encoding:NSUTF8StringEncoding];
                responseDictionary = [NSJSONSerialization JSONObjectWithData:cachedResponse.bodyData options:0 error:&serializationError];
                
                if (serializationError) {
                    responseDictionary = nil;
                    success = NO;
                    usedCachedResponse = NO;
                    MPILogError(@"Identity response serialization error: %@", [serializationError localizedDescription]);
                } else {
                    responseCode = cachedResponse.statusCode;
                    success = YES;
                    usedCachedResponse = YES;
                }
            } @catch (NSException *exception) {
                responseDictionary = nil;
                success = NO;
                usedCachedResponse = NO;
                MPILogError(@"Identity response serialization error: %@", [exception reason]);
            }
        }
    } 
    
    if (!usedCachedResponse) {
        __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        
        if (![MPStateMachine_PRIVATE isAppExtension]) {
            backgroundTaskIdentifier = [[MPApplication_PRIVATE sharedUIApplication] beginBackgroundTaskWithExpirationHandler:^{
                if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                    self.identifying = NO;
                    
                    [[MPApplication_PRIVATE sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
                    backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                }
            }];
        }
        
        NSObject<MPConnectorProtocol> *connector = [self makeConnector];
        NSObject<MPConnectorResponseProtocol> *response = [connector responseFromPostRequestToURL:mpURL
                                                                                          message:nil
                                                                                 serializedParams:data 
                                                                                           secret:nil];
        
        NSData *responseData = response.data;
        error = response.error;
        NSHTTPURLResponse *httpResponse = response.httpResponse;
        
        if (![MPStateMachine_PRIVATE isAppExtension]) {
            if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                [[MPApplication_PRIVATE sharedUIApplication] endBackgroundTask:backgroundTaskIdentifier];
                backgroundTaskIdentifier = UIBackgroundTaskInvalid;
            }
        }
        
        responseCode = [httpResponse statusCode];
        success = responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted;
        success = success && [responseData length] > 0;
        
        
        MPILogVerbose(@"Identity response code: %ld", (long)responseCode);
                
        if (success) {
            @try {
                NSError *serializationError = nil;
                responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&serializationError];
                
                if (responseDictionary && !serializationError) {
                    // Cache response if it contains the custom max age header and the feature is enabled
                    if (enableIdentityCaching) {
                        NSInteger maxAgeSeconds = [response.httpResponse.allHeaderFields[kMPIdentityCachingMaxAgeHeader] integerValue];
                        MPILogVerbose(@"Identity Caching - max age header value (in seconds): %li", (long)maxAgeSeconds);
                        if (maxAgeSeconds > 0) {
                            NSDate *expires = [[NSDate date] dateByAddingTimeInterval:(NSTimeInterval)maxAgeSeconds];
                            MPIdentityCachedResponse *cachedResponse = [[MPIdentityCachedResponse alloc] initWithBodyData:responseData
                                                                                                               statusCode:responseCode
                                                                                                                  expires:expires];
                            [MPIdentityCaching cacheIdentityResponse:cachedResponse endpoint:endpointType identityRequest:identityRequest];
                        }
                    }
                } else {
                    responseDictionary = nil;
                    success = NO;
                    MPILogError(@"Identity response serialization error: %@", [serializationError localizedDescription]);
                }
            } @catch (NSException *exception) {
                responseDictionary = nil;
                success = NO;
                MPILogError(@"Identity response serialization error: %@", [exception reason]);
            }
        }
    }
    
    MPILogVerbose(@"Identity execution time: %.2fms", ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
    
    self.identifying = NO;
    
    [MPListenerController.sharedInstance onNetworkRequestFinished:endpointType url:url.absoluteString body:responseDictionary responseCode:responseCode];
    if (success) {
        if (responseString) {
            MPILogVerbose(@"Identity response:\n%@", responseString);
        }
        BOOL isModify = [identityRequest isMemberOfClass:[MPIdentityHTTPModifyRequest class]];
        if (isModify) {
            MPIdentityHTTPModifySuccessResponse *successResponse = [[MPIdentityHTTPModifySuccessResponse alloc] initWithJsonObject:responseDictionary];
            if (completion) {
                completion(successResponse, nil);
            }
        } else {
            MPIdentityHTTPSuccessResponse *response = [[MPIdentityHTTPSuccessResponse alloc] initWithJsonObject:responseDictionary];
            _context = response.context;
            if (completion) {
                completion(response, nil);
            }
        }
    } else {
        if (completion) {
            MPIdentityHTTPErrorResponse *errorResponse;
            if (error) {
                if (error.code == MPConnectivityErrorCodeNoConnection) {
                    errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithCode:MPIdentityErrorResponseCodeClientNoConnection message:@"Device has no network connectivity." error:error];
                } else if ([error.domain isEqualToString: NSURLErrorDomain] ){
                    errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithCode:MPIdentityErrorResponseCodeSSLError message:@"Failed to establish SSL connection." error:error];
                } else {
                    errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithCode:MPIdentityErrorResponseCodeUnknown message:@"An unknown client-side error has occured" error:error];
                }
            } else {
                errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithJsonObject:responseDictionary httpCode:responseCode];
            }
            completion(nil, [NSError errorWithDomain:mParticleIdentityErrorDomain code:errorResponse.code userInfo:@{mParticleIdentityErrorKey:errorResponse}]);
        }
    }
}

- (void)identify:(MPIdentityApiRequest *_Nonnull)identifyRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    if (!userDefaults[kMPATT] && identifyRequest.identities[@(MPIdentityIOSAdvertiserId)]) {
        MPILogDebug(@"The IDFA was supplied but the App Tracking Transparency Status not set with [[MParticle sharedInstance] setATTStatus:withATTStatusTimestampMillis:]");
    }
    
    MPIdentifyHTTPRequest *request = [[MPIdentifyHTTPRequest alloc] initWithIdentityApiRequest:identifyRequest];
    [self identityApiRequestWithURL:self.identifyURL.url identityRequest:request blockOtherRequests: YES completion:completion];
}

- (void)login:(MPIdentityApiRequest *_Nullable)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    if (!userDefaults[kMPATT] && loginRequest.identities[@(MPIdentityIOSAdvertiserId)]) {
        MPILogDebug(@"The IDFA was supplied but the App Tracking Transparency Status not set with [[MParticle sharedInstance] setATTStatus:withATTStatusTimestampMillis:]");
    }
    
    MPIdentifyHTTPRequest *request = [[MPIdentifyHTTPRequest alloc] initWithIdentityApiRequest:loginRequest];
    [self identityApiRequestWithURL:self.loginURL.url identityRequest:request blockOtherRequests: YES completion:completion];
}

- (void)logout:(MPIdentityApiRequest *_Nullable)logoutRequest completion:(nullable
                                                                          MPIdentityApiManagerCallback)completion {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    if (!userDefaults[kMPATT] && logoutRequest.identities[@(MPIdentityIOSAdvertiserId)]) {
        MPILogDebug(@"The IDFA was supplied but the App Tracking Transparency Status not set with [[MParticle sharedInstance] setATTStatus:withATTStatusTimestampMillis:]");
    }
    
    MPIdentifyHTTPRequest *request = [[MPIdentifyHTTPRequest alloc] initWithIdentityApiRequest:logoutRequest];
    [self identityApiRequestWithURL:self.logoutURL.url identityRequest:request blockOtherRequests: YES completion:completion];
}

- (void)modify:(MPIdentityApiRequest *_Nonnull)modifyRequest completion:(nullable MPIdentityApiManagerModifyCallback)completion {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    if (!userDefaults[kMPATT] && modifyRequest.identities[@(MPIdentityIOSAdvertiserId)]) {
        MPILogDebug(@"The IDFA was supplied but the App Tracking Transparency Status not set with [[MParticle sharedInstance] setATTStatus:withATTStatusTimestampMillis:]");
    }
    
    NSMutableArray *identityChanges = [NSMutableArray array];
    
    NSDictionary *identitiesDictionary = modifyRequest.identities;
    NSDictionary *existingIdentities = [MParticle sharedInstance].identity.currentUser.identities;
    
    [identitiesDictionary enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull identityType, NSString *value, BOOL * _Nonnull stop) {
        NSString *oldValue = existingIdentities[identityType];
        
        if ((NSNull *)value == [NSNull null]) {
            value = nil;
        }
        
        if (!oldValue || ![value isEqualToString:oldValue]) {
            MPIdentity userIdentity = (MPIdentity)[identityType intValue];
            NSString *stringType = [MPIdentityHTTPIdentities stringForIdentityType:userIdentity];
            MPIdentityHTTPIdentityChange *identityChange = [[MPIdentityHTTPIdentityChange alloc] initWithOldValue:oldValue value:value identityType:stringType];
            [identityChanges addObject:identityChange];
        }
    }];
    
    [self modifyWithIdentityChanges:identityChanges blockOtherRequests:YES completion:completion];
    
}

- (void)modifyDeviceID:(NSString *_Nonnull)deviceIdType value:(NSString *_Nonnull)value oldValue:(NSString *_Nonnull)oldValue {
    NSMutableArray *identityChanges = [NSMutableArray array];
    MPIdentityHTTPIdentityChange *identityChange = [[MPIdentityHTTPIdentityChange alloc] initWithOldValue:oldValue value:value identityType:deviceIdType];
    [identityChanges addObject:identityChange];
    [self modifyWithIdentityChanges:identityChanges blockOtherRequests:NO completion:nil];
}

- (void)modifyWithIdentityChanges:(NSArray *)identityChanges blockOtherRequests:(BOOL)blockOtherRequests completion:(nullable MPIdentityApiManagerModifyCallback)completion {
    
    if (identityChanges == nil || identityChanges.count == 0) {
        if (completion) {
            completion([[MPIdentityHTTPModifySuccessResponse alloc] init], nil);
        }
        return;
    }

    MPIdentityHTTPModifyRequest *request = [[MPIdentityHTTPModifyRequest alloc] initWithIdentityChanges:[identityChanges copy]];
    [self identityApiRequestWithURL:self.modifyURL.url identityRequest:request blockOtherRequests:blockOtherRequests completion:^(MPIdentityHTTPBaseSuccessResponse * _Nullable httpResponse, NSError * _Nullable error) {
        if (completion) {
            completion((MPIdentityHTTPModifySuccessResponse *)httpResponse, error);
        }
    }];
}

+ (void)setConnectorFactory:(NSObject<MPConnectorFactoryProtocol> *)connectorFactory {
    factory = connectorFactory;
}

+ (NSObject<MPConnectorFactoryProtocol> *)connectorFactory {
    return factory;
}

+ (void)parseConfiguration:(nonnull NSDictionary *)configuration {
    if (MPIsNull(configuration) || MPIsNull(configuration[kMPMessageTypeKey])) {
        return;
    }
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;

    // Consumer Information
    MPConsumerInfo *consumerInfo = [MParticle sharedInstance].stateMachine.consumerInfo;
    [consumerInfo updateWithConfiguration:configuration[kMPRemoteConfigConsumerInfoKey]];
    [persistence updateConsumerInfo:consumerInfo];
    MPConsumerInfo *persistenceInfo = [persistence fetchConsumerInfoForUserId:[MPPersistenceController_PRIVATE mpId]];
    if (persistenceInfo.cookies != nil) {
        [MParticle sharedInstance].stateMachine.consumerInfo.cookies = persistenceInfo.cookies;
    }
}

@end

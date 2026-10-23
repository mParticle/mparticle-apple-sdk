#import "MPNetworkCommunication.h"
#import <UIKit/UIKit.h>
#import "MPAudience.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPIdentityApiRequest.h"
#import "mParticle.h"
#import "MPEnums.h"
#import "MPIdentityDTO.h"
#import "MPConnectorFactoryProtocol.h"
#import "MPUserDefaultsConnector.h"
@import mParticle_Apple_SDK_Swift;

NSString *const kMPURLScheme = @"https";
NSString *const kMPIdentityCachingMaxAgeHeader = @"X-MP-Max-Age";

static NSObject<MPConnectorFactoryProtocol> *factory = nil;

@interface MPIdentityHTTPErrorResponse ()

- (instancetype)initWithJsonObject:(nullable NSDictionary *)dictionary httpCode:(NSInteger) httpCode;
- (instancetype)initWithCode:(MPIdentityErrorResponseCode) code message: (NSString *) message error:(NSError *) error;

@end

@implementation MPNetworkCommunication_PRIVATE (ObjCBoundary)

#pragma mark Private methods
- (BOOL)isRetriableTransportError:(NSError *)error {
    return [MPTransportErrorDetector isRetriableTransportError:error];
}

- (void)throttleWithRetryAfter:(NSTimeInterval)retryAfter uploadType:(MPUploadType)uploadType {
    MPLog *logger = self.host.sdkLogger;
    NSDate *now = [NSDate date];

    NSDate *minUploadDate = [self.host.stateMachine minUploadDateForUploadType:uploadType];
    if ([minUploadDate compare:now] == NSOrderedAscending) {
        [self.host.stateMachine setMinUploadDate:[now dateByAddingTimeInterval:retryAfter] uploadType:uploadType];
        if (uploadType == MPUploadTypeMessage) {
            NSString *messageThrottleLog = [NSString stringWithFormat:@"Throttling uploads for %.0f seconds", retryAfter];
            [logger debug:messageThrottleLog];
        } else if (uploadType == MPUploadTypeAlias) {
            NSString *aliasThrottleLog = [NSString stringWithFormat:@"Throttling alias requests for %.0f seconds", retryAfter];
            [logger debug:aliasThrottleLog];
        }
    }
}

- (NSNumber *)maxAgeForCache:(nonnull NSString *)cache {
    return [MPConfigResponseParser maxAgeFromCacheControl:cache maxExpirationAge:CONFIG_REQUESTS_MAX_EXPIRATION_AGE];
}

- (MPURLRequestContext *)requestContextForKind:(MPURLRequestKind)requestKind {
    id<MPNetworkHost> host = self.host;

    NSString *apiKey = nil;
    NSString *fallbackSecret = nil;
    NSString *userAgent = nil;
    NSArray<NSNumber *> *supportedKits = nil;
    NSArray<NSNumber *> *configuredKits = nil;
    NSString *eTag = nil;
    BOOL hasStoredConfiguration = NO;
    NSInteger environment = 0;

    if (requestKind != MPURLRequestKindCustom) {
        // The state machine's secret is a non-optional string that starts empty, so "not set yet"
        // arrives as @"" rather than nil. Signing needs it to stay nil in that case: an HMAC over
        // an empty key is not a meaningful signature, and MPURLRequestBuilder omits the
        // x-mp-signature header entirely when the secret is absent.
        NSString *stateMachineSecret = host.stateMachine.secret;
        fallbackSecret = stateMachineSecret.length > 0 ? stateMachineSecret : nil;
    }

    switch (requestKind) {
        case MPURLRequestKindAudience:
            apiKey = host.stateMachine.apiKey;
            userAgent = host.webView.userAgent;
            break;
        case MPURLRequestKindIdentity:
            apiKey = host.stateMachine.apiKey;
            break;
        case MPURLRequestKindEvent:
            supportedKits = host.supportedKits;
            configuredKits = host.configuredKits;
            userAgent = host.webView.userAgent;
            break;
        case MPURLRequestKindConfig: {
            MPUserDefaults *userDefaults = host.userDefaults;
            eTag = userDefaults[kMPHTTPETagHeaderKey];
            hasStoredConfiguration = [userDefaults getConfiguration] != nil;
            supportedKits = host.supportedKits;
            userAgent = host.webView.originalDefaultUserAgent;
            environment = (NSInteger)[MPStateMachine_PRIVATE environment];
            break;
        }
        case MPURLRequestKindCustom:
            break;
    }

    MPLog *logger = host.sdkLogger;
    if (!logger) {
        logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:host.logLevel]];
    }

    return [[MPURLRequestContext alloc] initWithAPIKey:apiKey
                                        fallbackSecret:fallbackSecret
                                             userAgent:userAgent
                                         supportedKits:supportedKits
                                        configuredKits:configuredKits
                                                  eTag:eTag
                                hasStoredConfiguration:hasStoredConfiguration
                                           environment:environment
                                        requestTimeout:NETWORK_REQUEST_MAX_WAIT_SECONDS
                         networkPerformanceMessageType:kMPMessageTypeNetworkPerformance
                                                logger:logger];
}

- (MPConnectorConfiguration *)connectorConfiguration {
    id<MPNetworkHost> host = self.host;

    MPLog *logger = host.sdkLogger;
    if (!logger) {
        logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:host.logLevel]];
    }

    return [[MPConnectorConfiguration alloc]
        initWithCustomCertificates:host.customCertificates
        pinningDisabledInDevelopment:host.pinningDisabledInDevelopment
        pinningDisabled:host.pinningDisabled
        isDevelopmentEnvironment:host.isDevelopmentEnvironment
        secureScheme:kMPURLScheme
        requestTimeout:NETWORK_REQUEST_MAX_WAIT_SECONDS
        logger:logger
        requestContextProvider:^MPURLRequestContext * _Nonnull(MPURLRequestKind requestKind) {
            return [self requestContextForKind:requestKind];
        }];
}

#pragma mark Public methods
- (NSObject<MPConnectorProtocol> *_Nonnull)makeConnector {
    if (MPNetworkCommunication_PRIVATE.connectorFactory) {
        return [MPNetworkCommunication_PRIVATE.connectorFactory createConnector];
    }

    return [[MPConnector alloc] initWithConfiguration:self.connectorConfiguration];
}

- (UIBackgroundTaskIdentifier)beginSafeBackgroundTaskWithExpirationHandler:(void(^_Nullable)(void))handler {
    if ([MPStateMachine_PRIVATE isAppExtension]) {
        return UIBackgroundTaskInvalid;
    }
    __block UIBackgroundTaskIdentifier taskId = UIBackgroundTaskInvalid;
    [self.host executeOnMainSync:^{
        taskId = [[MPApplication_PRIVATE sharedUIApplication] beginBackgroundTaskWithExpirationHandler:^{
            if (taskId != UIBackgroundTaskInvalid) {
                MPILogDebug(@"Background task expiration handler invoked");
                if (handler) handler();
                [[MPApplication_PRIVATE sharedUIApplication] endBackgroundTask:taskId];
                taskId = UIBackgroundTaskInvalid;
            }
        }];
    }];
    return taskId;
}

- (void)endSafeBackgroundTask:(UIBackgroundTaskIdentifier)taskId {
    if (taskId == UIBackgroundTaskInvalid) return;
    [self.host executeOnMain:^{
        [[MPApplication_PRIVATE sharedUIApplication] endBackgroundTask:taskId];
    }];
}

- (void)requestConfig:(nullable NSObject<MPConnectorProtocol> *)connector withCompletionHandler:(void(^)(BOOL success))completionHandler {
    MPUserDefaults *userDefaults = self.host.userDefaults;
    BOOL shouldSendRequest = [userDefaults isConfigurationExpired];

    if (!shouldSendRequest) {
        completionHandler(YES);
        return;
    }

    MPILogVerbose(@"Starting config request");
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];

    UIBackgroundTaskIdentifier backgroundTaskIdentifier = [self beginSafeBackgroundTaskWithExpirationHandler:nil];

    connector = connector ? connector : [self makeConnector];
    NSObject<MPConnectorResponseProtocol> *response = [connector responseFromGetRequestToURL:self.configURL];
    NSData *data = response.data;
    NSHTTPURLResponse *httpResponse = response.httpResponse;

    NSString *cacheControl = httpResponse.allHeaderFields[kMPHTTPCacheControlHeaderKey];
    NSString *ageString = httpResponse.allHeaderFields[kMPHTTPAgeHeaderKey];
    NSNumber *maxAge = [self maxAgeForCache:cacheControl];

    [self endSafeBackgroundTask:backgroundTaskIdentifier];

    NSInteger responseCode = [httpResponse statusCode];
    MPILogVerbose(@"Config Response Code: %ld, Execution Time: %.2fms", (long)responseCode, ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);

    if (responseCode == HTTPStatusCodeNotModified) {
        MPILogDebug(@"Config response 304 Not Modified - using cached config");
        MPUserDefaults *userDefaults = self.host.userDefaults;
        NSDictionary *configuration = [userDefaults getConfiguration];
        if (configuration != nil) {
            [userDefaults setConfiguration:configuration eTag:userDefaults[kMPHTTPETagHeaderKey] requestTimestamp:[[NSDate date] timeIntervalSince1970] currentAge:ageString.doubleValue maxAge:maxAge];
        }

        completionHandler(YES);
        return;
    }

    BOOL success = responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted;

    if (!data && success) {
        completionHandler(NO);
        MPILogError(@"Config request failed - no data received (responseCode: %ld). Kits may not initialize.", (long)responseCode);
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

    if (success && configurationDictionary) {
        NSDictionary *headersDictionary = [httpResponse allHeaderFields];
        NSString *eTag = headersDictionary[kMPHTTPETagHeaderKey];
        if (!MPIsNull(eTag)) {
            MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configurationDictionary dataReceivedFromServer:YES connector:(id<MPUserDefaultsConnectorProtocol>)[[MPUserDefaultsConnector alloc] init]];
            MPILogDebug(@"MPResponseConfig init: %@", responseConfig.description);

            MPUserDefaults *userDefaults = self.host.userDefaults;
            // An entry no kit can be configured from is dropped here rather than written to the
            // cache, where it would be re-read and re-rejected at every launch. The live
            // MPResponseConfig above still sees the response as it arrived.
            NSDictionary *storableConfiguration = [MPKitConfigurationParser configurationDroppingUnusableKitsFrom:configurationDictionary];
            [userDefaults setConfiguration:storableConfiguration eTag:eTag requestTimestamp:[[NSDate date] timeIntervalSince1970] currentAge:ageString.doubleValue maxAge:maxAge];
        }

        completionHandler(success);
    } else {
        MPILogError(@"Config request failed - could not parse response or wrong message type (responseCode: %ld). Kits may not initialize.", (long)responseCode);
        completionHandler(NO);
    }
}

- (void)requestAudiencesWithCompletionHandler:(MPAudienceResponseHandler)completionHandler {
    UIBackgroundTaskIdentifier backgroundTaskIdentifier = [self beginSafeBackgroundTaskWithExpirationHandler:nil];

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

    [self endSafeBackgroundTask:backgroundTaskIdentifier];

    MPAudienceResponsePRIVATE *audienceResponse = [MPAudienceResponsePRIVATE responseFromData:data
                                                                                   statusCode:[httpResponse statusCode]
                                                                                       logger:self.host.sdkLogger];

    NSMutableArray<MPAudience *> *currentAudiences = nil;
    if (audienceResponse.audienceIDs.count > 0) {
        currentAudiences = [[NSMutableArray alloc] initWithCapacity:audienceResponse.audienceIDs.count];
        for (NSNumber *audienceId in audienceResponse.audienceIDs) {
            [currentAudiences addObject:[[MPAudience alloc] initWithAudienceId:audienceId]];
        }
    }

    completionHandler(audienceResponse.isSuccess, currentAudiences, audienceResponse.error);
}

- (BOOL)performMessageUpload:(MPUpload *)upload {
    MPStateMachine_PRIVATE *stateMachine = self.host.stateMachine;

    NSDate *minUploadDate = [stateMachine minUploadDateForUploadType:MPUploadTypeMessage];
    if ([minUploadDate compare:[NSDate date]] == NSOrderedDescending) {
        return YES;  //stop upload loop
    }

    MPURL *eventURL = [self eventURLForUpload:upload];

    NSString *uploadString = [upload serializedString];
    NSObject<MPConnectorProtocol> *connector = [self makeConnector];

    MPILogVerbose(@"Beginning upload for upload ID: %@", upload.uuid);

    NSData *zipUploadData;
    NSNumber *authTimestamp = stateMachine.attAuthorizationTimestamp;
    NSNumber *authStatus = stateMachine.attAuthorizationStatus;

    if (authStatus != nil && authTimestamp != nil) {
        NSData *updatedData = [MPUploadDeviceInfo uploadDataApplyingATT:upload.uploadData
                                                            authStatus:authStatus.integerValue
                                                         authTimestamp:authTimestamp];
        uploadString = [[NSString alloc] initWithData:updatedData encoding:NSUTF8StringEncoding];
        zipUploadData = [MPZipPRIVATE compressedDataFromData:updatedData];
    } else {
        zipUploadData = [MPZipPRIVATE compressedDataFromData:upload.uploadData];
    }

    if (zipUploadData == nil || zipUploadData.length <= 0) {
        [self.host deleteUpload:upload];
        return NO;
    }
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];

    NSObject<MPConnectorResponseProtocol> *response = [connector responseFromPostRequestToURL:eventURL
                                                                                      message:uploadString
                                                                             serializedParams:zipUploadData
                                                                                       secret:((MPUploadSettings *)upload.uploadSettings).secret];
    NSData *data = response.data;
    NSError *error = response.error;
    NSHTTPURLResponse *httpResponse = response.httpResponse;

    NSInteger responseCode = [httpResponse statusCode];
    MPILogVerbose(@"Upload response code: %ld", (long)responseCode);

    NSDictionary *httpHeaders = [httpResponse allHeaderFields] ?: @{};
    MPUploadResponseOutcome *outcome = [MPUploadResponseHandler handleMessageResponseWithStatusCode:responseCode
                                                                                     transportError:error
                                                                                            headers:httpHeaders
                                                                                       uploadString:uploadString
                                                                                             upload:upload
                                                                                        persistence:self.host
                                                                                     kitBatchLogger:self.host];

    if (outcome.isSuccess && data && [data length] > 0) {
        @try {
            NSError *serializationError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            if (responseDictionary &&
                serializationError == nil &&
                [responseDictionary[kMPMessageTypeKey] isEqualToString:kMPMessageTypeResponseHeader]) {
                [self.host mergeConsumerInfoFromResponse:responseDictionary];
            }
            MPILogVerbose(@"Upload complete: %@\n", uploadString);

        } @catch (NSException *exception) {
            MPILogError(@"Upload error: %@", [exception reason]);
        }
    }

    MPILogVerbose(@"Upload execution time: %.2fms", ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);

    if (outcome.shouldThrottle) {
        [self throttleWithRetryAfter:outcome.throttleRetryAfter uploadType:MPUploadTypeMessage];
    }
    return outcome.willRetry;
}

- (BOOL)performAliasUpload:(MPUpload *)upload {
    NSDate *minUploadDate = [self.host.stateMachine minUploadDateForUploadType:MPUploadTypeAlias];
    if ([minUploadDate compare:[NSDate date]] == NSOrderedDescending) {
        return YES; //stop upload loop
    }

    MPURL *aliasURL = [self aliasURLForUpload:upload];

    NSString *uploadString = [upload serializedString];
    NSObject<MPConnectorProtocol> *connector = [self makeConnector];

    MPILogVerbose(@"Beginning alias request with upload ID: %@", upload.uuid);

    if (upload.uploadData == nil || upload.uploadData.length <= 0) {
        [self.host deleteUpload:upload];
        return NO;
    }
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];

    MPILogVerbose(@"Alias request:\nURL: %@ \nBody:%@", aliasURL.url, uploadString);

    NSObject<MPConnectorResponseProtocol> *response = [connector responseFromPostRequestToURL:aliasURL
                                                                                      message:uploadString
                                                                             serializedParams:upload.uploadData
                                                                                       secret:((MPUploadSettings *)upload.uploadSettings).secret];
    NSData *data = response.data;
    NSError *error = response.error;
    NSHTTPURLResponse *httpResponse = response.httpResponse;

    NSInteger responseCode = [httpResponse statusCode];
    MPILogVerbose(@"Alias response code: %ld", (long)responseCode);

    MPAliasResponsePlanPRIVATE *plan = [MPAliasResponsePlanPRIVATE planFromRequestData:upload.uploadData
                                                                          responseData:data
                                                                            statusCode:responseCode
                                                                                logger:self.host.sdkLogger];

    if (plan.isSuccessCode) {
        [MPTransportErrorDetector resetTransportErrorCounter];
    }
    if (plan.isSuccessCode || plan.isInvalidCode) {
        [self.host deleteUpload:upload];
    }

    NSString *responseString = [[NSString alloc] initWithData:response.data encoding:NSUTF8StringEncoding];
    if (responseString != nil && responseString.length > 0) {
        MPILogVerbose(@"Alias response:\n%@", responseString);
    }

    MPILogVerbose(@"Alias execution time: %.2fms", ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);

    // 429, 503
    if (plan.shouldRetry) {
        NSDictionary *httpHeaders = [httpResponse allHeaderFields];
        NSTimeInterval retryAfter = [[MPNetworkCommunicationHelper calculateRetryTimeForHeaders:httpHeaders] doubleValue];
        [self throttleWithRetryAfter:retryAfter uploadType:upload.uploadType];
        return YES;
    }

    //5xx, 0, 999, -1, etc
    if (!plan.isSuccessCode && !plan.isInvalidCode) {
        if ([self isRetriableTransportError:error]) {
            MPILogWarning(@"Throttling alias requests after transport error.");
            NSTimeInterval retryAfter = [[MPTransportErrorDetector calculateRetryTimeForTransportError] doubleValue];
            [self throttleWithRetryAfter:retryAfter uploadType:MPUploadTypeAlias];
        }
        return YES;
    }

    return NO;
}

- (void)upload:(NSArray<MPUpload *> *)uploads completionHandler:(MPUploadsCompletionHandler)completionHandler {
    UIBackgroundTaskIdentifier backgroundTaskIdentifier = [self beginSafeBackgroundTaskWithExpirationHandler:nil];

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

    [self endSafeBackgroundTask:backgroundTaskIdentifier];
    completionHandler();
}

- (void)identityApiRequestWithURL:(NSURL*)url identityRequest:(MPIdentityHTTPBaseRequest *_Nonnull)identityRequest blockOtherRequests: (BOOL) blockOtherRequests completion:(nullable MPIdentityApiManagerCallback)completion {

    if (self.identifying) {
        MPILogWarning(@"Identity API request blocked - another identity request is already in progress");
        if (completion) {
            completion(nil, [NSError errorWithDomain:mParticleIdentityErrorDomain code:MPIdentityErrorResponseCodeRequestInProgress userInfo:@{mParticleIdentityErrorKey:@"Identity API request in progress."}]);
        }
        return;
    }

    if (self.host.stateMachine.optOut) {
        MPILogWarning(@"Identity API request blocked - SDK is opted out");
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

    BOOL success = NO;
    NSError *error = nil;
    NSDictionary *responseDictionary = nil;
    NSString *responseString = nil;
    NSInteger responseCode = 0;
    BOOL bodyWasNotAnObject = NO;

    BOOL enableIdentityCaching = self.host.stateMachine.enableIdentityCaching;
    BOOL usedCachedResponse = NO;
    MPIdentityCaching *identityCaching = [[MPIdentityCaching alloc] initWithUserDefaults:self.host.userDefaults
                                                                                  logger:self.host.sdkLogger];

    // Try to use the cache if enabled
    if (enableIdentityCaching) {
        MPIdentityCachedResponse *cachedResponse = [identityCaching getCachedIdentityResponseForEndpoint:endpointType
                                                                                       requestDictionary:dictionary];
        if (cachedResponse) {
            @try {
                NSError *serializationError = nil;
                responseString = [[NSString alloc] initWithData:cachedResponse.bodyData encoding:NSUTF8StringEncoding];
                responseDictionary = [NSJSONSerialization JSONObjectWithData:cachedResponse.bodyData options:0 error:&serializationError];

                // An entry that is not an object is as unusable as one that will not parse, and is
                // treated the same way: as a miss, so the request falls through to the network
                // rather than failing for as long as the entry has left to live. An entry written
                // before this was checked on the way in heals itself that way.
                if (serializationError || ![responseDictionary isKindOfClass:[NSDictionary class]]) {
                    responseDictionary = nil;
                    success = NO;
                    usedCachedResponse = NO;
                    MPILogError(@"Cached identity response was unusable: %@",
                                serializationError ? serializationError.localizedDescription : @"body was not a JSON object");
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
        UIBackgroundTaskIdentifier backgroundTaskIdentifier = [self beginSafeBackgroundTaskWithExpirationHandler:^{
            self.identifying = NO;
        }];

        NSObject<MPConnectorProtocol> *connector = [self makeConnector];
        NSObject<MPConnectorResponseProtocol> *response = [connector responseFromPostRequestToURL:mpURL
                                                                                          message:nil
                                                                                 serializedParams:data
                                                                                           secret:nil];

        NSData *responseData = response.data;
        error = response.error;
        NSHTTPURLResponse *httpResponse = response.httpResponse;

        [self endSafeBackgroundTask:backgroundTaskIdentifier];

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
                    // A JSON body is as legitimately an array, string or number as it is an object,
                    // and every reader below subscripts it by key. This has to be settled before
                    // the cache below rather than after it: caching a body that is then rejected
                    // would hand it back on every request until it expired, turning one bad
                    // response into a window of failing ones.
                    if (![responseDictionary isKindOfClass:[NSDictionary class]]) {
                        bodyWasNotAnObject = YES;
                        responseDictionary = nil;
                        success = NO;
                    } else if (enableIdentityCaching) {
                        // Cache response if it contains the custom max age header and the feature is enabled
                        NSInteger maxAgeSeconds = [response.httpResponse.allHeaderFields[kMPIdentityCachingMaxAgeHeader] integerValue];
                        MPILogVerbose(@"Identity Caching - max age header value (in seconds): %li", (long)maxAgeSeconds);
                        if (maxAgeSeconds > 0) {
                            NSDate *expires = [[NSDate date] dateByAddingTimeInterval:(NSTimeInterval)maxAgeSeconds];
                            MPIdentityCachedResponse *cachedResponse = [[MPIdentityCachedResponse alloc] initWithBodyData:responseData
                                                                                                               statusCode:responseCode
                                                                                                                  expires:expires];
                            [identityCaching cacheIdentityResponse:cachedResponse
                                                         endpoint:endpointType
                                                requestDictionary:dictionary];
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
            if (completion) {
                completion(response, nil);
            }
        }
    } else {
        if (completion) {
            MPIdentityHTTPErrorResponse *errorResponse;
            if (error) {
                if (error.code == MPConnectivityErrorCodeNoConnection) {
                    MPILogError(@"Identity request failed - no network connectivity");
                    errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithCode:MPIdentityErrorResponseCodeClientNoConnection message:@"Device has no network connectivity." error:error];
                } else if ([error.domain isEqualToString: NSURLErrorDomain] ){
                    MPILogError(@"Identity request failed - SSL error: %@ (code: %ld)", error.localizedDescription, (long)error.code);
                    errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithCode:MPIdentityErrorResponseCodeSSLError message:@"Failed to establish SSL connection." error:error];
                } else {
                    MPILogError(@"Identity request failed - unknown error: %@ (domain: %@, code: %ld)", error.localizedDescription, error.domain, (long)error.code);
                    errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithCode:MPIdentityErrorResponseCodeUnknown message:@"An unknown client-side error has occured" error:error];
                }
            } else if (bodyWasNotAnObject) {
                MPILogError(@"Identity request failed - response body was not a JSON object");
                errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithCode:MPIdentityErrorResponseCodeUnknown message:@"Identity response body was not a JSON object." error:nil];
            } else {
                MPILogError(@"Identity request failed - HTTP error (code: %ld)", (long)responseCode);
                errorResponse = [[MPIdentityHTTPErrorResponse alloc] initWithJsonObject:responseDictionary httpCode:responseCode];
            }
            completion(nil, [NSError errorWithDomain:mParticleIdentityErrorDomain code:errorResponse.code userInfo:@{mParticleIdentityErrorKey:errorResponse}]);
        }
    }
}

- (void)identify:(MPIdentityApiRequest *_Nonnull)identifyRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    MPUserDefaults *userDefaults = self.host.userDefaults;
    if (!userDefaults[kMPATT] && identifyRequest.identities[@(MPIdentityIOSAdvertiserId)]) {
        MPILogDebug(@"The IDFA was supplied but the App Tracking Transparency Status not set with [[MParticle sharedInstance] setATTStatus:withATTStatusTimestampMillis:]");
    }

    MPIdentifyHTTPRequest *request = [[MPIdentifyHTTPRequest alloc] initWithIdentityApiRequest:identifyRequest];
    [self identityApiRequestWithURL:self.identifyURL.url identityRequest:request blockOtherRequests: YES completion:completion];
}

- (void)login:(MPIdentityApiRequest *_Nullable)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion {
    MPUserDefaults *userDefaults = self.host.userDefaults;
    if (!userDefaults[kMPATT] && loginRequest.identities[@(MPIdentityIOSAdvertiserId)]) {
        MPILogDebug(@"The IDFA was supplied but the App Tracking Transparency Status not set with [[MParticle sharedInstance] setATTStatus:withATTStatusTimestampMillis:]");
    }

    MPIdentifyHTTPRequest *request = [[MPIdentifyHTTPRequest alloc] initWithIdentityApiRequest:loginRequest];
    [self identityApiRequestWithURL:self.loginURL.url identityRequest:request blockOtherRequests: YES completion:completion];
}

- (void)logout:(MPIdentityApiRequest *_Nullable)logoutRequest completion:(nullable
                                                                          MPIdentityApiManagerCallback)completion {
    MPUserDefaults *userDefaults = self.host.userDefaults;
    if (!userDefaults[kMPATT] && logoutRequest.identities[@(MPIdentityIOSAdvertiserId)]) {
        MPILogDebug(@"The IDFA was supplied but the App Tracking Transparency Status not set with [[MParticle sharedInstance] setATTStatus:withATTStatusTimestampMillis:]");
    }

    MPIdentifyHTTPRequest *request = [[MPIdentifyHTTPRequest alloc] initWithIdentityApiRequest:logoutRequest];
    [self identityApiRequestWithURL:self.logoutURL.url identityRequest:request blockOtherRequests: YES completion:completion];
}

- (void)modify:(MPIdentityApiRequest *_Nonnull)modifyRequest completion:(nullable MPIdentityApiManagerModifyCallback)completion {
    MPUserDefaults *userDefaults = self.host.userDefaults;
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

@end

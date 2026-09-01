#import "MPURLRequestBuilder.h"
#import "MPIConstants.h"
#import <UIKit/UIKit.h>
#import "MPKitContainer.h"
#import "MPExtensionProtocol.h"
#import "MPILogger.h"
#import "MPURL.h"
#import "mParticle.h"
#import "MPUserDefaultsConnector.h"
@import mParticle_Apple_SDK_Swift;

@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong, readonly) MParticleWebViewPRIVATE *webView;

@end
    
@interface MPURLRequestBuilder() {
    BOOL _SDKURLRequest;
    NSString *_secret;
}

@property (nonatomic, strong) NSData *headerData;
@property (nonatomic, strong) NSString *message;

@end

@implementation MPURLRequestBuilder

- (instancetype)initWithURL:(MPURL *)url {
    self = [super init];
    if (!self || !url) {
        return nil;
    }
    
    _url = url;
    _headerData = nil;
    _httpMethod = kMPHTTPMethodGet;
    _message = nil;
    _postData = nil;

    return self;
}

#pragma mark Private methods
- (NSString *)hmacSha256Encode:(NSString *const)message key:(NSString *const)key {
    return [MPRequestSigner hmacSHA256HexForMessage:message key:key];
}

- (NSString *)userAgent {
    BOOL isConfig = [[_url.defaultURL relativePath] rangeOfString:@"/config"].location != NSNotFound;
    if (isConfig) {
        return MParticle.sharedInstance.webView.originalDefaultUserAgent;
    }
    return MParticle.sharedInstance.webView.userAgent;
}

#pragma mark Public class methods
+ (MPURLRequestBuilder *)newBuilderWithURL:(MPURL *)url {
    MPURLRequestBuilder *urlRequestBuilder = [[MPURLRequestBuilder alloc] initWithURL:url];
    
    if (urlRequestBuilder) {
        urlRequestBuilder->_SDKURLRequest = NO;
    }
    
    return urlRequestBuilder;
}

+ (MPURLRequestBuilder *)newBuilderWithURL:(MPURL *)url message:(NSString *)message httpMethod:(NSString *)httpMethod {
    MPURLRequestBuilder *urlRequestBuilder = [[MPURLRequestBuilder alloc] initWithURL:url];
    [urlRequestBuilder withHttpMethod:httpMethod];
    urlRequestBuilder.message = message;
    
    if (urlRequestBuilder) {
        urlRequestBuilder->_SDKURLRequest = YES;
    }
    
    return urlRequestBuilder;
}

+ (NSTimeInterval)requestTimeout {
    return NETWORK_REQUEST_MAX_WAIT_SECONDS;
}

#pragma mark Public instance methods
- (MPURLRequestBuilder *)withHeaderData:(NSData *)headerData {
    _headerData = headerData;
    
    return self;
}

- (MPURLRequestBuilder *)withHttpMethod:(NSString *)httpMethod {
    if (httpMethod) {
        _httpMethod = httpMethod;
    } else {
        _httpMethod = kMPHTTPMethodGet;
    }
    
    return self;
}

- (MPURLRequestBuilder *)withPostData:(NSData *)postData {
    _postData = postData;
    
    return self;
}

- (MPURLRequestBuilder *)withSecret:(nullable NSString *)secret {
    _secret = secret;
    
    return self;
}

- (NSMutableURLRequest *)build {
    if (!_url.url) {
        MPILogError(@"Cannot build URL request — URL is nil");
        return nil;
    }

    if (!_url.defaultURL) {
        MPILogError(@"Cannot build URL request — defaultURL is nil");
        return nil;
    }

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:_url.url];
    [urlRequest setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [urlRequest setTimeoutInterval:[MPURLRequestBuilder requestTimeout]];
    [urlRequest setHTTPMethod:_httpMethod];

    BOOL isIdentityRequest = [urlRequest.URL.accessibilityHint isEqualToString:@"identity"];
    BOOL isAudienceRequest = [urlRequest.URL.accessibilityHint isEqualToString:@"audience"];
    
    NSString *date = [MPDateFormatter stringFromDateRFC1123:[NSDate date]] ?: @"";
    NSString *secret = _secret ?: [MParticle sharedInstance].stateMachine.secret;
    NSString *apiKey = [MParticle sharedInstance].stateMachine.apiKey;

    NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
    MPLocaleHeaders *localeHeaders =
        [[MPLocaleHeaders alloc] initWithDeviceLocale:[[NSLocale autoupdatingCurrentLocale] localeIdentifier]
                                        timeZoneName:[timeZone name]
                                      secondsFromGMT:[timeZone secondsFromGMT]];
    MPURLRequestPlan *plan = nil;

    if (isAudienceRequest) {
        MPRequestSigningTarget *target =
            [[MPRequestSigningTarget alloc] initWithHTTPMethod:_httpMethod
                                                          date:date
                                                  relativePath:[urlRequest.URL relativePath]];
        plan = [MPURLRequestPlan audiencePlanWithTarget:target
                                                 query:[urlRequest.URL query]
                                                apiKey:apiKey
                                             userAgent:[self userAgent]];
        if (plan.failureReason == nil) {
            MPILogVerbose(@"Audience Signature:\n%@", plan.signatureMessage);
        }
    } else if (isIdentityRequest || _SDKURLRequest) {
        MPRequestSigningTarget *target =
            [[MPRequestSigningTarget alloc] initWithHTTPMethod:_httpMethod
                                                          date:date
                                                  relativePath:[_url.defaultURL relativePath]];
        if (isIdentityRequest) { // /identify, /login, /logout, /<mpid>/modify
            plan = [MPURLRequestPlan identityPlanWithTarget:target
                                                  postData:_postData
                                                    apiKey:apiKey
                                             localeHeaders:localeHeaders];
        } else if (_message != nil) { // /events
            MPKitContainer_PRIVATE *kitContainer = [MParticle sharedInstance].kitContainer_PRIVATE;
            plan = [MPURLRequestPlan eventPlanWithTarget:target
                                                message:_message
                                          supportedKits:[kitContainer supportedKits]
                                         configuredKits:kitContainer.configuredKitsRegistry
                                              userAgent:[self userAgent]
                                          localeHeaders:localeHeaders
                          networkPerformanceMessageType:kMPMessageTypeNetworkPerformance];
        } else { // /config
            MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
            NSString *eTag = userDefaults[kMPHTTPETagHeaderKey];
            BOOL hasStoredConfiguration = [userDefaults getConfiguration] != nil;
            plan = [MPURLRequestPlan configPlanWithTarget:target
                                                   query:[_url.defaultURL query]
                                           supportedKits:[[MParticle sharedInstance].kitContainer_PRIVATE supportedKits]
                                                    eTag:eTag
                                  hasStoredConfiguration:hasStoredConfiguration
                                               userAgent:[self userAgent]
                                           localeHeaders:localeHeaders
                                             environment:[MPStateMachine_PRIVATE environment]];
        }
    }

    if (plan) {
        if (plan.failureReason) {
            MPILogError(@"Cannot build URL request — %@", plan.failureReason);
            return nil;
        }
        [plan.headers enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, __unused BOOL *stop) {
            [urlRequest setValue:value forHTTPHeaderField:field];
        }];
        NSString *hmacSha256Encode = [self hmacSha256Encode:plan.signatureMessage key:secret];
        if (hmacSha256Encode) {
            [urlRequest setValue:hmacSha256Encode forHTTPHeaderField:@"x-mp-signature"];
        }
    } else if (_headerData) {
        NSDictionary *headerDictionary = [NSJSONSerialization JSONObjectWithData:_headerData options:0 error:nil];
        
        if (headerDictionary) {
            NSEnumerator *headerEnumerator = [headerDictionary keyEnumerator];
            NSString *key;
            
            while ((key = [headerEnumerator nextObject])) {
                [urlRequest setValue:headerDictionary[key] forHTTPHeaderField:key];
            }
        }
    }

    if (_postData.length > 0) {
        [urlRequest setHTTPBody:_postData];
    }
    
    MPILogVerbose(@"URL Request built");
    MPILogVerbose(@"with URL:\n%@", urlRequest.URL);
    MPILogVerbose(@"with headers:\n%@", urlRequest.allHTTPHeaderFields);

    return urlRequest;
}

@end

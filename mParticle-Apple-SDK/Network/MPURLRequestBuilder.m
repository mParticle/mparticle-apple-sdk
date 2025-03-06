#import "MPURLRequestBuilder.h"
#import <CommonCrypto/CommonHMAC.h>
#import "MPIConstants.h"
#import <UIKit/UIKit.h>
#import "MPKitContainer.h"
#import "MPExtensionProtocol.h"
#import "MPILogger.h"
#import "MPApplication.h"
#import "MPURL.h"
#import "mParticle.h"
#import "MParticleSwift.h"

static NSDateFormatter *RFC1123DateFormatter;

@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong, readonly) MParticleWebView_PRIVATE *webView;

@end
    
@interface MPURLRequestBuilder() {
    BOOL _SDKURLRequest;
    NSString *_secret;
}

@property (nonatomic, strong) NSData *headerData;
@property (nonatomic, strong) NSString *message;

@end


@implementation MPURLRequestBuilder

+ (void)initialize {
    if (self == [MPURLRequestBuilder class]) {
        RFC1123DateFormatter = [[NSDateFormatter alloc] init];
        RFC1123DateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        RFC1123DateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        RFC1123DateFormatter.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
    }
}

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
    if (!message || !key) {
        return nil;
    }
    
    const char *cKey = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cMessage = [message cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cMessage, strlen(cMessage), cHMAC);
    
    NSMutableString *encodedMessage = [NSMutableString stringWithCapacity:(CC_SHA256_DIGEST_LENGTH << 1)];
    
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
        [encodedMessage appendFormat:@"%02x", cHMAC[i]];
    }
    
    return (NSString *)encodedMessage;
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
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:_url.url];
    [urlRequest setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [urlRequest setTimeoutInterval:[MPURLRequestBuilder requestTimeout]];
    [urlRequest setHTTPMethod:_httpMethod];

    BOOL isIdentityRequest = [urlRequest.URL.accessibilityHint isEqualToString:@"identity"];
    BOOL isAudienceRequest = [urlRequest.URL.accessibilityHint isEqualToString:@"audience"];
    
    NSString *date = [RFC1123DateFormatter stringFromDate:[NSDate date]];
    NSString *secret = _secret ?: [MParticle sharedInstance].stateMachine.secret;

    if (isAudienceRequest) {
        NSString *audienceSignature = [NSString stringWithFormat:@"%@\n%@\n%@?%@", _httpMethod, date, [urlRequest.URL relativePath], [urlRequest.URL query]];
        MPILogVerbose(@"Audience Signature:\n%@", audienceSignature);
        NSString *hmacSha256Encode = [self hmacSha256Encode:audienceSignature key:secret];
        if (hmacSha256Encode) {
            [urlRequest setValue:hmacSha256Encode forHTTPHeaderField:@"x-mp-signature"];
        }
        [urlRequest setValue:date forHTTPHeaderField:@"Date"];
        [urlRequest setValue:[MParticle sharedInstance].stateMachine.apiKey forHTTPHeaderField:@"x-mp-key"];
        NSString *userAgent = [self userAgent];
        if (userAgent) {
            [urlRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
        }
    } else if (_SDKURLRequest || isIdentityRequest) {
        NSString *deviceLocale = [[NSLocale autoupdatingCurrentLocale] localeIdentifier];
        MPKitContainer_PRIVATE *kitContainer = !isIdentityRequest ? [MParticle sharedInstance].kitContainer_PRIVATE : nil;
        NSArray<NSNumber *> *supportedKits = [kitContainer supportedKits];
        NSString *contentType = nil;
        NSString *kits = nil;
        NSString *relativePath = [_url.defaultURL relativePath];
        NSString *signatureMessage;
        NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
        NSString *secondsFromGMT = [NSString stringWithFormat:@"%ld", (unsigned long)[timeZone secondsFromGMT]];
        NSRange range;
        BOOL containsMessage = _message != nil;
                
        if (isIdentityRequest) { // /identify, /login, /logout, /<mpid>/modify
            contentType = @"application/json";
            [urlRequest setValue:[MParticle sharedInstance].stateMachine.apiKey forHTTPHeaderField:@"x-mp-key"];
            NSString *postDataString = [[NSString alloc] initWithData:_postData encoding:NSUTF8StringEncoding];
            signatureMessage = [NSString stringWithFormat:@"%@\n%@\n%@%@", _httpMethod, date, relativePath, postDataString];
        } else if (containsMessage) { // /events
            contentType = @"application/json";
            
            if (supportedKits) {
                kits = [supportedKits componentsJoinedByString:@","];
                [urlRequest setValue:kits forHTTPHeaderField:@"x-mp-bundled-kits"];
                kits = nil;
            }
            
            kits = [MParticle.sharedInstance.kitContainer_PRIVATE.configuredKitsRegistry componentsJoinedByString:@","];
            
            range = [_message rangeOfString:kMPMessageTypeNetworkPerformance];
            if (range.location != NSNotFound) {
                [urlRequest setValue:kMPMessageTypeNetworkPerformance forHTTPHeaderField:kMPMessageTypeNetworkPerformance];
            }
            
            signatureMessage = [NSString stringWithFormat:@"%@\n%@\n%@%@", _httpMethod, date, relativePath, _message];
        } else { // /config
            contentType = @"application/x-www-form-urlencoded";
            
            if (supportedKits) {
                kits = [supportedKits componentsJoinedByString:@","];
            }
            
            NSString *environment = [NSString stringWithFormat:@"%d", (int)[MPStateMachine_PRIVATE environment]];
            [urlRequest setValue:environment forHTTPHeaderField:@"x-mp-env"];
            
            MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
            NSString *eTag = userDefaults[kMPHTTPETagHeaderKey];
            NSDictionary *config = [userDefaults getConfiguration];
            if (eTag && config) {
                [urlRequest setValue:eTag forHTTPHeaderField:@"If-None-Match"];
            }
            
            NSString *query = [_url.defaultURL query];
            signatureMessage = [NSString stringWithFormat:@"%@\n%@\n%@?%@", _httpMethod, date, relativePath, query];
        }
        
        NSString *hmacSha256Encode = [self hmacSha256Encode:signatureMessage key:secret];
        if (hmacSha256Encode) {
            [urlRequest setValue:hmacSha256Encode forHTTPHeaderField:@"x-mp-signature"];
        }
        
        if (kits) {
            [urlRequest setValue:kits forHTTPHeaderField:@"x-mp-kits"];
        }

        if (!isIdentityRequest) {
            NSString *userAgent = [self userAgent];
            if (userAgent) {
                [urlRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
            }
        }
        
        [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        if (!isIdentityRequest) {
            [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        }
        [urlRequest setValue:deviceLocale forHTTPHeaderField:@"locale"];
        [urlRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
        [urlRequest setValue:[timeZone name] forHTTPHeaderField:@"timezone"];
        [urlRequest setValue:secondsFromGMT forHTTPHeaderField:@"secondsFromGMT"];
        [urlRequest setValue:date forHTTPHeaderField:@"Date"];
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

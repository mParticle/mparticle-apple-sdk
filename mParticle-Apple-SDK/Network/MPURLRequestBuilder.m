#import "MPURLRequestBuilder.h"
#import <CommonCrypto/CommonHMAC.h>
#import "MPStateMachine.h"
#import "MPIConstants.h"
#import <UIKit/UIKit.h>
#import "MPIUserDefaults.h"
#import "MPKitContainer.h"
#import "MPExtensionProtocol.h"
#import "MPILogger.h"
#import "MPApplication.h"
#import "MParticleWebView.h"
#import "NSString+MPPercentEscape.h"
#import "MPPersistenceController.h"

static NSDateFormatter *RFC1123DateFormatter;

@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine *stateMachine;
@property (nonatomic, strong, readonly) MPKitContainer *kitContainer;
@property (nonatomic, strong, readonly) MParticleWebView *webView;

@end
    
@interface MPURLRequestBuilder() {
    BOOL SDKURLRequest;
}

@property (nonatomic, strong) NSData *headerData;
@property (nonatomic, strong) NSString *message;

@end


@implementation MPURLRequestBuilder

+ (void)initialize {
    RFC1123DateFormatter = [[NSDateFormatter alloc] init];
    RFC1123DateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    RFC1123DateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    RFC1123DateFormatter.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
}

- (instancetype)initWithURL:(NSURL *)url {
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
    BOOL isConfig = [[_url relativePath] rangeOfString:@"/config"].location != NSNotFound;
    if (isConfig) {
        return MParticle.sharedInstance.webView.originalDefaultAgent;
    }
    return MParticle.sharedInstance.webView.userAgent;
}

#pragma mark Public class methods
+ (MPURLRequestBuilder *)newBuilderWithURL:(NSURL *)url {
    MPURLRequestBuilder *urlRequestBuilder = [[MPURLRequestBuilder alloc] initWithURL:url];
    
    if (urlRequestBuilder) {
        urlRequestBuilder->SDKURLRequest = NO;
    }
    
    return urlRequestBuilder;
}

+ (MPURLRequestBuilder *)newBuilderWithURL:(NSURL *)url message:(NSString *)message httpMethod:(NSString *)httpMethod {
    MPURLRequestBuilder *urlRequestBuilder = [[MPURLRequestBuilder alloc] initWithURL:url];
    [urlRequestBuilder withHttpMethod:httpMethod];
    urlRequestBuilder.message = message;
    
    if (urlRequestBuilder) {
        urlRequestBuilder->SDKURLRequest = YES;
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

- (NSMutableURLRequest *)build {
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:_url];
    [urlRequest setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [urlRequest setTimeoutInterval:[MPURLRequestBuilder requestTimeout]];
    [urlRequest setHTTPMethod:_httpMethod];

    BOOL isIdentityRequest = [urlRequest.URL.accessibilityHint isEqualToString:@"identity"];
    
    if (SDKURLRequest || isIdentityRequest) {
        NSString *deviceLocale = [[NSLocale autoupdatingCurrentLocale] localeIdentifier];
        MPKitContainer *kitContainer = !isIdentityRequest ? [MParticle sharedInstance].kitContainer : nil;
        NSArray<NSNumber *> *supportedKits = [kitContainer supportedKits];
        NSString *contentType = nil;
        NSString *kits = nil;
        NSString *relativePath = [_url relativePath];
        NSString *signatureMessage;
        NSString *date = [RFC1123DateFormatter stringFromDate:[NSDate date]];
        NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
        NSString *secondsFromGMT = [NSString stringWithFormat:@"%ld", (unsigned long)[timeZone secondsFromGMT]];
        NSRange range;
        BOOL containsMessage = _message != nil;
        
        if (isIdentityRequest) { // /identify, /login, /logout, /<mpid>/modify
            contentType = @"application/json";
            [urlRequest setValue:[MParticle sharedInstance].stateMachine.apiKey forHTTPHeaderField:@"x-mp-key"];
            NSString *postDataString = [[NSString alloc] initWithData:_postData encoding:NSUTF8StringEncoding];
            
            NSString *pathComponent = nil;
            range = [relativePath rangeOfString:@"/identify"];
            if (range.location != NSNotFound) {
                pathComponent = @"identify";
            }
            range = [relativePath rangeOfString:@"/login"];
            if (range.location != NSNotFound) {
                pathComponent = @"login";
            }
            range = [relativePath rangeOfString:@"/logout"];
            if (range.location != NSNotFound) {
                pathComponent = @"logout";
            }
            range = [relativePath rangeOfString:@"/modify"];
            if (range.location != NSNotFound) {
                pathComponent = @"modify";
            }
            signatureMessage = [NSString stringWithFormat:@"%@\n%@\n%@%@", _httpMethod, date, [[self identityURLDefault:pathComponent] relativePath], postDataString];
        } else if (containsMessage) { // /events
            contentType = @"application/json";
            
            if (supportedKits) {
                kits = [supportedKits componentsJoinedByString:@","];
                [urlRequest setValue:kits forHTTPHeaderField:@"x-mp-bundled-kits"];
                kits = nil;
            }
            
            NSArray<id<MPExtensionKitProtocol>> *activeKitsRegistry = [[MParticle sharedInstance].kitContainer activeKitsRegistry];
            if (activeKitsRegistry.count > 0) {
                NSMutableArray<NSNumber *> *activeKitIds = [[NSMutableArray alloc] initWithCapacity:activeKitsRegistry.count];
                
                for (id<MPExtensionKitProtocol> kitRegister in activeKitsRegistry) {
                    [activeKitIds addObject:kitRegister.code];
                }
                
                kits = [activeKitIds componentsJoinedByString:@","];
            }
            
            range = [_message rangeOfString:kMPMessageTypeNetworkPerformance];
            if (range.location != NSNotFound) {
                [urlRequest setValue:kMPMessageTypeNetworkPerformance forHTTPHeaderField:kMPMessageTypeNetworkPerformance];
            }
            
            signatureMessage = [NSString stringWithFormat:@"%@\n%@\n%@%@", _httpMethod, date, [[self eventURLDefault] relativePath], _message];
        } else { // /config and /audience
            contentType = @"application/x-www-form-urlencoded";
            
            range = [relativePath rangeOfString:@"/config"];
            if (range.location != NSNotFound) { // /config
                if (supportedKits) {
                    kits = [supportedKits componentsJoinedByString:@","];
                }
                
                NSString *environment = [NSString stringWithFormat:@"%d", (int)[MPStateMachine environment]];
                [urlRequest setValue:environment forHTTPHeaderField:@"x-mp-env"];
                
                MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
                NSString *eTag = userDefaults[kMPHTTPETagHeaderKey];
                NSDictionary *config = [userDefaults getConfiguration];
                if (eTag && config) {
                    [urlRequest setValue:eTag forHTTPHeaderField:@"If-None-Match"];
                }
                
                NSString *query = [_url query];
                signatureMessage = [NSString stringWithFormat:@"%@\n%@\n%@?%@", _httpMethod, date, [[self configURLDefault] relativePath], query];
            } else {  // /audience
                signatureMessage = [NSString stringWithFormat:@"%@\n%@\n%@", _httpMethod, date, relativePath];
            }
        }
        
        NSString *hmacSha256Encode = [self hmacSha256Encode:signatureMessage key:[MParticle sharedInstance].stateMachine.secret];
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
    
    return urlRequest;
}

#pragma mark Private accessors
- (NSURL *)configURLDefault {
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    MPApplication *application = [[MPApplication alloc] init];
    
    NSString *configURLFormat = [kMPUrlFormat stringByAppendingString:@"?av=%@&sv=%@"];
    NSString *urlString = [NSString stringWithFormat:configURLFormat, kMPURLScheme, kMPURLHostConfig, kMPConfigVersion, stateMachine.apiKey, kMPConfigURL, [application.version percentEscape], kMParticleSDKVersion];
    NSURL *configURLDefault = [NSURL URLWithString:urlString];
    
    return configURLDefault;
}

- (NSURL *)eventURLDefault {
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSString *urlString = [NSString stringWithFormat:kMPUrlFormat, kMPURLScheme, kMPURLHost, kMPEventsVersion, stateMachine.apiKey, kMPEventsURL];
    NSURL *eventURLDefault = [NSURL URLWithString:urlString];
    
    return eventURLDefault;
}

- (NSURL *)identityURLDefault:(NSString *)pathComponent {
    NSString *identityHost = [MParticle sharedInstance].networkOptions.identityHost ?: kMPURLHostIdentity;
    NSString *urlString = [NSString stringWithFormat:kMPIdentityURLFormat, kMPURLScheme, identityHost, kMPIdentityVersion, pathComponent];
    NSURL *identityURLDefault = [NSURL URLWithString:urlString];
    
    identityURLDefault.accessibilityHint = @"identity";
    return identityURLDefault;
}

@end

#import "MPIAdobe.h"
@import mParticle_Apple_SDK_ObjC;

NSString *const MPIAdobeErrorKey = @"MPIAdobeErrorKey";

static NSString *      host = @"dpm.demdex.net";
static NSString *const protocol = @"https";
static NSString *const path = @"/id?";

static NSString *const marketingCloudIdKey = @"d_mid";
static NSString *const organizationIdKey = @"d_orgid";
static NSString *const deviceIdKey = @"d_cid";
static NSString *const userIdentityKey = @"d_cid_ic";
static NSString *const regionKey = @"dcs_region";
static NSString *const blobKey = @"d_blob";
static NSString *const platformKey = @"d_ptfm";
static NSString *const versionKey = @"d_ver";

static NSString *const platform = @"ios";
static NSString *const version = @"2";

static NSString *const advertiserIdDeviceKey = @"20915";
static NSString *const pushTokenDeviceKey = @"20920";

static NSString *const idSuffix = @"%01";

static NSString *const errorResponseKey = @"error_msg";

static NSString *const errorDomain = @"mParticle-Adobe";
static NSString *const serverErrorDomain = @"mParticle-Adobe Server Response";

static NSString *const marketingCloudIdUserDefaultsKey = @"ADBMOBILE_PERSISTED_MID";


@interface MPIAdobeError ()

- (id)initWithCode:(MPIAdobeErrorCode)code message:(NSString *)message error:(NSError *)error;

@end

@implementation MPIAdobeError

- (id)initWithCode:(MPIAdobeErrorCode)code message:(NSString *)message error:(NSError *)error {
    self = [super init];
    if (self) {
        _code = code;
        _message = message;
        _innerError = error;
    }
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"MPIAdobeError {\n"];
    [description appendFormat:@"  code: %@\n", @(_code)];
    [description appendFormat:@"  message: %@\n", _message];
    [description appendFormat:@"  inner error: %@\n", _innerError];
    [description appendString:@"}"];
    return description;
}

@end

@interface MPIAdobe ()

@property (nonatomic, copy) NSString *region;
@property (nonatomic, copy) NSString *blob;

@end

@implementation MPIAdobe

id<SessionProtocol> _session;

- (instancetype)initWithSession:(id<SessionProtocol>) session {
    self = [super init];
    if (self != nil) {
        _session = session;
    }
    return self;
}

- (void)sendRequestWithMarketingCloudId:(NSString *)marketingCloudId
                           advertiserId:(NSString *)advertiserId
                              pushToken:(NSString *)pushToken
                         organizationId:(NSString *)organizationId
                         userIdentities:(NSDictionary<NSNumber *, NSString *> *)userIdentities
                  audienceManagerServer:(NSString *)audienceManagerServer
                             completion:(void (^)(NSString *marketingCloudId, NSString *locationHint, NSString *blob, NSError *error))completion {
    
    if (audienceManagerServer != nil && audienceManagerServer.length > 0) {
        host = audienceManagerServer;
    }
    NSDictionary *userIdentityMappings = @{
                                           @(MPUserIdentityOther): @"other",
                                           @(MPUserIdentityCustomerId): @"customerid",
                                           @(MPUserIdentityFacebook): @"facebook",
                                           @(MPUserIdentityTwitter): @"twitter",
                                           @(MPUserIdentityGoogle): @"google",
                                           @(MPUserIdentityMicrosoft): @"microsoft",
                                           @(MPUserIdentityYahoo): @"yahoo",
                                           @(MPUserIdentityEmail): @"email",
                                           @(MPUserIdentityAlias): @"alias",
                                           @(MPUserIdentityFacebookCustomAudienceId): @"facebookcustomaudienceid"
                                           };
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@://%@%@", protocol, host, path];
    
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    NSMutableArray *queryItems = [NSMutableArray array];
    
    if (marketingCloudId) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:marketingCloudIdKey value:marketingCloudId]];
    }
    
    if (advertiserId) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:deviceIdKey value:[NSString stringWithFormat:@"%@%@%@", advertiserIdDeviceKey, idSuffix, advertiserId]]];
    }
    
    if (pushToken) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:deviceIdKey value:[NSString stringWithFormat:@"%@%@%@", pushTokenDeviceKey, idSuffix, pushToken]]];
    }
    
    if (userIdentities) {
        [userIdentities enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *mappedKey = userIdentityMappings[key];
            if (mappedKey.length) {
                [queryItems addObject:[NSURLQueryItem queryItemWithName:userIdentityKey value:[NSString stringWithFormat:@"%@%@%@", mappedKey, idSuffix, obj]]];
            }
        }];
    }
    
    if (self.blob) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:blobKey value:self.blob]];
    }
    
    if (self.region) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:regionKey value:self.region]];
    }
    
    [queryItems addObject:[NSURLQueryItem queryItemWithName:organizationIdKey value:organizationId]];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:platformKey value:platform]];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:versionKey value:version]];
    
    components.queryItems = queryItems;
    NSURL *url = components.URL;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    __weak MPIAdobe *weakSelf = self;
    
    [[_session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        void (^callbackWithCode)(MPIAdobeErrorCode code, NSString *message, NSError *error) = ^void(MPIAdobeErrorCode code, NSString *message, NSError *error) {
            MPIAdobeError *adobeError = [[MPIAdobeError alloc] initWithCode:code message:message error:error];
            NSError *compositeError = [NSError errorWithDomain:errorDomain code:adobeError.code userInfo:@{MPIAdobeErrorKey:adobeError}];
            completion(nil, nil, nil, compositeError);
        };
        
        if (error) {
            return callbackWithCode(MPIAdobeErrorCodeClientFailedRequestError, @"Request failed", error);
        }
        
        NSDictionary *dictionary = nil;
        @try {
            dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        } @catch (NSException *exception) {
            return callbackWithCode(MPIAdobeErrorCodeClientSerializationError, @"Deserializing the response failed", nil);
        }
        
        NSDictionary *errorDictionary = dictionary[errorResponseKey];
        if (errorDictionary) {
            if ([errorDictionary isKindOfClass:[NSDictionary class]]) {
                NSError *error = [NSError errorWithDomain:serverErrorDomain code:0 userInfo:errorDictionary];
                return callbackWithCode(MPIAdobeErrorCodeServerError, @"Server returned an error", error);
            } else {
                NSError *error = [NSError errorWithDomain:serverErrorDomain code:0 userInfo:@{}];
                return callbackWithCode(MPIAdobeErrorCodeServerError, @"Server returned an error", error);
            }
        }
        
        NSString *marketingCloudId = [dictionary[marketingCloudIdKey] isKindOfClass:[NSString class]] ? dictionary[marketingCloudIdKey] : nil;
        NSString *region = [dictionary[regionKey] isKindOfClass:[NSString class]] ? dictionary[regionKey] : nil;
        NSString *blob = [dictionary[blobKey] isKindOfClass:[NSString class]] ? dictionary[blobKey] : nil;
        
        weakSelf.region = region;
        weakSelf.blob = blob;
        
        completion([marketingCloudId copy], [region copy], [blob copy], nil);
    }] resume];
}

- (NSString *)marketingCloudIdFromUserDefaults {
    return [[NSUserDefaults standardUserDefaults] objectForKey:marketingCloudIdUserDefaultsKey];
}

@end

//
//  MPIdentityDTO.m
//

#import "MPIdentityDTO.h"
#import "mParticle.h"
#import "MPDevice.h"
#import "MPNotificationController.h"
#import "MPUtils.h"
#import "MPStateMachine.h"
#import "MPConsumerInfo.h"

@implementation MPIdentityHTTPBaseRequest

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    NSDictionary *clientSDKDictionary = [MPIdentityHTTPClientSDK clientSDKDictionaryWithVersion:kMParticleSDKVersion];
    if (clientSDKDictionary) {
        dictionary[@"client_sdk"] = clientSDKDictionary;
    }
    
    NSString *environment = [MParticle sharedInstance].environment == MPEnvironmentProduction ? @"production" : @"development";
    if (environment) {
        dictionary[@"environment"] = environment;
    }
    
    NSString *requestId = [NSUUID UUID].UUIDString;
    if (requestId) {
        dictionary[@"request_id"] = requestId;
    }
    
    NSNumber *requestTimestamp = @(floor([[NSDate date] timeIntervalSince1970]));
    if (requestTimestamp) {
        dictionary[@"request_timestamp_ms"] = @([requestTimestamp longLongValue] * 1000);
    }
    
    NSString *deviceApplicationStamp = [MPStateMachine sharedInstance].consumerInfo.deviceApplicationStamp;
    if (deviceApplicationStamp) {
        dictionary[@"device_application_stamp"] = deviceApplicationStamp;
    }
    
    return dictionary;
}

@end

@implementation MPIdentifyHTTPRequest

- (instancetype)initWithIdentityApiRequest:(MPIdentityApiRequest *)apiRequest {
    self = [super init];
    if (self) {
        _knownIdentities = [[MPIdentityHTTPIdentities alloc] initWithIdentities:apiRequest.userIdentities];
        
        NSNumber *mpid = [MPUtils mpId];
        if (mpid.longLongValue != 0) {
            _previousMPID = [MPUtils mpId].stringValue;
        }
        
        MPDevice *device = [[MPDevice alloc] init];
        
        NSString *advertiserId = device.advertiserId;
        if (advertiserId) {
            _knownIdentities.advertiserId = advertiserId;
        }
        
        NSString *vendorId = device.vendorId;
        if (vendorId) {
            _knownIdentities.vendorId = vendorId;
        }
        
#if TARGET_OS_IOS == 1
        NSString *deviceToken = [[NSString alloc] initWithData:[MPNotificationController deviceToken] encoding:NSUTF8StringEncoding];
        if (deviceToken) {
            _knownIdentities.pushToken = deviceToken;
        }
#endif
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [[super dictionaryRepresentation] mutableCopy];
    
    if (_previousMPID) {
        dictionary[@"previous_mpid"] = _previousMPID;
    }
    
    NSDictionary *identitiesDictionary = [_knownIdentities dictionaryRepresentation];
    
    if (identitiesDictionary) {
        dictionary[@"known_identities"] = identitiesDictionary;
    }
    
    return dictionary;
}

@end

@implementation MPIdentityHTTPClientSDK

+ (NSDictionary *)clientSDKDictionaryWithVersion:(NSString *)sdkVersion {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    

    NSString *platform = @"ios";
    #if TARGET_OS_TVOS == 1
    platform = @"tvos";
    #endif
    
    dictionary[@"platform"] = platform;
    dictionary[@"sdk_vendor"] = @"mparticle";
    
    if (sdkVersion) {
        dictionary[@"sdk_version"] = sdkVersion;
    }
    
    return dictionary;
}

@end

@implementation MPIdentityHTTPModifyRequest

- (instancetype)initWithMPID:(NSString *)mpid identityChanges:(NSArray *)identityChanges {
    self = [super init];
    if (self) {
        _identityChanges = identityChanges;
        _mpid = mpid;
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [[super dictionaryRepresentation] mutableCopy];
    
    NSMutableArray *identityChanges = [NSMutableArray array];
    [_identityChanges enumerateObjectsUsingBlock:^(MPIdentityHTTPIdentityChange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *changeDictionary = [obj dictionaryRepresentation];
        [identityChanges addObject:changeDictionary];
    }];
    
    if (identityChanges) {
        dictionary[@"identity_changes"] = identityChanges;
    }
    
    return dictionary;
}

@end


@implementation MPIdentityHTTPIdentities

- (instancetype)initWithIdentities:(NSDictionary *)identities {
    self = [super init];
    if (self) {
        [identities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            MPUserIdentity identityType = (MPUserIdentity)key.intValue;
            
            switch (identityType) {
                case MPUserIdentityCustomerId:
                    _customerId = obj;
                    break;
                    
                case MPUserIdentityEmail:
                    _email = obj;
                    break;
                    
                case MPUserIdentityFacebook:
                    _facebook = obj;
                    break;
                    
                case MPUserIdentityFacebookCustomAudienceId:
                    _facebookCustomAudienceId = obj;
                    break;
                    
                case MPUserIdentityGoogle:
                    _google = obj;
                    break;
                    
                case MPUserIdentityMicrosoft:
                    _microsoft = obj;
                    break;
                    
                case MPUserIdentityOther:
                    _other = obj;
                    break;
                    
                case MPUserIdentityTwitter:
                    _twitter = obj;
                    break;
                    
                case MPUserIdentityYahoo:
                    _yahoo = obj;
                    break;
                    
                default:
                    break;
            }
        }];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    if (_advertiserId) {
        dictionary[@"ios_idfa"] = _advertiserId;
    }
    
    if (_vendorId) {
        dictionary[@"ios_idfv"] = _vendorId;
    }
    
#if TARGET_OS_IOS == 1
    
    if (_pushToken) {
        dictionary[@"push_token"] = _pushToken;
    }
    
#endif
    
    if (_customerId) {
        dictionary[@"customerid"] = _customerId;
    }
    
    if (_email) {
        dictionary[@"email"] = _email;
    }
    
    if (_facebook) {
        dictionary[@"facebook"] = _facebook;
    }
    
    if (_facebookCustomAudienceId) {
        dictionary[@"facebookcustomaudienceid"] = _facebookCustomAudienceId;
    }
    
    if (_google) {
        dictionary[@"google"] = _google;
    }
    
    if (_microsoft) {
        dictionary[@"microsoft"] = _microsoft;
    }
    
    if (_other) {
        dictionary[@"other"] = _other;
    }
    
    if (_twitter) {
        dictionary[@"twitter"] = _twitter;
    }
    
    if (_yahoo) {
        dictionary[@"yahoo"] = _yahoo;
    }
    
    return dictionary;
}

+ (NSString *)stringForIdentityType:(MPUserIdentity)identityType {
    switch (identityType) {
        case MPUserIdentityCustomerId:
            return @"customerid";
            
        case MPUserIdentityEmail:
            return @"email";
            
        case MPUserIdentityFacebook:
            return @"facebook";
            
        case MPUserIdentityFacebookCustomAudienceId:
            return @"facebookcustomaudienceid";
            
        case MPUserIdentityGoogle:
            return @"google";
            
        case MPUserIdentityMicrosoft:
            return @"microsoft";
            
        case MPUserIdentityOther:
            return @"other";
            
        case MPUserIdentityTwitter:
            return @"twitter";
            
        case MPUserIdentityYahoo:
            return @"yahoo";
            
        default:
            return nil;
    }
}

@end

@implementation MPIdentityHTTPIdentityChange

- (instancetype)initWithOldValue:(NSString *)oldValue value:(NSString *)value identityType:(NSString *)identityType {
    self = [super init];
    if (self) {
        _oldValue = oldValue;
        _value = value;
        _identityType = identityType;
    }
    return self;
}

- (NSMutableDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (_oldValue) {
        dictionary[@"old_value"] = _oldValue;
    } else {
        dictionary[@"old_value"] = [NSNull null];
    }
    
    if (_value) {
        dictionary[@"new_value"] = _value;
    }
    else {
        dictionary[@"new_value"] = [NSNull null];
    }
    if (_identityType) {
        dictionary[@"identity_type"] = _identityType;
    }
    return dictionary;
}

@end

@implementation MPIdentityHTTPErrorResponse

- (instancetype)initWithJsonObject:(NSDictionary *)dictionary httpCode:(NSInteger) httpCode {
    self = [super init];
    if (self) {
        _httpCode = httpCode;
        if (dictionary) {
            _code = dictionary[@"code"];
            _message = dictionary[@"message"];
        }
    }
    return self;
}

@end

@implementation MPIdentityHTTPSuccessResponse

- (instancetype)initWithJsonObject:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _context = dictionary[@"context"];
        NSString *mpidString = dictionary[@"mpid"];
        if (mpidString) {
            _mpid = [NSNumber numberWithLongLong:(long long)[mpidString longLongValue]];
        }
        _isEphemeral = [[dictionary valueForKey:@"is_ephemeral"] boolValue];
        
    }
    return self;
}

@end

@implementation MPIdentityHTTPBaseSuccessResponse

@end

@implementation MPIdentityHTTPModifySuccessResponse

- (instancetype)initWithJsonObject:(NSDictionary *)dictionary {
    self = [super init];
    return self;
}

@end

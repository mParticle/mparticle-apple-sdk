//
//  MPIdentityDTO.m
//

#import "MPIdentityDTO.h"
#import "mParticle.h"
#import "MPDevice.h"
#import "MPNotificationController.h"

@implementation MPIdentityBaseRequest

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    NSDictionary *clientSDKDictionary = [MPIdentityClientSDK clientSDKDictionaryWithVersion:kMParticleSDKVersion];
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
        dictionary[@"request_timestamp_ms"] = requestTimestamp;
    }
    
    return dictionary;
}

@end

@implementation MPIdentifyRequest

- (instancetype)initWithIdentityApiRequest:(MPIdentityApiRequest *)apiRequest {
    self = [super init];
    if (self) {
        _knownIdentities = [[MPIdentities alloc] initWithIdentities:apiRequest.userIdentities];
        
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

@implementation MPIdentityClientSDK

+ (NSDictionary *)clientSDKDictionaryWithVersion:(NSString *)sdkVersion {
    if (!sdkVersion) {
        return nil;
    }
    
#if TARGET_OS_IOS == 1
    NSString *platform = @"ios";
#elif TARGET_OS_TVOS == 1
    NSString *platform = @"tvos";
#endif
    
    NSDictionary *dictionary = @{ @"platform": platform, @"sdk_vendor": @"mparticle", @"sdk_version": sdkVersion };
    return dictionary;
}

@end

@implementation MPIdentities

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

@end

@implementation MPIdentityRequest
@end

@implementation MPIdentityChange

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
    dictionary[@"old_value"] = _oldValue;
    dictionary[@"new_value"] = _value;
    dictionary[@"identity_type"] = _identityType;
    return dictionary;
}

@end
@implementation MPIdentityModifyRequest

- (instancetype)initWithMPID:(NSString *)mpid identityChanges:(NSArray *)identityChanges {
    if (!mpid || !identityChanges.count) {
        return nil;
    }
    
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
    [_identityChanges enumerateObjectsUsingBlock:^(MPIdentityChange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *changeDictionary = [obj dictionaryRepresentation];
        [identityChanges addObject:changeDictionary];
    }];
    
    dictionary[@"identity_changes"] = identityChanges;
    
    return dictionary;
}

@end

@implementation MPIdentityErrorResponse

- (instancetype)initWithJsonObject:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _items = [NSMutableArray array];
        NSDictionary *errors = dictionary[@"errors"];
        NSArray *items = errors[@"items"];
        [items enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            MPIdentityErrorItem *item = [[MPIdentityErrorItem alloc] initWithJsonDictionary:obj];
            if (item) {
                [_items addObject:item];
            }
        }];
    }
    return self;
}

@end

@implementation MPIdentityErrorItem

- (instancetype)initWithJsonDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _code = dictionary[@"code"];
        _message = dictionary[@"message"];
    }
    return self;
}

@end

@implementation MPIdentitySuccessResponse

- (instancetype)initWithJsonObject:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _context = dictionary[@"context"];
        NSString *mpidString = dictionary[@"mpid"];
        if (mpidString) {
            _mpid = [NSNumber numberWithLongLong:(long long)[mpidString longLongValue]];
        }
    }
    return self;
}

@end

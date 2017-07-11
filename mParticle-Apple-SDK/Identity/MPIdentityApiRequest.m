//
//  MPIdentityApiRequest.m
//

#import "MPIdentityApiRequest.h"
#import "MPDevice.h"
#import "MPNotificationController.h"
#import "MPIConstants.h"

@interface MPIdentityApiRequest ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSString *> *identities;

@end

@implementation MPIdentityApiRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        _identities = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    [_identities setObject:identityString forKey:@(identityType)];
}

+ (MPIdentityApiRequest *)requestWithEmptyUser {
    return [[self alloc] init];
}

+ (MPIdentityApiRequest *)requestWithUser:(MParticleUser *) user {
    MPIdentityApiRequest *request = [[self alloc] init];
    request.identities = [user.userIdentities mutableCopy];
    return request;
}

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    NSMutableDictionary *knownIdentities = [NSMutableDictionary dictionary];
    
    [_identities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        
        MPUserIdentity identityType = [key boolValue];
        switch (identityType) {
            case MPUserIdentityCustomerId:
                knownIdentities[@"customerid"] = obj;
                break;
                
            case MPUserIdentityEmail:
                knownIdentities[@"email"] = obj;
                break;
                
            case MPUserIdentityFacebook:
                knownIdentities[@"facebook"] = obj;
                break;
                
            case MPUserIdentityFacebookCustomAudienceId:
                knownIdentities[@"facebookcustomaudienceid"] = obj;
                break;
                
            case MPUserIdentityGoogle:
                knownIdentities[@"google"] = obj;
                break;
                
            case MPUserIdentityMicrosoft:
                knownIdentities[@"microsoft"] = obj;
                break;
                
            case MPUserIdentityOther:
                knownIdentities[@"other"] = obj;
                break;
                
            case MPUserIdentityTwitter:
                knownIdentities[@"twitter"] = obj;
                break;
                
            case MPUserIdentityYahoo:
                knownIdentities[@"yahoo"] = obj;
                break;
            default:
                break;
        }
    }];
    
    MPDevice *device = [[MPDevice alloc] init];
    
    NSString *advertiserId = device.advertiserId;
    if (advertiserId) {
        knownIdentities[@"ios_idfa"] = advertiserId;
    }
    
    NSString *vendorId = device.vendorId;
    if (vendorId) {
        knownIdentities[@"ios_idfv"] = vendorId;
    }
    
#if TARGET_OS_IOS == 1
    NSString *deviceToken = [[NSString alloc] initWithData:[MPNotificationController deviceToken] encoding:NSUTF8StringEncoding];
    if (deviceToken) {
        knownIdentities[@"push_token"] = deviceToken;
    }
#endif
    
    return knownIdentities;
}

- (NSString *)email {
    return _identities[@(MPUserIdentityEmail)];
}

- (void)setEmail:(NSString *)email {
    [self setUserIdentity:email identityType:MPUserIdentityEmail];
}

- (NSString *)customerId {
    return _identities[@(MPUserIdentityCustomerId)];
}

- (void)setCustomerId:(NSString *)customerId {
    [self setUserIdentity:customerId identityType:MPUserIdentityCustomerId];
}

@end



//
//  MPIdentityRequest.m
//

#import <Foundation/Foundation.h>

//NSString *const kMParticleSDKVersion = @"6.13.3";

typedef NS_ENUM(NSUInteger, MPIdentityType) {
    MPIdentityTypeAdvertiserId,
    MPIdentityTypeVendorId,
    MPIdentityTypePushToken,
    MPIdentityTypeCustomerId,
    MPIdentityTypeEmail,
    MPIdentityTypeFacebook,
    MPIdentityTypeFacebookCustomAudienceId,
    MPIdentityTypeGoogle,
    MPIdentityTypeMicrosoft,
    MPIdentityTypeOther,
    MPIdentityTypeTwitter,
    MPIdentityTypeYahoo
};

@interface MPIdentities : NSObject

@property (nonatomic) NSString *advertiserId;
@property (nonatomic) NSString *vendorId;
@property (nonatomic) NSString *pushToken;
@property (nonatomic) NSString *customerId;
@property (nonatomic) NSString *email;
@property (nonatomic) NSString *facebook;
@property (nonatomic) NSString *facebookCustomAudienceId;
@property (nonatomic) NSString *google;
@property (nonatomic) NSString *microsoft;
@property (nonatomic) NSString *other;
@property (nonatomic) NSString *twitter;
@property (nonatomic) NSString *yahoo;

- (NSDictionary *)dictionaryRepresentation;

@end

@interface MPIdentityClientSDK : NSObject

+ (NSDictionary *)clientSDKDictionaryWithVersion:(NSString *)mParticleVersion;

@end

@interface MPIdentityBaseRequest : NSObject

- (NSDictionary *)dictionaryRepresentation;

@end

@implementation MPIdentityBaseRequest

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    NSDictionary *clientSDKDictionary = [MPIdentityClientSDK clientSDKDictionaryWithVersion:kMParticleSDKVersion];
    if (clientSDKDictionary) {
        dictionary[@"client_sdk"] = clientSDKDictionary;
    }
    
    NSString *context = nil;
    if (context) {
        dictionary[@"context"] = context;
    }
    
    NSString *environment = nil;
    if (environment) {
        dictionary[@"environment"] = environment;
    }
    
    NSString *requestId = nil;
    if (requestId) {
        dictionary[@"request_id"] = requestId;
    }
    
    NSNumber *requestTimestamp = nil;
    if (requestTimestamp) {
        dictionary[@"request_timestamp_ms"] = requestTimestamp;
    }
    
    return dictionary;
}

@end

@interface MPIdentifyRequest : MPIdentityBaseRequest

@property (nonatomic) NSString *previousMPID;
@property (nonatomic) MPIdentities *knownIdentities;

- (NSDictionary *)dictionaryRepresentation;

@end

@interface MPIdentityModifyRequest : MPIdentityBaseRequest

@property (nonatomic) NSArray *identityChanges;
@property (nonatomic) NSString *mpid;

@end

@implementation MPIdentifyRequest

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

- (instancetype)init {
    return nil;
}

- (instancetype)initWithIdentities:(NSDictionary *)identities {
    if (!identities.count) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        [identities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            MPIdentityType identityType = key.intValue;
            
            switch (identityType) {
                case MPIdentityTypeAdvertiserId:
                    _advertiserId = obj;
                    break;
                    
                case MPIdentityTypeCustomerId:
                    _customerId = obj;
                    break;
                    
                case MPIdentityTypeEmail:
                    _email = obj;
                    break;
                    
                case MPIdentityTypeFacebook:
                    _facebook = obj;
                    break;
                    
                case MPIdentityTypeFacebookCustomAudienceId:
                    _facebookCustomAudienceId = obj;
                    break;
                    
                case MPIdentityTypeGoogle:
                    _google = obj;
                    break;
                    
                case MPIdentityTypeMicrosoft:
                    _microsoft = obj;
                    break;
                    
                case MPIdentityTypeOther:
                    _other = obj;
                    break;
                    
                case MPIdentityTypeTwitter:
                    _twitter = obj;
                    break;
                    
                case MPIdentityTypeYahoo:
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

@interface MPIdentityRequest : NSObject

@end

@protocol MPIdentityRequesting <NSObject>

- (NSDictionary *)dictionaryRepresentation;

@end

@protocol MPIdentityResponding <NSObject>

- (NSDictionary *)initWithJson:(id)json;

@end

@implementation MPIdentityRequest
@end

@interface MPIdentityUtils : NSObject

+ (NSString *)stringForIdentityType:(MPIdentityType)identityType;

@end

@interface MPIdentityChange : NSObject

@property (nonatomic) NSString *oldValue;
@property (nonatomic) NSString *value;
@property (nonatomic) MPIdentityType identityType;

- (instancetype)initWithOldValue:(NSString *)oldValue value:(NSString *)value identityType:(MPIdentityType)identityType;
- (NSMutableDictionary *)dictionaryRepresentation;

@end

@implementation MPIdentityChange

- (instancetype)init {
    return nil;
}

- (instancetype)initWithOldValue:(NSString *)oldValue value:(NSString *)value identityType:(MPIdentityType)identityType {
    if (!oldValue || !value || ![MPIdentityUtils stringForIdentityType:identityType]) {
        return nil;
    }
    
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
    dictionary[@"identity_type"] = @(_identityType);
    return dictionary;
}

@end

@interface MPIdentityErrorItem : NSObject

- (instancetype)initWithJsonDictionary:(NSDictionary *)dictionary;

@property (nonatomic) NSString *code;
@property (nonatomic) NSString *message;

@end

@interface MPIdentityErrorResponse : NSObject

@property (nonatomic) NSMutableArray<MPIdentityErrorItem *> *items;

@end

@implementation MPIdentityErrorResponse

- (instancetype)init {
    return nil;
}

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

- (instancetype)init {
    return nil;
}

- (instancetype)initWithJsonDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _code = dictionary[@"code"];
        _message = dictionary[@"message"];
    }
    return self;
}

@end

@interface MPIdentifySuccessResponse : NSObject

- (instancetype)initWithJsonObject:(NSDictionary *)dictionary;

@property (nonatomic) NSString *context;
@property (nonatomic) NSString *mpid;

@end

@implementation MPIdentifySuccessResponse

- (instancetype)init {
    return nil;
}

- (instancetype)initWithJsonObject:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _context = dictionary[@"context"];
        _mpid = dictionary[@"mpid"];
    }
    return self;
}

@end

@implementation MPIdentityModifyRequest

- (instancetype)init {
    return nil;
}

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

//- (NSURLRequest *)requestRepresentation {
//    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
//
//
//
//    dictionary[@"identity_changes"] = @"";
//
//    return dictionary;
//
////    NSURLSession
////    dictionary[@"mpid"] = _mpid;
//}

@end

@implementation MPIdentityUtils

+ (NSString *)stringForIdentityType:(MPIdentityType)identityType {
    switch (identityType) {
        case MPIdentityTypeAdvertiserId:
            return @"ios_idfa";
            
        case MPIdentityTypeCustomerId:
            return @"customerid";
            
        case MPIdentityTypeEmail:
            return @"email";
            
        case MPIdentityTypeFacebook:
            return @"facebook";
            
        case MPIdentityTypeFacebookCustomAudienceId:
            return @"facebookcustomaudienceid";
            
        case MPIdentityTypeGoogle:
            return @"google";
            
        case MPIdentityTypeMicrosoft:
            return @"microsoft";
            
        case MPIdentityTypeOther:
            return @"other";
            
        case MPIdentityTypeTwitter:
            return @"twitter";
            
        case MPIdentityTypeYahoo:
            return @"yahoo";
            
        default:
            return nil;
    }
}

@end

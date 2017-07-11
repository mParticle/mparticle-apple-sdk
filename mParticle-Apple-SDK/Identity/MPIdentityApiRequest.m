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
    MPIdentityTypeYahoo,
};

@interface MPIdentityUtils : NSObject

+ (NSString *)stringForIdentityType:(MPIdentityType)identityType;

@end

@interface MPIdentityChange : NSObject

@property (nonatomic) NSString *oldValue;
@property (nonatomic) NSString *value;
@property (nonatomic) MPIdentityType identityType;
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




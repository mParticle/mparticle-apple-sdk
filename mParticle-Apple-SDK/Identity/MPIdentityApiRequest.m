//
//  MPIdentityApiRequest.m
//

#import "MPIdentityApiRequest.h"
#import "MPDevice.h"
#import "MPNotificationController.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "MPIUserDefaults.h"

@interface MPIdentityApiRequest ()
@property (nonatomic) NSMutableDictionary *mutableUserIdentities;
@end

@implementation MPIdentityApiRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mutableUserIdentities = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    if (MPIsNull(identityString)) {
        [_mutableUserIdentities setObject:(NSString *)[NSNull null]
                            forKey:@(identityType)];
    } else if ([identityString length] > 0) {
        [_mutableUserIdentities setObject:identityString
                            forKey:@(identityType)];
    }
}

+ (MPIdentityApiRequest *)requestWithEmptyUser {
    return [[self alloc] init];
}

+ (MPIdentityApiRequest *)requestWithUser:(MParticleUser *) user {
    MPIdentityApiRequest *request = [[self alloc] init];
    [user.userIdentities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        MPUserIdentity identityType = [key intValue];
        [request setUserIdentity:obj identityType:identityType];
    }];

    return request;
}

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    NSMutableDictionary *knownIdentities = [NSMutableDictionary dictionary];
    
    [_mutableUserIdentities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        
        MPUserIdentity identityType = [key intValue];
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
                
            case MPUserIdentityOther2:
                knownIdentities[@"other2"] = obj;
                break;
                
            case MPUserIdentityOther3:
                knownIdentities[@"other3"] = obj;
                break;
                
            case MPUserIdentityOther4:
                knownIdentities[@"other4"] = obj;
                break;
                
            case MPUserIdentityOther5:
                knownIdentities[@"other5"] = obj;
                break;
                
            case MPUserIdentityOther6:
                knownIdentities[@"other6"] = obj;
                break;
                
            case MPUserIdentityOther7:
                knownIdentities[@"other7"] = obj;
                break;
                
            case MPUserIdentityOther8:
                knownIdentities[@"other8"] = obj;
                break;
                
            case MPUserIdentityOther9:
                knownIdentities[@"other9"] = obj;
                break;
                
            case MPUserIdentityOther10:
                knownIdentities[@"other10"] = obj;
                break;
                
            case MPUserIdentityMobileNumber:
                knownIdentities[@"mobile_number"] = obj;
                break;
                
            case MPUserIdentityPhoneNumber2:
                knownIdentities[@"phone_number_2"] = obj;
                break;
                
            case MPUserIdentityPhoneNumber3:
                knownIdentities[@"phone_number_3"] = obj;
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
    if (![MPStateMachine isAppExtension]) {
        NSData *deviceTokenData = [MPNotificationController deviceToken];
        if (deviceTokenData) {
            NSString *deviceTokenString = [MPIUserDefaults stringFromDeviceToken:deviceTokenData];
            if (deviceTokenString && [deviceTokenString length] > 0) {
                knownIdentities[@"push_token"] = deviceTokenString;
            }
        }
    }
#endif
    
    return knownIdentities;
}

- (NSString *)email {
    NSString *result = _mutableUserIdentities[@(MPUserIdentityEmail)];
    if ((NSNull *)result == [NSNull null]) {
        result = nil;
    }
    return result;
}

- (void)setEmail:(NSString *)email {
    [self setUserIdentity:email identityType:MPUserIdentityEmail];
}

- (NSString *)customerId {
    NSString *result = _mutableUserIdentities[@(MPUserIdentityCustomerId)];
    if ((NSNull *)result == [NSNull null]) {
        result = nil;
    }
    return result;
}

- (void)setCustomerId:(NSString *)customerId {
    [self setUserIdentity:customerId identityType:MPUserIdentityCustomerId];
}

- (NSDictionary *)userIdentities {
    return [_mutableUserIdentities copy];
}

@end

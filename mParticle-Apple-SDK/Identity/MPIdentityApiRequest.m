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
    //TODO undo
    
//    MPDevice *device = [[MPDevice alloc] init];
//    
//    NSString *advertiserId = device.advertiserId;
//    if (advertiserId) {
//        knownIdentities[@"ios_idfa"] = advertiserId;
//    }
//    
//    NSString *vendorId = device.vendorId;
//    if (vendorId) {
//        knownIdentities[@"ios_idfv"] = vendorId;
//    }
    knownIdentities[@"customerid"] = @"foo";
    
#if TARGET_OS_IOS == 1
 //   NSString *deviceToken = [[NSString alloc] initWithData:[MPNotificationController deviceToken] encoding:NSUTF8StringEncoding];
 //   if (deviceToken) {
 //       knownIdentities[@"push_token"] = deviceToken;
//}
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

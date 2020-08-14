//
//  MPIdentityApiRequest.m
//

#import "MPIdentityApiRequest.h"
#import "MPDevice.h"
#import "MPNotificationController.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "MPIUserDefaults.h"
#import "MPIdentityDTO.h"

@interface MPIdentityApiRequest ()
@property (nonatomic) NSMutableDictionary *mutableIdentities;
@end

@implementation MPIdentityApiRequest

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mutableIdentities = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setIdentity:(NSString *)identityString identityType:(MPIdentity)identityType {
    if (MPIsNull(identityString)) {
        [_mutableIdentities setObject:(NSString *)[NSNull null]
                            forKey:@(identityType)];
    } else if ([identityString length] > 0) {
        [_mutableIdentities setObject:identityString
                            forKey:@(identityType)];
    }
}

+ (MPIdentityApiRequest *)requestWithEmptyUser {
    return [[self alloc] init];
}

+ (MPIdentityApiRequest *)requestWithUser:(MParticleUser *) user {
    MPIdentityApiRequest *request = [[self alloc] init];
    [user.identities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        MPIdentity identityType = [key intValue];
        [request setIdentity:obj identityType:identityType];
    }];

    return request;
}

- (NSDictionary<NSString *, id> *)dictionaryRepresentation {
    NSMutableDictionary *knownIdentities = [NSMutableDictionary dictionary];
    
    [_mutableIdentities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        
        NSString *identityKey = [MPIdentityHTTPIdentities stringForIdentityType:[key intValue]];
        knownIdentities[identityKey] = obj;
    }];
    
    MPDevice *device = [[MPDevice alloc] init];
    
    NSString *vendorId = device.vendorId;
    if (vendorId && !knownIdentities[@"ios_idfv"]) {
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
    NSString *result = _mutableIdentities[@(MPIdentityEmail)];
    if ((NSNull *)result == [NSNull null]) {
        result = nil;
    }
    return result;
}

- (void)setEmail:(NSString *)email {
    [self setIdentity:email identityType:MPIdentityEmail];
}

- (NSString *)customerId {
    NSString *result = _mutableIdentities[@(MPIdentityCustomerId)];
    if ((NSNull *)result == [NSNull null]) {
        result = nil;
    }
    return result;
}

- (void)setCustomerId:(NSString *)customerId {
    [self setIdentity:customerId identityType:MPIdentityCustomerId];
}

- (NSDictionary *)identities {
    return [_mutableIdentities copy];
}

@end

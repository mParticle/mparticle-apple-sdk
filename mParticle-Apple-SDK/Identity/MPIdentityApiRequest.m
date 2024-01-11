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
@property (nonatomic) NSMutableDictionary<NSNumber*, NSString*> *mutableIdentities;
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

- (NSString *)email {
    NSString *result = _mutableIdentities[@(MPIdentityEmail)];
    if ([result isEqual:[NSNull null]]) {
        result = nil;
    }
    return result;
}

- (void)setEmail:(NSString *)email {
    [self setIdentity:email identityType:MPIdentityEmail];
}

- (NSString *)customerId {
    NSString *result = _mutableIdentities[@(MPIdentityCustomerId)];
    if ([result isEqual:[NSNull null]]) {
        result = nil;
    }
    return result;
}

- (void)setCustomerId:(NSString *)customerId {
    [self setIdentity:customerId identityType:MPIdentityCustomerId];
}

- (NSDictionary<NSNumber*, NSString*> *)identities {
    return [_mutableIdentities copy];
}

@end

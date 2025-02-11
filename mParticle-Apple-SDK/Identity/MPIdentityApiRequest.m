//
//  MPIdentityApiRequest.m
//

#import "MPIdentityApiRequest.h"
#import "MPNotificationController.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "MPIdentityDTO.h"

@interface MPIdentityApiRequest ()
@property (nonatomic) NSMutableDictionary<NSNumber*, NSObject*> *mutableIdentities;
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
    NSObject *result = _mutableIdentities[@(MPIdentityEmail)];
    if ([result isKindOfClass:[NSString class]]) {
        return (NSString *)result;
    }
    return nil;
}

- (void)setEmail:(NSString *)email {
    [self setIdentity:email identityType:MPIdentityEmail];
}

- (NSString *)customerId {
    NSObject *result = _mutableIdentities[@(MPIdentityCustomerId)];
    if ([result isKindOfClass:[NSString class]]) {
        return (NSString *)result;
    }
    return nil;
}

- (void)setCustomerId:(NSString *)customerId {
    [self setIdentity:customerId identityType:MPIdentityCustomerId];
}

- (NSDictionary<NSNumber*, NSObject*> *)identities {
    return [_mutableIdentities copy];
}

@end

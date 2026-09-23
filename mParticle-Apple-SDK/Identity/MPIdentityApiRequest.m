//
//  MPIdentityApiRequest.m
//

#import "MPIdentityApiRequest.h"
@import mParticle_Apple_SDK_Swift;

@interface MPIdentityApiRequest ()
@property (nonatomic, strong) MPIdentityApiRequestStoragePRIVATE *storage;
@end

@implementation MPIdentityApiRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        _storage = [[MPIdentityApiRequestStoragePRIVATE alloc] init];
    }
    return self;
}

// Exposed for the ObjC contract test, which inspects the raw identity map.
- (NSMutableDictionary<NSNumber *, NSObject *> *)mutableIdentities {
    return self.storage.mutableIdentities;
}

- (void)setIdentity:(NSString *)identityString identityType:(MPIdentity)identityType {
    [self.storage setIdentity:identityString identityType:identityType];
}

+ (MPIdentityApiRequest *)requestWithEmptyUser {
    return [[self alloc] init];
}

+ (MPIdentityApiRequest *)requestWithUser:(MParticleUser *)user {
    MPIdentityApiRequest *request = [[self alloc] init];
    [user.identities enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [request setIdentity:obj identityType:(MPIdentity)key.intValue];
    }];

    return request;
}

- (NSString *)email {
    return self.storage.email;
}

- (void)setEmail:(NSString *)email {
    self.storage.email = email;
}

- (NSString *)customerId {
    return self.storage.customerId;
}

- (void)setCustomerId:(NSString *)customerId {
    self.storage.customerId = customerId;
}

- (NSString *)emailSha256 {
    return self.storage.emailSha256;
}

- (void)setEmailSha256:(NSString *)emailSha256 {
    self.storage.emailSha256 = emailSha256;
}

- (NSString *)mobileSha256 {
    return self.storage.mobileSha256;
}

- (void)setMobileSha256:(NSString *)mobileSha256 {
    self.storage.mobileSha256 = mobileSha256;
}

- (NSDictionary<NSNumber *, NSObject *> *)identities {
    return self.storage.identities;
}

@end

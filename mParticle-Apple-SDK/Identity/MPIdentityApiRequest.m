//
//  MPIdentityApiRequest.m
//

#import "MPIdentityApiRequest.h"

@implementation MPIdentityApiRequest

- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    //TODO
}

+ (MPIdentityApiRequest*)requestWithEmptyUser {
    return [[self alloc] init];
}

+ (MPIdentityApiRequest*)requestWithUser:(MParticleUser *) user {
    return [[self alloc] init];
}

@end

//
//  MPIdentityApiRequest.m
//

#import "MPIdentityApiRequest.h"

@implementation MPIdentityApiRequest

+ (MPIdentityApiRequest*)requestWithEmptyUser {
    return [[self alloc] init];
}

+ (MPIdentityApiRequest*)requestWithUser:(MParticleUser *) user {
    return [[self alloc] init];
}

@end

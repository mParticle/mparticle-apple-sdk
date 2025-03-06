//
//  MPAudience.m
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 2/20/24.
//

#import "MPAudience.h"

// Internal keys
NSString * const kMPAudienceMembershipKey = @"audience_memberships";
NSString * const kMPAudienceIdKey = @"audience_id";

@implementation MPAudience

- (instancetype)initWithAudienceId:(NSNumber *)audienceId {
    self = [super init];
    if (self) {
        _audienceId = audienceId;
    }
    return self;
}

@end

//
//  MPAudience.m
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 2/20/24.
//

#import "MPAudience.h"

@implementation MPAudience

- (instancetype)initWithAudienceId:(NSNumber *)audienceId {
    self = [super init];
    if (self) {
        _audienceId = audienceId;
    }
    return self;
}

@end

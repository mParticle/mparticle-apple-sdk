//
//  MPAudience.m
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 2/20/24.
//

#import "MPAudience.h"

// Internal keys
NSString * const kMPAudienceListKey = @"m";
NSString * const kMPAudienceIdKey = @"id";
NSString * const kMPAudienceNameKey = @"n";
NSString * const kMPAudienceMembershipListKey = @"c";
NSString * const kMPAudienceMembershipListChangeActionKey = @"a";
NSString * const kMPAudienceMembershipListChangeActionAddValue = @"add";
NSString * const kMPAudienceMembershipListChangeActionDropValue = @"drop";

@implementation MPAudience

- (instancetype)initWithAudienceId:(NSNumber *)audienceId andName:(NSString *)name {
    self = [super init];
    if (self) {
        _audienceId = audienceId;
        _name = name;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)audienceDictionary {
    NSNumber *audienceId = audienceDictionary[kMPAudienceIdKey];
    NSString *audienceName = audienceDictionary[kMPAudienceNameKey];

    return [self initWithAudienceId:audienceId andName:audienceName];
}

@end

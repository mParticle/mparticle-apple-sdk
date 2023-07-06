//
//  MPNetworkOptions.m
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import "MPNetworkOptions.h"

@implementation MPNetworkOptions

- (instancetype)init
{
    self = [super init];
    if (self) {
        _pinningDisabledInDevelopment = NO;
        _overridesConfigSubdirectory = NO;
        _overridesEventsSubdirectory = NO;
        _overridesIdentitySubdirectory = NO;
        _overridesAliasSubdirectory = NO;
        _eventsOnly = NO;
    }
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"MPNetworkOptions {\n"];
    [description appendFormat:@"  configHost: %@\n", _configHost];
    [description appendFormat:@"  overridesConfigSubdirectory: %s\n", _overridesConfigSubdirectory ? "true" : "false"];
    [description appendFormat:@"  eventsHost: %@\n", _eventsHost];
    [description appendFormat:@"  overridesEventSubdirectory: %s\n", _overridesEventsSubdirectory ? "true" : "false"];
    [description appendFormat:@"  identityHost: %@\n", _identityHost];
    [description appendFormat:@"  overridesIdentitySubdirectory: %s\n", _overridesIdentitySubdirectory ? "true" : "false"];
    [description appendFormat:@"  aliasHost: %@\n", _aliasHost];
    [description appendFormat:@"  overridesAliasSubdirectory: %s\n", _overridesAliasSubdirectory ? "true" : "false"];
    [description appendFormat:@"  certificates: %@\n", _certificates];
    [description appendFormat:@"  pinningDisabledInDevelopment: %s\n", _pinningDisabledInDevelopment ? "true" : "false"];
    [description appendFormat:@"  eventsOnly: %s\n", _eventsOnly ? "true" : "false"];
    [description appendString:@"}"];
    return description;
}

@end

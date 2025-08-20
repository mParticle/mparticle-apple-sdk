@import Foundation;
#import "mParticle.h"


@implementation MPNetworkOptions

- (instancetype)init
{
    self = [super init];
    if (self) {
        _pinningDisabledInDevelopment = NO;
        _pinningDisabled = NO;
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
    [description appendFormat:@"  eventsTrackingHost: %@\n", _eventsTrackingHost];
    [description appendFormat:@"  overridesEventSubdirectory: %s\n", _overridesEventsSubdirectory ? "true" : "false"];
    [description appendFormat:@"  identityHost: %@\n", _identityHost];
    [description appendFormat:@"  identityTrackingHost: %@\n", _identityTrackingHost];
    [description appendFormat:@"  overridesIdentitySubdirectory: %s\n", _overridesIdentitySubdirectory ? "true" : "false"];
    [description appendFormat:@"  aliasHost: %@\n", _aliasHost];
    [description appendFormat:@"  aliasTrackingHost: %@\n", _aliasTrackingHost];
    [description appendFormat:@"  overridesAliasSubdirectory: %s\n", _overridesAliasSubdirectory ? "true" : "false"];
    [description appendFormat:@"  certificates: %@\n", _certificates];
    [description appendFormat:@"  pinningDisabledInDevelopment: %s\n", _pinningDisabledInDevelopment ? "true" : "false"];
    [description appendFormat:@"  pinningDisabled: %s\n", _pinningDisabled ? "true" : "false"];
    [description appendFormat:@"  eventsOnly: %s\n", _eventsOnly ? "true" : "false"];
    [description appendString:@"}"];
    return description;
}

@end

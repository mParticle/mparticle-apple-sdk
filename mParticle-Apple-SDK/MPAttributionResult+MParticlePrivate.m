#import <mParticle_Apple_SDK/mParticle.h>
#import "MPAttributionResult+MParticlePrivate.h"

@implementation MPAttributionResult

- (instancetype)initWithKitCode:(NSNumber *) kitCode
                        kitName:(NSString *) kitName {
    self = [super init];
    if (self) {
        _kitCode = kitCode;
        _kitName = kitName;
    }
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"MPAttributionResult {\n"];
    [description appendFormat:@"  kitCode: %@\n", _kitCode];
    [description appendFormat:@"  kitName: %@\n", _kitName];
    [description appendFormat:@"  linkInfo: %@\n", _linkInfo];
    [description appendString:@"}"];
    return description;
}

@end

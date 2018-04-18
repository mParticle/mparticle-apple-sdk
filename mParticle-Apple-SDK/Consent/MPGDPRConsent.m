#import "MPGDPRConsent.h"
#import "MPIConstants.h"

@implementation MPGDPRConsent

- (instancetype)init
{
    self = [super init];
    if (self) {
        _consented = NO;
        _document = nil;
        _timestamp = [NSDate date];
        _location = nil;
        _hardwareId = nil;
    }
    return self;
}

@end

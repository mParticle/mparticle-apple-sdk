#import "MPCCPAConsent.h"
#import "MPIConstants.h"

@implementation MPCCPAConsent

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

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    MPCCPAConsent *copyObject = [[MPCCPAConsent alloc] init];
    copyObject.consented = _consented;
    copyObject.document = _document;
    copyObject.timestamp = _timestamp;
    copyObject.location = _location;
    copyObject.hardwareId = _hardwareId;
    return copyObject;
}

@end

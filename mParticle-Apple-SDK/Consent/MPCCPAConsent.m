#import "MPCCPAConsent.h"

@implementation MPCCPAConsent

- (instancetype)init {
    self = [super init];
    if (self) {
        _consented = NO;
        _timestamp = [NSDate date];
        _document = nil;
        _location = nil;
        _hardwareId = nil;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MPCCPAConsent *copy = [[MPCCPAConsent allocWithZone:zone] init];
    copy.consented = self.consented;
    copy.document = self.document;
    copy.timestamp = self.timestamp;
    copy.location = self.location;
    copy.hardwareId = self.hardwareId;
    return copy;
}

@end


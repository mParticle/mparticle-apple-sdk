#import "MPGDPRConsent.h"

@implementation MPGDPRConsent

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
    MPGDPRConsent *copy = [[MPGDPRConsent allocWithZone:zone] init];
    copy.consented = self.consented;
    copy.document = self.document;
    copy.timestamp = self.timestamp;
    copy.location = self.location;
    copy.hardwareId = self.hardwareId;
    return copy;
}

@end


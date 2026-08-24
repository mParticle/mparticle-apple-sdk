#import "MPCCPAConsent.h"
@import mParticle_Apple_SDK_Swift;

@interface MPCCPAConsent ()
@property (nonatomic, strong) MPConsentRecordPRIVATE *implementation;
@end

@implementation MPCCPAConsent

- (instancetype)init {
    self = [super init];
    if (self) {
        _implementation = [[MPConsentRecordPRIVATE alloc] init];
    }
    return self;
}

- (BOOL)consented {
    return self.implementation.consented;
}

- (void)setConsented:(BOOL)consented {
    self.implementation.consented = consented;
}

- (NSString *)document {
    return self.implementation.document;
}

- (void)setDocument:(NSString *)document {
    self.implementation.document = document;
}

- (NSDate *)timestamp {
    return self.implementation.timestamp;
}

- (void)setTimestamp:(NSDate *)timestamp {
    self.implementation.timestamp = timestamp;
}

- (NSString *)location {
    return self.implementation.location;
}

- (void)setLocation:(NSString *)location {
    self.implementation.location = location;
}

- (NSString *)hardwareId {
    return self.implementation.hardwareId;
}

- (void)setHardwareId:(NSString *)hardwareId {
    self.implementation.hardwareId = hardwareId;
}

- (id)copyWithZone:(NSZone *)zone {
    MPCCPAConsent *copy = [[MPCCPAConsent allocWithZone:zone] init];
    copy.implementation = [self.implementation copyRecord];
    return copy;
}

@end

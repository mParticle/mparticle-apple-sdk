#import "MParticleSwift.h"
#import "MParticleSession+MParticlePrivate.h"

@implementation MParticleSession

- (instancetype)initWithUUID:(NSString *)uuid {
    self = [super init];
    if (self) {
        NSNumber *sessionID = [self sessionIDFromUUID:uuid];
        self.sessionID = sessionID;
        self.UUID = uuid;
    }
    return self;
}

- (NSNumber *)sessionIDFromUUID:(NSString *)uuid {
    NSNumber *sessionID = nil;
    sessionID = @([MPIHasher hashStringUTF16:uuid].integerValue);
    return sessionID;
}

@end

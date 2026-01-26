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
    MPIHasher* hasher = [[MPIHasher alloc] init];
    sessionID = @([hasher hashStringUTF16:uuid].integerValue);
    return sessionID;
}

@end

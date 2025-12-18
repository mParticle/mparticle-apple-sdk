#import "MParticleSwift.h"
#import "MParticleSession+MParticlePrivate.h"
#import <mParticle_Apple_SDK_Swift/mParticle_Apple_SDK_Swift-Swift.h>

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
    MParticle* mparticle = MParticle.sharedInstance;
    MPLog* logger = [[MPLog alloc] initWithLogLevel:mparticle.logLevel];
    logger.customLogger = mparticle.customLogger;
    MPIHasher* hasher = [[MPIHasher alloc] initWithLogger:logger];
    
    sessionID = @([hasher hashStringUTF16:uuid].integerValue);
    return sessionID;
}

@end

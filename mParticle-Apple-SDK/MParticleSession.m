//
//  MParticleSession.m
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import "MParticleSession.h"
#import "MPIHasher.h"

@interface MParticleSession ()

@property (nonatomic, readwrite) NSNumber *sessionID;
@property (nonatomic, readwrite) NSString *UUID;
@property (nonatomic, readwrite) NSNumber *startTime;

@end

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

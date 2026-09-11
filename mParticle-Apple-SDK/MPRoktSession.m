//
//  MPRoktSession.m
//  mParticle-Apple-SDK
//

#import "MPRoktSession.h"

@implementation MPRoktSession

- (instancetype)initWithSessionId:(NSString *)sessionId
                     sessionToken:(NSString *)sessionToken
                        expiresAt:(NSNumber *)expiresAt {
    self = [super init];
    if (self) {
        _sessionId = [sessionId copy];
        _sessionToken = [sessionToken copy];
        _expiresAt = expiresAt;
    }
    return self;
}

@end

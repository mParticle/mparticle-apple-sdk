#import "MPBracket.h"
@import mParticle_Apple_SDK_Swift;

@interface MPBracket ()
@property (nonatomic, strong) MPBracketPRIVATE *implementation;
@end

@implementation MPBracket

- (instancetype)initWithMpId:(int64_t)mpId low:(short)low high:(short)high {
    self = [super init];
    if (self) {
        _implementation = [[MPBracketPRIVATE alloc] initWithMpId:mpId low:low high:high];
    }
    return self;
}

- (instancetype)init {
    return [self initWithMpId:0 low:0 high:100];
}

- (int64_t)mpId {
    return self.implementation.mpId;
}

- (void)setMpId:(int64_t)mpId {
    self.implementation.mpId = mpId;
}

- (short)low {
    return self.implementation.low;
}

- (void)setLow:(short)low {
    self.implementation.low = low;
}

- (short)high {
    return self.implementation.high;
}

- (void)setHigh:(short)high {
    self.implementation.high = high;
}

- (BOOL)shouldForward {
    return [self.implementation shouldForward];
}

- (BOOL)isEqualToBracket:(MPBracket *)bracket {
    return [self.implementation isEqualToBracket:bracket.implementation];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[MPBracket class]]) {
        return NO;
    }

    return [self isEqualToBracket:(MPBracket *)object];
}

- (NSUInteger)hash {
    return self.implementation.hash;
}

- (NSString *)description {
    return self.implementation.description;
}

@end

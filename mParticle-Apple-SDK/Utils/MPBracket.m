#import "MPBracket.h"

@implementation MPBracket

- (instancetype)initWithMpId:(int64_t)mpId low:(short)low high:(short)high {
    self = [super init];
    if (self) {
        _mpId = mpId;
        _low = low;
        _high = high;
    }
    return self;
}

- (instancetype)init {
    return [self initWithMpId:0 low:0 high:100];
}

- (BOOL)shouldForward {
    if (self.mpId == 0 || self.high == 0) {
        return NO;
    }

    int64_t shiftedMpId = self.mpId >> 8;
    int64_t absoluteValue = shiftedMpId < 0 ? -shiftedMpId : shiftedMpId;
    int userBucket = (int)(absoluteValue % 100);
    return userBucket >= self.low && userBucket < self.high;
}

- (BOOL)isEqualToBracket:(MPBracket *)bracket {
    if (!bracket) {
        return NO;
    }

    return self.mpId == bracket.mpId &&
           self.low == bracket.low &&
           self.high == bracket.high;
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
    return (NSUInteger)(self.mpId ^ self.low ^ self.high);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<MPBracket: mpId=%lld, low=%d, high=%d>", 
            self.mpId, self.low, self.high];
}

@end

#import "Executor.h"
@import mParticle_Apple_SDK_Swift;

@interface Executor ()
@property (nonatomic, strong) MPExecutorPRIVATE *implementation;
@end

@implementation Executor

- (instancetype)init {
    self = [super init];
    if (self) {
        _implementation = [[MPExecutorPRIVATE alloc] init];
    }
    return self;
}

- (dispatch_queue_t)messageQueue {
    return self.implementation.messageQueue;
}

- (BOOL)isMessageQueue {
    return self.implementation.isMessageQueue;
}

- (void)executeOnMessage:(void (^)(void))block {
    [self.implementation executeOnMessage:block];
}

- (void)executeOnMessageSync:(void (^)(void))block {
    [self.implementation executeOnMessageSync:block];
}

- (void)executeOnMain:(void (^)(void))block {
    [self.implementation executeOnMain:block];
}

- (void)executeOnMainSync:(void (^)(void))block {
    [self.implementation executeOnMainSync:block];
}

@end

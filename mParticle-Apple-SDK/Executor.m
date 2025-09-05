#import "Executor.h"

@implementation Executor

static dispatch_queue_t messageQueue = nil;
static void *messageQueueKey = "mparticle message queue key";
static void *messageQueueToken = "mparticle message queue token";

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    messageQueue = dispatch_queue_create("com.mparticle.messageQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(messageQueue, messageQueueKey, messageQueueToken, nil);
    
    return self;
}

- (dispatch_queue_t)messageQueue {
    return messageQueue;
}

- (BOOL)isMessageQueue {
    void *token = dispatch_get_specific(messageQueueKey);
    BOOL isMessage = token == messageQueueToken;
    return isMessage;
}

- (void)executeOnMessage:(void(^)(void))block {
    if (self.isMessageQueue) {
        block();
    } else {
        dispatch_async(self.messageQueue, block);
    }
}

- (void)executeOnMessageSync:(void(^)(void))block {
    if (self.isMessageQueue) {
        block();
    } else {
        dispatch_sync(self.messageQueue, block);
    }
}

- (void)executeOnMain:(void(^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void)executeOnMainSync:(void(^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@end

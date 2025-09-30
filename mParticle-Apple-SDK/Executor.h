#import <Foundation/Foundation.h>

@protocol ExecutorProtocol
- (dispatch_queue_t)messageQueue;
- (BOOL)isMessageQueue;
- (void)executeOnMessage:(void(^)(void))block;
- (void)executeOnMessageSync:(void(^)(void))block;
- (void)executeOnMain:(void(^)(void))block;
- (void)executeOnMainSync:(void(^)(void))block;
@end

@interface Executor : NSObject<ExecutorProtocol>
- (dispatch_queue_t)messageQueue;
- (BOOL)isMessageQueue;
- (void)executeOnMessage:(void(^)(void))block;
- (void)executeOnMessageSync:(void(^)(void))block;
- (void)executeOnMain:(void(^)(void))block;
- (void)executeOnMainSync:(void(^)(void))block;
@end

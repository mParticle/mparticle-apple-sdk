#import "MParticleWebView.h"
#import "MPILogger.h"
#import "mParticle.h"
#import "MPStateMachine.h"
#import "MPApplication.h"

@interface MParticle ()
+ (dispatch_queue_t)messageQueue;
@end

@interface MParticleWebView ()

// options
@property (nonatomic) NSString *customAgent;
@property (nonatomic, assign) BOOL shouldCollect;
@property (nonatomic) NSString *defaultAgent;

@property (nonatomic) NSDate *initializedDate;
@property (nonatomic) NSString *resolvedAgent; // final result
@property (nonatomic, assign) BOOL isCollecting;
@property (nonatomic, assign) int retryCount;

#if TARGET_OS_IOS == 1
@property (nonatomic) WKWebView *webView;
#endif

@end

@implementation MParticleWebView

- (void)startWithCustomUserAgent:(nullable NSString *)customUserAgent shouldCollect:(BOOL)shouldCollect defaultAgentOverride:(nullable NSString *)defaultAgent {
    self.initializedDate = [NSDate date];
    self.customAgent = customUserAgent;
    self.shouldCollect = shouldCollect;
    self.defaultAgent = defaultAgent ?: [self originalDefaultAgent];
    self.retryCount = 0;
    [self startCollectionIfNecessary];
}

- (void)startCollectionIfNecessary {
    if (self.customAgent != nil) {
        self.resolvedAgent = self.customAgent;
    } else if (![self canAndShouldCollect]) {
        self.resolvedAgent = self.defaultAgent;
    }
    if (self.resolvedAgent != nil) {
        return;
    }
    [self evaluateAgent];
}

- (BOOL)canAndShouldCollect {
#if TARGET_OS_IOS != 1
    return NO;
#else
    return self.shouldCollect;
#endif
}

- (void)evaluateAgent {
#if TARGET_OS_IOS == 1
    dispatch_async([MParticle messageQueue], ^{
        self.isCollecting = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.webView) {
                self.webView = [[WKWebView alloc] initWithFrame:CGRectZero];
            }
            MPILogVerbose(@"Getting user agent");
            [self.webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                if (result == nil || error != nil) {
                    MPILogVerbose(@"Error collecting user agent: %@", error);
                }
                if (result == nil) {
                    if (self.retryCount < 10) {
                        self.retryCount += 1;
                        MPILogVerbose(@"User agent collection failed (count=%@), retrying", @(self.retryCount));
                        self.webView = nil;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self evaluateAgent];
                        });
                        return;
                    } else {
                        MPILogVerbose(@"Falling back on default user agent");
                        self.resolvedAgent = self.defaultAgent;
                    }
                } else {
                    MPILogVerbose(@"Finished getting user agent");
                    self.resolvedAgent = result;
                }
                self.webView = nil;
                dispatch_async([MParticle messageQueue], ^{
                    self.isCollecting = NO;
                });
            }];
        });
    });
#endif
}

- (BOOL)shouldDelayUpload:(NSTimeInterval)maxWaitTime {
    if (self.resolvedAgent || !self.isCollecting || !self.initializedDate) {
        return NO;
    }
    
    NSTimeInterval timeInterval = -1 * [self.initializedDate timeIntervalSinceNow];
    if (timeInterval > maxWaitTime) {
        static BOOL printedMessage = NO;
        if (!printedMessage) {
            printedMessage = YES;
            MPILogDebug(@"Max wait time exceeded for user agent");
        }
        return NO;
    }
    static BOOL printedMessageDelay = NO;
    if (!printedMessageDelay) {
        printedMessageDelay = YES;
        MPILogVerbose(@"Delaying initial upload for user agent");
    }
    return YES;
}

- (nullable NSString *)userAgent {
    return self.resolvedAgent ?: self.defaultAgent;
}

- (nullable NSString *)originalDefaultAgent {
    return [NSString stringWithFormat:@"mParticle Apple SDK/%@", MParticle.sharedInstance.version];
}

@end

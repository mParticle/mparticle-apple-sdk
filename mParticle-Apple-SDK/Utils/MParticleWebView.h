#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface MParticleWebView : NSObject

- (void)startWithCustomUserAgent:(nullable NSString *)customUserAgent shouldCollect:(BOOL)shouldCollect defaultAgentOverride:(nullable NSString *)defaultAgent;
- (BOOL)shouldDelayUpload:(NSTimeInterval)maxWaitTime;
- (nullable NSString *)userAgent;
- (nullable NSString *)originalDefaultAgent;

@end

NS_ASSUME_NONNULL_END

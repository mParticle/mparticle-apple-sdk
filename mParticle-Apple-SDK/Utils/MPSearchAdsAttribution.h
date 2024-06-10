#import <Foundation/Foundation.h>

#if TARGET_OS_IOS == 1
@interface MPSearchAdsAttribution : NSObject

- (void)requestAttributionDetailsWithBlock:(void (^ _Nonnull)(void))completionHandler requestsCompleted:(int)requestsCompleted;

@end
#endif

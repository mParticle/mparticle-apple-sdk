#import <Foundation/Foundation.h>

@class MPSession;

#pragma mark - MPResponseEvents
@interface MPResponseEvents : NSObject

+ (void)parseConfiguration:(nonnull NSDictionary *)configuration sessionId:(nullable NSNumber *)sessionId;

@end

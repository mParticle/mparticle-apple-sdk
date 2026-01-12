#ifndef __mParticle__Bracket__
#define __mParticle__Bracket__

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPBracket : NSObject

@property (nonatomic, assign) int64_t mpId;
@property (nonatomic, assign) short low;
@property (nonatomic, assign) short high;

- (instancetype)initWithMpId:(int64_t)mpId low:(short)low high:(short)high;
- (BOOL)shouldForward;
- (BOOL)isEqualToBracket:(MPBracket *)bracket;

@end

NS_ASSUME_NONNULL_END

#endif

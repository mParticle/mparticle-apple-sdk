//
//  MPIdentityApiManager.h
//

#import <Foundation/Foundation.h>
#import "MPIdentityApiRequest.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^MPIdentityApiManagerCallback)(NSNumber *_Nullable newMPID, NSError *_Nullable error);
typedef void (^MPIdentityApiManagerModifyCallback)(NSError *_Nullable error);

@interface MPIdentityApiManager : NSObject

- (void)identify:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)loginRequest:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)logout:(MPIdentityApiRequest *)logoutRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)modify:(MPIdentityApiRequest *)modifyRequest completion:(nullable MPIdentityApiManagerModifyCallback)completion;

@end

NS_ASSUME_NONNULL_END

//
//  MPIdentity.h
//


#import <Foundation/Foundation.h>
#import "MParticleUser.h"
#import "MPIdentityApiRequest.h"
#import "MPIdentityApiResult.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^MPIdentityApiResultCallback)(MPIdentityApiResult *_Nullable user, NSError *_Nullable error);

@interface MPIdentityApi : NSObject

@property(nonatomic, strong, readonly, nullable) MParticleUser *currentUser;

- (void)login:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiResultCallback)completion;

- (void)loginWithCompletion:(nullable MPIdentityApiResultCallback)completion;

- (void)logout:(MPIdentityApiRequest *)logoutRequest completion:(nullable MPIdentityApiResultCallback)completion;

- (void)logoutWithCompletion:(nullable MPIdentityApiResultCallback)completion;

- (void)modify:(MPIdentityApiRequest *)modifyRequest completion:(nullable MPIdentityApiResultCallback)completion;

@end

NS_ASSUME_NONNULL_END

//
//  MPIdentityApi.h
//


#import <Foundation/Foundation.h>
#import "MParticleUser.h"
#import "MPIdentityApiRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPIdentityApiResult : NSObject

@property(nonatomic, strong, readwrite, nonnull) MParticleUser *user;

@end

typedef void (^MPIdentityApiResultCallback)(MPIdentityApiResult *_Nullable apiResult, NSError *_Nullable error);

@interface MPIdentityApi : NSObject

@property(nonatomic, strong, readonly, nullable) MParticleUser *currentUser;

- (void)identify:(MPIdentityApiRequest *)identifyRequest completion:(nullable MPIdentityApiResultCallback)completion;

- (void)identifyWithCompletion:(nullable MPIdentityApiResultCallback)completion;

- (void)login:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiResultCallback)completion;

- (void)loginWithCompletion:(nullable MPIdentityApiResultCallback)completion;

- (void)logout:(MPIdentityApiRequest *)logoutRequest completion:(nullable MPIdentityApiResultCallback)completion;

- (void)logoutWithCompletion:(nullable MPIdentityApiResultCallback)completion;

- (void)modify:(MPIdentityApiRequest *)modifyRequest completion:(nullable MPIdentityApiResultCallback)completion;

@end

@interface MPIdentityHTTPErrorResponse : NSObject

@property (nonatomic) NSInteger httpCode;
@property (nonatomic, nullable) NSString *code;
@property (nonatomic, nullable) NSString *message;

@end

NS_ASSUME_NONNULL_END

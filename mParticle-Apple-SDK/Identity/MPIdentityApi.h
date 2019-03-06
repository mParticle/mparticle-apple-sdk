//
//  MPIdentityApi.h
//


#import <Foundation/Foundation.h>
#import "MParticleUser.h"
#import "MPIdentityApiRequest.h"
#import "FilteredMParticleUser.h"
#import "FilteredMPIdentityApiRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPIdentityChange : NSObject

@property(nonatomic, strong, readwrite, nonnull) MParticleUser *changedUser;
@property(nonatomic) MPUserIdentity changedIdentity;

@end

@interface MPIdentityApiResult : NSObject

@property(nonatomic, strong, readwrite, nonnull) MParticleUser *user;

@end

@interface MPModifyApiResult : MPIdentityApiResult

@property(nonatomic, strong, readwrite, nonnull) NSArray<MPIdentityChange *> *identityChanges;

@end

typedef void (^MPIdentityApiResultCallback)(MPIdentityApiResult *_Nullable apiResult, NSError *_Nullable error);

typedef void (^MPModifyApiResultCallback)(MPModifyApiResult *_Nullable apiResult, NSError *_Nullable error);

@interface MPIdentityApi : NSObject

@property(nonatomic, strong, readonly, nullable) MParticleUser *currentUser;

@property(nonatomic, strong, readonly, nonnull) NSString *deviceApplicationStamp;

- (nullable MParticleUser *)getUser:(NSNumber *)mpId;

- (nonnull NSArray<MParticleUser *> *)getAllUsers;

- (void)identify:(MPIdentityApiRequest *)identifyRequest completion:(nullable MPIdentityApiResultCallback)completion;

- (void)identifyWithCompletion:(nullable MPIdentityApiResultCallback)completion;

- (void)login:(MPIdentityApiRequest *)loginRequest completion:(nullable MPIdentityApiResultCallback)completion;

- (void)loginWithCompletion:(nullable MPIdentityApiResultCallback)completion;

- (void)logout:(MPIdentityApiRequest *)logoutRequest completion:(nullable MPIdentityApiResultCallback)completion;

- (void)logoutWithCompletion:(nullable MPIdentityApiResultCallback)completion;

- (void)modify:(MPIdentityApiRequest *)modifyRequest completion:(nullable MPModifyApiResultCallback)completion;

@end

@interface MPIdentityHTTPErrorResponse : NSObject

@property (nonatomic) NSInteger httpCode;
@property (nonatomic, assign) MPIdentityErrorResponseCode code;
@property (nonatomic, nullable) NSString *message;
@property (nonatomic, nullable) NSError *innerError;

@end

NS_ASSUME_NONNULL_END

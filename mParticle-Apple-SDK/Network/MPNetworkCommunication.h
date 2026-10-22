#import <Foundation/Foundation.h>
@import mParticle_Apple_SDK_Swift;

@class MPIdentityApiRequest;
@class MPIdentityHTTPSuccessResponse;
@class MPIdentityHTTPBaseSuccessResponse;
@class MPIdentityHTTPModifySuccessResponse;

typedef NS_ENUM(NSInteger, MPNetworkError) {
    MPNetworkErrorTimeout = 1,
    MPNetworkErrorDelayedSegments
};

typedef void (^MPIdentityApiManagerCallback)(MPIdentityHTTPBaseSuccessResponse *_Nullable httpResponse, NSError *_Nullable error);
typedef void (^MPIdentityApiManagerModifyCallback)(MPIdentityHTTPModifySuccessResponse *_Nullable httpResponse, NSError *_Nullable error);

/// The network layer's members that are still Objective-C: the identity request entry points, which
/// build each request from its Objective-C DTO. The Swift class sends them and holds the rest.
@interface MPNetworkCommunication_PRIVATE (ObjCBoundary)

- (void)identify:(MPIdentityApiRequest *_Nonnull)identifyRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)login:(MPIdentityApiRequest *_Nullable)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)logout:(MPIdentityApiRequest *_Nullable)logoutRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)modify:(MPIdentityApiRequest *_Nonnull)modifyRequest completion:(nullable MPIdentityApiManagerModifyCallback)completion;
- (void)modifyDeviceID:(NSString *_Nonnull)deviceIdType value:(NSString *_Nonnull)value oldValue:(NSString *_Nonnull)oldValue;

@end

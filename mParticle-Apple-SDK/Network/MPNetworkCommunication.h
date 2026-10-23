#import <Foundation/Foundation.h>
@import mParticle_Apple_SDK_Swift;

@class MPAudience;
@class MPIdentityApiRequest;
@class MPIdentityHTTPSuccessResponse;
@class MPIdentityHTTPBaseSuccessResponse;
@class MPIdentityHTTPModifySuccessResponse;
@protocol MPConnectorFactoryProtocol;

typedef NS_ENUM(NSInteger, MPNetworkError) {
    MPNetworkErrorTimeout = 1,
    MPNetworkErrorDelayedSegments
};

typedef void(^ _Nonnull MPAudienceResponseHandler)(BOOL success, NSArray<MPAudience *> * _Nullable currentAudience, NSError * _Nullable error);
typedef void(^ _Nonnull MPUploadsCompletionHandler)(void);

typedef void (^MPIdentityApiManagerCallback)(MPIdentityHTTPBaseSuccessResponse *_Nullable httpResponse, NSError *_Nullable error);
typedef void (^MPIdentityApiManagerModifyCallback)(MPIdentityHTTPModifySuccessResponse *_Nullable httpResponse, NSError *_Nullable error);
typedef void(^ _Nonnull MPConfigCompletionHandler)(BOOL success);

/// The network layer's members that are still Objective-C: the connector, the config, audience
/// and upload requests, and the identity requests. The Swift class holds the host, the
/// identity-request flag and the endpoint URLs.
@interface MPNetworkCommunication_PRIVATE (ObjCBoundary) <MPBackendUploadNetworking>

+ (void)setConnectorFactory:(NSObject<MPConnectorFactoryProtocol> *_Nullable)connectorFactory;
+ (NSObject<MPConnectorFactoryProtocol> *_Nullable)connectorFactory;

- (NSObject<MPConnectorProtocol> *_Nonnull)makeConnector;
- (void)requestConfig:(nullable NSObject<MPConnectorProtocol> *)connector withCompletionHandler:(MPConfigCompletionHandler)completionHandler;
- (void)requestAudiencesWithCompletionHandler:(MPAudienceResponseHandler)completionHandler;
- (void)upload:(nonnull NSArray<MPUpload *> *)uploads completionHandler:(MPUploadsCompletionHandler)completionHandler;

- (void)identify:(MPIdentityApiRequest *_Nonnull)identifyRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)login:(MPIdentityApiRequest *_Nullable)loginRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)logout:(MPIdentityApiRequest *_Nullable)logoutRequest completion:(nullable MPIdentityApiManagerCallback)completion;
- (void)modify:(MPIdentityApiRequest *_Nonnull)modifyRequest completion:(nullable MPIdentityApiManagerModifyCallback)completion;
- (void)modifyDeviceID:(NSString *_Nonnull)deviceIdType value:(NSString *_Nonnull)value oldValue:(NSString *_Nonnull)oldValue;

@end

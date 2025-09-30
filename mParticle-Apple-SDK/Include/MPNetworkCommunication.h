#import <Foundation/Foundation.h>

@class MPURL;
@class MPSession;
@class MPUpload;
@class MPAudience;
@class MPIdentityApiRequest;
@class MPIdentityHTTPSuccessResponse;
@class MPIdentityHTTPBaseSuccessResponse;
@class MPIdentityHTTPModifySuccessResponse;
@protocol MPConnectorProtocol;
@protocol MPConnectorFactoryProtocol;


extern NSString * _Nonnull const kMPURLScheme;

typedef NS_ENUM(NSInteger, MPNetworkError) {
    MPNetworkErrorTimeout = 1,
    MPNetworkErrorDelayedSegments
};

typedef void(^ _Nonnull MPAudienceResponseHandler)(BOOL success, NSArray<MPAudience *> * _Nullable currentAudience, NSError * _Nullable error);
typedef void(^ _Nonnull MPUploadsCompletionHandler)(void);

typedef void (^MPIdentityApiManagerCallback)(MPIdentityHTTPBaseSuccessResponse *_Nullable httpResponse, NSError *_Nullable error);
typedef void (^MPIdentityApiManagerModifyCallback)(MPIdentityHTTPModifySuccessResponse *_Nullable httpResponse, NSError *_Nullable error);
typedef void(^ _Nonnull MPConfigCompletionHandler)(BOOL success);

@interface MPNetworkCommunication_PRIVATE : NSObject

@property (nonatomic, strong, readonly, nullable) MPURL *audienceURL;
@property (nonatomic, strong, readonly, nullable) MPURL *configURL;
@property (nonatomic, strong, readonly, nullable) MPURL *eventURL;
@property (nonatomic, strong, readonly, nullable) MPURL *identifyURL;
@property (nonatomic, strong, readonly, nullable) MPURL *loginURL;
@property (nonatomic, strong, readonly, nullable) MPURL *logoutURL;
@property (nonatomic, strong, readonly, nullable) MPURL *modifyURL;
@property (nonatomic, strong, readonly, nullable) MPURL *aliasURL;

- (nullable MPURL *)eventURLForUpload:(nonnull MPUpload *)mpUpload;
- (nullable MPURL *)aliasURLForUpload:(nonnull MPUpload *)mpUpload;

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

+ (void)parseConfiguration:(nonnull NSDictionary *)configuration;

@end

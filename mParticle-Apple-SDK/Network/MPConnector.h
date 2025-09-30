#import <Foundation/Foundation.h>
#import "MPConnectorProtocol.h"
#import "MPConnectorResponseProtocol.h"

@class MPURL;

typedef NS_ENUM(NSInteger, HTTPStatusCode) {
    HTTPStatusCodeSuccess = 200,
    HTTPStatusCodeCreated = 201,
    HTTPStatusCodeAccepted = 202,
    HTTPStatusCodeNoContent = 204,
    HTTPStatusCodeNotModified = 304,
    HTTPStatusCodeBadRequest = 400,
    HTTPStatusCodeUnauthorized = 401,
    HTTPStatusCodeForbidden = 403,
    HTTPStatusCodeNotFound = 404,
    HTTPStatusCodeTimeout = 408,
    HTTPStatusCodeTooManyRequests = 429,
    HTTPStatusCodeServerError = 500,
    HTTPStatusCodeNotImplemented = 501,
    HTTPStatusCodeBadGateway = 502,
    HTTPStatusCodeServiceUnavailable = 503,
    HTTPStatusCodeNetworkAuthenticationRequired = 511
};

@interface MPConnectorResponse : NSObject<MPConnectorResponseProtocol>

@property (nonatomic, nullable) NSData *data;
@property (nonatomic, nullable) NSError *error;
@property (nonatomic) NSTimeInterval downloadTime;
@property (nonatomic, nullable) NSHTTPURLResponse *httpResponse;

@end


@interface MPConnector : NSObject<MPConnectorProtocol>

- (nonnull NSObject<MPConnectorResponseProtocol> *)responseFromGetRequestToURL:(nonnull MPURL *)url;
- (nonnull NSObject<MPConnectorResponseProtocol> *)responseFromPostRequestToURL:(nonnull MPURL *)url message:(nullable NSString *)message serializedParams:(nullable NSData *)serializedParams secret:(nullable NSString *)secret;

@end

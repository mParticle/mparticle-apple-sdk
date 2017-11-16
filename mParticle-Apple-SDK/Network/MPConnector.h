#import <Foundation/Foundation.h>

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

@interface MPConnector : NSObject

@property (nonatomic, unsafe_unretained, readonly) BOOL active;
@property (nonatomic, unsafe_unretained, readonly, getter = characterEncoding) NSStringEncoding characterEncoding;
@property (nonatomic, strong, nonnull) NSString *connectionId;

- (void)asyncGetDataFromURL:(nonnull NSURL *)url completionHandler:(void (^ _Nonnull)(NSData * _Nullable data, NSError * _Nullable error, NSTimeInterval downloadTime, NSHTTPURLResponse * _Nullable httpResponse))completionHandler;
- (void)asyncPostDataFromURL:(nonnull NSURL *)url message:(nullable NSString *)message serializedParams:(nullable NSData *)serializedParams completionHandler:(void (^ _Nonnull)(NSData * _Nullable data, NSError * _Nullable error, NSTimeInterval downloadTime, NSHTTPURLResponse * _Nullable httpResponse))completionHandler;
- (void)cancelRequest;

@end

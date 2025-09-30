#ifndef MPConnectorProtocol_h
#define MPConnectorProtocol_h

#import "MPConnectorResponseProtocol.h"
@class MPURL;

@protocol MPConnectorProtocol<NSObject>

- (nonnull NSObject<MPConnectorResponseProtocol> *)responseFromGetRequestToURL:(nonnull MPURL *)url;
- (nonnull NSObject<MPConnectorResponseProtocol> *)responseFromPostRequestToURL:(nonnull MPURL *)url message:(nullable NSString *)message serializedParams:(nullable NSData *)serializedParams secret:(nullable NSString *)secret;

@end

#endif /* MPConnectorProtocol_h */

#import "MPNetworkCommunication.h"

@class MPURL;
@class MPConnectorConfiguration;

@interface MPNetworkCommunication_PRIVATE(Tests)

- (nonnull NSString *)defaultHostWithSubdomain:(nonnull NSString *)subdomain apiKey:(nonnull NSString *)apiKey;
- (nonnull NSString *)defaultEventHost;
- (nonnull NSString *)defaultIdentityHost;

- (nonnull MPURL *)configURL;
- (nonnull MPURL *)modifyURL;
- (nonnull MPURL *)identifyURL;
- (nonnull MPConnectorConfiguration *)connectorConfiguration;

@end

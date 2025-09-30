#import "MPNetworkCommunication.h"

@class MPURL;

extern NSString * _Nonnull const kMPURLHostEventSubdomain;
extern NSString * _Nonnull const kMPURLHostIdentitySubdomain;

@interface MPNetworkCommunication_PRIVATE(Tests)

- (nonnull NSString *)defaultHostWithSubdomain:(nonnull NSString *)subdomain apiKey:(nonnull NSString *)apiKey enableDirectRouting:(BOOL)enableDirectRouting;
- (nonnull NSString *)defaultEventHost;
- (nonnull NSString *)defaultIdentityHost;

- (nonnull MPURL *)configURL;
- (nonnull MPURL *)eventURL;
- (nonnull MPURL *)aliasURL;
- (nonnull MPURL *)modifyURL;
- (nonnull MPURL *)identifyURL;

@end

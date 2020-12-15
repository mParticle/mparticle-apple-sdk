#import "MPNetworkCommunication.h"

@class MPURL;

@interface MPNetworkCommunication(Tests)

- (MPURL *)configURL;
- (MPURL *)eventURL;
- (MPURL *)aliasURL;
- (MPURL *)modifyURL;
- (MPURL *)identifyURL;

@end

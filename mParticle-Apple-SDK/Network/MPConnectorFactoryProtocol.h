#ifndef MPConnectorFactoryProtocol_h
#define MPConnectorFactoryProtocol_h

#import "MPConnectorProtocol.h"
@protocol MPConnectorFactoryProtocol
- (NSObject<MPConnectorProtocol> * _Nonnull)createConnector;
@end

#endif /* MPConnectorFactoryProtocol_h */

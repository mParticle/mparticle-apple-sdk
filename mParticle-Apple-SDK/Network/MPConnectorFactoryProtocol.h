#ifndef MPConnectorFactoryProtocol_h
#define MPConnectorFactoryProtocol_h

#import <Foundation/Foundation.h>

@protocol MPConnectorProtocol;

@protocol MPConnectorFactoryProtocol
- (NSObject<MPConnectorProtocol> * _Nonnull)createConnector;
@end

#endif /* MPConnectorFactoryProtocol_h */

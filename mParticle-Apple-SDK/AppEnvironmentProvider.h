#import <Foundation/Foundation.h>

@protocol AppEnvironmentProviderProtocol
- (BOOL)isAppExtension;
@end

@interface AppEnvironmentProvider : NSObject<AppEnvironmentProviderProtocol>
- (BOOL)isAppExtension;
@end

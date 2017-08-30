#import <Foundation/Foundation.h>

@interface MPKitAPI : NSObject

- (NSDictionary<NSString *, NSString *> *)integrationAttributes;
- (NSDictionary<NSNumber *, NSString *> *)userIdentities;
- (NSDictionary<NSString *, id> *)userAttributes;

@end

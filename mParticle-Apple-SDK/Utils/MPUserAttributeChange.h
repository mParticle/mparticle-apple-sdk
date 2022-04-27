#import <Foundation/Foundation.h>

@interface MPUserAttributeChange : NSObject

@property (nonatomic, strong, nonnull) NSString *key;
@property (nonatomic, strong, nullable) NSDate *timestamp;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *userAttributes;
@property (nonatomic, strong, nullable) id value;
@property (nonatomic, strong, nullable) id valueToLog;
@property (nonatomic, readonly) BOOL changed;
@property (nonatomic) BOOL deleted;
@property (nonatomic) BOOL isArray;

- (nullable instancetype)initWithUserAttributes:(nullable NSDictionary<NSString *, id> *)userAttributes key:(nonnull NSString *)key value:(nullable id)value;

@end

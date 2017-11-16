#import <Foundation/Foundation.h>

@interface MPIUserDefaults : NSObject

+ (nonnull instancetype)standardUserDefaults;
- (nullable id)mpObjectForKey:(nonnull NSString *)key userId:(nonnull NSNumber *)userId;
- (void)setMPObject:(nullable id)value forKey:(nonnull NSString *)key userId:(nonnull NSNumber *)userId;
- (void)removeMPObjectForKey:(nonnull NSString *)key userId:(nonnull NSNumber *)userId;
- (void)removeMPObjectForKey:(nonnull NSString *)key;
- (nullable id)objectForKeyedSubscript:(nonnull NSString *const)key;
- (void)setObject:(nullable id)obj forKeyedSubscript:(nonnull NSString *)key;
- (void)synchronize;
- (void)migrateUserKeysWithUserId:(nonnull NSNumber *)userId;

@end

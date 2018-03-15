#import <Foundation/Foundation.h>
#import "sqlite3.h"

@interface MPDatabaseMigrationController : NSObject

@property (nonatomic, readonly, nonnull) NSArray *databaseVersions;

- (nonnull instancetype)initWithDatabaseVersions:(nonnull NSArray<NSNumber *> *)databaseVersions;
- (void)migrateDatabaseFromVersion:(nonnull NSNumber *)oldVersion;
- (nullable NSNumber *)needsMigration;

@end

#import "MPEnums.h"

@class UIApplication;

extern NSString * _Nonnull const kMPApplicationInformationKey;

@interface MPApplication_PRIVATE : NSObject <NSCopying>

@property (nonatomic, strong, nonnull) NSNumber *lastUseDate;
@property (nonatomic, strong, nullable) NSNumber *launchCount;
@property (nonatomic, strong, nullable) NSNumber *launchCountSinceUpgrade;
@property (nonatomic, strong, nullable) NSString *storedBuild;
@property (nonatomic, strong, nullable) NSString *storedVersion;
@property (nonatomic, strong, nullable) NSNumber *upgradeDate;
@property (nonatomic, strong, readonly, nonnull) NSString *architecture;
@property (nonatomic, strong, readonly, nullable) NSString *build __attribute__((const));
@property (nonatomic, strong, readonly, nullable) NSString *buildUUID;
@property (nonatomic, strong, readonly, nullable) NSString *bundleIdentifier __attribute__((const));
@property (nonatomic, strong, readonly, nonnull) NSNumber *firstSeenInstallation __attribute__((const));
@property (nonatomic, strong, readonly, nonnull) NSNumber *initialLaunchTime;
@property (nonatomic, strong, readonly, nullable) NSString *name __attribute__((const));
@property (nonatomic, strong, readonly, nonnull) NSNumber *pirated;
@property (nonatomic, strong, readonly, nullable) NSString *version __attribute__((const));
@property (nonatomic, readonly) MPEnvironment environment __attribute__((const));

+ (nullable NSString *)appStoreReceipt;
+ (void)markInitialLaunchTime;
+ (void)updateLastUseDate:(nonnull NSDate *)date;
+ (void)updateLaunchCountsAndDates;
+ (void)updateStoredVersionAndBuildNumbers;
+ (nonnull NSDictionary *)appImageInfo;
+ (nullable UIApplication *)sharedUIApplication;
- (nonnull NSDictionary<NSString *, id> *)dictionaryRepresentation;

@end

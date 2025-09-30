#import "MPEnums.h"

@class UIApplication;

extern NSString * _Nonnull const kMPApplicationInformationKey;
extern NSString * _Nonnull const kMPApplicationNameKey;
extern NSString * _Nonnull const kMPApplicationVersionKey;
extern NSString * _Nonnull const kMPAppPackageNameKey;
extern NSString * _Nonnull const kMPAppInitialLaunchTimeKey;
extern NSString * _Nonnull const kMPAppBuildNumberKey;
extern NSString * _Nonnull const kMPAppBuildUUIDKey;
extern NSString * _Nonnull const kMPAppArchitectureKey;
extern NSString * _Nonnull const kMPAppPiratedKey;
extern NSString * _Nonnull const kMPAppDeploymentTargetKey;
extern NSString * _Nonnull const kMPAppBuildSDKKey;
extern NSString * _Nonnull const kMPAppUpgradeDateKey;
extern NSString * _Nonnull const kMPAppLaunchCountKey;
extern NSString * _Nonnull const kMPAppLaunchCountSinceUpgradeKey;
extern NSString * _Nonnull const kMPAppLastUseDateKey;
extern NSString * _Nonnull const kMPAppStoredVersionKey;
extern NSString * _Nonnull const kMPAppStoredBuildKey;
extern NSString * _Nonnull const kMPAppEnvironmentKey;
extern NSString * _Nonnull const kMPAppStoreReceiptKey;
extern NSString * _Nonnull const kMPAppImageBaseAddressKey;
extern NSString * _Nonnull const kMPAppImageSizeKey;
extern NSString * _Nonnull const kMPAppSideloadKitsCountKey;

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

#import "MPEnums.h"

@class MPSession;
@class MPNotificationController_PRIVATE;
@class MPConsumerInfo;
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    @class CLLocation;
    @class MPLocationManager_PRIVATE;
#endif
#endif
@class MPCustomModule;
@class MPDataPlanOptions;
@class MPLaunchInfo;

@interface MPStateMachine_PRIVATE : NSObject

@property (nonatomic, strong, nonnull) NSString *apiKey __attribute__((const));
@property (nonatomic, strong, nonnull) MPConsumerInfo *consumerInfo;
@property (nonatomic, weak, nullable) MPSession *currentSession;
@property (nonatomic, strong, nullable) NSArray<MPCustomModule *> *customModules;
@property (nonatomic, strong, nullable) NSString *exceptionHandlingMode;
@property (nonatomic, strong, nullable) NSNumber *crashMaxPLReportLength;
@property (nonatomic, strong, nullable) NSString *locationTrackingMode;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
@property (nonatomic, strong, nullable) CLLocation *location;
@property (nonatomic, strong, nullable) MPLocationManager_PRIVATE *locationManager;
#endif
#endif
@property (nonatomic, strong, nullable) NSString *networkPerformanceMeasuringMode;
@property (nonatomic, strong, nullable) NSString *pushNotificationMode;
@property (nonatomic, strong, nonnull) NSString *secret __attribute__((const));
@property (nonatomic, strong, nonnull) NSDate *startTime;
@property (nonatomic, strong, nullable) MPLaunchInfo *launchInfo;
@property (nonatomic, strong, readonly, nullable) NSString *deviceTokenType;
@property (nonatomic, strong, readonly, nonnull) NSNumber *firstSeenInstallation;
@property (nonatomic, strong, readonly, nullable) NSDate *launchDate;
@property (nonatomic, strong, readonly, nullable) NSArray *triggerEventTypes;
@property (nonatomic, strong, readonly, nullable) NSArray *triggerMessageTypes;
@property (nonatomic) MPILogLevel logLevel;
@property (nonatomic) MPInstallationType installationType;
@property (nonatomic, readonly) BOOL backgrounded;
@property (nonatomic, readonly) BOOL dataRamped;
@property (nonatomic) BOOL optOut;
@property (nonatomic) NSNumber * _Nullable attAuthorizationStatus;
@property (nonatomic) NSNumber * _Nullable attAuthorizationTimestamp;
@property (nonatomic, strong, nonnull) NSNumber *aliasMaxWindow;
@property (nonatomic, strong, nonnull) NSDictionary *searchAdsInfo;
@property (nonatomic) BOOL automaticSessionTracking;
@property (nonatomic) BOOL allowASR;
@property (nonatomic, nullable) MPDataPlanOptions *dataPlanOptions;
@property (nonatomic) BOOL enableDirectRouting;
@property (nonatomic) BOOL enableAudienceAPI;
@property (nonatomic) BOOL enableIdentityCaching;

+ (MPEnvironment)environment;
+ (void)setEnvironment:(MPEnvironment)environment;
+ (nullable NSString *)provisioningProfileString;
+ (BOOL)runningInBackground;
+ (void)setRunningInBackground:(BOOL)background;
+ (BOOL)isAppExtension;
- (void)configureCustomModules:(nullable NSArray<NSDictionary *> *)customModuleSettings;
- (void)configureRampPercentage:(nullable NSNumber *)rampPercentage;
- (void)configureTriggers:(nullable NSDictionary *)triggerDictionary;
- (void)configureAliasMaxWindow:(nullable NSNumber *)aliasMaxWindow;
- (void)configureDataBlocking:(nullable NSDictionary *)blockSettings;
- (void)setMinUploadDate:(nullable NSDate *)date uploadType:(MPUploadType)uploadType;
- (nonnull NSDate *)minUploadDateForUploadType:(MPUploadType)uploadType;
- (void)requestAttributionDetailsWithBlock:(void (^ _Nonnull)(void))completionHandler requestsCompleted:(int)requestsCompleted;

@end

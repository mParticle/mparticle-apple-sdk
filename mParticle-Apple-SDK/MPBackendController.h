#import "MPEnums.h"
#import "MPUploadSettings.h"
@import mParticle_Apple_SDK_Swift;

#if TARGET_OS_IOS == 1
    @class MParticleUserNotification;
#endif

@class MPSession;
@class MPMessage;
@class MPNetworkPerformance;
@class MPBaseEvent;
@class MPEvent;
@class MPCommerceEvent;
@class MPConsentState;
@class MParticleSession;
@class MPNetworkOptions;
@class MPNetworkCommunication_PRIVATE;

@protocol MPBackendControllerProtocol
- (void)setOptOut:(BOOL)optOutStatus completionHandler:(void (^ _Nonnull)(BOOL optOut, MPExecStatus execStatus))completionHandler;
- (nonnull NSMutableDictionary<NSString *, id> *)userAttributesForUserId:(nonnull NSNumber *)userId;
- (void)startWithKey:(nonnull NSString *)apiKey secret:(nonnull NSString *)secret networkOptions:(nullable MPNetworkOptions *)networkOptions firstRun:(BOOL)firstRun installationType:(MPInstallationType)installationType startKitsAsync:(BOOL)startKitsAsync consentState:(MPConsentState *_Nullable)consentState completionHandler:(dispatch_block_t _Nonnull)completionHandler;
- (void)prepareBatchesForUpload:(nonnull MPUploadSettings *)uploadSettings NS_SWIFT_NAME(prepareBatches(forUpload:));
- (MParticleSession* _Nullable)tempSession;
- (void)endSession;
- (void)beginTimedEvent:(nonnull MPEvent *)event completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)logEvent:(nonnull MPEvent *)event completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (nullable MPEvent *)eventWithName:(nonnull NSString *)eventName;
- (void)logBaseEvent:(nonnull MPBaseEvent *)event completionHandler:(void (^ _Nonnull)(MPBaseEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)logCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent completionHandler:(void (^ _Nonnull)(MPCommerceEvent * _Nonnull commerceEvent, MPExecStatus execStatus))completionHandler;
- (void)logNetworkPerformanceMeasurement:(nonnull MPNetworkPerformance *)networkPerformance completionHandler:(void (^ _Nullable)(MPNetworkPerformance * _Nonnull networkPerformance, MPExecStatus execStatus))completionHandler;
- (void)logScreen:(nonnull MPEvent *)event completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)leaveBreadcrumb:(nonnull MPEvent *)event completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)logError:(nullable NSString *)message exception:(nullable NSException *)exception topmostContext:(nullable id)topmostContext eventInfo:(nullable NSDictionary *)eventInfo completionHandler:(void (^ _Nonnull)(NSString * _Nullable message, MPExecStatus execStatus))completionHandler;
- (void)logCrash:(nullable NSString *)message stackTrace:(nullable NSString *)stackTrace plCrashReport:(nonnull NSString *)plCrashReport completionHandler:(void (^ _Nonnull)(NSString * _Nullable message, MPExecStatus execStatus)) completionHandler;
- (MPExecStatus)setSessionAttribute:(nonnull MPSession *)session key:(nonnull NSString *)key value:(nonnull id)value;
- (nullable NSNumber *)incrementSessionAttribute:(nonnull MPSession *)session key:(nonnull NSString *)key byValue:(nonnull NSNumber *)value;
- (void)createTempSession;
- (void)beginSessionWithIsManual:(BOOL)isManual date:(nonnull NSDate *)date;
- (void)endSessionWithIsManual:(BOOL)isManual;
- (MPExecStatus)waitForKitsAndUploadWithCompletionHandler:(void (^ _Nullable)(void))completionHandler;

#if TARGET_OS_IOS == 1
- (void)logUserNotification:(nonnull MParticleUserNotification *)userNotification;
#endif

@property (nonatomic, readwrite) NSTimeInterval sessionTimeout;
@property (nonatomic) NSTimeInterval uploadInterval;
@property (nonatomic, strong, nullable) NSMutableSet<MPEvent *> *eventSet;
@property (strong, nullable) MPSession *session;
@end

@interface MPBackendController_PRIVATE : NSObject

@property (nonatomic, weak, nullable) id<MPBackendControllerDelegate> delegate;
@property (nonatomic, strong, nullable) NSMutableSet<MPEvent *> *eventSet;
@property (nonatomic, strong, nullable) MPNetworkCommunication_PRIVATE *networkCommunication;
@property (strong, nullable) MPSession *session;
@property (nonatomic, readwrite) NSTimeInterval sessionTimeout;
@property (nonatomic) NSTimeInterval uploadInterval;
@property (nonatomic, strong, readonly, nonnull) MPBackendSessionState *sessionState;
@property (nonatomic, readonly, nonnull) MPBackendEventLogger *eventLogger;
@property (nonatomic, readonly, nonnull) MPBackendIdentityWriter *identityWriter;
@property (nonatomic, readonly, nonnull) MPBackendStartupCoordinator *startupCoordinator;
@property (nonatomic, readonly, nonnull) MPBackendUploadCoordinator *uploadCoordinator;
/// The pending session, untyped so that a Swift implementation of the controller can hold it.
@property (nonatomic, strong, nullable) id pendingSessionStorage;

- (nonnull instancetype)initWithDelegate:(nonnull id<MPBackendControllerDelegate>)delegate;
- (void)beginSession;
- (void)endSession;
- (void)beginSessionWithIsManual:(BOOL)isManual date:(nonnull NSDate *)date;
- (void)endSessionWithIsManual:(BOOL)isManual;
- (void)createTempSession;
- (MPExecStatus)fetchAudiencesWithCompletionHandler:(void (^ _Nonnull)(NSArray * _Nullable currentAudiences, NSError * _Nullable error))completionHandler;
- (nullable NSNumber *)incrementSessionAttribute:(nonnull MPSession *)session key:(nonnull NSString *)key byValue:(nonnull NSNumber *)value;
- (nullable NSNumber *)incrementUserAttribute:(nonnull NSString *)key byValue:(nonnull NSNumber *)value;
- (void)logError:(nullable NSString *)message exception:(nullable NSException *)exception topmostContext:(nullable id)topmostContext eventInfo:(nullable NSDictionary *)eventInfo completionHandler:(void (^ _Nonnull)(NSString * _Nullable message, MPExecStatus execStatus))completionHandler;
- (void)logCrash:(nullable NSString *)message stackTrace:(nullable NSString *)stackTrace plCrashReport:(nonnull NSString *)plCrashReport completionHandler:(void (^ _Nonnull)(NSString * _Nullable message, MPExecStatus execStatus)) completionHandler;
- (void)logNetworkPerformanceMeasurement:(nonnull MPNetworkPerformance *)networkPerformance completionHandler:(void (^ _Nullable)(MPNetworkPerformance * _Nonnull networkPerformance, MPExecStatus execStatus))completionHandler;
- (void)setOptOut:(BOOL)optOutStatus completionHandler:(void (^ _Nonnull)(BOOL optOut, MPExecStatus execStatus))completionHandler;
- (MPExecStatus)setSessionAttribute:(nonnull MPSession *)session key:(nonnull NSString *)key value:(nonnull id)value;
- (void)setUserTag:(nonnull NSString *)key timestamp:(nonnull NSDate *)timestamp completionHandler:(void (^ _Nullable)(NSString * _Nonnull key, id _Nullable value, MPExecStatus execStatus))completionHandler;
- (void)setUserAttribute:(nonnull NSString *)key value:(nullable id)value timestamp:(nonnull NSDate *)timestamp completionHandler:(void (^ _Nullable)(NSString * _Nonnull key, id _Nullable value, MPExecStatus execStatus))completionHandler;
- (void)setUserAttribute:(nonnull NSString *)key values:(nullable NSArray<NSString *> *)values timestamp:(nonnull NSDate *)timestamp completionHandler:(void (^ _Nullable)(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus))completionHandler;
- (void)removeUserAttribute:(nonnull NSString *)key timestamp:(nonnull NSDate *)timestamp completionHandler:(void (^ _Nullable)(NSString * _Nullable key, id _Nullable value, MPExecStatus execStatus))completionHandler;
- (void)saveMessage:(nonnull MPMessage *)message updateSession:(BOOL)updateSession;
- (void)skipNextUpload;
- (MPExecStatus)waitForKitsAndUploadWithCompletionHandler:(void (^ _Nullable)(void))completionHandler;
- (nonnull NSMutableDictionary<NSString *, id> *)userAttributesForUserId:(nonnull NSNumber *)userId;
- (nonnull NSMutableArray<NSDictionary<NSString *, id> *> *)userIdentitiesForUserId:(nonnull NSNumber *)userId;

#if TARGET_OS_IOS == 1
- (void)handleDeviceTokenNotification:(nonnull NSNotification *)notification;
- (void)logUserNotification:(nonnull MParticleUserNotification *)userNotification;
#endif

@end

/// The controller's entry points that take or return Objective-C types the Swift module cannot see.
@interface MPBackendController_PRIVATE (ObjCBoundary) <MPBackendControllerProtocol>

+ (BOOL)checkAttribute:(nonnull NSDictionary *)attributesDictionary key:(nonnull NSString *)key value:(nonnull id)value error:(out NSError *__autoreleasing _Nullable * _Nullable)error;
+ (nonnull MPUploadBuilderContext *)uploadBuilderContextWithPersistence:(id<MPUploadEnrichmentPersistence> _Nonnull (^ _Nonnull)(void))persistence;
- (void)startWithKey:(nonnull NSString *)apiKey secret:(nonnull NSString *)secret networkOptions:(nullable MPNetworkOptions *)networkOptions firstRun:(BOOL)firstRun installationType:(MPInstallationType)installationType startKitsAsync:(BOOL)startKitsAsync consentState:(MPConsentState *_Nullable)consentState completionHandler:(dispatch_block_t _Nonnull)completionHandler;
- (void)prepareBatchesForUpload:(nonnull MPUploadSettings *)uploadSettings NS_SWIFT_NAME(prepareBatches(forUpload:));
- (void)prepareBatchesForUploadSettings:(nullable NSObject *)settings;
- (nonnull MParticleSession *)tempSession;
- (void)createPendingSessionWithUUID:(nonnull NSString *)uuid;
- (void)setPendingSessionStartTime:(double)timestamp;
- (void)clearPendingSession;
- (void)setUserIdentity:(nullable NSString *)identityString identityType:(MPUserIdentity)identityType timestamp:(nonnull NSDate *)timestamp completionHandler:(void (^ _Nonnull)(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus))completionHandler;
- (void)beginTimedEvent:(nonnull MPEvent *)event completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (nullable MPEvent *)eventWithName:(nonnull NSString *)eventName;
- (void)leaveBreadcrumb:(nonnull MPEvent *)event completionHandler:(void (^ _Nonnull)(MPEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)logBaseEvent:(nonnull MPBaseEvent *)event completionHandler:(void (^ _Nonnull)(MPBaseEvent * _Nonnull event, MPExecStatus execStatus))completionHandler;
- (void)logCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent completionHandler:(void (^ _Nonnull)(MPCommerceEvent * _Nonnull commerceEvent, MPExecStatus execStatus))completionHandler;

@end

#import "MPDataPlanFilter.h"
#import "MPListenerController.h"
#import "MParticleSwift.h"
#import "SettingsProvider.h"

@interface MParticle (Tests)
- (void)setOptOutCompletion:(MPExecStatus)execStatus optOut:(BOOL)optOut;
- (void)identifyNoDispatchCallback:(MPIdentityApiResult *_Nullable)apiResult
                             error:(NSError *_Nullable)error
                           options:(MParticleOptions *_Nonnull)options;
- (void)configureWithOptions:(MParticleOptions *_Nonnull)options;
- (void)startWithKeyCallback:(BOOL)firstRun
                     options:(MParticleOptions *_Nonnull)options
                userDefaults:(id<MPUserDefaultsProtocol>)userDefaults;
- (void)beginTimedEventCompletionHandler:(MPEvent *)event
                              execStatus:(MPExecStatus)execStatus;
- (void)logEventCallback:(MPEvent *)event execStatus:(MPExecStatus)execStatus;
- (void)logEvent:(MPBaseEvent *)event;
- (void)logCustomEvent:(MPEvent *)event;
- (void)logScreenCallback:(MPEvent *)event execStatus:(MPExecStatus)execStatus;
- (void)leaveBreadcrumbCallback:(MPEvent *)event
                     execStatus:(MPExecStatus)execStatus;
- (void)logErrorCallback:(NSDictionary<NSString *, id> *_Nullable)eventInfo
              execStatus:(MPExecStatus)execStatus
                 message:(NSString *)message;
- (void)logExceptionCallback:(NSException *_Nonnull)exception
                  execStatus:(MPExecStatus)execStatus
                     message:(NSString *)message
              topmostContext:(id _Nullable)topmostContext;
- (void)logCrashCallback:(MPExecStatus)execStatus
                 message:(NSString *_Nullable)message;
- (void)logCommerceEventCallback:(MPCommerceEvent *)commerceEvent
                      execStatus:(MPExecStatus)execStatus;
- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent;
- (void)logLTVIncreaseCallback:(MPEvent *)event
                    execStatus:(MPExecStatus)execStatus;
- (void)logNetworkPerformanceCallback:(MPExecStatus)execStatus;
+ (void)setSharedInstance:(MParticle *)instance;
- (void)executeKitsInitializedBlocks;
- (BOOL)isValidBridgeName:(NSString *)bridgeName;
- (NSString *)webviewBridgeValueWithCustomerBridgeName:
    (NSString *)customerBridgeName;
#if TARGET_OS_IOS == 1
- (void)userContentController:
            (nonnull WKUserContentController *)userContentController
      didReceiveScriptMessage:(nonnull WKScriptMessage *)message;
#endif
- (void)handleWebviewCommand:(NSString *)command
                  dictionary:(NSDictionary *)dictionary;
- (void)sessionDidBegin:(MPSession *)session;
- (void)sessionDidEnd:(nonnull MPSession *)session;
- (void)setExecutor:(id<ExecutorProtocol>)newExecutor;
- (void)setBackendController:(id<MPBackendControllerProtocol>)backendController;
- (void)setKitContainer:(id<MPKitContainerProtocol>)kitContainer;
- (void)forwardLogInstall;
- (void)forwardLogUpdate;
- (void)setUploadInterval:(NSTimeInterval)uploadInterval;
- (NSTimeInterval)uploadInterval;
- (NSDictionary<NSString *, id> *)userAttributesForUserId:(NSNumber *)userId;

- (MPLog *)getLogger;

@property(nonatomic, strong, nonnull) id<MPBackendControllerProtocol>
    backendController;
@property(nonatomic, strong) id<SettingsProviderProtocol> settingsProvider;
@property(nonatomic, strong, nullable) id<MPDataPlanFilterProtocol>
    dataPlanFilter;
@property(nonatomic, strong, nonnull) id<MPListenerControllerProtocol>
    listenerController;
@property(nonatomic, strong) id<MPStateMachineProtocol> stateMachine;
@property(nonatomic, strong) id<MPPersistenceControllerProtocol>
    persistenceController;
@end

#import "SettingsProvider.h"
#import "MParticleSwift.h"
#import "MPDataPlanFilter.h"

@interface MParticle (Tests)
- (void)setOptOutCompletion:(MPExecStatus)execStatus optOut:(BOOL)optOut;
- (void)identifyNoDispatchCallback:(MPIdentityApiResult * _Nullable)apiResult
                             error:(NSError * _Nullable)error
                           options:(MParticleOptions * _Nonnull)options;
- (void)configureWithOptions:(MParticleOptions * _Nonnull)options;
- (void)startWithKeyCallback:(BOOL)firstRun options:(MParticleOptions * _Nonnull)options userDefaults:(id<MPUserDefaultsProtocol>)userDefaults;
- (void)beginTimedEventCompletionHandler:(MPEvent *)event execStatus:(MPExecStatus)execStatus;
- (void)logEventCallback:(MPEvent *)event execStatus:(MPExecStatus)execStatus;
- (void)logScreenCallback:(MPEvent *)event execStatus:(MPExecStatus)execStatus;
- (void)leaveBreadcrumbCallback:(MPEvent *)event execStatus:(MPExecStatus)execStatus;
- (void)logErrorCallback:(NSDictionary<NSString *,id> * _Nullable)eventInfo execStatus:(MPExecStatus)execStatus message:(NSString *)message;
- (void)logExceptionCallback:(NSException * _Nonnull)exception execStatus:(MPExecStatus)execStatus message:(NSString *)message topmostContext:(id _Nullable)topmostContext;
- (void)logCrashCallback:(MPExecStatus)execStatus message:(NSString * _Nullable)message;
- (void)logCommerceEventCallback:(MPCommerceEvent *)commerceEvent execStatus:(MPExecStatus)execStatus;
- (void)logLTVIncreaseCallback:(MPEvent *)event execStatus:(MPExecStatus)execStatus;
- (void)logNetworkPerformanceCallback:(MPExecStatus)execStatus;

@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong) id<SettingsProviderProtocol> settingsProvider;
@property (nonatomic, strong, nullable) id<MPDataPlanFilterProtocol> dataPlanFilter;
@end
    

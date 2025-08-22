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

@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong) id<SettingsProviderProtocol> settingsProvider;
@property (nonatomic, strong, nullable) id<MPDataPlanFilterProtocol> dataPlanFilter;
@end
    

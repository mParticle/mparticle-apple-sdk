#import "SettingsProvider.h"
#import "MParticleSwift.h"

@interface MParticle (Tests)
- (void)setOptOutCompletion:(MPExecStatus)execStatus optOut:(BOOL)optOut;
- (void)identifyNoDispatchCallback:(MPIdentityApiResult * _Nullable)apiResult
                             error:(NSError * _Nullable)error
                           options:(MParticleOptions * _Nonnull)options;
- (void)configureWithOptions:(MParticleOptions * _Nonnull)options;
- (void)startWithKeyCallback:(BOOL)firstRun options:(MParticleOptions * _Nonnull)options userDefaults:(id<MPUserDefaultsProtocol>)userDefaults;

@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong) id<SettingsProviderProtocol> settingsProvider;
@end

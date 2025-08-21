@interface MParticle (Tests)
- (void)setOptOutCompletion:(MPExecStatus)execStatus optOut:(BOOL)optOut;
- (void)identifyNoDispatchCallback:(MPIdentityApiResult * _Nullable)apiResult
                             error:(NSError * _Nullable)error
                           options:(MParticleOptions * _Nonnull)options;
- (void)configureWithOptions:(MParticleOptions * _Nonnull)options;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@end

@interface MParticle (Tests)
- (void)setOptOutCompletion:(MPExecStatus)execStatus optOut:(BOOL)optOut;
- (void)identifyNoDispatchCallback:(MPIdentityApiResult * _Nullable)apiResult
                             error:(NSError * _Nullable)error
                           options:(MParticleOptions * _Nonnull)options;
@end

#import "mParticle.h"

@interface MPUserDefaultsConnector: NSObject

+ (MPUserDefaultsConnector*)defaultConnector;

- (MPStateMachine_PRIVATE*)stateMachine;
- (MPBackendController_PRIVATE*)backendController;
- (MPIdentityApi*)identity;
- (MParticle*)mparticle;

@end

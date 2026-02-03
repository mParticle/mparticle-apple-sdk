#import "MPBackendController.h"
#import "MPStateMachine.h"
#import "MPIdentityApi.h"
#import "mParticle.h"

@class MPUserDefaults;

@interface MPUserDefaultsConnector: NSObject

- (MPStateMachine_PRIVATE*)stateMachine;
- (MPBackendController_PRIVATE*)backendController;
- (MPIdentityApi*)identity;
- (MParticle*)mparticle;

+ (MPUserDefaults*)userDefaults;

@end

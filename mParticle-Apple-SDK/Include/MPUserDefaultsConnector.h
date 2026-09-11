#import "MPBackendController.h"
#import "MPIdentityApi.h"

@class MPUserDefaults;
@class MParticle;
@class MPStateMachine_PRIVATE;

@interface MPUserDefaultsConnector: NSObject

- (MPStateMachine_PRIVATE*)stateMachine;
- (MPBackendController_PRIVATE*)backendController;
- (MPIdentityApi*)identity;

+ (MPUserDefaults*)userDefaults;

@end

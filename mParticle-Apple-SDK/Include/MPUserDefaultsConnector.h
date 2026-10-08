#import "MPIdentityApi.h"

@class MPUserDefaults;
@class MParticle;
@class MPStateMachine_PRIVATE;

@interface MPUserDefaultsConnector: NSObject

- (MPStateMachine_PRIVATE*)stateMachine;
- (MPIdentityApi*)identity;

+ (MPUserDefaults*)userDefaults;

@end

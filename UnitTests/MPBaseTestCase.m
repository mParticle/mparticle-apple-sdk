#import <XCTest/XCTest.h>
#import "MPBaseTestCase.h"
#import "mParticle.h"
#import "MPPersistenceController.h"
#import "MPStateMachine.h"
#import "MPKitContainer.h"
#import "MPAppNotificationHandler.h"

@implementation MPBaseTestCase

- (void)setUp {
    [super setUp];
    [[MParticle sharedInstance] reset];
}

- (void)tearDown {
    [[MParticle sharedInstance] reset];
    [super tearDown];
}

@end

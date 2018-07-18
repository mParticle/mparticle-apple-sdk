#import <XCTest/XCTest.h>
#import "mParticle.h"
#import "MPBaseTestCase.h"
#import "MPStateMachine.h"

@interface MParticle ()

@property (nonatomic, strong) MPStateMachine *stateMachine;

@end

@interface MParticleTests : MPBaseTestCase {
}

@end

@implementation MParticleTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testResetInstance {
    MParticle *instance = [MParticle sharedInstance];
    MParticle *instance2 = [MParticle sharedInstance];
    XCTAssertNotNil(instance);
    XCTAssertEqual(instance, instance2);
    [instance reset];
    MParticle *instance3 = [MParticle sharedInstance];
    MParticle *instance4 = [MParticle sharedInstance];
    XCTAssertNotEqual(instance, instance3);
    XCTAssertEqual(instance3, instance4);
}

- (void)testOptOut {
    MParticle *instance = [MParticle sharedInstance];
    instance.stateMachine = [[MPStateMachine alloc] init];
    
    XCTAssertFalse(instance.optOut, "By Default Opt Out should be set to false");
    
    instance.optOut = YES;
    XCTAssert(instance.optOut, "Opt Out failed to set True");
    
    instance.optOut = NO;
    XCTAssertFalse(instance.optOut, "Opt Out failed to set False");
}

@end

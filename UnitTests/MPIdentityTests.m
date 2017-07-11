//
//  MPIdentityTests.m
//

#import <XCTest/XCTest.h>
#import "mParticle.h"

@interface MPIdentityTests : XCTestCase

@end

@implementation MPIdentityTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBasicAssumptions {
    XCTAssert([MParticle sharedInstance].identity);
    XCTAssert([MParticle sharedInstance].identity.currentUser);
    XCTAssert([MParticle sharedInstance].identity.currentUser.userId);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

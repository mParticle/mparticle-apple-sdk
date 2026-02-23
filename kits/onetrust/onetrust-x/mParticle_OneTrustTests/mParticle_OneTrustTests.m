#import <XCTest/XCTest.h>
#import "MPKitOneTrust.h"

@interface mParticle_OneTrustTests : XCTestCase

@end

@implementation mParticle_OneTrustTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testModuleID {
    XCTAssertEqualObjects([MPKitOneTrust kitCode], @134);
}

- (void)testStarted {
    MPKitOneTrust *oneTrustKit = [[MPKitOneTrust alloc] init];
    [oneTrustKit didFinishLaunchingWithConfiguration:@{@"mobileConsentGroups":@"12345"}];
    XCTAssertTrue(oneTrustKit.started);
}

@end

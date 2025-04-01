#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MParticle.h"
#import "MPKitContainer.h"
#import "MPForwardQueueParameters.h"

@interface MPRokt (Testing)
@end

@interface MPRoktTests : XCTestCase
@property (nonatomic, strong) MPRokt *rokt;
@end

@implementation MPRoktTests

- (void)setUp {
    [super setUp];
    self.rokt = [[MPRokt alloc] init];
}

- (void)tearDown {
    self.rokt = nil;
    [super tearDown];
}

- (void)testSelectPlacementsSimpleWithValidParameters {
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    // Set up test parameters
    NSString *viewName = @"testView";
    NSDictionary *attributes = @{@"key": @"value"};
    
    // Set up expectations for kit container
    SEL roktSelector = @selector(executeWithViewName:attributes:placements:onLoad:onUnLoad:onShouldShowLoadingIndicator:onShouldHideLoadingIndicator:onEmbeddedSizeChange:filteredUser:);
    OCMExpect([mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], viewName);
        XCTAssertEqualObjects(params[1], attributes);
        XCTAssertNil(params[2]);
        XCTAssertNil(params[3]);
        XCTAssertNil(params[4]);
        XCTAssertNil(params[5]);
        XCTAssertNil(params[6]);
        XCTAssertNil(params[7]);
        return true;
    }]
                                       messageType:MPMessageTypeEvent
                                          userInfo:nil]);
    
    // Execute method
    [self.rokt selectPlacements:viewName
                     attributes:attributes];
    
    // Wait for async operation
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    // Verify
    OCMVerifyAll(mockContainer);
}

- (void)testSelectPlacementsExpandedWithValidParameters {
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    // Set up test parameters
    NSString *viewName = @"testView";
    NSDictionary *attributes = @{@"key": @"value"};
    NSDictionary *placements = @{@"placement": @"test"};
    void (^onLoad)(void) = ^{};
    void (^onUnLoad)(void) = ^{};
    void (^onShouldShowLoadingIndicator)(void) = ^{};
    void (^onShouldHideLoadingIndicator)(void) = ^{};
    void (^onEmbeddedSizeChange)(NSString *, CGFloat) = ^(NSString *p, CGFloat s){};
    
    // Set up expectations for kit container
    SEL roktSelector = @selector(executeWithViewName:attributes:placements:onLoad:onUnLoad:onShouldShowLoadingIndicator:onShouldHideLoadingIndicator:onEmbeddedSizeChange:filteredUser:);
    OCMExpect([mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], viewName);
        XCTAssertEqualObjects(params[1], attributes);
        XCTAssertEqualObjects(params[2], placements);
        XCTAssertTrue(params[3] != nil);
        XCTAssertTrue(params[4] != nil);
        XCTAssertTrue(params[5] != nil);
        XCTAssertTrue(params[6] != nil);
        XCTAssertTrue(params[7] != nil);
        return true;
    }]
                                       messageType:MPMessageTypeEvent
                                          userInfo:nil]);
    
    // Execute method
    [self.rokt selectPlacements:viewName
                     attributes:attributes
                     placements:placements
                         onLoad:onLoad
                       onUnLoad:onUnLoad
   onShouldShowLoadingIndicator:onShouldShowLoadingIndicator
   onShouldHideLoadingIndicator:onShouldHideLoadingIndicator
           onEmbeddedSizeChange:onEmbeddedSizeChange];
    
    // Wait for async operation
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    // Verify
    OCMVerifyAll(mockContainer);
}

- (void)testSelectPlacementsExpandedWithNilParameters {
    id mockInstance = OCMClassMock([MParticle class]);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    // Execute method with nil parameters
    [self.rokt selectPlacements:nil
                     attributes:nil
                     placements:nil
                         onLoad:nil
                       onUnLoad:nil
   onShouldShowLoadingIndicator:nil
   onShouldHideLoadingIndicator:nil
           onEmbeddedSizeChange:nil];
    
    // Wait for async operation
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    // Verify the call is still forwarded with nil parameters
    SEL roktSelector = @selector(executeWithViewName:attributes:placements:onLoad:onUnLoad:onShouldShowLoadingIndicator:onShouldHideLoadingIndicator:onEmbeddedSizeChange:filteredUser:);
    OCMVerify([mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg any]
                                messageType:MPMessageTypeEvent
                                   userInfo:nil]);
}

@end 

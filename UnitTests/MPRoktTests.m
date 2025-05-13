#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MParticle.h"
#import "MPKitContainer.h"
#import "MPForwardQueueParameters.h"
#import "MPIConstants.h"

@interface MPRokt ()
- (NSArray<NSDictionary<NSString *, NSString *> *> *)getRoktPlacementAttributesMapping;
- (void)confirmEmail:(NSString * _Nullable)email user:(MParticleUser * _Nullable)user completion:(void (^)(MParticleUser *_Nullable))completion;
@end

@interface MPRokt (Testing)
@end

@interface MPRoktTests : XCTestCase
@property (nonatomic, strong) MPRokt *rokt;
@property (nonatomic, strong) id mockRokt;
@end

@implementation MPRoktTests

- (void)setUp {
    [super setUp];
    self.rokt = [[MPRokt alloc] init];
    self.mockRokt = OCMPartialMock(self.rokt);
}

- (void)tearDown {
    self.rokt = nil;
    [super tearDown];
}

- (void)testSelectPlacementsSimpleWithValidParameters {
    [[[self.mockRokt stub] andReturn:@[]] getRoktPlacementAttributesMapping];
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    // Set up test parameters
    NSString *viewName = @"testView";
    NSDictionary *attributes = @{@"email": @"test@gmail.com", @"sandbox": @"false"};
    
    // Set up expectations for kit container
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    SEL roktSelector = @selector(executeWithViewName:attributes:placements:callbacks:filteredUser:);
    OCMExpect([mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], viewName);
        XCTAssertEqualObjects(params[1], attributes);
        XCTAssertNil(params[2]);
        XCTAssertNil(params[3]);
        return true;
    }]
                                messageType:MPMessageTypeEvent
                                   userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });
    
    // Execute method
    [self.rokt selectPlacements:viewName
                     attributes:attributes];
    
    // Wait for async operation
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Verify
    OCMVerifyAll(mockContainer);
}

- (void)testSelectPlacementsExpandedWithValidParameters {
    [[[self.mockRokt stub] andReturn:@[]] getRoktPlacementAttributesMapping];
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    // Set up test parameters
    NSString *viewName = @"testView";
    NSDictionary *attributes = @{@"key": @"value"};
    NSDictionary *finalAttributes = @{@"key": @"value", @"sandbox": @"true"};
    MPRoktEmbeddedView *exampleView = [[MPRoktEmbeddedView alloc] initWithFrame:CGRectZero];
    NSDictionary *placements = @{@"placement": exampleView};
    MPRoktEventCallback *exampleCallbacks = [[MPRoktEventCallback alloc] init];
    exampleCallbacks.onLoad = ^{};
    exampleCallbacks.onUnLoad = ^{};
    exampleCallbacks.onShouldShowLoadingIndicator = ^{};
    exampleCallbacks.onShouldHideLoadingIndicator = ^{};
    exampleCallbacks.onEmbeddedSizeChange = ^(NSString *p, CGFloat s){};
    
    // Set up expectations for kit container
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    SEL roktSelector = @selector(executeWithViewName:attributes:placements:callbacks:filteredUser:);
    OCMExpect([mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], viewName);
        XCTAssertEqualObjects(params[1], finalAttributes);
        XCTAssertEqualObjects(params[2], placements);
        XCTAssertEqualObjects(params[3], exampleCallbacks);
        return true;
    }]
                                       messageType:MPMessageTypeEvent
                                          userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });
    
    // Execute method
    [self.rokt selectPlacements:viewName
                     attributes:attributes
                     placements:placements
                      callbacks:exampleCallbacks];
    
    // Wait for async operation
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    // Verify
    OCMVerifyAll(mockContainer);
}

- (void)testSelectPlacementsExpandedWithNilParameters {
    [[[self.mockRokt stub] andReturn:@[]] getRoktPlacementAttributesMapping];
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    // Set up test parameters
    NSString *viewName = @"testView";
    
    // Execute method with nil parameters
    [self.rokt selectPlacements:viewName
                     attributes:nil
                     placements:nil
                      callbacks:nil];
    
    // Wait for async operation
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    
    SEL roktSelector = @selector(executeWithViewName:attributes:placements:callbacks:filteredUser:);
    NSDictionary *finalAttributes = @{@"sandbox": @"true"};

    OCMExpect([mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], viewName);
        XCTAssertEqualObjects(params[1], finalAttributes);
        XCTAssertNil(params[2]);
        XCTAssertNil(params[3]);
        return true;
    }]
                                messageType:MPMessageTypeEvent
                                   userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });
    
    // Wait for async operation
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    
    // Verify
    OCMVerifyAll(mockContainer);
}

- (void)testSelectPlacementsSimpleWithMapping {
    [[[self.mockRokt stub] andReturn:@[@{@"map": @"f.name", @"maptype": @"UserAttributeClass.Name", @"value": @"firstname"}, @{@"map": @"zip", @"maptype": @"UserAttributeClass.Name", @"value": @"billingzipcode"}, @{@"map": @"l.name", @"maptype": @"UserAttributeClass.Name", @"value": @"lastname"}]] getRoktPlacementAttributesMapping];
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    // Set up test parameters
    NSString *viewName = @"testView";
    NSDictionary *attributes = @{@"f.name": @"Brandon"};
    NSDictionary *mappedAttributes = @{@"firstname": @"Brandon", @"sandbox": @"true"};
    
    // Set up expectations for kit container
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    SEL roktSelector = @selector(executeWithViewName:attributes:placements:callbacks:filteredUser:);
    OCMExpect([mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], viewName);
        XCTAssertEqualObjects(params[1], mappedAttributes);
        XCTAssertNil(params[2]);
        XCTAssertNil(params[3]);
        return true;
    }]
                                messageType:MPMessageTypeEvent
                                   userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });
    
    // Execute method
    [self.rokt selectPlacements:viewName
                     attributes:attributes];
    
    // Wait for async operation
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Verify
    OCMVerifyAll(mockContainer);
}

- (void)testSelectPlacementsSimpleWithNilMapping {
    [[[self.mockRokt stub] andReturn:nil] getRoktPlacementAttributesMapping];
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    SEL roktSelector = @selector(executeWithViewName:attributes:placements:callbacks:filteredUser:);
    OCMReject([mockContainer forwardSDKCall:roktSelector
                                      event:[OCMArg any]
                                 parameters:[OCMArg any]
                                messageType:MPMessageTypeEvent
                                   userInfo:[OCMArg any]]);
    
    // Set up test parameters
    NSString *viewName = @"testView";
    NSDictionary *attributes = @{@"f.name": @"Brandon"};
    
    // Execute method
    [self.rokt selectPlacements:viewName
                     attributes:attributes];

    // Verify
    OCMVerifyAll((id)mockContainer);
}

- (void)testGetRoktPlacementAttributesMapping {
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    NSArray *kitConfig = @[@{
        @"AllowJavaScriptResponse": @"True",
        @"accountId": @12345,
        @"onboardingExpProvider": @"None",
        kMPPlacementAttributesMapping: @"[{\"jsmap\":null,\"map\":\"f.name\",\"maptype\":\"UserAttributeClass.Name\",\"value\":\"firstname\"},{\"jsmap\":null,\"map\":\"zip\",\"maptype\":\"UserAttributeClass.Name\",\"value\":\"billingzipcode\"},{\"jsmap\":null,\"map\":\"l.name\",\"maptype\":\"UserAttributeClass.Name\",\"value\":\"lastname\"}]",
        @"sandboxMode": @"True",
        @"eau": @0,
        @"hs": @{
            @"pur": @{},
            @"reg": @{}
        },
        @"id": @181
    }];
    [[[mockContainer stub] andReturn:kitConfig] originalConfig];
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    NSArray<NSDictionary<NSString *, NSString *> *> *testResult = [self.rokt getRoktPlacementAttributesMapping];
    NSArray<NSDictionary<NSString *, NSString *> *> *expectedResult = @[@{@"map": @"f.name", @"maptype": @"UserAttributeClass.Name", @"value": @"firstname", @"jsmap": [NSNull null]}, @{@"map": @"zip", @"maptype": @"UserAttributeClass.Name", @"value": @"billingzipcode", @"jsmap": [NSNull null]}, @{@"map": @"l.name", @"maptype": @"UserAttributeClass.Name", @"value": @"lastname", @"jsmap": [NSNull null]}];
    
    XCTAssertEqualObjects(testResult, expectedResult, @"Mapping does not match .");
}

- (void)testSelectPlacementsIdentifyUser {
    [[[self.mockRokt stub] andReturn:@[]] getRoktPlacementAttributesMapping];
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    // Set up test parameters
    NSString *viewName = @"testView";
    NSDictionary *attributes = @{@"email": @"test@gmail.com", @"sandbox": @"false"};
    
    // Set up expectations for kit container
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    OCMExpect([self.mockRokt confirmEmail:@"test@gmail.com" user:OCMOCK_ANY completion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });
    
    // Execute method
    [self.rokt selectPlacements:viewName
                     attributes:attributes];
    
    // Wait for async operation
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    // Verify
    OCMVerifyAll(mockContainer);
}

@end 

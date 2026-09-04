#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
@import RoktContracts;
#import "MParticle.h"
#import "MParticleUser.h"
#import "MPIdentityApi.h"
#import "MPIdentityApiManager.h"
#import "MPKitContainer+MParticlePrivate.h"
#import "MPIConstants.h"
#import "MPUserDefaultsConnector.h"

@interface MPKitContainer_PRIVATE (MParticlePrivateTests)
- (nullable NSDictionary *)launchConfigurationForKitCode:(nonnull NSNumber *)kitCode;
@end

// Rokt kit identifier for testing
static NSNumber * const kTestRoktKitId = @181;

// Forward/drain values are ceilings: the wait returns as soon as it is satisfied, so they are
// paid only on failure. The negative value is spent in full on every run — keep it small.
static const NSTimeInterval kMPRoktForwardTimeout = 5.0;
static const NSTimeInterval kMPRoktNegativeTimeout = 0.3;
static const NSTimeInterval kMPRoktDrainTimeout = 5.0;

// Test helper class that simulates a kit with getSessionId and handleURLCallback methods
@interface MPRoktTestKitInstance : NSObject <MPRoktKitDispatchTarget>
@property (nonatomic, copy) NSString *sessionIdToReturn;
@property (nonatomic, copy) NSString *lastDiagnosticCode;
@property (nonatomic, assign) BOOL handleURLCallbackReturn;
@property (nonatomic, strong) NSURL *lastHandleURLCallbackURL;
- (NSString *)getSessionId;
- (void)logMParticleApiDiagnostic:(NSString *)code;
- (BOOL)handleURLCallback:(NSURL *)url;
@end

@implementation MPRoktTestKitInstance
- (NSString *)getSessionId {
    return self.sessionIdToReturn;
}
- (void)logMParticleApiDiagnostic:(NSString *)code {
    self.lastDiagnosticCode = code;
}
- (BOOL)handleURLCallback:(NSURL *)url {
    self.lastHandleURLCallbackURL = url;
    return self.handleURLCallbackReturn;
}
@end

@interface MPRoktNonconformingKitInstance : NSObject
@property (nonatomic, copy) NSString *sessionIdToReturn;
@property (nonatomic, copy) NSString *lastDiagnosticCode;
@property (nonatomic, assign) BOOL handleURLCallbackReturn;
- (NSString *)getSessionId;
- (void)logMParticleApiDiagnostic:(NSString *)code;
- (BOOL)handleURLCallback:(NSURL *)url;
@end

@implementation MPRoktNonconformingKitInstance
- (NSString *)getSessionId {
    return self.sessionIdToReturn;
}
- (void)logMParticleApiDiagnostic:(NSString *)code {
    self.lastDiagnosticCode = code;
}
- (BOOL)handleURLCallback:(NSURL *)url {
    return self.handleURLCallbackReturn;
}
@end

@interface MPRokt (Testing)
- (void)logRoktApiDiagnostic:(NSString *)code;
@end

@interface MParticle ()
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;
+ (dispatch_queue_t)messageQueue;
@end

@interface MPIdentityApi ()
@property (nonatomic, strong) MPIdentityApiManager *apiManager;
@end

@interface MPRoktTests : XCTestCase
@property (nonatomic, strong) MPRokt *rokt;
@property (nonatomic, strong) id mockRokt;
@property (nonatomic, strong) id mockInstance;
@property (nonatomic, strong) id mockContainer;
@property (nonatomic, strong) id identityMock;
@property (nonatomic, strong) id mockApiResult;
@end

@implementation MPRoktTests

- (void)setUp {
    [super setUp];
    self.rokt = [[MPRokt alloc] init];
    self.mockRokt = OCMPartialMock(self.rokt);
}

- (void)tearDown {
    [self drainPendingAsyncWork];
    // Stop the partial mock before releasing the object it wraps, not after.
    [self.mockRokt stopMocking];
    self.rokt = nil;
    [self.mockInstance stopMocking];
    [self.mockContainer stopMocking];
    [self.identityMock stopMocking];
    [self.mockApiResult stopMocking];
    self.mockRokt = nil;
    self.mockInstance = nil;
    self.mockContainer = nil;
    self.identityMock = nil;
    self.mockApiResult = nil;
    [super tearDown];
}

/// Dispatched work can outlive its test: if a forward or clearSession block lands after tearDown
/// stops the mocks, OCMock raises on a queue XCTest cannot catch and the process aborts. Both
/// queues are serial, so a sentinel drains them; two passes, as either can dispatch onto the other.
- (void)drainPendingAsyncWork {
    for (NSUInteger pass = 0; pass < 2; pass++) {
        [self drainSerialQueue:[MParticle messageQueue] named:@"mParticle message queue"];
        [self drainMainQueue];
    }
}

- (void)drainSerialQueue:(dispatch_queue_t)queue named:(NSString *)name {
    dispatch_semaphore_t drained = dispatch_semaphore_create(0);
    dispatch_async(queue, ^{
        dispatch_semaphore_signal(drained);
    });
    // Bounded rather than dispatch_sync: a stalled queue should fail slowly, not deadlock the run.
    if (dispatch_semaphore_wait(drained, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMPRoktDrainTimeout * NSEC_PER_SEC))) != 0) {
        XCTFail(@"%@ did not drain within %.0fs; a dispatched block may outlive its mocks", name, kMPRoktDrainTimeout);
    }
}

- (void)drainMainQueue {
    // Tests run on the main thread, so spin the run loop instead of blocking on a semaphore.
    __block BOOL drained = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        drained = YES;
    });
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:kMPRoktDrainTimeout];
    while (!drained && [deadline timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    if (!drained) {
        XCTFail(@"main queue did not drain within %.0fs; a dispatched block may outlive its mocks", kMPRoktDrainTimeout);
    }
}

- (void)testSelectPlacementsSimpleWithValidParameters {
    MParticleUser *currentUser = [MParticle sharedInstance].identity.currentUser;

    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.identityMock = OCMClassMock([MPIdentityApi class]);
    OCMStub([(MParticle *)self.mockInstance identity]).andReturn(self.identityMock);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];
    [[[self.identityMock stub] andReturn:currentUser] currentUser];

    self.mockApiResult = OCMClassMock([MPIdentityApiResult class]);
    OCMStub([self.mockApiResult user]).andReturn(currentUser);
    
    [[[self.identityMock stub] andDo:^(NSInvocation *invocation) {
        void (^completion)(MPIdentityApiResult * _Nullable, NSError * _Nullable);
        [invocation getArgument:&completion atIndex:3];
        completion(self.mockApiResult, nil);
    }] identify:[OCMArg any] completion:[OCMArg any]];

    // Set up test parameters
    NSString *identifier = @"testView";
    NSDictionary *attributes = @{@"email": @"test@gmail.com", @"sandbox": @"false"};
    
    // Capture time before calling selectPlacements
    long long timeBeforeCall = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    
    // Set up expectations for kit container
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    SEL roktSelector = @selector(selectPlacementsWithIdentifier:attributes:embeddedViews:config:onEvent:filteredUser:options:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], identifier);
        XCTAssertEqualObjects(params[1], attributes);
        XCTAssertNil(params[2]);
        XCTAssertNil(params[3]);
        XCTAssertNil(params[4]);
        // Verify placement options
        RoktPlacementOptions *options = params[5];
        XCTAssertNotNil(options);
        XCTAssertTrue(options.jointSdkSelectPlacements >= timeBeforeCall);
        return true;
    }]
                                messageType:MPMessageTypeEvent
                                   userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });
    
    // Execute method
    [self.rokt selectPlacements:identifier
                     attributes:attributes];
    
    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];

    // Verify
    OCMVerifyAll(self.mockContainer);
}

- (void)testSelectPlacementsExpandedWithValidParameters {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];
    
    // Set up test parameters
    NSString *identifier = @"testView";
    NSDictionary *attributes = @{@"key": @"value"};
    NSDictionary *finalAttributes = @{@"key": @"value"};
    RoktEmbeddedView *exampleView = [[RoktEmbeddedView alloc] initWithFrame:CGRectZero];
    NSDictionary *embeddedViews = @{@"placement": exampleView};
    
    // Create onEvent callback block
    void (^exampleOnEvent)(RoktEvent * _Nonnull) = ^(RoktEvent * _Nonnull event) {
        // Handle event
    };
    
    RoktConfigBuilder *builder = [[RoktConfigBuilder alloc] init];
    [builder colorMode:RoktColorModeDark];
    RoktCacheConfig *cacheConfig = [[RoktCacheConfig alloc] initWithCacheDuration:60*10 cacheAttributes:@{@"test": @"test"}];
    [builder cacheConfig:cacheConfig];
    RoktConfig *roktConfig = [builder build];
    
    // Capture time before calling selectPlacements
    long long timeBeforeCall = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    
    // Set up expectations for kit container
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    SEL roktSelector = @selector(selectPlacementsWithIdentifier:attributes:embeddedViews:config:onEvent:filteredUser:options:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], identifier);
        XCTAssertEqualObjects(params[1], finalAttributes);
        XCTAssertEqualObjects(params[2], embeddedViews);
        XCTAssertEqualObjects(params[3], roktConfig);
        XCTAssertNotNil(params[4]); // onEvent callback should be set
        // Verify placement options
        RoktPlacementOptions *options = params[5];
        XCTAssertNotNil(options);
        XCTAssertTrue(options.jointSdkSelectPlacements >= timeBeforeCall);
        return true;
    }]
                                messageType:MPMessageTypeEvent
                                   userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });
    
    // Execute method
    [self.rokt selectPlacements:identifier
                     attributes:attributes
                  embeddedViews:embeddedViews
                         config:roktConfig
                        onEvent:exampleOnEvent];
    
    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];

    // Verify
    OCMVerifyAll(self.mockContainer);
}

- (void)testSelectPlacementsExpandedWithNilParameters {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];
    
    // Set up test parameters
    NSString *identifier = @"testView";
    
    // Set up expectations BEFORE calling selectPlacements
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    
    SEL roktSelector = @selector(selectPlacementsWithIdentifier:attributes:embeddedViews:config:onEvent:filteredUser:options:);
    NSDictionary *finalAttributes = @{};

    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], identifier);
        XCTAssertEqualObjects(params[1], finalAttributes);
        XCTAssertNil(params[2]);
        XCTAssertNil(params[3]);
        XCTAssertNil(params[4]);
        // Verify placement options exists
        RoktPlacementOptions *options = params[5];
        XCTAssertNotNil(options);
        return true;
    }]
                                messageType:MPMessageTypeEvent
                                   userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });
    
    // Execute method with nil parameters
    [self.rokt selectPlacements:identifier
                     attributes:nil
                  embeddedViews:nil
                         config:nil
                        onEvent:nil];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];
    
    // Verify
    OCMVerifyAll(self.mockContainer);
}

- (void)mp_stubSharedInstanceWithOriginalConfig:(NSArray *)kitConfig kitsInitialized:(BOOL)kitsInitialized {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    NSDictionary *roktConfiguration = nil;
    for (NSDictionary *configuration in kitConfig) {
        if ([configuration[@"id"] isEqualToNumber:kTestRoktKitId]) {
            roktConfiguration = configuration;
            break;
        }
    }
    [[[self.mockContainer stub] andReturn:roktConfiguration] launchConfigurationForKitCode:kTestRoktKitId];
    [[[self.mockContainer stub] andReturnValue:OCMOCK_VALUE(kitsInitialized)] kitsInitialized];
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];
}

- (XCTestExpectation *)mp_expectSelectPlacementsForwardWithIdentifier:(NSString *)identifier
                                                   unmappedAttributes:(NSDictionary *)attributes {
    XCTestExpectation *expectation = [self expectationWithDescription:@"forwarded to kit container"];
    SEL roktSelector = @selector(selectPlacementsWithIdentifier:attributes:embeddedViews:config:onEvent:filteredUser:options:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                           event:nil
                                      parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], identifier);
        NSDictionary *forwarded = params[1];
        for (NSString *key in attributes) {
            XCTAssertEqualObjects(forwarded[key], attributes[key], @"unmapped key %@ should be preserved", key);
        }
        XCTAssertNil(forwarded[@"sandbox"]);
        XCTAssertNotNil(params[5]);
        return YES;
    }]
                                     messageType:MPMessageTypeEvent
                                        userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    return expectation;
}

- (void)testSelectPlacementsSimpleWithNilMappingForwardsUnmappedAttributes {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    NSString *identifier = @"testView";
    NSDictionary *attributes = @{@"f.name": @"Brandon"};
    [self mp_expectSelectPlacementsForwardWithIdentifier:identifier unmappedAttributes:attributes];

    [self.rokt selectPlacements:identifier attributes:attributes];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];
    OCMVerifyAll(self.mockContainer);
}

- (void)testSelectPlacementsForwardsWhenOriginalConfigEmptyBeforeKitsInitialized {
    [self mp_stubSharedInstanceWithOriginalConfig:@[] kitsInitialized:NO];
    NSDictionary *attributes = @{@"f.name": @"Brandon"};
    [self mp_expectSelectPlacementsForwardWithIdentifier:@"checkout" unmappedAttributes:attributes];

    [self.rokt selectPlacements:@"checkout" attributes:attributes];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];
    OCMVerifyAll(self.mockContainer);
}

- (void)testSelectPlacementsForwardsWhenKitsInitializedFromCacheButOriginalConfigEmpty {
    [self mp_stubSharedInstanceWithOriginalConfig:@[] kitsInitialized:YES];
    NSDictionary *attributes = @{@"f.name": @"Brandon"};
    [self mp_expectSelectPlacementsForwardWithIdentifier:@"checkout" unmappedAttributes:attributes];

    [self.rokt selectPlacements:@"checkout" attributes:attributes];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];
    OCMVerifyAll(self.mockContainer);
}

- (void)testSelectPlacementsForwardsWhenOriginalConfigLacksKit181 {
    NSArray *kitConfig = @[@{@"id": @80, kMPRemoteConfigKitConfigurationKey: @{}}];
    [self mp_stubSharedInstanceWithOriginalConfig:kitConfig kitsInitialized:YES];
    NSDictionary *attributes = @{@"f.name": @"Brandon"};
    [self mp_expectSelectPlacementsForwardWithIdentifier:@"checkout" unmappedAttributes:attributes];

    [self.rokt selectPlacements:@"checkout" attributes:attributes];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];
    OCMVerifyAll(self.mockContainer);
}

- (void)testSelectPlacementsForwardsWhenKit181IsInOriginalConfigEvenWithoutAttributeMap {
    NSArray *kitConfig = @[@{
        @"id": kTestRoktKitId,
        kMPRemoteConfigKitConfigurationKey: @{}
    }];
    [self mp_stubSharedInstanceWithOriginalConfig:kitConfig kitsInitialized:YES];

    XCTestExpectation *expectation = [self expectationWithDescription:@"forwarded to kit container"];
    SEL roktSelector = @selector(selectPlacementsWithIdentifier:attributes:embeddedViews:config:onEvent:filteredUser:options:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                           event:nil
                                      parameters:[OCMArg isNotNil]
                                     messageType:MPMessageTypeEvent
                                        userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    [self.rokt selectPlacements:@"checkout" attributes:@{@"f.name": @"Brandon"}];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];
    OCMVerifyAll(self.mockContainer);
}

- (void)testSelectPlacementsWithNilMappingDoesNotInvokeOnEventWithPlacementFailure {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    NSString *identifier = @"testView";
    NSDictionary *attributes = @{@"f.name": @"Brandon"};
    XCTestExpectation *forwarded = [self mp_expectSelectPlacementsForwardWithIdentifier:identifier unmappedAttributes:attributes];

    XCTestExpectation *noFailure = [self expectationWithDescription:@"onEvent must not fire from core"];
    noFailure.inverted = YES;

    [self.rokt selectPlacements:identifier
                     attributes:attributes
                  embeddedViews:nil
                         config:nil
                        onEvent:^(RoktEvent * _Nonnull event) {
        [noFailure fulfill];
    }];

    [self waitForExpectations:@[forwarded] timeout:kMPRoktForwardTimeout];
    [self waitForExpectations:@[noFailure] timeout:kMPRoktNegativeTimeout];
    OCMVerifyAll(self.mockContainer);
}

- (void)testSelectPlacementsWithNilMappingAndNilOnEventDoesNotCrash {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    NSString *identifier = @"testView";
    NSDictionary *attributes = @{@"f.name": @"Brandon"};
    [self mp_expectSelectPlacementsForwardWithIdentifier:identifier unmappedAttributes:attributes];

    XCTAssertNoThrow([self.rokt selectPlacements:identifier attributes:attributes]);

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];
    OCMVerifyAll(self.mockContainer);
}

- (void)testPurchaseFinalized {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    // Set up test parameters
    NSString *identifier = @"testonversion";
    NSString *catalogItemId = @"testcatalogItemId";
    BOOL success = YES;
    
    // Set up expectations for kit container
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    SEL roktSelector = @selector(purchaseFinalized:catalogItemId:success:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], identifier);
        XCTAssertEqualObjects(params[1], catalogItemId);
        XCTAssertEqualObjects(params[2], @(success));
        return true;
    }]
                                messageType:MPMessageTypeEvent
                                   userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });
    
    // Execute method
    [[MParticle sharedInstance].rokt purchaseFinalized:identifier catalogItemId:catalogItemId success:success];
    
    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];

    // Verify
    OCMVerifyAll(self.mockContainer);
}

- (void)testEventsWithIdentifier {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    // Set up test parameters
    NSString *identifier = @"testPlacementId";
    __block BOOL callbackInvoked = NO;
    __block RoktEvent *receivedEvent = nil;

    void (^onEventCallback)(RoktEvent *) = ^(RoktEvent *event) {
        callbackInvoked = YES;
        receivedEvent = event;
    };

    // Set up expectations for kit container
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    SEL roktSelector = @selector(events:onEvent:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], identifier);
        XCTAssertEqualObjects(params[1], onEventCallback);
        return true;
    }]
                                messageType:MPMessageTypeEvent
                                   userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    // Execute method
    [self.rokt events:identifier onEvent:onEventCallback];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];

    // Verify
    OCMVerifyAll(self.mockContainer);
}

- (void)testEventsWithIdentifierWithNilCallback {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    // Set up test parameters
    NSString *identifier = @"testPlacementId";

    // Set up expectations for kit container
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    SEL roktSelector = @selector(events:onEvent:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], identifier);
        XCTAssertNil(params[1]);
        return true;
    }]
                                messageType:MPMessageTypeEvent
                                   userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    // Execute method with nil callback
    [self.rokt events:identifier onEvent:nil];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];

    // Verify
    OCMVerifyAll(self.mockContainer);
}

- (void)testEventsWithIdentifierCallbackInvocation {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    // Set up test parameters
    NSString *identifier = @"testPlacementId";
    __block BOOL callbackInvoked = NO;
    __block RoktEvent *receivedEvent = nil;

    void (^onEventCallback)(RoktEvent *) = ^(RoktEvent *event) {
        callbackInvoked = YES;
        receivedEvent = event;
    };

    // Set up expectations for kit container to simulate callback invocation
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    SEL roktSelector = @selector(events:onEvent:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], identifier);
        // Simulate the kit calling the callback
        void (^capturedCallback)(RoktEvent *) = params[1];
        if (capturedCallback) {
            RoktPlacementReady *testEvent = [[RoktPlacementReady alloc] initWithIdentifier:identifier];
            capturedCallback(testEvent);
        }
        return true;
    }]
                                messageType:MPMessageTypeEvent
                                   userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    // Execute method
    [self.rokt events:identifier onEvent:onEventCallback];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];

    // Verify callback was invoked
    XCTAssertTrue(callbackInvoked, @"Callback should have been invoked");
    XCTAssertNotNil(receivedEvent, @"Should have received an event");
    XCTAssertTrue([receivedEvent isKindOfClass:[RoktPlacementReady class]], @"Should receive the correct event type");

    // Verify
    OCMVerifyAll(self.mockContainer);
}

- (void)testGlobalEvents {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    // Set up test parameters
    void (^onEventCallback)(RoktEvent *) = ^(RoktEvent *event) {
        // Handle global event
    };

    // Set up expectations for kit container
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    SEL roktSelector = @selector(globalEvents:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                      event:nil
                                 parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertNotNil(params[0]);
        return true;
    }]
                                messageType:MPMessageTypeEvent
                                   userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    // Execute method
    [self.rokt globalEvents:onEventCallback];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];

    // Verify
    OCMVerifyAll(self.mockContainer);
}

- (void)testGlobalEventsCallbackInvocation {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];
    
    // Set up test parameters
    __block BOOL callbackInvoked = NO;
    __block RoktEvent *receivedEvent = nil;
    
    void (^onEventCallback)(RoktEvent *) = ^(RoktEvent *event) {
        callbackInvoked = YES;
        receivedEvent = event;
    };
    
    // Set up expectations for kit container to simulate callback invocation
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    SEL roktSelector = @selector(globalEvents:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                           event:nil
                                      parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        // Simulate the kit calling the callback with InitComplete event
        void (^capturedCallback)(RoktEvent *) = params[0];
        if (capturedCallback) {
            RoktInitComplete *testEvent = [[RoktInitComplete alloc] initWithSuccess:YES];
            capturedCallback(testEvent);
        }
        return true;
    }]
                                     messageType:MPMessageTypeEvent
                                        userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });
    
    // Execute method
    [self.rokt globalEvents:onEventCallback];
    
    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];
    
    // Verify callback was invoked
    XCTAssertTrue(callbackInvoked, @"Callback should have been invoked");
    XCTAssertNotNil(receivedEvent, @"Should have received an event");
    XCTAssertTrue([receivedEvent isKindOfClass:[RoktInitComplete class]], @"Should receive the correct event type");
    XCTAssertTrue(((RoktInitComplete *)receivedEvent).success, @"InitComplete event should indicate success");
    
    // Verify
    OCMVerifyAll(self.mockContainer);
}

#pragma mark - registerPaymentExtension & selectShoppableAds

- (void)testRegisterPaymentExtensionForwardsToKitContainer {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wat-protocol"
    id paymentExtension = OCMProtocolMock(@protocol(RoktPaymentExtension));
#pragma clang diagnostic pop

    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for message queue forward"];
    SEL roktSelector = @selector(registerPaymentExtension:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                           event:nil
                                      parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], paymentExtension);
        return YES;
    }]
                                     messageType:MPMessageTypeEvent
                                        userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    [self.rokt registerPaymentExtension:paymentExtension];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];
    OCMVerifyAll(self.mockContainer);
}

- (void)testSelectShoppableAdsShortForwardsToKitWithValidParameters {
    MParticleUser *currentUser = [MParticle sharedInstance].identity.currentUser;

    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.identityMock = OCMClassMock([MPIdentityApi class]);
    OCMStub([(MParticle *)self.mockInstance identity]).andReturn(self.identityMock);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];
    [[[self.identityMock stub] andReturn:currentUser] currentUser];

    self.mockApiResult = OCMClassMock([MPIdentityApiResult class]);
    OCMStub([self.mockApiResult user]).andReturn(currentUser);
    [[[self.identityMock stub] andDo:^(NSInvocation *invocation) {
        void (^completion)(MPIdentityApiResult * _Nullable, NSError * _Nullable);
        [invocation getArgument:&completion atIndex:3];
        completion(self.mockApiResult, nil);
    }] identify:[OCMArg any] completion:[OCMArg any]];

    NSString *identifier = @"shoppableView";
    NSDictionary *attributes = @{@"email": @"test@gmail.com", @"sandbox": @"false"};

    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for shoppable forward"];
    SEL roktSelector = @selector(selectShoppableAdsWithIdentifier:attributes:config:onEvent:filteredUser:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                           event:nil
                                      parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], identifier);
        XCTAssertEqualObjects(params[1], attributes);
        XCTAssertNil(params[2]);
        XCTAssertNil(params[3]);
        return YES;
    }]
                                     messageType:MPMessageTypeEvent
                                        userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    [self.rokt selectShoppableAds:identifier attributes:attributes];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];
    OCMVerifyAll(self.mockContainer);
}

- (void)testSelectShoppableAdsFullForwardsToKitWithConfigAndCallback {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    NSString *identifier = @"shoppableView";
    NSDictionary *attributes = @{@"key": @"value"};
    NSDictionary *finalAttributes = @{@"key": @"value"};

    void (^exampleOnEvent)(RoktEvent * _Nonnull) = ^(RoktEvent * _Nonnull event) {
    };

    RoktConfigBuilder *builder = [[RoktConfigBuilder alloc] init];
    [builder colorMode:RoktColorModeDark];
    RoktConfig *roktConfig = [builder build];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for shoppable forward"];
    SEL roktSelector = @selector(selectShoppableAdsWithIdentifier:attributes:config:onEvent:filteredUser:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                           event:nil
                                      parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], identifier);
        XCTAssertEqualObjects(params[1], finalAttributes);
        XCTAssertEqualObjects(params[2], roktConfig);
        XCTAssertEqualObjects(params[3], exampleOnEvent);
        return YES;
    }]
                                     messageType:MPMessageTypeEvent
                                        userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    [self.rokt selectShoppableAds:identifier
                       attributes:attributes
                           config:roktConfig
                          onEvent:exampleOnEvent];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];
    OCMVerifyAll(self.mockContainer);
}

- (void)testSelectShoppableAdsWithNilMappingForwardsUnmappedAttributes {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    NSString *identifier = @"shoppableView";
    NSDictionary *attributes = @{@"f.name": @"Brandon"};
    XCTestExpectation *expectation = [self expectationWithDescription:@"forwarded shoppable ads"];
    SEL roktSelector = @selector(selectShoppableAdsWithIdentifier:attributes:config:onEvent:filteredUser:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                           event:nil
                                      parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], identifier);
        NSDictionary *forwarded = params[1];
        XCTAssertEqualObjects(forwarded[@"f.name"], @"Brandon");
        XCTAssertNil(forwarded[@"sandbox"]);
        return YES;
    }]
                                     messageType:MPMessageTypeEvent
                                        userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    [self.rokt selectShoppableAds:identifier attributes:attributes];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];
    OCMVerifyAll(self.mockContainer);
}

- (void)testSelectShoppableAdsWithNilMappingDoesNotInvokeOnEventWithPlacementFailure {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    NSString *identifier = @"shoppableView";
    XCTestExpectation *forwarded = [self expectationWithDescription:@"forwarded shoppable ads"];
    SEL roktSelector = @selector(selectShoppableAdsWithIdentifier:attributes:config:onEvent:filteredUser:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                           event:nil
                                      parameters:[OCMArg isNotNil]
                                     messageType:MPMessageTypeEvent
                                        userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [forwarded fulfill];
    });

    XCTestExpectation *noFailure = [self expectationWithDescription:@"onEvent must not fire from core"];
    noFailure.inverted = YES;

    [self.rokt selectShoppableAds:identifier
                       attributes:@{@"f.name": @"Brandon"}
                           config:nil
                          onEvent:^(RoktEvent * _Nonnull event) {
        [noFailure fulfill];
    }];

    [self waitForExpectations:@[forwarded] timeout:kMPRoktForwardTimeout];
    [self waitForExpectations:@[noFailure] timeout:kMPRoktNegativeTimeout];
    OCMVerifyAll(self.mockContainer);
}

#pragma mark - confirmUser nil-user path

- (void)testIdentityCurrentUserGetterNeverReturnsNil {
    MParticleUser *user = [MParticle sharedInstance].identity.currentUser;
    XCTAssertNotNil(user, @"iOS currentUser synthesizes an MParticleUser from persisted MPID; a nil-user Android-style guard would not fire after identity is accessed");
}

#pragma mark - mapPlacementAttributes

#pragma mark - setSessionId Tests

- (void)testSetSessionIdForwardsToKitContainer {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    // Set up test parameters
    NSString *sessionId = @"test-session-id-12345";

    // Set up expectations for kit container
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    SEL roktSelector = @selector(setSessionId:);
    OCMExpect([self.mockContainer forwardSDKCall:roktSelector
                                           event:nil
                                      parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], sessionId);
        return true;
    }]
                                     messageType:MPMessageTypeEvent
                                        userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    // Execute method
    [self.rokt setSessionId:sessionId];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];

    // Verify
    OCMVerifyAll(self.mockContainer);
}

#pragma mark - clearSession Tests

- (void)testClearSessionLogsApiDiagnostic {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    id mockKitRegister = OCMProtocolMock(@protocol(MPExtensionKitProtocol));
    OCMStub([(id<MPExtensionKitProtocol>)mockKitRegister code]).andReturn(kTestRoktKitId);
    MPRoktTestKitInstance *kitInstance = [[MPRoktTestKitInstance alloc] init];
    OCMStub([mockKitRegister wrapperInstance]).andReturn(kitInstance);
    OCMStub([self.mockContainer activeKitsRegistry]).andReturn(@[mockKitRegister]);

    [self.rokt clearSession];

    // The diagnostic is recorded synchronously, before the forward is dispatched, so it is
    // observable as soon as the call returns.
    XCTAssertEqualObjects(kitInstance.lastDiagnosticCode, @"ROKT_CLEAR_SESSION");
}

- (void)testClearSessionForwardsToKitContainer {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];
    OCMStub([self.mockContainer activeKitsRegistry]).andReturn(@[]);

    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    OCMExpect([self.mockContainer forwardSDKCall:@selector(clearSession)
                                           event:nil
                                      parameters:nil
                                     messageType:MPMessageTypeEvent
                                        userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    [self.rokt clearSession];

    [self waitForExpectationsWithTimeout:kMPRoktForwardTimeout handler:nil];

    OCMVerifyAll(self.mockContainer);
}

#pragma mark - Public API Diagnostics Tests

- (void)testLogRoktApiDiagnosticForwardsToActiveRoktKit {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    id mockKitRegister = OCMProtocolMock(@protocol(MPExtensionKitProtocol));
    OCMStub([(id<MPExtensionKitProtocol>)mockKitRegister code]).andReturn(kTestRoktKitId);
    MPRoktTestKitInstance *kitInstance = [[MPRoktTestKitInstance alloc] init];
    OCMStub([mockKitRegister wrapperInstance]).andReturn(kitInstance);
    OCMStub([self.mockContainer activeKitsRegistry]).andReturn(@[mockKitRegister]);

    [self.rokt logRoktApiDiagnostic:@"LOG_EVENT"];

    XCTAssertEqualObjects(kitInstance.lastDiagnosticCode, @"LOG_EVENT");
}

- (void)testLogRoktApiDiagnosticDoesNothingWithoutActiveRoktKit {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];
    OCMStub([self.mockContainer activeKitsRegistry]).andReturn(@[]);

    [self.rokt logRoktApiDiagnostic:@"LOG_EVENT"];

    OCMVerify([self.mockContainer activeKitsRegistry]);
}

#pragma mark - getSessionId Tests

- (void)testGetSessionIdReturnsSessionIdFromKit {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    // Create a mock kit register with Rokt kit code
    id mockKitRegister = OCMProtocolMock(@protocol(MPExtensionKitProtocol));
    OCMStub([(id<MPExtensionKitProtocol>)mockKitRegister code]).andReturn(kTestRoktKitId);

    // Create a real kit instance that responds to getSessionId
    NSString *expectedSessionId = @"mock-session-id-67890";
    MPRoktTestKitInstance *kitInstance = [[MPRoktTestKitInstance alloc] init];
    kitInstance.sessionIdToReturn = expectedSessionId;
    OCMStub([mockKitRegister wrapperInstance]).andReturn(kitInstance);

    // Return the mock kit register from activeKitsRegistry
    NSArray *activeKits = @[mockKitRegister];
    OCMStub([self.mockContainer activeKitsRegistry]).andReturn(activeKits);

    // Execute method
    NSString *result = [self.rokt getSessionId];

    // Verify
    XCTAssertEqualObjects(result, expectedSessionId, @"Should return the session id from the kit");
}

- (void)testGetSessionIdReturnsNilWhenKitInstanceIsNil {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    // Create a mock kit register with Rokt kit code but nil wrapperInstance
    id mockKitRegister = OCMProtocolMock(@protocol(MPExtensionKitProtocol));
    OCMStub([(id<MPExtensionKitProtocol>)mockKitRegister code]).andReturn(kTestRoktKitId);
    OCMStub([mockKitRegister wrapperInstance]).andReturn(nil);

    // Return the mock kit register from activeKitsRegistry
    NSArray *activeKits = @[mockKitRegister];
    OCMStub([self.mockContainer activeKitsRegistry]).andReturn(activeKits);

    // Execute method
    NSString *result = [self.rokt getSessionId];

    // Verify
    XCTAssertNil(result, @"Should return nil when kit wrapper instance is nil");
}

#pragma mark - handleURLCallback Tests

- (void)testHandleURLCallbackReturnsYESWhenKitClaimsURL {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    id mockKitRegister = OCMProtocolMock(@protocol(MPExtensionKitProtocol));
    OCMStub([(id<MPExtensionKitProtocol>)mockKitRegister code]).andReturn(kTestRoktKitId);

    MPRoktTestKitInstance *kitInstance = [[MPRoktTestKitInstance alloc] init];
    kitInstance.handleURLCallbackReturn = YES;
    OCMStub([mockKitRegister wrapperInstance]).andReturn(kitInstance);

    OCMStub([self.mockContainer activeKitsRegistry]).andReturn(@[mockKitRegister]);

    NSURL *url = [NSURL URLWithString:@"myapp://afterpay-redirect?token=abc"];
    BOOL result = [self.rokt handleURLCallback:url];

    XCTAssertTrue(result, @"Should return YES when the kit claims the URL");
    XCTAssertEqualObjects(kitInstance.lastHandleURLCallbackURL, url, @"Kit should have received the URL");
}

- (void)testHandleURLCallbackReturnsNOWhenKitDoesNotClaimURL {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    id mockKitRegister = OCMProtocolMock(@protocol(MPExtensionKitProtocol));
    OCMStub([(id<MPExtensionKitProtocol>)mockKitRegister code]).andReturn(kTestRoktKitId);

    MPRoktTestKitInstance *kitInstance = [[MPRoktTestKitInstance alloc] init];
    kitInstance.handleURLCallbackReturn = NO;
    OCMStub([mockKitRegister wrapperInstance]).andReturn(kitInstance);

    OCMStub([self.mockContainer activeKitsRegistry]).andReturn(@[mockKitRegister]);

    NSURL *url = [NSURL URLWithString:@"myapp://unrelated"];
    BOOL result = [self.rokt handleURLCallback:url];

    XCTAssertFalse(result, @"Should return NO when the kit does not claim the URL");
}

- (void)testHandleURLCallbackReturnsNOWhenNoActiveKits {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    OCMStub([self.mockContainer activeKitsRegistry]).andReturn(@[]);

    NSURL *url = [NSURL URLWithString:@"myapp://afterpay-redirect"];
    BOOL result = [self.rokt handleURLCallback:url];

    XCTAssertFalse(result, @"Should return NO when no kits are active");
}

- (void)testHandleURLCallbackReturnsNOWhenRoktKitNotRegistered {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    // A non-Rokt kit is registered
    id mockKitRegister = OCMProtocolMock(@protocol(MPExtensionKitProtocol));
    OCMStub([(id<MPExtensionKitProtocol>)mockKitRegister code]).andReturn(@999);
    OCMStub([self.mockContainer activeKitsRegistry]).andReturn(@[mockKitRegister]);

    NSURL *url = [NSURL URLWithString:@"myapp://afterpay-redirect"];
    BOOL result = [self.rokt handleURLCallback:url];

    XCTAssertFalse(result, @"Should return NO when the Rokt Kit is not registered");
}

- (void)testHandleURLCallbackReturnsNOForNilURL {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    BOOL result = [self.rokt handleURLCallback:nil];
#pragma clang diagnostic pop
    XCTAssertFalse(result, @"Should return NO when url is nil");
}

- (void)testDispatchIgnoresSelectorImplementationsWithoutProtocolConformance {
    MParticle *instance = [MParticle sharedInstance];
    self.mockInstance = OCMPartialMock(instance);
    self.mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[self.mockInstance stub] andReturn:self.mockContainer] kitContainer_PRIVATE];
    [[[self.mockInstance stub] andReturn:self.mockInstance] sharedInstance];

    id mockKitRegister = OCMProtocolMock(@protocol(MPExtensionKitProtocol));
    OCMStub([(id<MPExtensionKitProtocol>)mockKitRegister code]).andReturn(kTestRoktKitId);

    MPRoktNonconformingKitInstance *kitInstance = [[MPRoktNonconformingKitInstance alloc] init];
    kitInstance.sessionIdToReturn = @"should-not-be-used";
    kitInstance.handleURLCallbackReturn = YES;
    OCMStub([mockKitRegister wrapperInstance]).andReturn(kitInstance);
    OCMStub([self.mockContainer activeKitsRegistry]).andReturn(@[mockKitRegister]);

    XCTAssertNil([self.rokt getSessionId]);
    XCTAssertFalse([self.rokt handleURLCallback:[NSURL URLWithString:@"myapp://afterpay-redirect"]]);

    [self.rokt logRoktApiDiagnostic:@"SELECT_PLACEMENTS"];
    XCTAssertNil(kitInstance.lastDiagnosticCode);
}

@end

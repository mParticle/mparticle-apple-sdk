#import <XCTest/XCTest.h>
#import "mParticle.h"
#import "MPBaseTestCase.h"
#import "MPStateMachine.h"
#import "MPSession.h"
#import "MPBackendController.h"
#import "OCMock.h"
#import "MPURLRequestBuilder.h"
#import "MParticleWebView.h"
#import "MPPersistenceController.h"
#import "MPIUserDefaults.h"

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong) MPBackendController *backendController;
- (BOOL)isValidBridgeName:(NSString *)bridgeName;
- (void)handleWebviewCommand:(NSString *)command dictionary:(NSDictionary *)dictionary;
@property (nonatomic, strong) MParticleWebView *webView;

@end

@interface MParticleTests : MPBaseTestCase {
    NSNotification *lastNotification;
    __weak dispatch_block_t testNotificationHandler;
}

@end

@implementation MParticleTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    lastNotification = nil;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    lastNotification = nil;
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

- (void)testOptOutEndsSession {
    MParticle *instance = [MParticle sharedInstance];
    instance.stateMachine = [[MPStateMachine alloc] init];
    instance.optOut = YES;
    
    MParticleSession *session = instance.currentSession;
    XCTAssertNil(session, "Setting Opt Out failed end the current session");
}

- (void)testNonOptOutHasSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    [instance startWithOptions:[MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"]];
    dispatch_async([MParticle messageQueue], ^{
        MParticleSession *session = instance.currentSession;
        XCTAssertNotNil(session, "Not Opted Out but nil current session");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testNoAutoTrackingHasNoSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.automaticSessionTracking = NO;
    [instance startWithOptions:options];
    dispatch_async([MParticle messageQueue], ^{
        MParticleSession *session = instance.currentSession;
        XCTAssertNil(session, "No auto tracking but non-nil current session");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testNoAutoTrackingManualSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.automaticSessionTracking = NO;
    [instance startWithOptions:options];
    [instance beginSession];
    dispatch_async([MParticle messageQueue], ^{
        MParticleSession *session = instance.currentSession;
        XCTAssertNotNil(session, "No auto tracking called begin but nil current session");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testNoAutoTrackingManualEndSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.automaticSessionTracking = NO;
    [instance startWithOptions:options];
    [instance beginSession];
    [instance endSession];
    dispatch_async([MParticle messageQueue], ^{
        MParticleSession *session = instance.currentSession;
        XCTAssertNil(session, "No auto tracking called begin/end but non-nil current session");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

#if TARGET_OS_IOS == 1
- (void)testAutoTrackingContentAvail {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSData *testDeviceToken = [@"<000000000000000000000000000000>" dataUsingEncoding:NSUTF8StringEncoding];
    userDefaults[kMPDeviceTokenKey] = testDeviceToken;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.automaticSessionTracking = YES;
    options.proxyAppDelegate = NO;
    [instance startWithOptions:options];
    [instance endSession];
    
    [instance didReceiveRemoteNotification:@{@"aps":@{@"content-available":@"1"}, @"foo-notif-content": @"foo-notif-content-value"}];
    dispatch_async([MParticle messageQueue], ^{
        MParticleSession *session = instance.currentSession;
        XCTAssertNil(session, "Auto tracking but non-nil current session after content-available push");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testAutoTrackingNonContentAvail {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.automaticSessionTracking = YES;
    options.proxyAppDelegate = NO;
    [instance startWithOptions:options];
    [instance endSession];
    
    [instance didReceiveRemoteNotification:@{@"aps":@{@"alert":@"Testing.. (0)",@"badge":@1,@"sound":@"default"}, @"foo-notif-content": @"foo-notif-content-value"}];
    dispatch_async([MParticle messageQueue], ^{
        MParticleSession *session = instance.currentSession;
        XCTAssertNotNil(session, "Auto tracking but nil current session after non-content-available push");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}
#endif

- (void)testNormalSessionContents {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    [instance startWithOptions:[MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"]];
    dispatch_async([MParticle messageQueue], ^{
        MParticle.sharedInstance.stateMachine.currentSession.uuid = @"76F1ABB9-7A9A-4D4E-AB4D-56C8FF79CAD1";
        MParticleSession *session = instance.currentSession;
        NSNumber *sessionID = session.sessionID;
        NSString *uuid = session.UUID;
        XCTAssertEqualObjects(@"76F1ABB9-7A9A-4D4E-AB4D-56C8FF79CAD1", uuid);
        XCTAssertEqual(-6881666186511944082, sessionID.integerValue);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testOptionsConsentStateInitialNil {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key"
    secret:@"unit-test-secret"];
    MPCCPAConsent *ccpaConsent = [[MPCCPAConsent alloc] init];
    ccpaConsent.consented = YES;
    ccpaConsent.document = @"ccpa_consent_agreement_v3";
    ccpaConsent.timestamp = [[NSDate alloc] init];
    ccpaConsent.location = @"17 Cherry Tree Lane";
    ccpaConsent.hardwareId = @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702";
    
    MPConsentState *newConsentState = [[MPConsentState alloc] init];
    [newConsentState setCCPAConsentState:ccpaConsent];
    [newConsentState setGDPRConsentState:[MParticle sharedInstance].identity.currentUser.consentState.gdprConsentState];

    options.consentState = newConsentState;
    [instance startWithOptions:options];
    dispatch_async([MParticle messageQueue], ^{
        MPConsentState *storedConsentState = [MPPersistenceController consentStateForMpid:[MPPersistenceController mpId]];
        XCTAssert(storedConsentState.ccpaConsentState.consented);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testOptionsConsentStateInitialSet {
    MPCCPAConsent *ccpaConsent = [[MPCCPAConsent alloc] init];
    ccpaConsent.consented = NO;
    ccpaConsent.document = @"ccpa_consent_agreement_v3";
    ccpaConsent.timestamp = [[NSDate alloc] init];
    ccpaConsent.location = @"17 Cherry Tree Lane";
    ccpaConsent.hardwareId = @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702";
    
    MPConsentState *storedConsentState = [[MPConsentState alloc] init];
    [storedConsentState setCCPAConsentState:ccpaConsent];
    [storedConsentState setGDPRConsentState:[MParticle sharedInstance].identity.currentUser.consentState.gdprConsentState];
    [MPPersistenceController setConsentState:storedConsentState forMpid:[MPPersistenceController mpId]];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key"
    secret:@"unit-test-secret"];
    MPCCPAConsent *newCCPAState = [[MPCCPAConsent alloc] init];
    newCCPAState.consented = YES;
    newCCPAState.document = @"ccpa_consent_agreement_v3";
    newCCPAState.timestamp = [[NSDate alloc] init];
    newCCPAState.location = @"17 Cherry Tree Lane";
    newCCPAState.hardwareId = @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702";
    
    MPConsentState *newConsentState = [[MPConsentState alloc] init];
    [newConsentState setCCPAConsentState:newCCPAState];
    [newConsentState setGDPRConsentState:[MParticle sharedInstance].identity.currentUser.consentState.gdprConsentState];

    options.consentState = newConsentState;
    [instance startWithOptions:options];
    dispatch_async([MParticle messageQueue], ^{
        MPConsentState *storedConsentState = [MPPersistenceController consentStateForMpid:[MPPersistenceController mpId]];
        XCTAssertFalse(storedConsentState.ccpaConsentState.consented);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)handleTestSessionStart:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:mParticleSessionDidBeginNotification object:nil];
    lastNotification = notification;
    testNotificationHandler();
}

- (void)handleTestSessionEnd:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:mParticleSessionDidEndNotification object:nil];
    lastNotification = notification;
    testNotificationHandler();
}

- (void)testIsValidBridgeName {
    BOOL valid = [[MParticle sharedInstance] isValidBridgeName:@"abc_123"];
    XCTAssertFalse(valid);
    valid = [[MParticle sharedInstance] isValidBridgeName:@"abc123"];
    XCTAssertTrue(valid);
    valid = [[MParticle sharedInstance] isValidBridgeName:@"àbc123"];
    XCTAssertFalse(valid);
    valid = [[MParticle sharedInstance] isValidBridgeName:@""];
    XCTAssertFalse(valid);
}

#if TARGET_OS_IOS == 1
- (void)testWebviewLogEvent {
    id mockBackend = OCMClassMock([MPBackendController class]);
    
    MPEvent *testEvent = [[MPEvent alloc] initWithName:@"foo webview event 1" type:MPEventTypeNavigation];
    testEvent.customAttributes = @{@"foo webview event attribute 1":@"foo webview event attribute value 1"};
    
    [[[mockBackend expect] ignoringNonObjectArgs] logEvent:[OCMArg checkWithBlock:^BOOL(id value) {
        XCTAssert([value isKindOfClass:[MPEvent class]]);
        MPEvent *returnedEvent = ((MPEvent *)value);
        XCTAssertEqualObjects(returnedEvent.name, testEvent.name);
        XCTAssertEqual(returnedEvent.type, testEvent.type);
        XCTAssertEqualObjects(returnedEvent.customAttributes, testEvent.customAttributes);
        
        return YES;
    }] completionHandler:[OCMArg any]];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    NSString *command = @"logEvent";
    NSDictionary *dictionary = @{@"EventDataType":@(MPJavascriptMessageTypePageEvent), @"EventName":@"foo webview event 1", @"EventCategory":@(MPEventTypeNavigation), @"EventAttributes":@{@"foo webview event attribute 1":@"foo webview event attribute value 1"}};
    [instance handleWebviewCommand:command dictionary:dictionary];
    
    [mockBackend verifyWithDelay:2];
    
    [mockInstance stopMocking];
    [mockBackend stopMocking];
}

- (void)testWebviewLogCommerceAttributes {
    id mockBackend = OCMClassMock([MPBackendController class]);
    
    MPProduct *testProduct = [[MPProduct alloc] initWithName:@"foo product 1" sku:@"12345" quantity:@1 price:@19.95];
    MPCommerceEvent *testEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:testProduct];
    testEvent.customAttributes = @{@"foo webview event attribute 1":@"foo webview event attribute value 1"};
    
    [[[mockBackend expect] ignoringNonObjectArgs] logCommerceEvent:[OCMArg checkWithBlock:^BOOL(id value) {
        XCTAssert([value isKindOfClass:[MPCommerceEvent class]]);
        MPCommerceEvent *returnedEvent = ((MPCommerceEvent *)value);
        XCTAssertEqualObjects(returnedEvent.products[0].name, testProduct.name);
        XCTAssertEqualObjects(returnedEvent.products[0].sku, testProduct.sku);
        XCTAssertEqualObjects(returnedEvent.products[0].quantity, testProduct.quantity);
        XCTAssertEqualObjects(returnedEvent.products[0].price, testProduct.price);
        XCTAssertEqualObjects(returnedEvent.customAttributes, testEvent.customAttributes);
        
        return YES;
    }] completionHandler:[OCMArg any]];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    NSString *command = @"logEvent";
    NSDictionary *dictionary = @{
        @"EventDataType":@(MPJavascriptMessageTypeCommerce),
        @"ProductAction":@{
                @"ProductActionType":@0,
                @"ProductList":@[
                        @{
                            @"Name":@"foo product 1",
                            @"Sku":@"12345",
                            @"Quantity":@1,
                            @"Price": @19.95
                        }
                ]
        },
        @"EventAttributes":@{
                @"foo webview event attribute 1":@"foo webview event attribute value 1"
        }
    };
    [instance handleWebviewCommand:command dictionary:dictionary];
    
    [mockBackend verifyWithDelay:2];
    
    [mockInstance stopMocking];
    [mockBackend stopMocking];
}

- (void)testWebviewLogCommerceInvalidArray {
    id mockBackend = OCMClassMock([MPBackendController class]);
    
    [[mockBackend reject] logCommerceEvent:[OCMArg any] completionHandler:[OCMArg any]];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    NSString *command = @"logEvent";
    NSDictionary *dictionary = (NSDictionary *)@[
        @{
            @"EventDataType":@(MPJavascriptMessageTypeCommerce),
            @"ProductAction":@{
                    @"ProductActionType":@0,
                    @"ProductList":@[
                            @{
                                @"Name":@"foo product 1",
                                @"Sku":@"12345",
                                @"Quantity":@1,
                                @"Price": @19.95
                            }
                    ]
            },
            @"EventAttributes":@{
                    @"foo webview event attribute 1":@"foo webview event attribute value 1"
            }
        }];
    [instance handleWebviewCommand:command dictionary:dictionary];
    
    [mockBackend verifyWithDelay:2];
    
    [mockInstance stopMocking];
    [mockBackend stopMocking];
}

- (void)testWebviewLogCommerceInvalidArrayValues {
    id mockBackend = OCMClassMock([MPBackendController class]);
    
    [[mockBackend reject] logCommerceEvent:[OCMArg any] completionHandler:[OCMArg any]];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    NSString *command = @"logEvent";
    NSDictionary *dictionary = @{
            @"EventDataType":@(MPJavascriptMessageTypeCommerce),
            @"ProductAction":@{
                    @"ProductActionType":@[],
                    @"ProductList":@[
                            @{
                                @"Name":@[],
                                @"Sku":@[],
                                @"Quantity":@[],
                                @"Price": @[]
                            }
                    ]
            },
            @"EventAttributes":@{
                    @"foo webview event attribute 1":@[]
            }
        };
    [instance handleWebviewCommand:command dictionary:dictionary];
    
    [mockBackend verifyWithDelay:2];
    
    [mockInstance stopMocking];
    [mockBackend stopMocking];
}

- (void)testWebviewLogCommerceNull {
    id mockBackend = OCMClassMock([MPBackendController class]);
    
    [[[mockBackend expect] ignoringNonObjectArgs] logCommerceEvent:[OCMArg checkWithBlock:^BOOL(id value) {
        XCTAssert([value isKindOfClass:[MPCommerceEvent class]]);
        MPCommerceEvent *returnedEvent = ((MPCommerceEvent *)value);
        XCTAssertNotEqual((NSNull *)returnedEvent.currency, [NSNull null]);
        
        return YES;
    }] completionHandler:[OCMArg any]];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    NSString *command = @"logEvent";
    NSDictionary *dictionary = @{
        @"EventDataType":@(MPJavascriptMessageTypeCommerce),
        @"ProductAction":@{
                @"ProductActionType":@0,
                @"ProductList":@[
                        @{
                            @"Name":@"foo product 1",
                            @"Sku":@"12345",
                            @"Quantity":@1,
                            @"Price": @19.95
                        }
                ]
        },
        @"CurrencyCode":[NSNull null],
        @"EventAttributes":@{
                @"foo webview event attribute 1":@"foo webview event attribute value 1"
        }
    };
    
    [instance handleWebviewCommand:command dictionary:dictionary];
    
    [mockBackend verifyWithDelay:2];
    
    [mockInstance stopMocking];
    [mockBackend stopMocking];
}
- (void)testTrackNotificationsDefault {
    id mockBackend = OCMClassMock([MPBackendController class]);
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    [mockInstance startWithOptions:options];
    
    XCTAssertTrue(instance.trackNotifications, "By Default Track Notifications should be set to true");
    
    [mockInstance stopMocking];
    [mockBackend stopMocking];
}

- (void)testTrackNotificationsOff {
    id mockBackend = OCMClassMock([MPBackendController class]);
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.trackNotifications = NO;
    [mockInstance startWithOptions:options];
    
    XCTAssertFalse(instance.trackNotifications, "Track Notifications failed to set False");
    
    [mockInstance stopMocking];
    [mockBackend stopMocking];
}

- (void)testTrackNotificationsOn {
    id mockBackend = OCMClassMock([MPBackendController class]);
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.trackNotifications = YES;
    [mockInstance startWithOptions:options];
    
    XCTAssertTrue(instance.trackNotifications, "Track Notifications failed to set True");
    
    [mockInstance stopMocking];
    [mockBackend stopMocking];
}

- (void)testSessionStartNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTestSessionStart:) name:mParticleSessionDidBeginNotification object:nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    __strong dispatch_block_t block = ^{
        XCTAssertNotNil(self->lastNotification);
        NSDictionary *userInfo = self->lastNotification.userInfo;
        XCTAssertEqual(2, userInfo.count);
        NSNumber *sessionID = userInfo[mParticleSessionId];
        XCTAssertEqualObjects(NSStringFromClass([sessionID class]), @"__NSCFNumber");
        NSString *sessionUUID = userInfo[mParticleSessionUUID];
        XCTAssertEqualObjects(NSStringFromClass([sessionUUID class]), @"__NSCFString");
        [expectation fulfill];
    };
    testNotificationHandler = block;
    MParticle *instance = [MParticle sharedInstance];
    [instance startWithOptions:[MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"]];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    testNotificationHandler = nil;
}

- (void)testSessionEndNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTestSessionEnd:) name:mParticleSessionDidEndNotification object:nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    __strong dispatch_block_t block = ^{
        XCTAssertNotNil(self->lastNotification);
        NSDictionary *userInfo = self->lastNotification.userInfo;
        XCTAssertEqual(2, userInfo.count);
        NSNumber *sessionID = userInfo[mParticleSessionId];
        XCTAssertEqualObjects(NSStringFromClass([sessionID class]), @"__NSCFNumber");
        NSString *sessionUUID = userInfo[mParticleSessionUUID];
        XCTAssertEqualObjects(NSStringFromClass([sessionUUID class]), @"__NSCFString");
        [expectation fulfill];
    };
    testNotificationHandler = block;
    MParticle *instance = [MParticle sharedInstance];
    [instance startWithOptions:[MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"]];
    dispatch_async([MParticle messageQueue], ^{
        [[MParticle sharedInstance].backendController endSession];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
    testNotificationHandler = nil;
}

- (void)testLogNotificationWithUserInfo {
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturnValue:OCMOCK_VALUE(NO)] trackNotifications];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];

    id mockBackendController = OCMClassMock([MPBackendController class]);
    instance.backendController = mockBackendController;
    
    NSNotification *testNotification = [[NSNotification alloc] initWithName:@"tester" object:self userInfo:@{@"foo-notif-key-1":@"foo-notif-value-1"}];
    
    [[mockBackendController expect] logUserNotification:OCMOCK_ANY];
    
    [mockInstance logNotificationOpenedWithUserInfo:[testNotification userInfo]];
    
    [mockBackendController verifyWithDelay:1.0];
    [mockBackendController stopMocking];
    [mockInstance stopMocking];
}
#endif

- (void)testLogNilEvent {
    MParticle *instance = [MParticle sharedInstance];
    NSException *e = nil;
    @try {
        [instance logEvent:(id _Nonnull)nil];
    } @catch (NSException *ex) {
        e = ex;
    }
    XCTAssertNil(e);
}

- (void)testLogNilScreenEvent {
    MParticle *instance = [MParticle sharedInstance];
    NSException *e = nil;
    @try {
        [instance logScreenEvent:(id _Nonnull)nil];
    } @catch (NSException *ex) {
        e = ex;
    }
    XCTAssertNil(e);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)testLogNilCommerceEvent {
    MParticle *instance = [MParticle sharedInstance];
    NSException *e = nil;
    @try {
        [instance logCommerceEvent:(id _Nonnull)nil];
    } @catch (NSException *ex) {
        e = ex;
    }
    XCTAssertNil(e);
}
#pragma clang diagnostic pop

- (void)testUserAgentDefault {
    id mockWebView = OCMClassMock([MParticleWebView class]);
#if TARGET_OS_IOS == 1
    [[[mockWebView stub] andReturn:@"Example resolved agent"] userAgent];
#else
    [[[mockWebView stub] andReturn:[NSString stringWithFormat:@"mParticle Apple SDK/%@", MParticle.sharedInstance.version]] userAgent];
#endif
    id mockMParticle = OCMPartialMock([MParticle sharedInstance]);
    [[[mockMParticle stub] andReturn:mockWebView] webView];
    NSURL *url = [NSURL URLWithString:@"https://nativesdks.mparticle.com"];
    NSMutableURLRequest *urlRequest = [[MPURLRequestBuilder newBuilderWithURL:url message:nil httpMethod:kMPHTTPMethodGet] build];
    NSDictionary *fields = urlRequest.allHTTPHeaderFields;
    NSString *actualAgent = fields[@"User-Agent"];
    NSString *defaultAgent = [NSString stringWithFormat:@"mParticle Apple SDK/%@", MParticle.sharedInstance.version];
    #if TARGET_OS_IOS == 1
    XCTAssertNotEqualObjects(actualAgent, defaultAgent);
    #else
    XCTAssertEqualObjects(actualAgent, defaultAgent);
    #endif
    [mockWebView stopMocking];
    [mockMParticle stopMocking];
}

- (void)testUserAgentCustom {
    NSString *customAgent = @"Foo 1.2.3 Like Bar";
    id mockWebView = OCMClassMock([MParticleWebView class]);
    [[[mockWebView stub] andReturn:customAgent] userAgent];
    id mockMParticle = OCMPartialMock([MParticle sharedInstance]);
    [[[mockMParticle stub] andReturn:mockWebView] webView];
    
    NSURL *url = [NSURL URLWithString:@"https://nativesdks.mparticle.com"];
    NSMutableURLRequest *urlRequest = [[MPURLRequestBuilder newBuilderWithURL:url message:nil httpMethod:kMPHTTPMethodGet] build];
    NSDictionary *fields = urlRequest.allHTTPHeaderFields;
    NSString *actualAgent = fields[@"User-Agent"];
    XCTAssertEqualObjects(actualAgent, customAgent);
    
    [mockMParticle stopMocking];
    [mockWebView stopMocking];
}

@end

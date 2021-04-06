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
#import "MPURL.h"
#import "MPDevice.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong) MPBackendController *backendController;
- (BOOL)isValidBridgeName:(NSString *)bridgeName;
- (void)handleWebviewCommand:(NSString *)command dictionary:(NSDictionary *)dictionary;
@property (nonatomic, strong) MParticleWebView *webView;

@end

@interface MParticleUser ()
- (void)setIdentitySync:(NSString *)identityString identityType:(MPIdentity)identityType;
- (void)setUserId:(NSNumber *)userId;

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

- (void)testInitStartsSessionSync {
    MParticle *instance = [MParticle sharedInstance];
    [instance startWithOptions:[MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"]];
    MParticleSession *session = instance.currentSession;
    XCTAssertNotNil(session, "Nil current session immediately after SDK init");
}

- (void)testInitStartsSessionSyncDisable {
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.shouldBeginSession = NO;
    [instance startWithOptions:options];
    MParticleSession *session = instance.currentSession;
    XCTAssertNil(session, "No begin session flag, but non-nil current session immediately after SDK init");
}

- (void)testInitStartsSessionSyncDisableAll {
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.shouldBeginSession = NO;
    options.automaticSessionTracking = NO;
    [instance startWithOptions:options];
    MParticleSession *session = instance.currentSession;
    XCTAssertNil(session, "No begin session (or auto tracking) flags, but non-nil current session immediately after SDK init");
}

- (void)testNoAutoTrackingHasNoSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.automaticSessionTracking = NO;
    options.shouldBeginSession = NO;
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
    options.shouldBeginSession = NO;
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
    options.shouldBeginSession = NO;
    [instance startWithOptions:options];
    [instance beginSession];
    XCTAssertNotNil(instance.currentSession, "No auto tracking called begin but nil current session");
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
    
    [instance didReceiveRemoteNotification:@{@"aps":@{@"content-available":@1}, @"foo-notif-content": @"foo-notif-content-value"}];
    dispatch_async([MParticle messageQueue], ^{
        MParticleSession *session = instance.currentSession;
        XCTAssertNil(session, "Auto tracking but non-nil current session after content-available push");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testEventStartSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.automaticSessionTracking = YES;
    options.proxyAppDelegate = NO;
    [instance startWithOptions:options];
    [instance endSession];
    
    MPBaseEvent *sessionEvent = [[MPEvent alloc] initWithName:@"foo-event" type:MPEventTypeOther];
    XCTAssertTrue(sessionEvent.shouldBeginSession);
    [instance logEvent:sessionEvent];
    dispatch_async([MParticle messageQueue], ^{
        MParticleSession *session = instance.currentSession;
        XCTAssertNotNil(session, "Auto tracking but nil current session after an event logged with startSession = YES");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testEventNoStartSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.automaticSessionTracking = YES;
    options.proxyAppDelegate = NO;
    [instance startWithOptions:options];
    [instance endSession];
    
    MPBaseEvent *sessionEvent = [[MPEvent alloc] initWithName:@"foo-event" type:MPEventTypeOther];
    sessionEvent.shouldBeginSession = NO;
    XCTAssertFalse(sessionEvent.shouldBeginSession);
    [instance logEvent:sessionEvent];
    dispatch_async([MParticle messageQueue], ^{
        MParticleSession *session = instance.currentSession;
        XCTAssertNil(session, "Auto tracking but non-nil current session after an event logged with startSession = YES");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testEventStartSessionManual {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.automaticSessionTracking = NO;
    options.proxyAppDelegate = NO;
    [instance startWithOptions:options];
    [instance endSession];
    
    MPBaseEvent *sessionEvent = [[MPEvent alloc] initWithName:@"foo-event" type:MPEventTypeOther];
    XCTAssertTrue(sessionEvent.shouldBeginSession);
    [instance logEvent:sessionEvent];
    dispatch_async([MParticle messageQueue], ^{
        MParticleSession *session = instance.currentSession;
        XCTAssertNotNil(session, "No auto tracking but nil current session after an event logged with startSession = YES");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testEventNoStartSessionManual {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.automaticSessionTracking = NO;
    options.proxyAppDelegate = NO;
    [instance startWithOptions:options];
    [instance endSession];
    
    MPBaseEvent *sessionEvent = [[MPEvent alloc] initWithName:@"foo-event" type:MPEventTypeOther];
    sessionEvent.shouldBeginSession = NO;
    XCTAssertFalse(sessionEvent.shouldBeginSession);
    [instance logEvent:sessionEvent];
    dispatch_async([MParticle messageQueue], ^{
        MParticleSession *session = instance.currentSession;
        XCTAssertNil(session, "No auto tracking but non-nil current session after an event logged with startSession = YES");
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
    
    [mockBackend verifyWithDelay:5];
    
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
    
    [mockBackend verifyWithDelay:5];
    
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
    
    [mockBackend verifyWithDelay:5];
    
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
    
    [mockBackend verifyWithDelay:5];
    
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
    
    [mockBackend verifyWithDelay:5];
    
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
    
    [mockInstance logNotificationOpenedWithUserInfo:[testNotification userInfo] andActionIdentifier:nil];
    
    [mockBackendController verifyWithDelay:5.0];
    [mockBackendController stopMocking];
    [mockInstance stopMocking];
}
#endif

- (void)testATTAuthorizationStatusNotDetermined {
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.attStatus = @(MPATTAuthorizationStatusNotDetermined);
    [instance startWithOptions:options];
    MPStateMachine *stateMachine = instance.stateMachine;
    XCTAssertEqual(stateMachine.attAuthorizationStatus.integerValue, MPATTAuthorizationStatusNotDetermined);
    XCTAssert(stateMachine.attAuthorizationTimestamp);
}

- (void)testATTAuthorizationStatusRestricted {
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.attStatus = @(MPATTAuthorizationStatusRestricted);
    [instance startWithOptions:options];
    MPStateMachine *stateMachine = instance.stateMachine;
    XCTAssertEqual(stateMachine.attAuthorizationStatus.integerValue, MPATTAuthorizationStatusRestricted);
    XCTAssert(stateMachine.attAuthorizationTimestamp);
}

- (void)testATTAuthorizationStatusDenied {
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.attStatus = @(MPATTAuthorizationStatusDenied);
    [instance startWithOptions:options];
    MPStateMachine *stateMachine = instance.stateMachine;
    XCTAssertEqual(stateMachine.attAuthorizationStatus.integerValue, MPATTAuthorizationStatusDenied);
    XCTAssert(stateMachine.attAuthorizationTimestamp);
}

- (void)testATTAuthorizationStatusAuthorized {
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.attStatus = @(MPATTAuthorizationStatusAuthorized);
    [instance startWithOptions:options];
    MPStateMachine *stateMachine = instance.stateMachine;
    XCTAssertEqual(stateMachine.attAuthorizationStatus.integerValue, MPATTAuthorizationStatusAuthorized);
    XCTAssert(stateMachine.attAuthorizationTimestamp);
}

- (void)testattAuthorizationStatusWithTimestamp {
    MParticle *instance = [MParticle sharedInstance];
    NSNumber *testTimestamp = @([[NSDate date] timeIntervalSince1970] - 400);
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.attStatus = @(MPATTAuthorizationStatusRestricted);
    options.attStatusTimestampMillis = testTimestamp;
    [instance startWithOptions:options];
    MPStateMachine *stateMachine = instance.stateMachine;
    XCTAssertEqual(stateMachine.attAuthorizationStatus.integerValue, MPATTAuthorizationStatusRestricted);
    XCTAssertEqual(instance.stateMachine.attAuthorizationTimestamp.doubleValue, testTimestamp.doubleValue);
}

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

- (void)testSetATTStatusNotDetermined {
    MParticle *instance = [MParticle sharedInstance];
    MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
    [currentUser setIdentitySync:@"12345" identityType:MPIdentityIOSAdvertiserId];
    
    XCTAssertEqualObjects(@"12345", currentUser.identities[@(MPIdentityIOSAdvertiserId)]);
    
    NSException *e = nil;
    @try {
        [instance setATTStatus:(MPATTAuthorizationStatus)MPATTAuthorizationStatusNotDetermined withATTStatusTimestampMillis:nil];
    } @catch (NSException *ex) {
        e = ex;
    }
    XCTAssertNil(e);
    
    XCTAssertEqual(instance.stateMachine.attAuthorizationStatus.intValue, MPATTAuthorizationStatusNotDetermined);
    XCTAssert(instance.stateMachine.attAuthorizationTimestamp);
    
    MPDevice *device = [[MPDevice alloc] init];
    NSDictionary *deviceDict = [device dictionaryRepresentation];
    
    XCTAssertEqualObjects(deviceDict[kMPATT], @"not_determined");
    XCTAssert(deviceDict[kMPATTTimestamp]);
    
    currentUser = [[[MParticle sharedInstance] identity] currentUser];
    XCTAssertNil(currentUser.identities[@(MPIdentityIOSAdvertiserId)]);
}

- (void)testSetATTStatusRestricted {
    MParticle *instance = [MParticle sharedInstance];
    MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
    [currentUser setIdentitySync:@"12345" identityType:MPIdentityIOSAdvertiserId];
    
    XCTAssertEqualObjects(@"12345", currentUser.identities[@(MPIdentityIOSAdvertiserId)]);
    
    NSException *e = nil;
    @try {
        [instance setATTStatus:(MPATTAuthorizationStatus)MPATTAuthorizationStatusRestricted withATTStatusTimestampMillis:nil];
    } @catch (NSException *ex) {
        e = ex;
    }
    XCTAssertNil(e);
    
    XCTAssertEqual(instance.stateMachine.attAuthorizationStatus.intValue, MPATTAuthorizationStatusRestricted);
    XCTAssert(instance.stateMachine.attAuthorizationTimestamp);
    
    MPDevice *device = [[MPDevice alloc] init];
    NSDictionary *deviceDict = [device dictionaryRepresentation];
    
    XCTAssertEqualObjects(deviceDict[kMPATT], @"restricted");
    XCTAssert(deviceDict[kMPATTTimestamp]);
    
    currentUser = [[[MParticle sharedInstance] identity] currentUser];
    XCTAssertNil(currentUser.identities[@(MPIdentityIOSAdvertiserId)]);
}

- (void)testSetATTStatusDenied {
    MParticle *instance = [MParticle sharedInstance];
    MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
    [currentUser setIdentitySync:@"12345" identityType:MPIdentityIOSAdvertiserId];
    
    XCTAssertEqualObjects(@"12345", currentUser.identities[@(MPIdentityIOSAdvertiserId)]);
    
    NSException *e = nil;
    @try {
        [instance setATTStatus:(MPATTAuthorizationStatus)MPATTAuthorizationStatusDenied withATTStatusTimestampMillis:nil];
    } @catch (NSException *ex) {
        e = ex;
    }
    XCTAssertNil(e);
    
    XCTAssertEqual(instance.stateMachine.attAuthorizationStatus.intValue, MPATTAuthorizationStatusDenied);
    XCTAssert(instance.stateMachine.attAuthorizationTimestamp);
    
    MPDevice *device = [[MPDevice alloc] init];
    NSDictionary *deviceDict = [device dictionaryRepresentation];
    
    XCTAssertEqualObjects(deviceDict[kMPATT], @"denied");
    XCTAssert(deviceDict[kMPATTTimestamp]);
    
    currentUser = [[[MParticle sharedInstance] identity] currentUser];
    XCTAssertNil(currentUser.identities[@(MPIdentityIOSAdvertiserId)]);
}

- (void)testSetATTStatusAuthorized {
    MParticle *instance = [MParticle sharedInstance];
    MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
    [currentUser setIdentitySync:@"12345" identityType:MPIdentityIOSAdvertiserId];
    
    XCTAssertEqualObjects(@"12345", currentUser.identities[@(MPIdentityIOSAdvertiserId)]);
    
    NSException *e = nil;
    @try {
        [instance setATTStatus:(MPATTAuthorizationStatus)MPATTAuthorizationStatusAuthorized withATTStatusTimestampMillis:nil];
    } @catch (NSException *ex) {
        e = ex;
    }
    XCTAssertNil(e);
    
    XCTAssertEqual(instance.stateMachine.attAuthorizationStatus.intValue, MPATTAuthorizationStatusAuthorized);
    XCTAssert(instance.stateMachine.attAuthorizationTimestamp);
    
    MPDevice *device = [[MPDevice alloc] init];
    NSDictionary *deviceDict = [device dictionaryRepresentation];
    
    XCTAssertEqualObjects(deviceDict[kMPATT], @"authorized");
    XCTAssert(deviceDict[kMPATTTimestamp]);
    
    currentUser = [[[MParticle sharedInstance] identity] currentUser];
    XCTAssertEqualObjects(@"12345", currentUser.identities[@(MPIdentityIOSAdvertiserId)]);
}

- (void)testSetATTStatusWithTimestamp {
    MParticle *instance = [MParticle sharedInstance];
    MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
    [currentUser setIdentitySync:@"12345" identityType:MPIdentityIOSAdvertiserId];
    
    XCTAssertEqualObjects(@"12345", currentUser.identities[@(MPIdentityIOSAdvertiserId)]);

    NSNumber *testTimestamp = @([[NSDate date] timeIntervalSince1970] - 400);
    NSException *e = nil;
    @try {
        [instance setATTStatus:(MPATTAuthorizationStatus)MPATTAuthorizationStatusAuthorized withATTStatusTimestampMillis:testTimestamp];
    } @catch (NSException *ex) {
        e = ex;
    }
    XCTAssertNil(e);
    
    XCTAssertEqual(instance.stateMachine.attAuthorizationStatus.intValue, MPATTAuthorizationStatusAuthorized);
    XCTAssertEqual(instance.stateMachine.attAuthorizationTimestamp.doubleValue, testTimestamp.doubleValue);
    
    MPDevice *device = [[MPDevice alloc] init];
    NSDictionary *deviceDict = [device dictionaryRepresentation];
    
    XCTAssertEqualObjects(deviceDict[kMPATT], @"authorized");
    XCTAssertEqual(((NSNumber *)deviceDict[kMPATTTimestamp]).doubleValue, testTimestamp.doubleValue);
    
    currentUser = [[[MParticle sharedInstance] identity] currentUser];
    XCTAssertEqualObjects(@"12345", currentUser.identities[@(MPIdentityIOSAdvertiserId)]);
}

- (void)testSetATTStatusRemoveIDFA {
    MParticle *instance = [MParticle sharedInstance];
    MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
    [currentUser setIdentitySync:@"12345" identityType:MPIdentityIOSAdvertiserId];

    XCTAssertEqualObjects(@"12345", currentUser.identities[@(MPIdentityIOSAdvertiserId)]);

    NSException *e = nil;
    @try {
        [instance setATTStatus:(MPATTAuthorizationStatus)MPATTAuthorizationStatusDenied withATTStatusTimestampMillis:nil];
    } @catch (NSException *ex) {
        e = ex;
    }
    XCTAssertNil(e);
    
    XCTAssertEqual(instance.stateMachine.attAuthorizationStatus.intValue, MPATTAuthorizationStatusDenied);
    XCTAssert(instance.stateMachine.attAuthorizationTimestamp);
    
    MPDevice *device = [[MPDevice alloc] init];
    NSDictionary *deviceDict = [device dictionaryRepresentation];
    
    XCTAssertEqualObjects(deviceDict[kMPATT], @"denied");
    XCTAssert(deviceDict[kMPATTTimestamp]);
    
    currentUser = [[[MParticle sharedInstance] identity] currentUser];
    XCTAssertNil(currentUser.identities[@(MPIdentityIOSAdvertiserId)]);
}

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
    MPURL *mpURL = [[MPURL alloc] initWithURL:url defaultURL:url];
    NSMutableURLRequest *urlRequest = [[MPURLRequestBuilder newBuilderWithURL:mpURL message:nil httpMethod:kMPHTTPMethodGet] build];
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
    MPURL *mpURL = [[MPURL alloc] initWithURL:url defaultURL:url];
    NSMutableURLRequest *urlRequest = [[MPURLRequestBuilder newBuilderWithURL:mpURL message:nil httpMethod:kMPHTTPMethodGet] build];
    NSDictionary *fields = urlRequest.allHTTPHeaderFields;
    NSString *actualAgent = fields[@"User-Agent"];
    XCTAssertEqualObjects(actualAgent, customAgent);
    
    [mockMParticle stopMocking];
    [mockWebView stopMocking];
}

#pragma mark Error, Exception, and Crash Handling Tests

- (void)testLogCrash {
    id mockBackend = OCMClassMock([MPBackendController class]);
    
    NSString *message = @"crash report";
    NSString *stackTrace = @"stack track from crash report";
    NSString* plCrashReport = @"plcrash report test string";
    
    [[[mockBackend expect] ignoringNonObjectArgs] logCrash:message stackTrace:stackTrace plCrashReport:plCrashReport completionHandler:[OCMArg any]];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    [instance logCrash:message stackTrace:stackTrace plCrashReport:plCrashReport];
    
    [mockBackend verifyWithDelay:5];
    
    [mockInstance stopMocking];
    [mockBackend stopMocking];
}

- (void)testLogCrashNilMessage {
    id mockBackend = OCMClassMock([MPBackendController class]);
    
    NSString *message = nil;
    NSString *stackTrace = @"stack track from crash report";
    NSString* plCrashReport = @"plcrash report test string";
    
    [[[mockBackend expect] ignoringNonObjectArgs] logCrash:message stackTrace:stackTrace plCrashReport:plCrashReport completionHandler:[OCMArg any]];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    [instance logCrash:message stackTrace:stackTrace plCrashReport:plCrashReport];
    
    [mockBackend verifyWithDelay:5];
    
    [mockInstance stopMocking];
    [mockBackend stopMocking];
}

- (void)testLogCrashNilStackTrace {
    id mockBackend = OCMClassMock([MPBackendController class]);
    
    NSString *message = @"crash report";
    NSString *stackTrace = nil;
    NSString* plCrashReport = @"plcrash report test string";
    
    [[[mockBackend expect] ignoringNonObjectArgs] logCrash:message stackTrace:stackTrace plCrashReport:plCrashReport completionHandler:[OCMArg any]];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    [instance logCrash:message stackTrace:stackTrace plCrashReport:plCrashReport];
    
    [mockBackend verifyWithDelay:5];
    
    [mockInstance stopMocking];
    [mockBackend stopMocking];
}

- (void)testLogCrashNilPlCrashReport {
    // TODO: implement method to verify that logCrash is not invoked at MPBackendController
}

@end

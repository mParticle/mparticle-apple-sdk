#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "mParticle.h"
#import "MPBaseTestCase.h"
#import "MPStateMachine.h"
#import "MPSession.h"
#import "MPBackendController.h"
#import "MPURLRequestBuilder.h"
#import "MPPersistenceController.h"
#import "MPURL.h"
#import "MPKitContainer.h"
#import "MPKitTestClassSideloaded.h"
#import "MPKitTestClassNoStartImmediately.h"
#import "MPKitConfiguration.h"
#import "MParticleSwift.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import "MPIConstants.h"
#import "MPForwardQueueParameters.h"

@interface MParticle ()
+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong) MParticleOptions *options;
- (BOOL)isValidBridgeName:(NSString *)bridgeName;
- (void)handleWebviewCommand:(NSString *)command dictionary:(NSDictionary *)dictionary;
+ (void)_setWrapperSdk_internal:(MPWrapperSdk)wrapperSdk version:(nonnull NSString *)wrapperSdkVersion;
@property (nonatomic, strong) MParticleWebView_PRIVATE *webView;
@end

@interface MParticleUser ()
- (void)setIdentitySync:(NSString *)identityString identityType:(MPIdentity)identityType;
- (void)setUserId:(NSNumber *)userId;
@end

@interface MPKitContainer_PRIVATE ()
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MPKitConfiguration *> *kitConfigurations;
+ (NSMutableSet <id<MPExtensionKitProtocol>> *)kitsRegistry;
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
    
    // Ensure registeredKits is empty
    [MPKitContainer_PRIVATE.kitsRegistry removeAllObjects];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    lastNotification = nil;
}

- (void)testDeprecatedResetInstance {
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

- (void)testResetInstance {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    MParticle *instance2 = [MParticle sharedInstance];
    XCTAssertNotNil(instance);
    XCTAssertEqual(instance, instance2);
    [instance reset:^{
        MParticle *instance3 = [MParticle sharedInstance];
        MParticle *instance4 = [MParticle sharedInstance];
        XCTAssertNotEqual(instance, instance3);
        XCTAssertEqual(instance3, instance4);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testOptOut {
    MParticle *instance = [MParticle sharedInstance];
    instance.stateMachine = [[MPStateMachine_PRIVATE alloc] init];
    
    XCTAssertFalse(instance.optOut, "By Default Opt Out should be set to false");
    
    instance.optOut = YES;
    XCTAssert(instance.optOut, "Opt Out failed to set True");
    
    instance.optOut = NO;
    XCTAssertFalse(instance.optOut, "Opt Out failed to set False");
}

- (void)testOptOutEndsSession {
    MParticle *instance = [MParticle sharedInstance];
    instance.stateMachine = [[MPStateMachine_PRIVATE alloc] init];
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
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
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
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
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
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
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
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

#if TARGET_OS_IOS == 1
- (void)testAutoTrackingContentAvail {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
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
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
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
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
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
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
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
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
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
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
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
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
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
        MPConsentState *storedConsentState = [MPPersistenceController_PRIVATE consentStateForMpid:[MPPersistenceController_PRIVATE mpId]];
        XCTAssert(storedConsentState.ccpaConsentState.consented);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
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
    [MPPersistenceController_PRIVATE setConsentState:storedConsentState forMpid:[MPPersistenceController_PRIVATE mpId]];
    
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
        MPConsentState *storedConsentState = [MPPersistenceController_PRIVATE consentStateForMpid:[MPPersistenceController_PRIVATE mpId]];
        XCTAssertFalse(storedConsentState.ccpaConsentState.consented);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
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
    id mockBackend = OCMClassMock([MPBackendController_PRIVATE class]);
    
    MPEvent *testEvent = [[MPEvent alloc] initWithName:@"foo webview event 1" type:MPEventTypeNavigation];
    testEvent.customAttributes = @{@"foo webview event attribute 1":@"foo webview event attribute value 1"};
    [testEvent addCustomFlags:@[@"test1", @"test2"] withKey:@"testKeys"];
    
    [[[mockBackend expect] ignoringNonObjectArgs] logEvent:[OCMArg checkWithBlock:^BOOL(id value) {
        XCTAssert([value isKindOfClass:[MPEvent class]]);
        MPEvent *returnedEvent = ((MPEvent *)value);
        XCTAssertEqualObjects(returnedEvent.name, testEvent.name);
        XCTAssertEqual(returnedEvent.type, testEvent.type);
        XCTAssertEqualObjects(returnedEvent.customAttributes, testEvent.customAttributes);
        XCTAssertEqualObjects(returnedEvent.customFlags, testEvent.customFlags);
        
        return YES;
    }] completionHandler:[OCMArg any]];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    NSString *command = @"logEvent";
    NSDictionary *dictionary = @{@"EventDataType":@(MPJavascriptMessageTypePageEvent), @"EventName":@"foo webview event 1", @"EventCategory":@(MPEventTypeNavigation), @"CustomFlags":@{@"testKeys":@[@"test1", @"test2"]}, @"EventAttributes":@{@"foo webview event attribute 1":@"foo webview event attribute value 1"}};
    [instance handleWebviewCommand:command dictionary:dictionary];
    
    [mockBackend verifyWithDelay:5];
}

- (void)testWebviewLogScreenEvent {
    id mockBackend = OCMClassMock([MPBackendController_PRIVATE class]);
    
    MPEvent *testEvent = [[MPEvent alloc] initWithName:@"foo Page View" type:MPEventTypeNavigation];
    testEvent.customAttributes = @{@"foo webview event attribute 1":@"foo webview event attribute value 1"};
    [testEvent addCustomFlag:@"test1" withKey:@"testKeys"];
    
    [[[mockBackend expect] ignoringNonObjectArgs] logScreen:[OCMArg checkWithBlock:^BOOL(id value) {
        XCTAssert([value isKindOfClass:[MPEvent class]]);
        MPEvent *returnedEvent = ((MPEvent *)value);
        XCTAssertEqualObjects(returnedEvent.name, testEvent.name);
        XCTAssertEqual(returnedEvent.type, testEvent.type);
        XCTAssertEqualObjects(returnedEvent.customAttributes, testEvent.customAttributes);
        XCTAssertEqualObjects(returnedEvent.customFlags, testEvent.customFlags);
        
        return YES;
    }] completionHandler:[OCMArg any]];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    NSString *command = @"logEvent";
    NSDictionary *dictionary = @{@"EventDataType":@(MPJavascriptMessageTypePageView), @"EventName":@"foo Page View", @"EventCategory":@(MPEventTypeNavigation), @"CustomFlags":@{@"testKeys":@[@"test1"]}, @"EventAttributes":@{@"foo webview event attribute 1":@"foo webview event attribute value 1"}};
    [instance handleWebviewCommand:command dictionary:dictionary];
    
    [mockBackend verifyWithDelay:5];
}

- (void)testWebviewLogCommerceAttributes {
    id mockBackend = OCMClassMock([MPBackendController_PRIVATE class]);
    
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
}

- (void)testWebviewLogCommerceInvalidArray {
    id mockBackend = OCMClassMock([MPBackendController_PRIVATE class]);
    
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
}

- (void)testWebviewLogCommerceInvalidArrayValues {
    id mockBackend = OCMClassMock([MPBackendController_PRIVATE class]);
    
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
}

- (void)testWebviewLogCommerceNull {
    id mockBackend = OCMClassMock([MPBackendController_PRIVATE class]);
    
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
}
- (void)testTrackNotificationsDefault {
    id mockBackend = OCMClassMock([MPBackendController_PRIVATE class]);
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    [mockInstance startWithOptions:options];
    
    XCTAssertTrue(instance.trackNotifications, "By Default Track Notifications should be set to true");
}

- (void)testTrackNotificationsOff {
    id mockBackend = OCMClassMock([MPBackendController_PRIVATE class]);
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.trackNotifications = NO;
    [mockInstance startWithOptions:options];
    
    XCTAssertFalse(instance.trackNotifications, "Track Notifications failed to set False");
}

- (void)testTrackNotificationsOn {
    id mockBackend = OCMClassMock([MPBackendController_PRIVATE class]);
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.trackNotifications = YES;
    [mockInstance startWithOptions:options];
    
    XCTAssertTrue(instance.trackNotifications, "Track Notifications failed to set True");
}

- (void)testSessionStartNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTestSessionStart:) name:mParticleSessionDidBeginNotification object:nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    __strong dispatch_block_t block = ^{
        XCTAssertNotNil(self->lastNotification);
        NSDictionary *userInfo = self->lastNotification.userInfo;
        XCTAssertEqual(2, userInfo.count);
        NSNumber *sessionID = userInfo[mParticleSessionId];
        XCTAssertTrue([sessionID isKindOfClass:[NSNumber class]]);
        NSString *sessionUUID = userInfo[mParticleSessionUUID];
        XCTAssertTrue([sessionUUID isKindOfClass:[NSString class]]);
        [expectation fulfill];
    };
    testNotificationHandler = block;
    MParticle *instance = [MParticle sharedInstance];
    [instance startWithOptions:[MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"]];
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
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
        XCTAssertTrue([sessionID isKindOfClass:[NSNumber class]]);
        NSString *sessionUUID = userInfo[mParticleSessionUUID];
        XCTAssertTrue([sessionUUID isKindOfClass:[NSString class]]);
        [expectation fulfill];
    };
    testNotificationHandler = block;
    MParticle *instance = [MParticle sharedInstance];
    [instance startWithOptions:[MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"]];
    dispatch_async([MParticle messageQueue], ^{
        [[MParticle sharedInstance].backendController endSession];
    });
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
    testNotificationHandler = nil;
}

- (void)testLogNotificationWithUserInfo {
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturnValue:OCMOCK_VALUE(NO)] trackNotifications];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];

    id mockBackendController = OCMClassMock([MPBackendController_PRIVATE class]);
    instance.backendController = mockBackendController;
    
    NSNotification *testNotification = [[NSNotification alloc] initWithName:@"tester" object:self userInfo:@{@"foo-notif-key-1":@"foo-notif-value-1"}];
    
    [[mockBackendController expect] logUserNotification:OCMOCK_ANY];
    
    [mockInstance logNotificationOpenedWithUserInfo:[testNotification userInfo] andActionIdentifier:nil];
    
    [mockBackendController verifyWithDelay:5.0];
}
#endif

- (void)testATTAuthorizationStatusNotDetermined {
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.attStatus = @(MPATTAuthorizationStatusNotDetermined);
    [instance startWithOptions:options];
    MPStateMachine_PRIVATE *stateMachine = instance.stateMachine;
    XCTAssertEqual(stateMachine.attAuthorizationStatus.integerValue, MPATTAuthorizationStatusNotDetermined);
    XCTAssert(stateMachine.attAuthorizationTimestamp);
}

- (void)testATTAuthorizationStatusRestricted {
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.attStatus = @(MPATTAuthorizationStatusRestricted);
    [instance startWithOptions:options];
    MPStateMachine_PRIVATE *stateMachine = instance.stateMachine;
    XCTAssertEqual(stateMachine.attAuthorizationStatus.integerValue, MPATTAuthorizationStatusRestricted);
    XCTAssert(stateMachine.attAuthorizationTimestamp);
}

- (void)testATTAuthorizationStatusDenied {
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.attStatus = @(MPATTAuthorizationStatusDenied);
    [instance startWithOptions:options];
    MPStateMachine_PRIVATE *stateMachine = instance.stateMachine;
    XCTAssertEqual(stateMachine.attAuthorizationStatus.integerValue, MPATTAuthorizationStatusDenied);
    XCTAssert(stateMachine.attAuthorizationTimestamp);
}

- (void)testATTAuthorizationStatusAuthorized {
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    options.attStatus = @(MPATTAuthorizationStatusAuthorized);
    [instance startWithOptions:options];
    MPStateMachine_PRIVATE *stateMachine = instance.stateMachine;
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
    MPStateMachine_PRIVATE *stateMachine = instance.stateMachine;
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
    
    MPDevice *device = [[MPDevice alloc] initWithStateMachine:[MParticle sharedInstance].stateMachine userDefaults:[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] identity:[MParticle sharedInstance].identity];
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
    
    MPDevice *device = [[MPDevice alloc] initWithStateMachine:[MParticle sharedInstance].stateMachine userDefaults:[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] identity:[MParticle sharedInstance].identity];
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
    
    MPDevice *device = [[MPDevice alloc] initWithStateMachine:[MParticle sharedInstance].stateMachine userDefaults:[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] identity:[MParticle sharedInstance].identity];
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
    
    MPDevice *device = [[MPDevice alloc] initWithStateMachine:[MParticle sharedInstance].stateMachine userDefaults:[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] identity:[MParticle sharedInstance].identity];
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
    
    MPDevice *device = [[MPDevice alloc] initWithStateMachine:[MParticle sharedInstance].stateMachine userDefaults:[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] identity:[MParticle sharedInstance].identity];
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
    
    MPDevice *device = [[MPDevice alloc] initWithStateMachine:[MParticle sharedInstance].stateMachine userDefaults:[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] identity:[MParticle sharedInstance].identity];
    NSDictionary *deviceDict = [device dictionaryRepresentation];
    
    XCTAssertEqualObjects(deviceDict[kMPATT], @"denied");
    XCTAssert(deviceDict[kMPATTTimestamp]);
    
    currentUser = [[[MParticle sharedInstance] identity] currentUser];
    XCTAssertNil(currentUser.identities[@(MPIdentityIOSAdvertiserId)]);
}

- (void)testUserAgentDefault {
    id mockWebView = OCMClassMock([MParticleWebView_PRIVATE class]);
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
}

- (void)testUserAgentCustom {
    NSString *customAgent = @"Foo 1.2.3 Like Bar";
    id mockWebView = OCMClassMock([MParticleWebView_PRIVATE class]);
    [[[mockWebView stub] andReturn:customAgent] userAgent];
    id mockMParticle = OCMPartialMock([MParticle sharedInstance]);
    [[[mockMParticle stub] andReturn:mockWebView] webView];
    
    NSURL *url = [NSURL URLWithString:@"https://nativesdks.mparticle.com"];
    MPURL *mpURL = [[MPURL alloc] initWithURL:url defaultURL:url];
    NSMutableURLRequest *urlRequest = [[MPURLRequestBuilder newBuilderWithURL:mpURL message:nil httpMethod:kMPHTTPMethodGet] build];
    NSDictionary *fields = urlRequest.allHTTPHeaderFields;
    NSString *actualAgent = fields[@"User-Agent"];
    XCTAssertEqualObjects(actualAgent, customAgent);
}

- (void)testUploadInterval {
    MParticle *instance = [MParticle sharedInstance];
    instance.backendController = [[MPBackendController_PRIVATE alloc] init];

    XCTAssertEqual(instance.uploadInterval, DEFAULT_DEBUG_UPLOAD_INTERVAL);
}

- (void)testSetUploadInterval {
    MParticle *instance = [MParticle sharedInstance];
    instance.backendController = [[MPBackendController_PRIVATE alloc] init];
    NSTimeInterval testInterval = 800.0;
    instance.uploadInterval = testInterval;

#if TARGET_OS_TV == 1
    XCTAssertEqual(instance.uploadInterval, DEFAULT_UPLOAD_INTERVAL);
#else
    XCTAssertEqual(instance.uploadInterval, testInterval);
#endif
}

#pragma mark Error, Exception, and Crash Handling Tests

- (void)testLogCrash {
    id mockBackend = OCMClassMock([MPBackendController_PRIVATE class]);
    
    NSString *message = @"crash report";
    NSString *stackTrace = @"stack track from crash report";
    NSString* plCrashReport = @"plcrash report test string";
    
    [[[mockBackend expect] ignoringNonObjectArgs] logCrash:message stackTrace:stackTrace plCrashReport:plCrashReport completionHandler:[OCMArg any]];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    [instance logCrash:message stackTrace:stackTrace plCrashReport:plCrashReport];
    
    [mockBackend verifyWithDelay:5];
}

- (void)testLogCrashNilMessage {
    id mockBackend = OCMClassMock([MPBackendController_PRIVATE class]);
    
    NSString *message = nil;
    NSString *stackTrace = @"stack track from crash report";
    NSString* plCrashReport = @"plcrash report test string";
    
    [[[mockBackend expect] ignoringNonObjectArgs] logCrash:message stackTrace:stackTrace plCrashReport:plCrashReport completionHandler:[OCMArg any]];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    [instance logCrash:message stackTrace:stackTrace plCrashReport:plCrashReport];
    
    [mockBackend verifyWithDelay:5];
}

- (void)testLogCrashNilStackTrace {
    id mockBackend = OCMClassMock([MPBackendController_PRIVATE class]);
    
    NSString *message = @"crash report";
    NSString *stackTrace = nil;
    NSString* plCrashReport = @"plcrash report test string";
    
    [[[mockBackend expect] ignoringNonObjectArgs] logCrash:message stackTrace:stackTrace plCrashReport:plCrashReport completionHandler:[OCMArg any]];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockBackend] backendController];
    
    [instance logCrash:message stackTrace:stackTrace plCrashReport:plCrashReport];
    
    [mockBackend verifyWithDelay:5];
}

#pragma mark Workspace Switching Tests

#define WORKSPACE_SWITCHING_TIMEOUT 60
#define WORKSPACE_SWITCHING_DELAY (int64_t)(10 * NSEC_PER_SEC)

- (void)testSwitchWorkspaceOptions {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];

    MParticle *instance = [MParticle sharedInstance];
    XCTAssertNotNil(instance);
    XCTAssertNil(instance.options);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WORKSPACE_SWITCHING_DELAY), dispatch_get_main_queue(), ^{
        MParticleOptions *options1 = [MParticleOptions optionsWithKey:@"unit-test-key1" secret:@"unit-test-secret1"];
        [instance startWithOptions:options1];
        XCTAssertNotNil(instance.options);
        XCTAssertEqualObjects(instance.options.apiKey, @"unit-test-key1");
        XCTAssertEqualObjects(instance.options.apiSecret, @"unit-test-secret1");

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WORKSPACE_SWITCHING_DELAY), dispatch_get_main_queue(), ^{
            MParticleOptions *options2 = [MParticleOptions optionsWithKey:@"unit-test-key2" secret:@"unit-test-secret2"];
            [instance switchWorkspaceWithOptions:options2];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WORKSPACE_SWITCHING_DELAY), dispatch_get_main_queue(), ^{
                MParticle *instance3 = [MParticle sharedInstance];
                MParticle *instance4 = [MParticle sharedInstance];
                XCTAssertNotNil(instance.options);
                XCTAssertEqualObjects(instance.options.apiKey, @"unit-test-key1");
                XCTAssertEqualObjects(instance.options.apiSecret, @"unit-test-secret1");
                
                XCTAssertNotNil(instance3.options);
                XCTAssertEqualObjects(instance3.options.apiKey, @"unit-test-key2");
                XCTAssertEqualObjects(instance3.options.apiSecret, @"unit-test-secret2");
                XCTAssertNotEqual(instance, instance3);
                XCTAssertEqual(instance3, instance4);
                
                [expectation fulfill];
            });
        });
    });

    [self waitForExpectationsWithTimeout:WORKSPACE_SWITCHING_TIMEOUT handler:nil];
}

- (void)testSwitchWorkspaceSideloadedKits {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
     
    // Start with a sideloaded kit
    MParticleOptions *options1 = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    MPKitTestClassSideloaded *kitTestSideloaded1 = [[MPKitTestClassSideloaded alloc] init];
    options1.sideloadedKits = @[[[MPSideloadedKit alloc] initWithKitInstance:kitTestSideloaded1]];
    
    [[MParticle sharedInstance] startWithOptions:options1];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WORKSPACE_SWITCHING_DELAY), dispatch_get_main_queue(), ^{
        XCTAssertEqual(MPKitContainer_PRIVATE.registeredKits.count, 1);
        XCTAssertEqualObjects(MPKitContainer_PRIVATE.registeredKits.anyObject.wrapperInstance, kitTestSideloaded1);
       
        // Switch workspace with a new sideloaded kit
        MParticleOptions *options2 = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
        MPKitTestClassSideloaded *kitTestSideloaded2 = [[MPKitTestClassSideloaded alloc] init];
        options2.sideloadedKits = @[[[MPSideloadedKit alloc] initWithKitInstance:kitTestSideloaded2]];
        
        [[MParticle sharedInstance] switchWorkspaceWithOptions:options2];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WORKSPACE_SWITCHING_DELAY), dispatch_get_main_queue(), ^{
            XCTAssertEqual(MPKitContainer_PRIVATE.registeredKits.count, 1);
            XCTAssertEqualObjects(MPKitContainer_PRIVATE.registeredKits.anyObject.wrapperInstance, kitTestSideloaded2);
            
            // Switch workspace with no sideloaded kits
            MParticleOptions *options3 = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
            [[MParticle sharedInstance] switchWorkspaceWithOptions:options3];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WORKSPACE_SWITCHING_DELAY), dispatch_get_main_queue(), ^{
                XCTAssertEqual(MPKitContainer_PRIVATE.registeredKits.count, 0);
                
                [expectation fulfill];
            });
        });
    });
    
    [self waitForExpectationsWithTimeout:(WORKSPACE_SWITCHING_TIMEOUT) handler:nil];
}

// Kits without configurations should NOT be removed from the registry even if they implement `stop` becuase it means they weren't used by the previous workspace
- (void)testSwitchWorkspaceKitsNoConfigurations {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    
    XCTAssertEqual(MPKitContainer_PRIVATE.registeredKits.count, 0);
    [MParticle registerExtension:[[MPKitRegister alloc] initWithName:@"TestKitNoStop" className:@"MPKitTestClassNoStartImmediately"]];
    [MParticle registerExtension:[[MPKitRegister alloc] initWithName:@"TestKitWithStop" className:@"MPKitTestClassNoStartImmediatelyWithStop"]];
    XCTAssertEqual(MPKitContainer_PRIVATE.registeredKits.count, 2);
    
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    [[MParticle sharedInstance] startWithOptions:options];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WORKSPACE_SWITCHING_DELAY), dispatch_get_main_queue(), ^{
        XCTAssertEqual(MPKitContainer_PRIVATE.registeredKits.count, 2);
        [[MParticle sharedInstance] switchWorkspaceWithOptions:options];
       
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WORKSPACE_SWITCHING_DELAY), dispatch_get_main_queue(), ^{
            XCTAssertEqual(MPKitContainer_PRIVATE.registeredKits.count, 2);
            [expectation fulfill];
        });
    });
    
    [self waitForExpectationsWithTimeout:WORKSPACE_SWITCHING_TIMEOUT handler:nil];
}

// Kits with configurations that don't implement `stop` should be removed from the registry because they can't be cleanly restarted
- (void)testSwitchWorkspaceKitsWithoutStop {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    
    XCTAssertEqual(MPKitContainer_PRIVATE.registeredKits.count, 0);
    MPKitRegister *registerNoStop = [[MPKitRegister alloc] initWithName:@"TestKitNoStop" className:@"MPKitTestClassNoStartImmediately"];
    [MParticle registerExtension:registerNoStop];
    
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    [[MParticle sharedInstance] startWithOptions:options];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WORKSPACE_SWITCHING_DELAY), dispatch_get_main_queue(), ^{
        registerNoStop.wrapperInstance = [[MPKitTestClassNoStartImmediately alloc] init];
        [MParticle sharedInstance].kitContainer_PRIVATE.kitConfigurations[@42] = [[MPKitConfiguration alloc] init];
        
        XCTAssertEqual(MPKitContainer_PRIVATE.registeredKits.count, 1);
                
        [[MParticle sharedInstance] switchWorkspaceWithOptions:options];
       
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WORKSPACE_SWITCHING_DELAY), dispatch_get_main_queue(), ^{
            XCTAssertEqual(MPKitContainer_PRIVATE.registeredKits.count, 0);
            [expectation fulfill];
        });
    });
    
    [self waitForExpectationsWithTimeout:WORKSPACE_SWITCHING_TIMEOUT handler:nil];
}

// Kits with configurations that implement `stop` shouldn't be removed from the registry because they can be cleanly restarted
- (void)testSwitchWorkspaceKitsWithStop {
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    
    XCTAssertEqual(MPKitContainer_PRIVATE.registeredKits.count, 0);
    MPKitRegister *registerWithStop = [[MPKitRegister alloc] initWithName:@"TestKitWithStop" className:@"MPKitTestClassNoStartImmediatelyWithStop"];
    [MParticle registerExtension:registerWithStop];
    
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"];
    [[MParticle sharedInstance] startWithOptions:options];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WORKSPACE_SWITCHING_DELAY), dispatch_get_main_queue(), ^{
        registerWithStop.wrapperInstance = [[MPKitTestClassNoStartImmediatelyWithStop alloc] init];
        [MParticle sharedInstance].kitContainer_PRIVATE.kitConfigurations[@43] = [[MPKitConfiguration alloc] init];
        
        XCTAssertEqual(MPKitContainer_PRIVATE.registeredKits.count, 1);
                
        [[MParticle sharedInstance] switchWorkspaceWithOptions:options];
       
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, WORKSPACE_SWITCHING_DELAY), dispatch_get_main_queue(), ^{
            XCTAssertEqual(MPKitContainer_PRIVATE.registeredKits.count, 1);
            [expectation fulfill];
        });
    });
    
    [self waitForExpectationsWithTimeout:WORKSPACE_SWITCHING_TIMEOUT handler:nil];
}

- (void)testSetWrapperSdk {
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];

    MPWrapperSdk wrapperSdk = MPWrapperSdkXamarin;
    NSString *wrapperSdkVersion = @"1.0.0";

    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for async operation"];
    SEL roktSelector = @selector(setWrapperSdk:version:);
    OCMExpect([mockContainer forwardSDKCall:roktSelector
                                           event:nil
                                      parameters:[OCMArg checkWithBlock:^BOOL(MPForwardQueueParameters *params) {
        XCTAssertEqualObjects(params[0], @(wrapperSdk));
        XCTAssertEqualObjects(params[1], wrapperSdkVersion);
        return YES;
    }]
                                     messageType:MPMessageTypeUnknown
                                        userInfo:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

    [MParticle _setWrapperSdk_internal:wrapperSdk version:wrapperSdkVersion];

    [self waitForExpectationsWithTimeout:0.2 handler:nil];

    OCMVerifyAll(mockContainer);
    
    [mockInstance stopMocking];
    [mockContainer stopMocking];
    mockInstance = nil;
    mockContainer = nil;
}

@end

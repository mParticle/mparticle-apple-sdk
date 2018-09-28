#import <XCTest/XCTest.h>
#import "mParticle.h"
#import "MPBaseTestCase.h"
#import "MPStateMachine.h"
#import "MPSession.h"
#import "MPBackendController.h"
#import "OCMock.h"

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong) MPBackendController *backendController;

@end

@interface MParticleTests : MPBaseTestCase {
    NSNotification *lastNotification;
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

- (void)handleTestSessionStart:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:mParticleSessionDidBeginNotification object:nil];
    lastNotification = notification;
}

- (void)handleTestSessionEnd:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:mParticleSessionDidEndNotification object:nil];
    lastNotification = notification;
}

#if TARGET_OS_IOS == 1
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
    MParticle *instance = [MParticle sharedInstance];
    [instance startWithOptions:[MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"]];
    dispatch_async([MParticle messageQueue], ^{
        XCTAssertNotNil(self->lastNotification);
        NSDictionary *userInfo = self->lastNotification.userInfo;
        XCTAssertEqual(2, userInfo.count);
        NSNumber *sessionID = userInfo[mParticleSessionId];
        XCTAssertEqualObjects(NSStringFromClass([sessionID class]), @"__NSCFNumber");
        NSString *sessionUUID = userInfo[mParticleSessionUUID];
        XCTAssertEqualObjects(NSStringFromClass([sessionUUID class]), @"__NSCFString");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testSessionEndNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTestSessionEnd:) name:mParticleSessionDidEndNotification object:nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    MParticle *instance = [MParticle sharedInstance];
    [instance startWithOptions:[MParticleOptions optionsWithKey:@"unit-test-key" secret:@"unit-test-secret"]];
    dispatch_async([MParticle messageQueue], ^{
        [[MParticle sharedInstance].backendController endSession];
        dispatch_async(dispatch_get_main_queue(), ^{
            XCTAssertNotNil(self->lastNotification);
            NSDictionary *userInfo = self->lastNotification.userInfo;
            XCTAssertEqual(2, userInfo.count);
            NSNumber *sessionID = userInfo[mParticleSessionId];
            XCTAssertEqualObjects(NSStringFromClass([sessionID class]), @"__NSCFNumber");
            NSString *sessionUUID = userInfo[mParticleSessionUUID];
            XCTAssertEqualObjects(NSStringFromClass([sessionUUID class]), @"__NSCFString");
            [expectation fulfill];
        });
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
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

@end

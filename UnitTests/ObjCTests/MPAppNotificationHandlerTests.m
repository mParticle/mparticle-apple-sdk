#import <XCTest/XCTest.h>
#import "MPAppNotificationHandler.h"
#import "MPPersistenceUtilities.h"
#import "mParticle.h"
#import "MPBaseTestCase.h"
#import "MPIConstants.h"
#import "MPKitContainer+MParticlePrivate.h"
#import "MPKitExecStatus.h"
#import <OCMock/OCMock.h>
#if TARGET_OS_IOS == 1
#import <UserNotifications/UserNotifications.h>
#endif
@import mParticle_Apple_SDK_Swift;

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, readonly) MPAppNotificationHandler *appNotificationHandler;
@property (nonatomic, strong, readonly) MPPersistenceStorePRIVATE *persistenceStore;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;

@end

#if TARGET_OS_IOS == 1
@interface MPNotificationCenterTestKit : NSObject <MPKitProtocol>
@property (nonatomic, readonly) BOOL started;
@property (nonatomic) BOOL throwsException;
@property (nonatomic) NSUInteger notificationCallCount;
@end

@implementation MPNotificationCenterTestKit

+ (NSNumber *)kitCode {
    return @(-1);
}

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    return [[MPKitExecStatus alloc] initWithSDKCode:@(-1) returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)handleNotificationCall {
    self.notificationCallCount += 1;
    if (self.throwsException) {
        [NSException raise:NSInternalInconsistencyException format:@"Test kit failure"];
    }
    return [[MPKitExecStatus alloc] initWithSDKCode:@(-1) returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification {
    return [self handleNotificationCall];
}

- (MPKitExecStatus *)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response {
    return [self handleNotificationCall];
}

@end

@interface MPNotificationCenterTestKitRegister : NSObject <MPExtensionKitProtocol>
@property (nonatomic, strong, nonnull) NSNumber *code;
@property (nonatomic, strong, nullable) id<MPKitProtocol> wrapperInstance;
@property (nonatomic, strong, nonnull) NSString *name;
@property (nonatomic, strong, nonnull) NSString *className;
@end

@implementation MPNotificationCenterTestKitRegister

- (instancetype)initWithName:(NSString *)name className:(NSString *)className {
    self = [super init];
    if (self) {
        _code = @(-1);
        _name = name;
        _className = className;
    }
    return self;
}

@end
#endif

@interface MPAppNotificationHandlerTests : MPBaseTestCase

@end

@implementation MPAppNotificationHandlerTests

#if TARGET_OS_IOS == 1

- (void)testFailedToRegisterForRemoteNotification {
    MPAppNotificationHandler *appNotificationHandler = [MParticle sharedInstance].appNotificationHandler;
    XCTAssertNotNil(appNotificationHandler, @"Should not have been nil.");
    
    NSError *error = [NSError errorWithDomain:@"com.mParticle" code:123 userInfo:@{@"some":@"error"}];
    [MParticle sharedInstance];
    [appNotificationHandler didFailToRegisterForRemoteNotificationsWithError:error];
    
    NSArray<MPForwardRecordPRIVATE *> *forwardedRecords = [[MParticle sharedInstance].persistenceStore fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
    
    error = nil;
    [appNotificationHandler didFailToRegisterForRemoteNotificationsWithError:error];
    
    forwardedRecords = [[MParticle sharedInstance].persistenceStore fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
}

- (void)testRegisterForRemoteNotification {
    MPAppNotificationHandler *appNotificationHandler = [MParticle sharedInstance].appNotificationHandler;
    XCTAssertNotNil(appNotificationHandler, @"Should not have been nil.");
    
    NSData *deviceToken = [@"<1234 5678>" dataUsingEncoding:NSUTF8StringEncoding];
    [appNotificationHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    NSArray<MPForwardRecordPRIVATE *> *forwardedRecords = [[MParticle sharedInstance].persistenceStore fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
    
    deviceToken = nil;
    [appNotificationHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    forwardedRecords = [[MParticle sharedInstance].persistenceStore fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
}

- (void)testHandleActionWithIdentifierForRemoteNotification {
    MPAppNotificationHandler *appNotificationHandler = [MParticle sharedInstance].appNotificationHandler;
    
    NSString *actionIdentifier = @"Action 1";
    NSDictionary *notificationDictionary = @{};
    [appNotificationHandler handleActionWithIdentifier:actionIdentifier forRemoteNotification:notificationDictionary];
    
    actionIdentifier = nil;
    notificationDictionary = nil;
    [appNotificationHandler handleActionWithIdentifier:actionIdentifier forRemoteNotification:notificationDictionary];
    
    NSArray<MPForwardRecordPRIVATE *> *forwardedRecords = [[MParticle sharedInstance].persistenceStore fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
}

- (UNNotification *)notificationMockWithUserInfo:(NSDictionary *)userInfo {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.userInfo = userInfo;
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"test" content:content trigger:nil];
    id notification = OCMClassMock([UNNotification class]);
    OCMStub([notification request]).andReturn(request);
    return notification;
}

// Runs `call` with a throwing kit registered ahead of a working one, then returns the forward
// records saved once the main-queue kit loop and the message-queue saves it scheduled have run.
- (NSArray<MPForwardRecordPRIVATE *> *)forwardRecordsAfterNotificationCall:(void (^)(MPAppNotificationHandler *handler))call
                                                       throwingKit:(MPNotificationCenterTestKit *)throwingKit
                                                        workingKit:(MPNotificationCenterTestKit *)workingKit {
    throwingKit.throwsException = YES;
    MPNotificationCenterTestKitRegister *throwingRegister = [[MPNotificationCenterTestKitRegister alloc] initWithName:@"Throwing" className:@"MPNotificationCenterTestKit"];
    throwingRegister.wrapperInstance = throwingKit;
    MPNotificationCenterTestKitRegister *workingRegister = [[MPNotificationCenterTestKitRegister alloc] initWithName:@"Working" className:@"MPNotificationCenterTestKit"];
    workingRegister.wrapperInstance = workingKit;

    MParticle *instance = [MParticle sharedInstance];
    MPAppNotificationHandler *handler = instance.appNotificationHandler;
    id mockInstance = OCMPartialMock(instance);
    id mockContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    OCMStub([mockContainer activeKitsRegistry]).andReturn((@[throwingRegister, workingRegister]));
    [[[mockInstance stub] andReturn:mockContainer] kitContainer_PRIVATE];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];

    call(handler);

    XCTestExpectation *expectation = [self expectationWithDescription:@"Kit loop and forward-record saves finished"];
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_async([MParticle messageQueue], ^{
            [expectation fulfill];
        });
    });
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];

    NSArray<MPForwardRecordPRIVATE *> *forwardRecords = [instance.persistenceStore fetchForwardRecords];
    [mockInstance stopMocking];
    [mockContainer stopMocking];
    return forwardRecords;
}

- (void)testWillPresentNotificationContainsKitException {
    MPNotificationCenterTestKit *throwingKit = [[MPNotificationCenterTestKit alloc] init];
    MPNotificationCenterTestKit *workingKit = [[MPNotificationCenterTestKit alloc] init];
    UNNotification *notification = [self notificationMockWithUserInfo:@{@"aps": @{@"alert": @"Test"}}];
    id center = OCMClassMock([UNUserNotificationCenter class]);

    NSArray<MPForwardRecordPRIVATE *> *forwardRecords = [self forwardRecordsAfterNotificationCall:^(MPAppNotificationHandler *handler) {
        [handler userNotificationCenter:center willPresentNotification:notification];
    } throwingKit:throwingKit workingKit:workingKit];

    XCTAssertEqual(throwingKit.notificationCallCount, 1);
    XCTAssertEqual(workingKit.notificationCallCount, 1);
    XCTAssertEqual(forwardRecords.count, 1);
}

- (void)testDidReceiveNotificationResponseContainsKitException {
    MPNotificationCenterTestKit *throwingKit = [[MPNotificationCenterTestKit alloc] init];
    MPNotificationCenterTestKit *workingKit = [[MPNotificationCenterTestKit alloc] init];
    UNNotification *notification = [self notificationMockWithUserInfo:@{@"aps": @{@"alert": @"Test"}}];
    id response = OCMClassMock([UNNotificationResponse class]);
    OCMStub([response notification]).andReturn(notification);
    OCMStub([response actionIdentifier]).andReturn(UNNotificationDefaultActionIdentifier);
    id center = OCMClassMock([UNUserNotificationCenter class]);

    NSArray<MPForwardRecordPRIVATE *> *forwardRecords = [self forwardRecordsAfterNotificationCall:^(MPAppNotificationHandler *handler) {
        [handler userNotificationCenter:center didReceiveNotificationResponse:response];
    } throwingKit:throwingKit workingKit:workingKit];

    XCTAssertEqual(throwingKit.notificationCallCount, 1);
    XCTAssertEqual(workingKit.notificationCallCount, 1);
    XCTAssertEqual(forwardRecords.count, 1);
}

#endif

- (void)testOpenURLOptions {
    MPAppNotificationHandler *appNotificationHandler = [MParticle sharedInstance].appNotificationHandler;
    
    NSURL *url = [NSURL URLWithString:@"http://mparticle.com"];
    NSDictionary *options;
    options = @{UIApplicationOpenURLOptionsSourceApplicationKey:@"testApp"};
    [appNotificationHandler openURL:url options:options];
}

- (void)testContinueUserActivityNoCrash {
    MPAppNotificationHandler *appNotificationHandler = [MParticle sharedInstance].appNotificationHandler;
    
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:@"test"];
    userActivity.webpageURL = [[NSURL alloc] initWithString:@"http://mparticle.com"];
    [appNotificationHandler continueUserActivity:userActivity restorationHandler:^(NSArray<id<UIUserActivityRestoring>> *restorationHandler){}];
}

- (void)testContinueUserActivityWithNilURLNoCrash {
    MPAppNotificationHandler *appNotificationHandler = [MParticle sharedInstance].appNotificationHandler;
    
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:@"test"];
    [appNotificationHandler continueUserActivity:userActivity restorationHandler:^(NSArray<id<UIUserActivityRestoring>> *restorationHandler){}];
}

@end

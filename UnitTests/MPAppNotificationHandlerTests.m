#import <XCTest/XCTest.h>
#import "MPAppNotificationHandler.h"
#import "MPPersistenceController.h"
#import "mParticle.h"
#import "MPBaseTestCase.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#if TARGET_OS_IOS == 1
#import "OCMock.h"
#endif

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong, readonly) MPAppNotificationHandler *appNotificationHandler;
@property (nonatomic, strong, readonly) MPPersistenceController *persistenceController;

@end

@interface MPAppNotificationHandlerTests : MPBaseTestCase

@end

@implementation MPAppNotificationHandlerTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testFailedToRegisterForRemoteNotification {
    MPAppNotificationHandler *appNotificationHandler = [MParticle sharedInstance].appNotificationHandler;
    XCTAssertNotNil(appNotificationHandler, @"Should not have been nil.");
    
    NSError *error = [NSError errorWithDomain:@"com.mParticle" code:123 userInfo:@{@"some":@"error"}];
    [MParticle sharedInstance];
    [appNotificationHandler didFailToRegisterForRemoteNotificationsWithError:error];
    
    NSArray<MPForwardRecord *> *forwardedRecords = [[MParticle sharedInstance].persistenceController fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
    
    error = nil;
    [appNotificationHandler didFailToRegisterForRemoteNotificationsWithError:error];
    
    forwardedRecords = [[MParticle sharedInstance].persistenceController fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
}

- (void)testRegisterForRemoteNotification {
    MPAppNotificationHandler *appNotificationHandler = [MParticle sharedInstance].appNotificationHandler;
    XCTAssertNotNil(appNotificationHandler, @"Should not have been nil.");
    
    NSData *deviceToken = [@"<1234 5678>" dataUsingEncoding:NSUTF8StringEncoding];
    [appNotificationHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    NSArray<MPForwardRecord *> *forwardedRecords = [[MParticle sharedInstance].persistenceController fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
    
    deviceToken = nil;
    [appNotificationHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    forwardedRecords = [[MParticle sharedInstance].persistenceController fetchForwardRecords];
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
    
    NSArray<MPForwardRecord *> *forwardedRecords = [[MParticle sharedInstance].persistenceController fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
}

- (void)testOpenURLOptions {
    MPAppNotificationHandler *appNotificationHandler = [MParticle sharedInstance].appNotificationHandler;
    
    NSURL *url = [NSURL URLWithString:@"http://mparticle.com"];
    NSDictionary *options;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
#pragma clang diagnostic ignored "-Wunreachable-code"
    if (@available(iOS 9.0, *)) {
        if (&UIApplicationOpenURLOptionsSourceApplicationKey != NULL) {
            options = @{UIApplicationOpenURLOptionsSourceApplicationKey:@"testApp"};
        }
    }
#pragma clang diagnostic pop
    [appNotificationHandler openURL:url options:options];
    
    url = nil;
    options = @{};
    [appNotificationHandler openURL:url options:options];
    
    url = nil;
    options = nil;
    [appNotificationHandler openURL:url options:options];
}

@end

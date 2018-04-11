#import <XCTest/XCTest.h>
#import "MPAppNotificationHandler.h"
#import "MPPersistenceController.h"
#import "mParticle.h"

@interface MPAppNotificationHandlerTests : XCTestCase

@end

@interface MPAppNotificationHandler(Tests)

@property (nonatomic, unsafe_unretained) MPUserNotificationRunningMode runningMode;

@end


@implementation MPAppNotificationHandlerTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testFailedToRegisterForRemoteNotification {
    MPAppNotificationHandler *appNotificationHandler = [MPAppNotificationHandler sharedInstance];
    XCTAssertNotNil(appNotificationHandler, @"Should not have been nil.");
    
    NSError *error = [NSError errorWithDomain:@"com.mParticle" code:123 userInfo:@{@"some":@"error"}];
    [MParticle sharedInstance];
    [appNotificationHandler didFailToRegisterForRemoteNotificationsWithError:error];
    
    NSArray<MPForwardRecord *> *forwardedRecords = [[MPPersistenceController sharedInstance] fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
    
    error = nil;
    [appNotificationHandler didFailToRegisterForRemoteNotificationsWithError:error];
    
    forwardedRecords = [[MPPersistenceController sharedInstance] fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
}

- (void)testRegisterForRemoteNotification {
    MPAppNotificationHandler *appNotificationHandler = [MPAppNotificationHandler sharedInstance];
    XCTAssertNotNil(appNotificationHandler, @"Should not have been nil.");
    
    NSData *deviceToken = [@"<1234 5678>" dataUsingEncoding:NSUTF8StringEncoding];
    [appNotificationHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    NSArray<MPForwardRecord *> *forwardedRecords = [[MPPersistenceController sharedInstance] fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
    
    deviceToken = nil;
    [appNotificationHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    
    forwardedRecords = [[MPPersistenceController sharedInstance] fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
}

- (void)testHandleActionWithIdentifierForRemoteNotification {
    MPAppNotificationHandler *appNotificationHandler = [MPAppNotificationHandler sharedInstance];
    
    NSString *actionIdentifier = @"Action 1";
    NSDictionary *notificationDictionary = @{};
    [appNotificationHandler handleActionWithIdentifier:actionIdentifier forRemoteNotification:notificationDictionary];
    
    actionIdentifier = nil;
    notificationDictionary = nil;
    [appNotificationHandler handleActionWithIdentifier:actionIdentifier forRemoteNotification:notificationDictionary];
    
    NSArray<MPForwardRecord *> *forwardedRecords = [[MPPersistenceController sharedInstance] fetchForwardRecords];
    XCTAssertNil(forwardedRecords, @"Should have been nil.");
}

- (void)testOpenURLOptions {
    MPAppNotificationHandler *appNotificationHandler = [MPAppNotificationHandler sharedInstance];
    
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

- (void)testReceivedUserNotification {
    MPAppNotificationHandler *appNotificationHandler = [MPAppNotificationHandler sharedInstance];
    
    NSDictionary *notification = @{};
    NSString *action = @"";
    [appNotificationHandler receivedUserNotification:notification actionIdentifier:action userNotificationMode:MPUserNotificationModeRemote];
    [appNotificationHandler receivedUserNotification:notification actionIdentifier:action userNotificationMode:MPUserNotificationModeLocal];
    [appNotificationHandler receivedUserNotification:notification actionIdentifier:action userNotificationMode:MPUserNotificationModeAutoDetect];
    
    notification = nil;
    action = nil;
    [appNotificationHandler receivedUserNotification:notification actionIdentifier:action userNotificationMode:MPUserNotificationModeRemote];
    [appNotificationHandler receivedUserNotification:notification actionIdentifier:action userNotificationMode:MPUserNotificationModeLocal];
    [appNotificationHandler receivedUserNotification:notification actionIdentifier:action userNotificationMode:MPUserNotificationModeAutoDetect];
}

@end

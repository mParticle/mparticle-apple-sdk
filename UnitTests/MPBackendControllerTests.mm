//
//  MPBackendControllerTests.mm
//
//  Copyright 2015 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <XCTest/XCTest.h>
#import "MPBackendController.h"
#import "MPIConstants.h"
#import "MPSession.h"
#import "MPStateMachine.h"
#import "MPPersistenceController.h"
#import "MPMessage.h"
#import "MPUpload.h"
#import "MPNotificationController.h"
#import "MPEvent.h"
#import "MParticleUserNotification.h"
#import "MPUploadBuilder.h"
#import "MPMessageBuilder.h"
#import "mParticle.h"
#import "MPKitContainer.h"
#import "MPKitConfiguration.h"
#import "MPKitInstanceValidator.h"

#if TARGET_OS_IOS == 1
    #import <CoreLocation/CoreLocation.h>
#endif

#define BACKEND_TESTS_EXPECTATIONS_TIMEOUT 10

#pragma mark - MParticle+Tests category
@interface MParticle(Tests)

@property (nonatomic, strong, nonnull) MPBackendController *backendController;

@end

#pragma mark - MPKitContainer category for unit tests
@interface MPKitContainer(Tests)

- (id<MPKitProtocol>)startKit:(NSNumber *)kitCode configuration:(MPKitConfiguration *)kitConfiguration;

@end

#pragma mark - MPKitInstanceValidator category for unit tests
@interface MPKitInstanceValidator(BackendControllerTests)

+ (void)includeUnitTestKits:(NSArray<NSNumber *> *)kitCodes;

@end

#pragma mark - MPBackendController+Tests category
@interface MPBackendController(Tests)

@property (nonatomic, strong) MPNetworkCommunication *networkCommunication;
@property (nonatomic, strong) NSMutableDictionary *userAttributes;
@property (nonatomic, strong) NSMutableArray *userIdentities;
@property (nonatomic, unsafe_unretained) MPInitializationStatus initializationStatus;

- (NSString *)caseInsensitiveKeyInDictionary:(NSDictionary *)dictionary withKey:(NSString *)key;
- (void)cleanUp;
- (void)forceAppFinishedLaunching;
- (void)setInitializationStatus:(MPInitializationStatus)initializationStatus;
- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification;
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification;
- (void)logRemoteNotificationWithNotificationController:(MPNotificationController *const)notificationController;
- (void)parseConfigResponse:(NSDictionary *)configurationDictionary;
- (void)parseResponseHeader:(NSDictionary *)responseDictionary session:(MPSession *)session;
- (NSNumber *)previousSessionSuccessfullyClosed;
- (void)setPreviousSessionSuccessfullyClosed:(NSNumber *)previousSessionSuccessfullyClosed;
- (void)processOpenSessionsIncludingCurrent:(BOOL)includeCurrentSession completionHandler:(dispatch_block_t)completionHandler;
- (void)processPendingArchivedMessages;
- (void)resetUserIdentitiesFirstTimeUseFlag;
- (void)saveMessage:(MPMessage *)message updateSession:(BOOL)updateSession;
- (void)uploadMessagesFromSession:(MPSession *)session completionHandler:(void(^)(MPSession *uploadedSession))completionHandler;
- (void)uploadSessionHistory:(MPSession *)session completionHandler:(dispatch_block_t)completionHandler;
- (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value error:(out NSError *__autoreleasing *)error;
- (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value maxValueLength:(NSUInteger)maxValueLength error:(out NSError *__autoreleasing *)error;

@end

#pragma mark - MPBackendControllerTests unit test class
@interface MPBackendControllerTests : XCTestCase <MPBackendControllerDelegate>

@property (nonatomic, strong) MPBackendController *backendController;
@property (nonatomic, strong) MPSession *session;
@property (nonatomic, strong) MPNotificationController *notificationController;

@end

@implementation MPBackendControllerTests

- (void)setUp {
    [super setUp];
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.apiKey = @"unit_test_app_key";
    stateMachine.secret = @"unit_test_secret";

    [self addObserver:self forKeyPath:@"backendController.session" options:NSKeyValueObservingOptionNew context:NULL];
    
    [[MPPersistenceController sharedInstance] openDatabase];
    _session = self.backendController.session;
    
    [self notificationController];
}

- (void)tearDown {
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence deleteRecordsOlderThan:[[NSDate date] timeIntervalSince1970]];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tear down"];
    
    [persistence fetchSessions:^(NSMutableArray *sessions) {
        for (MPSession *session in sessions) {
            [persistence deleteSession:session];
        }
        
        [persistence fetchSessions:^(NSMutableArray *sessions) {
            XCTAssertEqual(sessions.count, 0, @"Sessions have not been deleted.");
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
    
    [persistence closeDatabase];
    
    [self removeObserver:self forKeyPath:@"backendController.session" context:NULL];
    
    [super tearDown];
}

- (void)forwardLogInstall {}

- (void)forwardLogUpdate {}

- (void)configureNetworkPerformanceMeasurement {}

- (void)configureSocialNetwork:(NSNumber *)socialNetworkNumber {}

- (void)sessionDidBegin:(MPSession *)session {}

- (void)sessionDidEnd:(MPSession *)session {}

- (MPBackendController *)backendController {
    if (_backendController) {
        return _backendController;
    }
    
    _backendController = [[MPBackendController alloc] initWithDelegate:self];
    
    return _backendController;
}

#if TARGET_OS_IOS == 1
- (NSDictionary *)remoteNotificationDictionary {
    UIMutableUserNotificationAction *dinoHandsUserAction = [[UIMutableUserNotificationAction alloc] init];
    dinoHandsUserAction.identifier = @"DINO_CAB_ACTION_IDENTIFIER";
    dinoHandsUserAction.title = @"Dino Cab";
    dinoHandsUserAction.activationMode = UIUserNotificationActivationModeForeground;
    dinoHandsUserAction.destructive = NO;
    
    UIMutableUserNotificationAction *shortArmsUserAction = [[UIMutableUserNotificationAction alloc] init];
    shortArmsUserAction.identifier = @"DINO_UBER_ACTION_IDENTIFIER";
    shortArmsUserAction.title = @"Dino Uber";
    shortArmsUserAction.activationMode = UIUserNotificationActivationModeBackground;
    shortArmsUserAction.destructive = NO;
    
    UIMutableUserNotificationCategory *dinosaurCategory = [[UIMutableUserNotificationCategory alloc] init];
    dinosaurCategory.identifier = @"DINOSAUR_TRANSPORTATION_CATEGORY";
    [dinosaurCategory setActions:@[dinoHandsUserAction, shortArmsUserAction] forContext:UIUserNotificationActionContextDefault];
    
    // Categories
    NSSet *categories = [NSSet setWithObjects:dinosaurCategory, nil];
    
    UIUserNotificationSettings *userNotificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert
                                                                                             categories:categories];
    
    UIApplication *application = [UIApplication sharedApplication];
    [application registerUserNotificationSettings:userNotificationSettings];
    [application registerForRemoteNotifications];
    
    NSDictionary *remoteNotificationDictionary = @{@"aps":@{
                                                           @"alert":@{
                                                                   @"body":@"Your pre-historic ride has arrived.",
                                                                   @"show-view":@NO
                                                                   },
                                                           @"badge":@1,
                                                           @"sound":@"t-rex_roar.aiff",
                                                           @"category":@"DINOSAUR_TRANSPORTATION_CATEGORY"
                                                           },
                                                   @"m_cmd":@1,
                                                   @"m_cid":@2,
                                                   @"m_cntid":@3,
                                                   @"m_expy":MPMilliseconds([[NSDate date] timeIntervalSince1970] + 100),
                                                   @"m_uid":@(arc4random_uniform(INT_MAX))
                                                   };
    
    return remoteNotificationDictionary;
}
#endif

- (NSDictionary *)nonmParticleRemoteNotificationDictionary {
    NSDictionary *remoteNotificationDictionary = @{@"aps":@{
                                                           @"alert":@{
                                                                   @"body":@"Your regular transportation has arrived.",
                                                                   @"show-view":@NO
                                                                   },
                                                           @"badge":@0,
                                                           @"sound":@"engine_sound.aiff"
                                                           }
                                                   };
    
    return remoteNotificationDictionary;
}

- (MPSession *)session {
    if (_session) {
        return _session;
    }
    
    _session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    return _session;
}

- (NSDictionary *)silentNotificationDictionary {
    NSDictionary *silentNotificationDictionary = @{@"aps":@{
                                                           @"content-available":@1,
                                                           @"sound":@""
                                                           }
                                                   };
    
    return silentNotificationDictionary;
}

#if TARGET_OS_IOS == 1
- (MPNotificationController *)notificationController {
    if (_notificationController) {
        return _notificationController;
    }
    
    __weak id<MPNotificationControllerDelegate> backendController = (id<MPNotificationControllerDelegate>)self.backendController;
    _notificationController = [[MPNotificationController alloc] initWithDelegate:backendController];
    
    return _notificationController;
}
#endif

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"backendController.session"]) {
        self.session = change[NSKeyValueChangeNewKey];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)testBeginSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Begin session test"];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [persistence fetchSessions:^(NSMutableArray *sessions) {
        MPSession *session = [sessions lastObject];
        
        XCTAssertEqualObjects(session, self.session, @"Sessions are not equal.");
        
        NSArray<MPMessage *> *messages = [persistence fetchMessagesForUploadingInSession:session];
        MPMessage *message = [messages lastObject];
        
        XCTAssertEqualObjects(message.messageType, @"ss", @"Message type is not session start.");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testEndSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"End session test"];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [persistence fetchSessions:^(NSMutableArray *sessions) {
        MPSession *session = [sessions lastObject];
        MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
        XCTAssertEqualObjects(session, stateMachine.currentSession, @"Current session and last session in the database are not equal.");
        
        NSArray<MPMessage *> *messages = [persistence fetchMessagesForUploadingInSession:session];

        BOOL containsSessionStart = NO;
        
        for (MPMessage *message in messages) {
            if ([message.messageType isEqualToString:@"ss"]) {
                containsSessionStart = YES;
            }
        }
        
        XCTAssertTrue(containsSessionStart, @"Begin session does not contain a session start message.");
        
        [self.backendController endSession];
        [self.backendController endSession];
        [self.backendController endSession];
        [self.backendController endSession];
        [self.backendController endSession];
        [self.backendController endSession];
        [self.backendController endSession];
        
        messages = [persistence fetchMessagesForUploadingInSession:session];
        
        
        NSUInteger endSessionCount = 0;
        for (MPMessage *message in messages) {
            if ([message.messageType isEqualToString:@"se"]) {
                ++endSessionCount;
            }
        }
        
        XCTAssertEqual(endSessionCount, 1, @"Logging session end multiple times.");
        
        [persistence deletePreviousSession];
        
        [persistence fetchPreviousSession:^(MPSession *previousSession) {
            XCTAssertNil(previousSession, @"Previous session is not being removed.");
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testCheckAttribute {
    // Add and tests valid attributes
    NSString *key;
    NSString *value;
    NSError *error;
    int i;
    int quantityLimit = 99;
    int lengthLimit = 254;
    BOOL validAttributes;
    for (i = 0; i < quantityLimit; ++i) {
        key = [NSString stringWithFormat:@"Key%d", i];
        value = [NSString stringWithFormat:@"Value%d", i];
        error = nil;
        validAttributes = [self.backendController checkAttribute:self.session.attributesDictionary key:key value:value error:&error];
        XCTAssertTrue(validAttributes, @"Checking attributes did not work.");
        self.session.attributesDictionary[key] = value;
    }
    
    // Adds one attribute over the limit
    key = [NSString stringWithFormat:@"Key%d", quantityLimit];
    value = [NSString stringWithFormat:@"Value%d", quantityLimit];
    self.session.attributesDictionary[key] = value;
    error = nil;
    validAttributes = [self.backendController checkAttribute:self.session.attributesDictionary key:key value:value error:&error];
    XCTAssertFalse(validAttributes, @"Checking attributes count limit did not work.");
    
    // Removes most attributes
    for (i = 0; i < quantityLimit; ++i) {
        key = [NSString stringWithFormat:@"Key%d", i];
        [self.session.attributesDictionary removeObjectForKey:key];
    }
    
    // Builds and tests a long key
    for (i = 0; i < lengthLimit; ++i) {
        key = [key stringByAppendingString:[NSString stringWithFormat:@"%d", i]];
    }
    value = [NSString stringWithFormat:@"Value%d", 0];
    error = nil;
    validAttributes = [self.backendController checkAttribute:self.session.attributesDictionary key:key value:value error:&error];
    XCTAssertFalse(validAttributes, @"Accepting keys that are too long.");
    
    // Builds and tests a long value
    for (i = 0; i < lengthLimit; ++i) {
        value = [value stringByAppendingString:[NSString stringWithFormat:@"%d", i]];
    }
    key = [NSString stringWithFormat:@"Key%d", 0];
    error = nil;
    validAttributes = [self.backendController checkAttribute:self.session.attributesDictionary key:key value:value error:&error];
    XCTAssertFalse(validAttributes, @"Accepting values that are too long.");
    
    // Nil values
    key = [NSString stringWithFormat:@"Key%d", 0];
    value = nil;
    error = nil;
    validAttributes = [self.backendController checkAttribute:self.session.attributesDictionary key:key value:value error:&error];
    XCTAssertFalse(validAttributes, @"Accepting nil values.");
}

- (void)testBatchCycle {
    MPInitializationStatus originalInitializationStatus = self.backendController.initializationStatus;
    self.backendController.initializationStatus = MPInitializationStatusStarted;
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Unit Test Event" type:MPEventTypeOther];
    event.info = @{@"key":@"value"};
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Batch cycle test"];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [self.backendController logEvent:event
                             attempt:0
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {}];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray<MPMessage *> *messages = [persistence fetchMessagesForUploadingInSession:self.session];

        XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
        
        for (MPMessage *message in messages) {
            XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        }
        
        MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithSession:self.session messages:messages sessionTimeout:100 uploadInterval:100];
        XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
        
        if (!uploadBuilder) {
            return;
        }
        
        [uploadBuilder withUserAttributes:self.backendController.userAttributes deletedUserAttributes:nil];
        [uploadBuilder withUserIdentities:self.backendController.userIdentities];
        [uploadBuilder build:^(MPDataModelAbstract *upload) {
            [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationFlag];
            
            NSArray *messages = [persistence fetchMessagesInSession:self.session];
            
            XCTAssertNotNil(messages, @"There are no messages in session.");
            
            for (MPMessage *message in messages) {
                XCTAssertTrue(message.uploadStatus == MPUploadStatusUploaded, @"Messages are not being marked as uploaded.");
            }
            
            [persistence fetchUploadsInSession:self.session
                             completionHandler:^(NSArray *uploads) {
                                 XCTAssertGreaterThan(uploads.count, 0, @"Messages are not being transfered to the Uploads table.");
                                 
                                 for (MPUpload *upload in uploads) {
                                     [persistence deleteUpload:upload];
                                 }
                                 
                                 [persistence fetchUploadsInSession:self.session
                                                  completionHandler:^(NSArray *uploads) {
                                                      XCTAssertNil(uploads, @"Uploads are not being deleted.");
                                                      
                                                      [expectation fulfill];
                                                  }];
                             }];
        }];
    });
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
    
    self.backendController.initializationStatus = originalInitializationStatus;
}

- (void)testRampUpload {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [persistence saveMessage:message];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ramp upload test"];
    
    NSArray<MPMessage *> *persistedMessages = [persistence fetchMessagesForUploadingInSession:session];

    MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithSession:session messages:persistedMessages sessionTimeout:100 uploadInterval:100];
    XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
    
    if (!uploadBuilder) {
        return;
    }
    
    [uploadBuilder withUserAttributes:self.backendController.userAttributes deletedUserAttributes:nil];
    [uploadBuilder withUserIdentities:self.backendController.userIdentities];
    [uploadBuilder build:^(MPDataModelAbstract *upload) {
        [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationFlag];
        
        [persistence fetchUploadsInSession:session
                         completionHandler:^(NSArray *uploads) {
                             XCTAssertGreaterThan(uploads.count, 0, @"Failed to retrieve messages to be uploaded.");
                             
                             MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
                             [stateMachine configureRampPercentage:@100];
                             
                             XCTAssertFalse(stateMachine.dataRamped, @"Data ramp is not respecting 100 percent upper limit.");
                             
                             for (MPUpload *upload in uploads) {
                                 [persistence deleteUpload:upload];
                             }
                             
                             [persistence fetchUploadsInSession:session
                                              completionHandler:^(NSArray *uploads) {
                                                  XCTAssertNil(uploads, @"Not deleting ramped upload messages.");
                                                  
                                                  [persistence fetchUploadedMessagesInSession:session
                                                            excludeNetworkPerformanceMessages:NO
                                                                            completionHandler:^(NSArray *persistedMessages) {
                                                                                MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithSession:self.session messages:persistedMessages sessionTimeout:100 uploadInterval:100];
                                                                                XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
                                                                                
                                                                                if (!uploadBuilder) {
                                                                                    return;
                                                                                }
                                                                                
                                                                                [uploadBuilder withUserAttributes:self.backendController.userAttributes deletedUserAttributes:nil];
                                                                                [uploadBuilder withUserIdentities:self.backendController.userIdentities];
                                                                                [uploadBuilder build:^(MPDataModelAbstract *upload) {
                                                                                    [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationDelete];
                                                                                    
                                                                                    [persistence fetchUploadedMessagesInSession:session
                                                                                              excludeNetworkPerformanceMessages:NO
                                                                                                              completionHandler:^(NSArray *persistedMessages) {
                                                                                                                  XCTAssertNil(persistedMessages, @"Messages are not being deleted are being moved to the uploads table.");
                                                                                                                  
                                                                                                                  [expectation fulfill];
                                                                                                              }];
                                                                                }];
                                                                            }];
                                              }];
                         }];
    }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testDidBecomeActiveWithAppLink {
#if TARGET_OS_IOS == 1
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    NSURL *url = [NSURL URLWithString:@"fb487730798014455://applinks?al_applink_data=%7B%22user_agent%22%3A%22Bolts%20iOS%201.0.0%22%2C%22target_url%22%3A%22http%3A%5C%2F%5C%2Fexample.com%5C%2Fapplinks%22%2C%22extras%22%3A%7B%22myapp_token%22%3A%22t0kEn%22%7D%7D"];
    NSString *sourceApplication = @"com.mParticle.UnitTest";
    NSDictionary *annotation = @{@"foo":@"bar"};
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    [self.backendController forceAppFinishedLaunching];
    [self.backendController handleApplicationDidBecomeActive:nil];
    
    NSArray<MPMessage *> *messages = [[MPPersistenceController sharedInstance] fetchMessagesForUploadingInSession:self.session];

    XCTAssertGreaterThan(messages.count, 0, @"Launch messages are not being persisted.");
    
    for (MPMessage *message in messages) {
        if ([message.messageType isEqualToString:@"ast"]) {
            NSString *messageString = [[NSString alloc] initWithData:message.messageData encoding:NSUTF8StringEncoding];
            NSRange testRange = [messageString rangeOfString:@"al_applink_data"];
            XCTAssertNotEqual(testRange.location, NSNotFound, @"AppLinks is not in the launch URL.");
            
            testRange = [messageString rangeOfString:@"\"src\":\"AppLink(com.mParticle.UnitTest)\""];
            XCTAssertNotEqual(testRange.location, NSNotFound, @"Source application is not present or formatted incorrectly.");
            
            testRange = [messageString rangeOfString:@"\"nsi\""];
            XCTAssertNotEqual(testRange.location, NSNotFound, @"'nsi' is not present.");
            
            testRange = [messageString rangeOfString:@"lpr"];
            XCTAssertNotEqual(testRange.location, NSNotFound);
        }
    }
#endif
}

- (void)testDidBecomeActive {
#if TARGET_OS_IOS == 1
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    NSURL *url = [NSURL URLWithString:@"particlebox://unit_test"];
    NSString *sourceApplication = @"com.mParticle.UnitTest";
    NSDictionary *annotation = @{@"key1":@1, @"key2":[NSDate date]};
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    [self.backendController forceAppFinishedLaunching];
    [self.backendController handleApplicationDidBecomeActive:nil];
    
    NSArray<MPMessage *> *messages = [[MPPersistenceController sharedInstance] fetchMessagesForUploadingInSession:self.session];

    XCTAssertGreaterThan(messages.count, 0, @"Launch messages are not being persisted.");
    
    for (MPMessage *message in messages) {
        if ([message.messageType isEqualToString:@"ast"]) {
            NSString *messageString = [[NSString alloc] initWithData:message.messageData encoding:NSUTF8StringEncoding];
            NSRange testRange = [messageString rangeOfString:@"particlebox"];
            XCTAssertNotEqual(testRange.location, NSNotFound, @"particlebox is not in the launch URL.");
            
            testRange = [messageString rangeOfString:@"\"src\":\"com.mParticle.UnitTest\""];
            XCTAssertNotEqual(testRange.location, NSNotFound, @"Source application is not present or formatted incorrectly.");
            
            testRange = [messageString rangeOfString:@"\"nsi\""];
            XCTAssertNotEqual(testRange.location, NSNotFound, @"'nsi' is not present.");
            
            testRange = [messageString rangeOfString:@"lpr"];
            XCTAssertNotEqual(testRange.location, NSNotFound);
            
            testRange = [messageString rangeOfString:@"key2"];
            XCTAssertNotEqual(testRange.location, NSNotFound);
        }
    }
#endif
}

- (void)testSessionEventCounter {
    MPSession *session = [self.session copy];
    
    XCTAssertEqualObjects(session, self.session, @"Session instances are not being copied correctly.");
    
    NSUInteger upperLimit = EVENT_LIMIT + 1;
    for (NSUInteger i = 0; i != upperLimit; ++i) {
        [self.session incrementCounter];
    }
    
    XCTAssertNotEqualObjects(session, self.session, @"New session has not began after reaching the maximum number of events limit.");
}

- (void)testCheckAttributes {
    NSMutableDictionary *dictionary = [@{@"Transport":@"Time Machine",
                                         @"Model":@"Tardis",
                                         @"Keywords":@[@"It is bigger on the inside", @"Looks like a police callbox", @"It is blue"]} mutableCopy];
    
    NSError *error = nil;
    BOOL validAttributes = [self.backendController checkAttribute:dictionary key:@"New Attributes" value:@[@"Noisy breaks", @"Temperamental"] maxValueLength:MAX_USER_ATTR_LIST_ENTRY_LENGTH error:&error];
    XCTAssertTrue(validAttributes);
    
    error = nil;
    validAttributes = [self.backendController checkAttribute:dictionary key:@"New Attributes" value:@"Temperamental" error:&error];
    XCTAssertTrue(validAttributes);
    
    NSMutableString *invalidLengthString = [[NSMutableString alloc] initWithCapacity:(MAX_USER_ATTR_LIST_ENTRY_LENGTH + 1)];
    for (int i = 0; i < (MAX_USER_ATTR_LIST_ENTRY_LENGTH + 1); ++i) {
        [invalidLengthString appendString:@"T"];
    }
    error = nil;
    validAttributes = [self.backendController checkAttribute:dictionary key:@"New Attributes" value:@[invalidLengthString] maxValueLength:MAX_USER_ATTR_LIST_ENTRY_LENGTH error:&error];
    XCTAssertFalse(validAttributes);
    
    NSMutableArray *invalidValues = [[NSMutableArray alloc] initWithCapacity:(MAX_USER_ATTR_LIST_SIZE + 1)];
    for (int i = 0; i < (MAX_USER_ATTR_LIST_SIZE + 1); ++i) {
        [invalidValues addObject:@"Use the stabilisers"];
    }
    error = nil;
    validAttributes = [self.backendController checkAttribute:dictionary key:@"New Attributes" value:invalidValues maxValueLength:MAX_USER_ATTR_LIST_ENTRY_LENGTH error:&error];
    XCTAssertFalse(validAttributes);
    
    error = nil;
    validAttributes = [self.backendController checkAttribute:dictionary key:@"New Attributes" value:nil maxValueLength:MAX_USER_ATTR_LIST_ENTRY_LENGTH error:&error];
    XCTAssertFalse(validAttributes);
    
    error = nil;
    validAttributes = [self.backendController checkAttribute:dictionary key:@"New Attributes" value:@"" maxValueLength:MAX_USER_ATTR_LIST_ENTRY_LENGTH error:&error];
    XCTAssertFalse(validAttributes);
    
    error = nil;
    validAttributes = [self.backendController checkAttribute:dictionary key:@"New Attributes" value:invalidLengthString maxValueLength:MAX_USER_ATTR_LIST_ENTRY_LENGTH error:&error];
    XCTAssertFalse(validAttributes);
    
    NSString *key = nil;
    error = nil;
    validAttributes = [self.backendController checkAttribute:dictionary key:key value:@[@"Noisy breaks", @"Temperamental"] maxValueLength:MAX_USER_ATTR_LIST_ENTRY_LENGTH error:&error];
    XCTAssertFalse(validAttributes);
    
    key = (NSString *)[NSNull null];
    error = nil;
    validAttributes = [self.backendController checkAttribute:dictionary key:key value:@"Noisy breaks" maxValueLength:MAX_USER_ATTR_LIST_ENTRY_LENGTH error:&error];
    XCTAssertFalse(validAttributes);
    
    invalidLengthString = [[NSMutableString alloc] initWithCapacity:(LIMIT_NAME + 1)];
    for (int i = 0; i < (LIMIT_NAME + 1); ++i) {
        [invalidLengthString appendString:@"K"];
    }
    error = nil;
    validAttributes = [self.backendController checkAttribute:dictionary key:invalidLengthString value:@"Noisy breaks" maxValueLength:MAX_USER_ATTR_LIST_ENTRY_LENGTH error:&error];
    XCTAssertFalse(validAttributes);
    
    for (int i = 0; i < LIMIT_ATTR_COUNT; ++i) {
        key = [@(i) stringValue];
        dictionary[key] = key;
    }
    error = nil;
    validAttributes = [self.backendController checkAttribute:dictionary key:@"New Attributes" value:@"Noisy breaks" maxValueLength:MAX_USER_ATTR_LIST_ENTRY_LENGTH error:&error];
    XCTAssertFalse(validAttributes);
}

- (void)testUserAttributes {
    [MPKitInstanceValidator includeUnitTestKits:@[@42, @314]];
    
    if (![MPKitContainer registeredKits]) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClass" startImmediately:NO];
        [MPKitContainer registerKit:kitRegister];
        
        kitRegister = [[MPKitRegister alloc] initWithName:@"KitSecondTest" className:@"MPKitSecondTestClass" startImmediately:YES];
        [MPKitContainer registerKit:kitRegister];
        
        NSDictionary *configuration1 = @{
                                         @"id":@42,
                                         @"as":@{
                                                 @"appId":@"MyAppId"
                                                 }
                                         };
        
        NSDictionary *configuration2 = @{
                                         @"id":@314,
                                         @"as":@{
                                                 @"appId":@"unique id"
                                                 }
                                         };
        
        NSArray *kitConfigs = @[configuration1, configuration2];
        [[MPKitContainer sharedInstance] configureKits:nil];
        [[MPKitContainer sharedInstance] configureKits:kitConfigs];
    }

    MPInitializationStatus originalInitializationStatus = self.backendController.initializationStatus;
    self.backendController.initializationStatus = MPInitializationStatusStarted;
    
    MParticle *mParticle = [MParticle sharedInstance];
    mParticle.backendController.initializationStatus = MPInitializationStatusStarted;
    
    NSDictionary *attributes = @{@"TardisKey1":@"Master",
                                 @"TardisKey2":@"Guest",
                                 @"TardisKey3":@42,
                                 @"TardisKey4":@[@"alohomora", @"open sesame"]
                                 };
    
    [attributes enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSArray class]]) {
            [mParticle setUserAttribute:key values:obj];
            [self.backendController setUserAttribute:key values:obj attempt:0 completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
        } else {
            [mParticle setUserAttribute:key value:obj];
            [self.backendController setUserAttribute:key value:obj attempt:0 completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
        }
    }];
    
    NSDictionary *userAttributes = self.backendController.userAttributes;
    XCTAssertEqualObjects(userAttributes, attributes);
    
    [self.backendController incrementUserAttribute:@"TardisKey4" byValue:@1];
    XCTAssertEqualObjects(userAttributes, attributes);
    
    [self.backendController setUserAttribute:@"TardisKey4" value:@"Door" attempt:0 completionHandler:nil];
    userAttributes = self.backendController.userAttributes;
    XCTAssertNotEqualObjects(userAttributes, attributes);
    XCTAssertEqualObjects(userAttributes[@"TardisKey4"], @"Door");
    
    attributes = @{@"TardisKey1":@"Master",
                   @"TardisKey2":@"Guest",
                   @"TardisKey3":@42,
                   @"TardisKey4":@"Door"
                   };
    
    userAttributes = self.backendController.userAttributes;
    XCTAssertEqualObjects(userAttributes, attributes);
    
    [self.backendController setUserAttribute:@"TardisKey1" value:@"Wrong" attempt:11 completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
    userAttributes = self.backendController.userAttributes;
    XCTAssertEqualObjects(userAttributes, attributes);

    NSMutableString *longString = [[NSMutableString alloc] initWithCapacity:(LIMIT_USER_ATTR_LENGTH + 1)];
    for (int i = 0; i < (LIMIT_USER_ATTR_LENGTH + 1); ++i) {
        [longString appendString:@"T"];
    }
    
    [self.backendController setUserAttribute:@"TardisKey1" value:longString attempt:0 completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
    userAttributes = self.backendController.userAttributes;
    XCTAssertEqualObjects(userAttributes, attributes);

    [self.backendController setUserAttribute:@"TardisKey1" value:@"" attempt:0 completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
    userAttributes = self.backendController.userAttributes;
    XCTAssertNotEqualObjects(userAttributes, attributes);
    XCTAssertNil(userAttributes[@"TardisKey1"]);
    
    attributes = @{@"TardisKey2":@"Guest",
                   @"TardisKey3":@42,
                   @"TardisKey4":@"Door"
                   };

    XCTAssertEqualObjects(userAttributes, attributes);

    [self.backendController setUserAttribute:@"TardisKey2" value:nil attempt:0 completionHandler:nil];
    userAttributes = self.backendController.userAttributes;
    XCTAssertNotEqualObjects(userAttributes, attributes);
    XCTAssertEqualObjects(userAttributes[@"TardisKey2"], [NSNull null]);

    attributes = @{@"TardisKey2":[NSNull null],
                   @"TardisKey3":@42,
                   @"TardisKey4":@"Door"
                   };
    
    XCTAssertEqualObjects(userAttributes, attributes);

    [self.backendController incrementUserAttribute:@"TardisKey2" byValue:@1];
    XCTAssertEqualObjects(userAttributes, attributes);
    
    NSArray *values = @[@"alohomora", @314];
    [self.backendController setUserAttribute:@"TardisKey4" values:values attempt:0 completionHandler:nil];
    XCTAssertEqualObjects(userAttributes[@"TardisKey4"], @"Door");
    userAttributes = self.backendController.userAttributes;
    XCTAssertEqualObjects(userAttributes, attributes);

    [self.backendController setUserAttribute:@"TardisKey4" values:nil attempt:0 completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    XCTAssertNil(userAttributes[@"TardisKey4"]);

    attributes = @{@"TardisKey2":[NSNull null],
                   @"TardisKey3":@42
                   };

    userAttributes = self.backendController.userAttributes;
    XCTAssertEqualObjects(userAttributes, attributes);
    
    self.backendController.initializationStatus = originalInitializationStatus;
    mParticle.backendController.initializationStatus = originalInitializationStatus;
    [[MPKitContainer sharedInstance] configureKits:nil];
}

- (void)testDeferredUserAttributes {
    MPInitializationStatus originalInitializationStatus = self.backendController.initializationStatus;
    self.backendController.initializationStatus = MPInitializationStatusStarting;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Deferred user attributes"];
    __weak MPBackendController *weakBackendController = self.backendController;
    __block NSString *setKey = nil;
    __block NSString *setValue = nil;
    
    [self.backendController setUserAttribute:@"TardisKey1" value:@"Master" attempt:0 completionHandler:^(NSString * _Nonnull key, id _Nullable value, MPExecStatus execStatus) {
        if (execStatus == MPExecStatusSuccess) {
            setKey = key;
            setValue = value;
            
            [expectation fulfill];
        } else if (execStatus == MPExecStatusDelayedExecution || execStatus == MPExecStatusContinuedDelayedExecution) {
            weakBackendController.initializationStatus = MPInitializationStatusStarted;
        }
    }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
    
    self.backendController.initializationStatus = originalInitializationStatus;
    
    XCTAssertEqualObjects(setKey, @"TardisKey1");
    XCTAssertEqualObjects(setValue, @"Master");
}

- (void)testDeferredUserAttributeList {
    MPInitializationStatus originalInitializationStatus = self.backendController.initializationStatus;
    self.backendController.initializationStatus = MPInitializationStatusStarting;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Deferred user attributes"];
    __weak MPBackendController *weakBackendController = self.backendController;
    __block NSString *setKey = nil;
    __block NSArray *setValues = nil;
    NSArray *values = @[@"Master", @"Guest"];
    
    [self.backendController setUserAttribute:@"TardisKey1" values:values attempt:0 completionHandler:^(NSString * _Nonnull key, id _Nullable values, MPExecStatus execStatus) {
        if (execStatus == MPExecStatusSuccess) {
            setKey = key;
            setValues = values;
            
            [expectation fulfill];
        } else if (execStatus == MPExecStatusDelayedExecution || execStatus == MPExecStatusContinuedDelayedExecution) {
            weakBackendController.initializationStatus = MPInitializationStatusStarted;
        }
    }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
    
    self.backendController.initializationStatus = originalInitializationStatus;
    
    XCTAssertEqualObjects(setKey, @"TardisKey1");
    XCTAssertEqualObjects(setValues, values);
}

- (void)testUserAttributeChanged {
    MPInitializationStatus originalInitializationStatus = self.backendController.initializationStatus;
    self.backendController.initializationStatus = MPInitializationStatusStarted;
    
    [self.backendController setUserAttribute:@"TardisModel" value:@"Police Call Box" attempt:0 completionHandler:nil];
    
    NSDictionary *userAttributes = self.backendController.userAttributes;
    XCTAssertEqualObjects(userAttributes[@"TardisModel"], @"Police Call Box");
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    NSArray *messages = [persistence fetchMessagesInSession:self.backendController.session];
    XCTAssertNotNil(messages);
    XCTAssertEqual(messages.count, 1);
    
    MPMessage *message = [messages firstObject];
    XCTAssertNotNil(message);
    
    NSDictionary *messageDictionary = [message dictionaryRepresentation];
    XCTAssertEqualObjects(@"uac", messageDictionary[@"dt"]);
    XCTAssertEqualObjects(@"Police Call Box", messageDictionary[@"nv"]);
    XCTAssertEqualObjects(@"TardisModel", messageDictionary[@"n"]);
    XCTAssertEqualObjects(@NO, messageDictionary[@"d"]);
    
    [persistence deleteSession:self.backendController.session];
    messages = [persistence fetchMessagesInSession:self.backendController.session];
    XCTAssertNil(messages);

    [self.backendController setUserAttribute:@"TardisModel" value:@"" attempt:0 completionHandler:nil];
    messages = [persistence fetchMessagesInSession:self.backendController.session];
    message = [messages firstObject];
    messageDictionary = [message dictionaryRepresentation];
    XCTAssertEqualObjects(@"uac", messageDictionary[@"dt"]);
    XCTAssertEqualObjects([NSNull null], messageDictionary[@"nv"]);
    XCTAssertEqualObjects(@"Police Call Box", messageDictionary[@"ov"]);
    XCTAssertEqualObjects(@"TardisModel", messageDictionary[@"n"]);
    XCTAssertEqualObjects(@YES, messageDictionary[@"d"]);
    
    self.backendController.initializationStatus = originalInitializationStatus;
}

- (void)testUserIdentityChanged {
    MPInitializationStatus originalInitializationStatus = self.backendController.initializationStatus;
    self.backendController.initializationStatus = MPInitializationStatusStarted;

    [self.backendController setUserIdentity:@"The Most Interesting Man in the World" identityType:MPUserIdentityCustomerId attempt:0 completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
    }];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF[%@] == %@", @"n", @(MPUserIdentityCustomerId)];
    NSDictionary *userIdentity = [[self.backendController.userIdentities filteredArrayUsingPredicate:predicate] lastObject];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqualObjects(userIdentity[@"i"], @"The Most Interesting Man in the World");
    XCTAssertEqualObjects(userIdentity[@"n"], @(MPUserIdentityCustomerId));
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    NSArray *messages = [persistence fetchMessagesInSession:self.session];
    XCTAssertNotNil(messages);
    XCTAssertEqual(messages.count, 1);

    MPMessage *message = [messages firstObject];
    XCTAssertNotNil(message);
    
    NSDictionary *messageDictionary = [message dictionaryRepresentation];
    XCTAssertEqualObjects(@"uic", messageDictionary[@"dt"]);
    XCTAssertNotNil(messageDictionary[@"ni"]);
    userIdentity = messageDictionary[@"ni"];
    XCTAssertEqualObjects(userIdentity[@"i"], @"The Most Interesting Man in the World");
    XCTAssertEqualObjects(userIdentity[@"n"], @(MPUserIdentityCustomerId));

    [persistence deleteSession:self.session];
    messages = [persistence fetchMessagesInSession:self.session];
    XCTAssertNil(messages);

    XCTestExpectation *expectation = [self expectationWithDescription:@"User identity changed"];
    [self.backendController setUserIdentity:nil identityType:MPUserIdentityCustomerId attempt:0 completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];

    userIdentity = [[self.backendController.userIdentities filteredArrayUsingPredicate:predicate] lastObject];
    XCTAssertNil(userIdentity);

    messages = [persistence fetchMessagesInSession:self.session];
    XCTAssertNotNil(messages);
    XCTAssertEqual(messages.count, 2);
    
    predicate = [NSPredicate predicateWithFormat:@"messageType == %@", @"uic"];
    message = [[messages filteredArrayUsingPredicate:predicate] firstObject];
    XCTAssertNotNil(message);
    
    messageDictionary = [message dictionaryRepresentation];
    XCTAssertEqualObjects(@"uic", messageDictionary[@"dt"]);
    XCTAssertNil(messageDictionary[@"ni"]);
    userIdentity = messageDictionary[@"oi"];
    XCTAssertEqualObjects(userIdentity[@"i"], @"The Most Interesting Man in the World");
    XCTAssertEqualObjects(userIdentity[@"n"], @(MPUserIdentityCustomerId));
    
    self.backendController.initializationStatus = originalInitializationStatus;
}

- (void)testIncrementUserAttribute {
    MPInitializationStatus originalInitializationStatus = self.backendController.initializationStatus;
    self.backendController.initializationStatus = MPInitializationStatusStarted;

    NSString *userAttributeKey = @"Number of time travels";
    NSNumber *userAttributeValue = self.backendController.userAttributes[userAttributeKey];
    XCTAssertNil(userAttributeValue);
    
    userAttributeValue = [self.backendController incrementUserAttribute:userAttributeKey byValue:@1];
    XCTAssertNotNil(userAttributeValue);
    XCTAssertEqualObjects(userAttributeValue, @1);

    userAttributeValue = self.backendController.userAttributes[userAttributeKey];
    XCTAssertNotNil(userAttributeValue);
    XCTAssertEqualObjects(userAttributeValue, @1);

    [self.backendController setUserAttribute:userAttributeKey value:@"" attempt:0 completionHandler:{}];
    userAttributeValue = self.backendController.userAttributes[userAttributeKey];
    XCTAssertNil(userAttributeValue);
    
    self.backendController.initializationStatus = originalInitializationStatus;
}

- (void)testSetLocation {
    MPInitializationStatus originalInitializationStatus = self.backendController.initializationStatus;
    self.backendController.initializationStatus = MPInitializationStatusStarted;
    
#if TARGET_OS_IOS == 1
    CLLocation *location = [[CLLocation alloc] initWithLatitude:40.738526 longitude:-73.98738];
    [MPStateMachine sharedInstance].location = location;
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Unit Test Event" type:MPEventTypeOther];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [self.backendController logEvent:event
                             attempt:0
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {}];
    
    NSArray<MPMessage *> *messages = [[MPPersistenceController sharedInstance] fetchMessagesForUploadingInSession:self.session];

    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    MPMessage *message = messages.lastObject;
    NSString *messageString = [[NSString alloc] initWithData:message.messageData encoding:NSUTF8StringEncoding];
    NSRange range = [messageString rangeOfString:@"\"lat\":40.738526"];
    XCTAssertNotEqual(range.location, NSNotFound);
    range = [messageString rangeOfString:@"\"lng\":-73.98738"];
    XCTAssertNotEqual(range.location, NSNotFound);
    
    [persistence deleteMessages:messages];
#endif

    self.backendController.initializationStatus = originalInitializationStatus;
}

@end

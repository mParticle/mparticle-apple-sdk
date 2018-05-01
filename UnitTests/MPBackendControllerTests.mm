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
#import "MPResponseConfig.h"

#if TARGET_OS_IOS == 1
#import <CoreLocation/CoreLocation.h>
#endif

#define BACKEND_TESTS_EXPECTATIONS_TIMEOUT 10

#pragma mark - MParticle+Tests category
@interface MParticle(Tests)

+ (dispatch_queue_t)messageQueue;
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

- (NSString *)caseInsensitiveKeyInDictionary:(NSDictionary *)dictionary withKey:(NSString *)key;
- (void)cleanUp;
- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification;
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification;
- (void)logRemoteNotificationWithNotificationController:(MPNotificationController *const)notificationController;
- (void)parseConfigResponse:(NSDictionary *)configurationDictionary;
- (void)parseResponseHeader:(NSDictionary *)responseDictionary session:(MPSession *)session;
- (NSNumber *)previousSessionSuccessfullyClosed;
- (void)setPreviousSessionSuccessfullyClosed:(NSNumber *)previousSessionSuccessfullyClosed;
- (void)processOpenSessionsEndingCurrent:(BOOL)endCurrentSession completionHandler:(dispatch_block_t)completionHandler;
- (void)processPendingArchivedMessages;
- (void)resetUserIdentitiesFirstTimeUseFlag;
- (void)saveMessage:(MPMessage *)message updateSession:(BOOL)updateSession;
- (void)uploadMessagesFromSession:(MPSession *)session completionHandler:(void(^)(MPSession *uploadedSession))completionHandler;
- (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value error:(out NSError *__autoreleasing *)error;
- (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value maxValueLength:(NSUInteger)maxValueLength error:(out NSError *__autoreleasing *)error;

@end

#pragma mark - MPBackendControllerTests unit test class
@interface MPBackendControllerTests : XCTestCase <MPBackendControllerDelegate> {
    dispatch_queue_t messageQueue;
}

@property (nonatomic, strong) MPBackendController *backendController;
@property (nonatomic, strong) MPSession *session;
@property (nonatomic, strong) MPNotificationController *notificationController;

@end

@implementation MPBackendControllerTests

- (void)setUp {
    [super setUp];
    [MParticle sharedInstance];
    messageQueue = [MParticle messageQueue];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Set up"];
    dispatch_async(messageQueue, ^{
        [MPPersistenceController setMpid:@1];
        MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
        stateMachine.apiKey = @"unit_test_app_key";
        stateMachine.secret = @"unit_test_secret";
        
        [[MPPersistenceController sharedInstance] openDatabase];
        _session = self.backendController.session;
        [self addObserver:self forKeyPath:@"backendController.session" options:NSKeyValueObservingOptionNew context:NULL];
        
        [self notificationController];
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)tearDown {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tear down"];
    dispatch_async([MParticle messageQueue], ^{
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        [persistence deleteRecordsOlderThan:[[NSDate date] timeIntervalSince1970]];
        NSMutableArray *sessions = [persistence fetchSessions];
        for (MPSession *session in sessions) {
            [persistence deleteSession:session];
        }
        
        sessions = [persistence fetchSessions];
        XCTAssertEqual(sessions.count, 0, @"Sessions have not been deleted.");
        [persistence closeDatabase];
        [self removeObserver:self forKeyPath:@"backendController.session" context:NULL];
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
    
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
                                                           }
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
    
    _session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]  userId:[MPPersistenceController mpId]];
    [[MPPersistenceController sharedInstance] saveSession:_session];
    return _session;
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
    dispatch_async(messageQueue, ^{
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        
        NSMutableArray *sessions = [persistence fetchSessions];
        MPSession *session = [sessions lastObject];
        
        XCTAssertEqualObjects(session, self.session, @"Sessions are not equal.");
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:_session.sessionId]];
        MPMessage *message = [messages lastObject];
        
        XCTAssertEqualObjects(message.messageType, @"ss", @"Message type is not session start.");
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testEndSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"End session test"];
    dispatch_async([MParticle messageQueue], ^{
        
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        
        NSMutableArray *sessions = [persistence fetchSessions];
        MPSession *session = [sessions lastObject];
        MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
        XCTAssertEqualObjects(session, stateMachine.currentSession, @"Current session and last session in the database are not equal.");
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:_session.sessionId]];
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
        
        messagesDictionary = [persistence fetchMessagesForUploading];
        sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:_session.sessionId]];
        NSUInteger endSessionCount = 0;
        for (MPMessage *message in messages) {
            if ([message.messageType isEqualToString:@"se"]) {
                ++endSessionCount;
            }
        }
        
        XCTAssertEqual(endSessionCount, 1, @"Logging session end multiple times.");
        
        [persistence deletePreviousSession];
        
        MPSession *previousSession = [persistence fetchPreviousSession];
        XCTAssertNil(previousSession, @"Previous session is not being removed.");
        
        [expectation fulfill];
    });
    
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
    MPEvent *event = [[MPEvent alloc] initWithName:@"Unit Test Event" type:MPEventTypeOther];
    event.info = @{@"key":@"value"};
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Batch cycle test"];
    dispatch_async(messageQueue, ^{
        
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        
        [self.backendController logEvent:event
                       completionHandler:^(MPEvent *event, MPExecStatus execStatus) {}];
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:_session.sessionId]];
        XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
        
        for (MPMessage *message in messages) {
            XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        }
        
        MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithMpid:[MPPersistenceController mpId] sessionId:[NSNumber numberWithLong:_session.sessionId] messages:messages sessionTimeout:100 uploadInterval:100];
        XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
        
        if (!uploadBuilder) {
            return;
        }
        
        [uploadBuilder withUserAttributes:[self.backendController userAttributesForUserId:[MPPersistenceController mpId]] deletedUserAttributes:nil];
        [uploadBuilder withUserIdentities:[self.backendController userIdentitiesForUserId:[MPPersistenceController mpId]]];
        [uploadBuilder build:^(MPUpload *upload) {
            [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationFlag];
            
            NSArray *messages = [persistence fetchMessagesInSession:self.session userId:[MPPersistenceController mpId]];
            
            XCTAssertNotNil(messages, @"There are no messages in session.");
            
            for (MPMessage *message in messages) {
                XCTAssertTrue(message.uploadStatus == MPUploadStatusUploaded, @"Messages are not being marked as uploaded.");
            }
            
            NSArray *uploads = [persistence fetchUploads];
            XCTAssertGreaterThan(uploads.count, 0, @"Messages are not being transfered to the Uploads table.");
            
            for (MPUpload *upload in uploads) {
                [persistence deleteUpload:upload];
            }
            
            uploads = [persistence fetchUploads];
            XCTAssertNil(uploads, @"Uploads are not being deleted.");
            
            [expectation fulfill];
        }];
    });
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];

}

- (void)testRampUpload {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ramp upload test"];
    dispatch_async(messageQueue, ^{
        MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                               session:session
                                                                           messageInfo:@{@"MessageKey1":@"MessageValue1"}];
        MPMessage *message = (MPMessage *)[messageBuilder build];
        
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        
        [persistence saveMessage:message];
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        NSArray *persistedMessages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
        MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithMpid:[MPPersistenceController mpId] sessionId:[NSNumber numberWithLong:_session.sessionId] messages:persistedMessages sessionTimeout:100 uploadInterval:100];
        XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
        
        if (!uploadBuilder) {
            return;
        }
        
        [uploadBuilder withUserAttributes:[self.backendController userAttributesForUserId:[MPPersistenceController mpId]] deletedUserAttributes:nil];
        [uploadBuilder withUserIdentities:[self.backendController userIdentitiesForUserId:[MPPersistenceController mpId]]];
        [uploadBuilder build:^(MPUpload *upload) {
            [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationFlag];
            
            NSArray *uploads = [persistence fetchUploads];
            XCTAssertGreaterThan(uploads.count, 0, @"Failed to retrieve messages to be uploaded.");
            
            MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
            [stateMachine configureRampPercentage:@100];
            
            XCTAssertFalse(stateMachine.dataRamped, @"Data ramp is not respecting 100 percent upper limit.");
            
            for (MPUpload *upload in uploads) {
                [persistence deleteUpload:upload];
            }
            
            uploads = [persistence fetchUploads];
            XCTAssertNil(uploads, @"Not deleting ramped upload messages.");
            
            NSArray *persistedMessages = [persistence fetchUploadedMessagesInSession:session];
            MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithMpid:[MPPersistenceController mpId] sessionId:[NSNumber numberWithLong:self.session.sessionId] messages:persistedMessages sessionTimeout:100 uploadInterval:100];
            XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
            
            if (!uploadBuilder) {
                return;
            }
            
            [uploadBuilder withUserAttributes:[self.backendController userAttributesForUserId:[MPPersistenceController mpId]] deletedUserAttributes:nil];
            [uploadBuilder withUserIdentities:[self.backendController userIdentitiesForUserId:[MPPersistenceController mpId]]];
            [uploadBuilder build:^(MPUpload *upload) {
                [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationDelete];
                
                NSArray *persistedMessages = [persistence fetchUploadedMessagesInSession:session];
                XCTAssertNil(persistedMessages, @"Messages are not being deleted are being moved to the uploads table.");
                
                [expectation fulfill];
            }];
        }];
        
    });
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testDidBecomeActiveWithAppLink {
#if TARGET_OS_IOS == 1
    XCTestExpectation *expectation = [self expectationWithDescription:@"Did become active with AppLink test"];
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    NSURL *url = [NSURL URLWithString:@"fb487730798014455://applinks?al_applink_data=%7B%22user_agent%22%3A%22Bolts%20iOS%201.0.0%22%2C%22target_url%22%3A%22http%3A%5C%2F%5C%2Fexample.com%5C%2Fapplinks%22%2C%22extras%22%3A%7B%22myapp_token%22%3A%22t0kEn%22%7D%7D"];
    NSString *sourceApplication = @"com.mParticle.UnitTest";
    NSDictionary *annotation = @{@"foo":@"bar"};
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    [self.backendController handleApplicationDidBecomeActive:nil];
    
    dispatch_async(messageQueue, ^{
        
        NSDictionary *messagesDictionary = [[MPPersistenceController sharedInstance] fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:_session.sessionId]];
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
        
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
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
    
    [self.backendController handleApplicationDidBecomeActive:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Did become active test"];
    
    dispatch_async(messageQueue, ^{
        NSDictionary *messagesDictionary = [[MPPersistenceController sharedInstance] fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:_session.sessionId]];
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
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
#endif
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
    XCTestExpectation *expectation = [self expectationWithDescription:@"test user attributes"];
    dispatch_async(messageQueue, ^{
        [MPKitInstanceValidator includeUnitTestKits:@[@42, @314]];
        
        if (![MPKitContainer registeredKits]) {
            MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
            [MPKitContainer registerKit:kitRegister];
            
            kitRegister = [[MPKitRegister alloc] initWithName:@"KitSecondTest" className:@"MPKitSecondTestClass"];
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
            
            NSString *eTag = @"1.618-2.718-3.141-42";
            NSArray *kitConfigs = @[configuration1, configuration2];
            NSDictionary *configuration = @{kMPRemoteConfigKitsKey:kitConfigs,
                              kMPRemoteConfigCustomModuleSettingsKey:[NSNull null],
                              kMPRemoteConfigRampKey:@100,
                              kMPRemoteConfigTriggerKey:[NSNull null],
                              kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                              kMPRemoteConfigSessionTimeoutKey:@112};
            
            MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];
            
            [MPResponseConfig save:responseConfig eTag:eTag];
        }
        
        
        MParticle *mParticle = [MParticle sharedInstance];
        
        NSDictionary *attributes = @{@"TardisKey1":@"Master",
                                     @"TardisKey2":@"Guest",
                                     @"TardisKey3":@42,
                                     @"TardisKey4":@[@"alohomora", @"open sesame"]
                                     };
        
        [attributes enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSArray class]]) {
                [mParticle.identity.currentUser setUserAttributeList:key values:obj];
                [self.backendController setUserAttribute:key values:obj timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
            } else {
                [mParticle.identity.currentUser setUserAttribute:key value:obj];
                [self.backendController setUserAttribute:key value:obj timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
            }
        }];
        
        NSDictionary *userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
        XCTAssertEqualObjects(userAttributes, attributes);
        
        
        [self.backendController setUserAttribute:@"TardisKey4" value:@"Door" timestamp:[NSDate date] completionHandler:nil];
        userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
        XCTAssertNotEqualObjects(userAttributes, attributes);
        XCTAssertEqualObjects(userAttributes[@"TardisKey4"], @"Door");
        
        attributes = @{@"TardisKey1":@"Master",
                       @"TardisKey2":@"Guest",
                       @"TardisKey3":@42,
                       @"TardisKey4":@"Door"
                       };
        
        userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
        XCTAssertEqualObjects(userAttributes, attributes);
        
        NSMutableString *longString = [[NSMutableString alloc] initWithCapacity:(LIMIT_USER_ATTR_LENGTH + 1)];
        for (int i = 0; i < (LIMIT_USER_ATTR_LENGTH + 1); ++i) {
            [longString appendString:@"T"];
        }
        
        [self.backendController setUserAttribute:@"TardisKey1" value:longString timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
        userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
        XCTAssertEqualObjects(userAttributes, attributes);
        
        [self.backendController removeUserAttribute:@"TardisKey1" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
        userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
        XCTAssertNotEqualObjects(userAttributes, attributes);
        XCTAssertNil(userAttributes[@"TardisKey1"]);
        
        attributes = @{@"TardisKey2":@"Guest",
                       @"TardisKey3":@42,
                       @"TardisKey4":@"Door"
                       };
        
        XCTAssertEqualObjects(userAttributes, attributes);
        
        [self.backendController removeUserAttribute:@"TardisKey2" timestamp:[NSDate date] completionHandler:nil];
        userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
        XCTAssertNotEqualObjects(userAttributes, attributes);
        XCTAssertNil(userAttributes[@"TardisKey2"]);
        
        attributes = @{@"TardisKey3":@42,
                       @"TardisKey4":@"Door"
                       };
        
        XCTAssertEqualObjects(userAttributes, attributes);
        
        [self.backendController incrementUserAttribute:@"TardisKey4" byValue:@1];
        userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];

        XCTAssertEqualObjects(userAttributes, attributes);
        
        NSArray *values = @[@"alohomora", @314];
        [self.backendController setUserAttribute:@"TardisKey4" values:values timestamp:[NSDate date] completionHandler:nil];
        XCTAssertEqualObjects(userAttributes[@"TardisKey4"], @"Door");
        userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
        XCTAssertEqualObjects(userAttributes, attributes);
        
        [self.backendController removeUserAttribute:@"TardisKey4" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
        userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
        XCTAssertNil(userAttributes[@"TardisKey4"]);
        
        attributes = @{@"TardisKey3":@42
                       };
        
        userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
        XCTAssertEqualObjects(userAttributes, attributes);
        
        
        [[MPKitContainer sharedInstance] configureKits:nil];
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testUserAttributeChanged {
    XCTestExpectation *expectation = [self expectationWithDescription:@"User attribute changed"];
    dispatch_async(messageQueue, ^{
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        [persistence saveSession:self.backendController.session];
        
        [self.backendController setUserAttribute:@"TardisModel" value:@"Police Call Box" timestamp:[NSDate date] completionHandler:nil];
        
        NSDictionary *userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
        XCTAssertEqualObjects(userAttributes[@"TardisModel"], @"Police Call Box");
        
        NSArray *messages = [persistence fetchMessagesInSession:self.backendController.session userId:[MPPersistenceController mpId]];
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
        messages = [persistence fetchMessagesInSession:self.backendController.session userId:[MPPersistenceController mpId]];
        XCTAssertNil(messages);
        
        [self.backendController removeUserAttribute:@"TardisModel" timestamp:[NSDate date] completionHandler:nil];
        messages = [persistence fetchMessagesInSession:self.backendController.session userId:[MPPersistenceController mpId]];
        message = [messages firstObject];
        messageDictionary = [message dictionaryRepresentation];
        XCTAssertEqualObjects(@"uac", messageDictionary[@"dt"]);
        XCTAssertEqualObjects([NSNull null], messageDictionary[@"nv"]);
        XCTAssertEqualObjects(@"Police Call Box", messageDictionary[@"ov"]);
        XCTAssertEqualObjects(@"TardisModel", messageDictionary[@"n"]);
        XCTAssertEqualObjects(@YES, messageDictionary[@"d"]);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testUserIdentityChanged {
    XCTestExpectation *expectation = [self expectationWithDescription:@"User identity changed"];
    __weak MPBackendControllerTests *weakSelf = self;
    dispatch_async(messageQueue, ^{
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        [persistence saveSession:weakSelf.session];
        
        [weakSelf.backendController setUserIdentity:@"The Most Interesting Man in the World" identityType:MPUserIdentityCustomerId timestamp:[NSDate date] completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
        }];
        
        __block NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF[%@] == %@", @"n", @(MPUserIdentityCustomerId)];
        __block NSDictionary *userIdentity = [[[self.backendController userIdentitiesForUserId:[MPPersistenceController mpId]] filteredArrayUsingPredicate:predicate] lastObject];
        XCTAssertNotNil(userIdentity);
        XCTAssertEqualObjects(userIdentity[@"i"], @"The Most Interesting Man in the World");
        XCTAssertEqualObjects(userIdentity[@"n"], @(MPUserIdentityCustomerId));
        
        __block NSArray *messages = [persistence fetchMessagesInSession:self.session userId:self.session.userId];
        XCTAssertNotNil(messages);
        XCTAssertEqual(messages.count, 1);
        
        __block MPMessage *message = [messages firstObject];
        XCTAssertNotNil(message);
        
        __block NSDictionary *messageDictionary = [message dictionaryRepresentation];
        XCTAssertEqualObjects(@"uic", messageDictionary[@"dt"]);
        XCTAssertNotNil(messageDictionary[@"ni"]);
        userIdentity = messageDictionary[@"ni"];
        XCTAssertEqualObjects(userIdentity[@"i"], @"The Most Interesting Man in the World");
        XCTAssertEqualObjects(userIdentity[@"n"], @(MPUserIdentityCustomerId));
        
        [persistence deleteSession:self.session];
        messages = [persistence fetchMessagesInSession:self.session userId:[MPPersistenceController mpId]];
        XCTAssertNil(messages);
        
        weakSelf.backendController.session = nil;
        [weakSelf.backendController setUserIdentity:nil identityType:MPUserIdentityCustomerId timestamp:[NSDate date] completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
            userIdentity = [[[weakSelf.backendController userIdentitiesForUserId:[MPPersistenceController mpId]] filteredArrayUsingPredicate:predicate] lastObject];
            XCTAssertNil(userIdentity);
            
            messages = [persistence fetchMessagesInSession:weakSelf.session userId:[MPPersistenceController mpId]];
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
            [expectation fulfill];
        }];
        
    });
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testIncrementUserAttribute {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Increment user attribute"];
    dispatch_async(messageQueue, ^{
        
        NSString *userAttributeKey = @"Number of time travels";
        NSNumber *userAttributeValue = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]][userAttributeKey];
        XCTAssertNil(userAttributeValue);
        
        userAttributeValue = [self.backendController incrementUserAttribute:userAttributeKey byValue:@1];
        XCTAssertNotNil(userAttributeValue);
        XCTAssertEqualObjects(userAttributeValue, @1);
        
        userAttributeValue = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]][userAttributeKey];
        XCTAssertNotNil(userAttributeValue);
        XCTAssertEqualObjects(userAttributeValue, @1);
        
        [self.backendController removeUserAttribute:userAttributeKey timestamp:[NSDate date] completionHandler:{}];
        userAttributeValue = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]][userAttributeKey];
        XCTAssertNil(userAttributeValue);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testSetLocation {
    
#if TARGET_OS_IOS == 1
    CLLocation *location = [[CLLocation alloc] initWithLatitude:40.738526 longitude:-73.98738];
    [MPStateMachine sharedInstance].location = location;
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Unit Test Event" type:MPEventTypeOther];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Set location"];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [self.backendController logEvent:event
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
    NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:_session.sessionId]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    MPMessage *message = messages.lastObject;
    NSString *messageString = [[NSString alloc] initWithData:message.messageData encoding:NSUTF8StringEncoding];
    NSRange range = [messageString rangeOfString:@"\"lat\":40.738526"];
    XCTAssertNotEqual(range.location, NSNotFound);
    range = [messageString rangeOfString:@"\"lng\":-73.98738"];
    XCTAssertNotEqual(range.location, NSNotFound);
    
    [persistence deleteMessages:messages];
    
    [expectation fulfill];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
#endif
}

- (void)testSessionAttributesAndIncrement {
    [self.backendController setSessionAttribute:_session key:@"foo-session-attribute-1" value:@"foo-session-value-1"];
    XCTAssertEqualObjects(_session.attributesDictionary[@"foo-session-attribute-1"], @"foo-session-value-1");
    [self.backendController setSessionAttribute:_session key:@"foo-session-attribute-1" value:@"foo-session-value-2"];
    XCTAssertEqualObjects(_session.attributesDictionary[@"foo-session-attribute-1"], @"foo-session-value-2");
    [self.backendController setSessionAttribute:_session key:@"foo-session-attribute-1" value:@2];
    XCTAssertEqualObjects(_session.attributesDictionary[@"foo-session-attribute-1"], @2);
    [self.backendController incrementSessionAttribute:_session key:@"foo-session-attribute-1" byValue:@3];
    XCTAssertEqualObjects(_session.attributesDictionary[@"foo-session-attribute-1"], @5);
}

@end

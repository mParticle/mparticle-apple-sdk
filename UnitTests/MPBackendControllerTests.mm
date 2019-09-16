#import <XCTest/XCTest.h>
#import "OCMock.h"
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
#import "MPResponseConfig.h"
#import "MPExceptionHandler.h"
#import "MPBaseTestCase.h"
#import "MPIUserDefaults.h"

#if TARGET_OS_IOS == 1
#import <CoreLocation/CoreLocation.h>
#endif

#define BACKEND_TESTS_EXPECTATIONS_TIMEOUT 10

@interface MPExceptionHandler(Tests)

#if TARGET_OS_IOS == 1
- (void)handleCrashReportOccurred:(NSNotification *)notification;
#endif

@end

#pragma mark - MParticle+Tests category
@interface MParticle (Tests)

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong, nonnull) MPBackendController *backendController;
@property (nonatomic, strong) MPPersistenceController *persistenceController;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong) MPKitContainer *kitContainer;

@end

#pragma mark - MPKitContainer category for unit tests
@interface MPKitContainer(Tests)

- (id<MPKitProtocol>)startKit:(NSNumber *)integrationId configuration:(MPKitConfiguration *)kitConfiguration;

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
- (NSArray *)batchMessageArraysFromMessageArray:(NSArray *)messages maxBatchMessages:(NSInteger)maxBatchMessages maxBatchBytes:(NSInteger)maxBatchBytes maxMessageBytes:(NSInteger)maxMessageBytes;
- (void)uploadOpenSessions:(NSMutableArray *)openSessions completionHandler:(void (^)(void))completionHandler;
- (void)backgroundTaskBlock;

@end

#pragma mark - MPBackendControllerTests unit test class
@interface MPBackendControllerTests : MPBaseTestCase <MPBackendControllerDelegate> {
    dispatch_queue_t messageQueue;
}

@property (nonatomic, strong) MPBackendController *backendController;
@property (nonatomic, strong) MPSession *session;
@property (nonatomic, strong) MPNotificationController *notificationController;

@end

@implementation MPBackendControllerTests

- (void)setUp {
    [super setUp];
    messageQueue = [MParticle messageQueue];
    
    [MPPersistenceController setMpid:@1];
    [MParticle sharedInstance].persistenceController = [[MPPersistenceController alloc] init];
    
    [MParticle sharedInstance].stateMachine = [[MPStateMachine alloc] init];
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    stateMachine.apiKey = @"unit_test_app_key";
    stateMachine.secret = @"unit_test_secret";
    
    [MParticle sharedInstance].kitContainer = [[MPKitContainer alloc] init];
    
    MParticle *mParticle = [MParticle sharedInstance];
    mParticle.backendController = [[MPBackendController alloc] initWithDelegate:(id<MPBackendControllerDelegate>)mParticle];
    self.backendController = [MParticle sharedInstance].backendController;
    [self notificationController];
}

- (void)tearDown {
    [MParticle sharedInstance].stateMachine.launchInfo = nil;
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    [persistence deleteRecordsOlderThan:[[NSDate date] timeIntervalSince1970]];
    NSMutableArray *sessions = [persistence fetchSessions];
    for (MPSession *session in sessions) {
        [persistence deleteSession:session];
    }
    
    sessions = [persistence fetchSessions];
    XCTAssertEqual(sessions.count, 0, @"Sessions have not been deleted.");
    [persistence closeDatabase];
    [super tearDown];
}

- (void)forwardLogInstall {}

- (void)forwardLogUpdate {}

- (void)configureNetworkPerformanceMeasurement {}

- (void)configureSocialNetwork:(NSNumber *)socialNetworkNumber {}

- (void)sessionDidBegin:(MPSession *)session {}

- (void)sessionDidEnd:(MPSession *)session {}

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

- (MPNotificationController *)notificationController {
    if (_notificationController) {
        return _notificationController;
    }
    
    _notificationController = [[MPNotificationController alloc] init];
    
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
    dispatch_sync(messageQueue, ^{
        [self.backendController beginSession];
        self.session = self.backendController.session;
        MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
        
        NSMutableArray *sessions = [persistence fetchSessions];
        MPSession *session = [sessions lastObject];
        
        XCTAssertEqualObjects(session, self.session, @"Sessions are not equal.");
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        MPMessage *message = [messages lastObject];
        
        XCTAssertEqualObjects(message.messageType, @"ss", @"Message type is not session start.");
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testEndSession {
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"End session test"];
    dispatch_sync(messageQueue, ^{
        [self.backendController beginSession];
        self.session = self.backendController.session;
        NSMutableArray *sessions = [persistence fetchSessions];
        MPSession *session = [sessions lastObject];
        MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
        XCTAssertEqualObjects(session, stateMachine.currentSession, @"Current session and last session in the database are not equal.");
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
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
        messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
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

- (void)testAutomaticSessionEnd {
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    MParticle *mParticle = [MParticle sharedInstance];
    id mockBackendController = OCMPartialMock(self.backendController);
    mParticle.backendController = mockBackendController;
    self.backendController = [MParticle sharedInstance].backendController;
    
    dispatch_sync(messageQueue, ^{
        [self.backendController beginSession];
        self.session = self.backendController.session;
        NSMutableArray *sessions = [persistence fetchSessions];
        MPSession *session = [sessions lastObject];
        MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
        XCTAssertEqualObjects(session, stateMachine.currentSession, @"Current session and last session in the database are not equal.");
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        BOOL containsSessionStart = NO;
        
        for (MPMessage *message in messages) {
            if ([message.messageType isEqualToString:@"ss"]) {
                containsSessionStart = YES;
            }
        }
        
        XCTAssertTrue(containsSessionStart, @"Begin session does not contain a session start message.");
        
        [[mockBackendController expect] uploadOpenSessions:sessions completionHandler:OCMOCK_ANY];
        
        [self.backendController processOpenSessionsEndingCurrent:YES completionHandler:nil];
        
        [mockBackendController verifyWithDelay:5.0];
        [mockBackendController stopMocking];
    });
}

- (void)testBackgroundBlock {
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Begin background block test"];
    
    dispatch_sync(messageQueue, ^{
        [self.backendController beginSession];
        self.session = self.backendController.session;
        NSMutableArray *sessions = [persistence fetchSessions];
        MPSession *session = [sessions lastObject];
        MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
        XCTAssertEqualObjects(session, stateMachine.currentSession, @"Current session and last session in the database are not equal.");
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        BOOL containsSessionStart = NO;
        
        for (MPMessage *message in messages) {
            if ([message.messageType isEqualToString:@"ss"]) {
                containsSessionStart = YES;
            }
        }
        XCTAssertTrue(containsSessionStart, @"Begin session does not contain a session start message.");
        
        [self.backendController endSession];
        [self.backendController beginSession];
        session = self.backendController.session;
        sessions = [persistence fetchSessions];
        XCTAssertEqual(sessions.count, 2);
        
        [self.backendController backgroundTaskBlock];
        XCTAssertNotNil(self.backendController.session);
        
        MPMessage *message = [persistence fetchSessionEndMessageInSession:session];
        XCTAssertNil(message);
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testCheckAttributeValueEmpty {
    NSError *error = nil;
    BOOL success = [MPBackendController checkAttribute:[NSDictionary dictionary] key:@"foo"
                                                 value:@"  "
                                                 error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kEmptyAttributeValue, error.code);
    
    error = nil;
    [MPBackendController checkAttribute:[NSDictionary dictionary] key:@"foo"
                                  value:@""
                                  error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqual(kEmptyAttributeValue, error.code);
}

- (void)testCheckAttributeStringAttribute {
    NSError *error = nil;
    BOOL success = [MPBackendController checkAttribute:[NSDictionary dictionary] key:@"foo" value:@"bar" error:&error];
    XCTAssert(success);
    XCTAssertNil(error);
}

- (void)testCheckAttributeNumberAttribute {
    NSError *error = nil;
    BOOL success = [MPBackendController checkAttribute:[NSDictionary dictionary] key:@"foo" value:@123.0 error:&error];
    XCTAssert(success);
    XCTAssertNil(error);
}

- (void)testCheckAttributeArrayAttribute {
    NSError *error = nil;
    NSArray *arrayValue = @[ @"foo", @"bar"];
    BOOL success = [MPBackendController checkAttribute:[NSDictionary dictionary] key:@"foo" value:arrayValue error:&error];
    XCTAssert(success);
    XCTAssertNil(error);
}

- (void)testCheckAttributeArrayValuesTooLongAttribute {
    NSError *error = nil;
    id mockValue = [OCMockObject mockForClass:[NSString class]];
    OCMStub([mockValue length]).andReturn(LIMIT_ATTR_VALUE_LENGTH);
    NSArray *arrayValue = @[@"foo", mockValue];
    BOOL success = [MPBackendController checkAttribute:[NSDictionary dictionary] key:@"foo" value:arrayValue error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kExceededAttributeValueMaximumLength, error.code);
}

- (void)testCheckAttributeArrayValueInvalidLongAttribute {
    NSError *error = nil;
    id mockValue = [OCMockObject mockForClass:[NSString class]];
    OCMStub([mockValue length]).andReturn(LIMIT_ATTR_VALUE_LENGTH);
    NSArray *arrayValue = @[@"foo", @10.0];
    BOOL success = [MPBackendController checkAttribute:[NSDictionary dictionary] key:@"foo" value:arrayValue error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kInvalidDataType, error.code);
}


- (void)testCheckAttributeTooManyAttributes {
    id mockAttributes = [OCMockObject mockForClass:[NSMutableDictionary class]];
    OCMStub([mockAttributes count]).andReturn(LIMIT_ATTR_COUNT);
    NSError *error = nil;
    BOOL success = [MPBackendController checkAttribute:mockAttributes key:@"foo" value:@"bar" error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kExceededAttributeCountLimit, error.code);
}

- (void)testCheckAttributeKeyTooLong {
    id mockKey = [OCMockObject mockForClass:[NSString class]];
    OCMStub([mockKey length]).andReturn(LIMIT_ATTR_KEY_LENGTH+1);
    
    NSError *error = nil;
    BOOL success = [MPBackendController checkAttribute:[NSDictionary dictionary] key:mockKey value:@"foo" error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kExceededAttributeKeyMaximumLength, error.code);
}

- (void)testCheckAttributeValueTooLong {
    id mockValue = [OCMockObject mockForClass:[NSString class]];
    OCMStub([mockValue length]).andReturn(LIMIT_ATTR_VALUE_LENGTH+1);
    OCMStub([mockValue stringByTrimmingCharactersInSet:OCMOCK_ANY]).andReturn(@"foo");
    NSError *error = nil;
    BOOL success = [MPBackendController checkAttribute:[NSDictionary dictionary] key:@"foo" value:mockValue error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kExceededAttributeValueMaximumLength, error.code);
}

- (void)testCheckAttributeValueNil {
    NSError *error = nil;
    NSString *nilValue = nil;
    BOOL success = [MPBackendController checkAttribute:[NSDictionary dictionary] key:@"foo" value:nilValue error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kNilAttributeValue, error.code);
}

- (void)testCheckAttributeKeyNullNil {
    NSError *error = nil;
    NSString *nilKey = (NSString*)[NSNull null];
    BOOL success = [MPBackendController checkAttribute:[NSDictionary dictionary] key:nilKey value:@"foo" error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kInvalidKey, error.code);
    
    error = nil;
    nilKey = nil;
    success = [MPBackendController checkAttribute:[NSDictionary dictionary] key:nilKey value:@"foo" error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kInvalidKey, error.code);
}

- (void)testBatchCycle {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPEvent *event = [[MPEvent alloc] initWithName:@"Unit Test Event" type:MPEventTypeOther];
    event.customAttributes = @{@"key":@"value"};
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    [self.backendController logEvent:event
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
    NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    BOOL eventFound = NO;
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        if ([message.messageType isEqualToString:kMPMessageTypeStringEvent]) {
            eventFound = YES;
        }
    }
    XCTAssertTrue(eventFound, @"Message for logEvent is not being saved.");

    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithMpid:[MPPersistenceController mpId] sessionId:[NSNumber numberWithLong:self->_session.sessionId] messages:messages sessionTimeout:100 uploadInterval:100];
    XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
    
    [uploadBuilder withUserAttributes:[self.backendController userAttributesForUserId:[MPPersistenceController mpId]] deletedUserAttributes:nil];
    [uploadBuilder withUserIdentities:[self.backendController userIdentitiesForUserId:[MPPersistenceController mpId]]];
    [uploadBuilder build:^(MPUpload *upload) {
        [persistence saveUpload:upload];
        
        NSArray *messages = [persistence fetchMessagesInSession:self.session userId:[MPPersistenceController mpId]];
        
        XCTAssertNotNil(messages, @"There are no messages in session.");
        
        NSArray *uploads = [persistence fetchUploads];
        XCTAssertGreaterThan(uploads.count, 0, @"Messages are not being transfered to the Uploads table.");
        
        for (MPUpload *upload in uploads) {
            [persistence deleteUpload:upload];
        }
        
        uploads = [persistence fetchUploads];
        XCTAssertNil(uploads, @"Uploads are not being deleted.");
    }];
}

- (void)testloggingBaseEvent {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPBaseEvent *event = [[MPBaseEvent alloc] initWithEventType:MPEventTypeOther];
    event.customAttributes = @{@"key":@"value"};
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    [self.backendController logBaseEvent:event
                   completionHandler:^(MPBaseEvent *event, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
    NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        XCTAssertTrue(![message.messageType isEqualToString:kMPMessageTypeStringUnknown], @"MPBaseEvent messages are being logged to server.");
    }
}

- (void)testRampUpload {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ramp upload test"];
    dispatch_async(messageQueue, ^{
        MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                               session:session
                                                                           messageInfo:@{@"MessageKey1":@"MessageValue1"}];
        MPMessage *message = [messageBuilder build];
        
        MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
        
        [persistence saveMessage:message];
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        NSArray *persistedMessages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
        MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithMpid:[MPPersistenceController mpId] sessionId:[NSNumber numberWithLong:self->_session.sessionId] messages:persistedMessages sessionTimeout:100 uploadInterval:100];
        XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
        
        if (!uploadBuilder) {
            return;
        }
        
        [uploadBuilder withUserAttributes:[self.backendController userAttributesForUserId:[MPPersistenceController mpId]] deletedUserAttributes:nil];
        [uploadBuilder withUserIdentities:[self.backendController userIdentitiesForUserId:[MPPersistenceController mpId]]];
        [uploadBuilder build:^(MPUpload *upload) {
            [persistence saveUpload:upload];
            
            NSArray *uploads = [persistence fetchUploads];
            XCTAssertGreaterThan(uploads.count, 0, @"Failed to retrieve messages to be uploaded.");
            
            MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
            [stateMachine configureRampPercentage:@100];
            
            XCTAssertFalse(stateMachine.dataRamped, @"Data ramp is not respecting 100 percent upper limit.");
            
            for (MPUpload *upload in uploads) {
                [persistence deleteUpload:upload];
            }
            
            uploads = [persistence fetchUploads];
            XCTAssertNil(uploads, @"Not deleting ramped upload messages.");
        }];
        [expectation fulfill];
    });
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"dispatch_after expectation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation2 fulfill];
    });
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testDidBecomeActiveWithAppLink {
#if TARGET_OS_IOS == 1
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSURL *url = [NSURL URLWithString:@"fb487730798014455://applinks?al_applink_data=%7B%22user_agent%22%3A%22Bolts%20iOS%201.0.0%22%2C%22target_url%22%3A%22http%3A%5C%2F%5C%2Fexample.com%5C%2Fapplinks%22%2C%22extras%22%3A%7B%22myapp_token%22%3A%22t0kEn%22%7D%7D"];
    NSString *sourceApplication = @"com.mParticle.UnitTest";
    NSDictionary *annotation = @{@"foo":@"bar"};
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    [self.backendController handleApplicationDidBecomeActive:nil];
    dispatch_sync(messageQueue, ^{
    });
    
    NSDictionary *messagesDictionary = [[MParticle sharedInstance].persistenceController fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
    NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
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
    XCTestExpectation *expectation = [self expectationWithDescription:@"dispatch_after expectation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
    
#endif
}

- (void)testSetIdentityToNil {
    [[self backendController] setUserIdentity:@"foo" identityType:MPUserIdentityEmail
                                    timestamp:[NSDate date]
                            completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
                                
                            }];
    NSDictionary *identities = [MParticle sharedInstance].identity.currentUser.userIdentities;
    XCTAssertEqualObjects(@"foo", [identities objectForKey:@(MPUserIdentityEmail)]);
    [[self backendController] setUserIdentity:(id)[NSNull null] identityType:MPUserIdentityEmail
                                    timestamp:[NSDate date]
                            completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
                                
                            }];
    
    identities = [MParticle sharedInstance].identity.currentUser.userIdentities;
    XCTAssertNil([identities objectForKey:@(MPUserIdentityEmail)]);
}

- (void)testDoNotSetDuplicateIdentityCasing {
    __block MPExecStatus status = MPExecStatusFail;
    [[self backendController] setUserIdentity:@"foo" identityType:MPUserIdentityEmail
                                    timestamp:[NSDate date]
                            completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
                                
                            }];
    [[self backendController] setUserIdentity:@"FOO" identityType:MPUserIdentityEmail
                                    timestamp:[NSDate date]
                            completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
                                status = execStatus;
                            }];
    XCTAssertEqual(MPExecStatusSuccess, status);
}

- (void)testDoNotSetDuplicateIdentity {
    __block MPExecStatus status = MPExecStatusSuccess;
    [[self backendController] setUserIdentity:@"foo" identityType:MPUserIdentityEmail
                                    timestamp:[NSDate date]
                            completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
                                
                            }];
    [[self backendController] setUserIdentity:@"foo" identityType:MPUserIdentityEmail
                                    timestamp:[NSDate date]
                            completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
                                status = execStatus;
                            }];
    XCTAssertEqual(MPExecStatusFail, status);
}

- (void)testDidBecomeActive {
#if TARGET_OS_IOS == 1
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSURL *url = [NSURL URLWithString:@"particlebox://unit_test"];
    NSString *sourceApplication = @"com.mParticle.UnitTest";
    NSDictionary *annotation = @{@"key1":@1, @"key2":[NSDate date]};
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    [self.backendController handleApplicationDidBecomeActive:nil];
    
    NSDictionary *messagesDictionary = [[MParticle sharedInstance].persistenceController fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
    NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
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
    XCTestExpectation *expectation = [self expectationWithDescription:@"dispatch_after expectation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
#endif
}

- (void)testSetStringAttribute {
    [self.backendController setUserAttribute:@"foo attribute 1" value:@"foo value 1" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
    NSString *value = attributes[@"foo attribute 1"];
    XCTAssertEqualObjects(value, @"foo value 1");
}

- (void)testSetExistingStringAttribute {
    [self.backendController setUserAttribute:@"foo attribute 1" value:@"foo value 1" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    [self.backendController setUserAttribute:@"foo attribute 1" value:@"foo value 2" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
    NSString *value = attributes[@"foo attribute 1"];
    XCTAssertEqualObjects(value, @"foo value 2");
}

- (void)testSetStringArrayAttribute {
    [self.backendController setUserAttribute:@"foo attribute 1" values:@[@"foo value 1", @"foo value 2"] timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
    NSArray *array = attributes[@"foo attribute 1"];
    NSArray *result = @[@"foo value 1", @"foo value 2"];
    XCTAssertEqualObjects(array, result);
}

- (void)testSetNumberAttribute {
    [self.backendController setUserAttribute:@"foo attribute 2" value:@12.34 timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
    NSNumber *value = attributes[@"foo attribute 2"];
    XCTAssertEqualObjects(value, @12.34);
}

- (void)testSetTooLongAttribute {
    NSMutableString *longValue = [[NSMutableString alloc] initWithCapacity:(LIMIT_ATTR_VALUE_LENGTH + 1)];
    for (int i = 0; i < (LIMIT_ATTR_VALUE_LENGTH + 1); ++i) {
        [longValue appendString:@"T"];
    }
    [self.backendController setUserAttribute:@"foo attribute 2" value:longValue timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
    XCTAssertEqualObjects(attributes, @{});
}

- (void)testSetInvalidDateAttribute {
    NSDate *date = [NSDate date];
    [self.backendController setUserAttribute:@"foo attribute 2" value:date timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
    XCTAssertEqualObjects(attributes, @{});
}

- (void)testSetInvalidNullAttribute {
    NSNull *nullObject = [NSNull null];
    [self.backendController setUserAttribute:@"foo attribute 2" value:nullObject timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
    XCTAssertEqualObjects(attributes, @{});
}

- (void)testIncrementInvalidAttribute {
    [self.backendController setUserAttribute:@"foo attribute 2" value:@"foo value 2" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    [self.backendController incrementUserAttribute:@"foo attribute 2" byValue:@1];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
    NSString *value = attributes[@"foo attribute 2"];
    XCTAssertEqualObjects(value, @"foo value 2");
}

- (void)testRemoveNumberAttribute {
    [self.backendController setUserAttribute:@"foo attribute 2" value:@12.34 timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    [self.backendController removeUserAttribute:@"foo attribute 2" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
    XCTAssertEqualObjects(attributes, @{});
}

- (void)testRemoveStringAttribute {
    [self.backendController setUserAttribute:@"foo attribute 2" value:@"foo value 2" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    [self.backendController removeUserAttribute:@"foo attribute 2" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
    XCTAssertEqualObjects(attributes, @{});
}

- (void)testSetUserTag {
    [self.backendController setUserAttribute:@"foo tag 1" value:@"  " timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
    XCTAssertEqual(attributes.count, 1);
    NSString *value = attributes[@"foo tag 1"];
    XCTAssertEqualObjects(value, [NSNull null]);
}

- (void)testSetUserAttributeKits {
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
        
        NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
        [[MPIUserDefaults standardUserDefaults] setConfiguration:configuration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];
    }
    
    [self.backendController setUserAttribute:@"foo attribute 3" value:@"foo value 3" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
    
    NSDictionary *userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController mpId]];
    XCTAssertEqualObjects(userAttributes, @{@"foo attribute 3":@"foo value 3"});
}

- (void)testUserAttributeChanged {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
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
}

- (void)testUserIdentityChanged {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    [self addObserver:self forKeyPath:@"backendController.session" options:NSKeyValueObservingOptionNew context:NULL];
    XCTestExpectation *expectation = [self expectationWithDescription:@"User identity changed"];
    __weak MPBackendControllerTests *weakSelf = self;
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
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
    weakSelf.backendController.session = nil;
    
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
        self.session = self.backendController.session;
        messages = [persistence fetchMessagesInSession:self.session userId:[MPPersistenceController mpId]];
        XCTAssertEqual(messages.count, 1);
    });
    
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
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
    [self removeObserver:self forKeyPath:@"backendController.session" context:NULL];
}

- (void)testIncrementUserAttribute {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Increment user attribute"];
    dispatch_sync(messageQueue, ^{
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
    [MParticle sharedInstance].stateMachine.location = location;
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Unit Test Event" type:MPEventTypeOther];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Set location"];
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
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
    MPSession *session = [[MPSession alloc] init];
    [self.backendController setSessionAttribute:session key:@"foo-session-attribute-1" value:@"foo-session-value-1"];
    XCTAssertEqualObjects(session.attributesDictionary[@"foo-session-attribute-1"], @"foo-session-value-1");
    [self.backendController setSessionAttribute:session key:@"foo-session-attribute-1" value:@"foo-session-value-2"];
    XCTAssertEqualObjects(session.attributesDictionary[@"foo-session-attribute-1"], @"foo-session-value-2");
    [self.backendController setSessionAttribute:session key:@"foo-session-attribute-1" value:@2];
    XCTAssertEqualObjects(session.attributesDictionary[@"foo-session-attribute-1"], @2);
    [self.backendController incrementSessionAttribute:session key:@"foo-session-attribute-1" byValue:@3];
    XCTAssertEqualObjects(session.attributesDictionary[@"foo-session-attribute-1"], @5);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"dispatch_after expectation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testMessageWithOptOut {
    [MPPersistenceController setMpid:@2];
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    [MParticle sharedInstance].stateMachine.optOut = YES;
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    [[MParticle sharedInstance].backendController saveMessage:message updateSession:NO];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
    NSArray<MPMessage *> *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
    
    XCTAssertEqual(messages.count, 0, @"No Messages should be saved.");
}

- (void)testMessageWithOptOutMessage {
    [MPPersistenceController setMpid:@2];
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    [MParticle sharedInstance].stateMachine.optOut = YES;
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeOptOut session:session messageInfo:@{kMPOptOutStatus:(@"true")}];
    
    MPMessage *message = [messageBuilder build];
    [[MParticle sharedInstance].backendController saveMessage:message updateSession:NO];
    
    XCTAssertTrue(message.messageId > 0, @"Message id not greater than zero: %lld", message.messageId);
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
    NSArray<MPMessage *> *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
    
    XCTAssertEqual(messages.count, 1, @"The Opt Out Message wasn't saved.");
}

- (void)testBatchAndMessageLimitsMessagesPerBatch {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    
    NSMutableArray *unlimitedMessages = [NSMutableArray array];
    for (int i=0; i<10; i++) {
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                               session:session
                                                                           messageInfo:@{@"MessageKey1":@"MessageValue1"}];
        MPMessage *message = [messageBuilder build];
        [unlimitedMessages addObject:message];
    }
    
    NSArray *batchArrays = [self.backendController batchMessageArraysFromMessageArray:unlimitedMessages maxBatchMessages:1 maxBatchBytes:NSIntegerMax maxMessageBytes:NSIntegerMax];
    XCTAssertEqual(batchArrays.count, 10);
    for (int i=0; i<batchArrays.count; i++) {
        NSArray *batchMessages = batchArrays[i];
        XCTAssertEqual(batchMessages.count, 1);
    }
}

- (void)testBatchAndMessageLimitsMultipleMessagesPerBatch {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    
    NSMutableArray *unlimitedMessages = [NSMutableArray array];
    for (int i=0; i<10; i++) {
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                               session:session
                                                                           messageInfo:@{@"MessageKey1":@"MessageValue1"}];
        MPMessage *message = [messageBuilder build];
        [unlimitedMessages addObject:message];
    }
    
    NSArray *batchArrays = [self.backendController batchMessageArraysFromMessageArray:unlimitedMessages maxBatchMessages:2 maxBatchBytes:NSIntegerMax maxMessageBytes:NSIntegerMax];
    XCTAssertEqual(batchArrays.count, 5);
    for (int i=0; i<batchArrays.count; i++) {
        NSArray *batchMessages = batchArrays[i];
        XCTAssertEqual(batchMessages.count, 2);
    }
}

- (void)testBatchAndMessageLimitsBytesPerBatch {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    
    NSMutableArray *unlimitedMessages = [NSMutableArray array];
    for (int i=0; i<10; i++) {
        [unlimitedMessages addObject:message];
    }
    
    NSArray *batchArrays = [self.backendController batchMessageArraysFromMessageArray:unlimitedMessages maxBatchMessages:NSIntegerMax maxBatchBytes:message.messageData.length*3 maxMessageBytes:NSIntegerMax];
    XCTAssertEqual(batchArrays.count, 4);
    for (int i=0; i<batchArrays.count; i++) {
        NSArray *batchMessages = batchArrays[i];
        if (i+1<batchArrays.count) {
            XCTAssertEqual(batchMessages.count, 3);
        } else {
            XCTAssertEqual(batchMessages.count, 1);
        }
        
    }
}

- (void)testBatchAndMessageLimitsBytesPerMessage {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    NSString *longString = @"a";
    while (longString.length < 1000) {
        longString = [NSString stringWithFormat:@"%@%@", longString, longString];
    }
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:@{@"MessageKey1":longString}];
    MPMessage *message = [messageBuilder build];
    NSMutableArray *unlimitedMessages = [NSMutableArray array];
    for (int i=0; i<10; i++) {
        [unlimitedMessages addObject:message];
    }
    
    NSArray *batchArrays = [self.backendController batchMessageArraysFromMessageArray:unlimitedMessages maxBatchMessages:NSIntegerMax maxBatchBytes:NSIntegerMax maxMessageBytes:message.messageData.length-1];
    XCTAssertEqual(batchArrays.count, 0);
    
    batchArrays = [self.backendController batchMessageArraysFromMessageArray:unlimitedMessages maxBatchMessages:NSIntegerMax maxBatchBytes:NSIntegerMax maxMessageBytes:message.messageData.length];
    XCTAssertEqual(batchArrays.count, 1);
    XCTAssertEqual(((NSArray *)batchArrays[0]).count, 10);
    
    
    batchArrays = [self.backendController batchMessageArraysFromMessageArray:unlimitedMessages maxBatchMessages:NSIntegerMax maxBatchBytes:message.messageData.length maxMessageBytes:NSIntegerMax];
    XCTAssertEqual(batchArrays.count, 10);
    for (int i=0; i<10; i++) {
        XCTAssertEqual(((NSArray *)batchArrays[i]).count, 1);
    }
    
}

@end

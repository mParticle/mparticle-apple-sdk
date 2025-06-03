#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
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
#import "MParticleSwift.h"
#import "MPBaseTestCase.h"

#if TARGET_OS_IOS == 1
#import <CoreLocation/CoreLocation.h>
#endif

@interface MPMessage ()

@property (nonatomic, strong, readwrite, nonnull) NSData *messageData;

@end

@interface MParticleUser ()

- (void)setIdentitySync:(NSString *)identityString identityType:(MPIdentity)identityType;
- (void)setUserId:(NSNumber *)userId;

@end

@interface MPIdentityApi ()

@property(nonatomic, strong, readwrite, nonnull) MParticleUser *currentUser;

@end

#pragma mark - MParticle+Tests category
@interface MParticle (Tests)

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
@property (nonatomic, strong, nonnull) MParticleOptions *options;

@end

#pragma mark - MPKitContainer category for unit tests
@interface MPKitContainer_PRIVATE(Tests)

- (id<MPKitProtocol>)startKit:(NSNumber *)integrationId configuration:(MPKitConfiguration *)kitConfiguration;

@end

#pragma mark - MPBackendController+Tests category
@interface MPBackendController_PRIVATE(Tests)

@property (nonatomic, strong) MPNetworkCommunication_PRIVATE *networkCommunication;
@property (nonatomic, strong) NSMutableDictionary *userAttributes;
@property (nonatomic, strong) NSMutableArray *userIdentities;

- (NSString *)caseInsensitiveKeyInDictionary:(NSDictionary *)dictionary withKey:(NSString *)key;
- (void)cleanUp;
- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification;
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification;
- (void)logRemoteNotificationWithNotificationController:(MPNotificationController_PRIVATE *const)notificationController;
- (void)parseConfigResponse:(NSDictionary *)configurationDictionary;
- (void)parseResponseHeader:(NSDictionary *)responseDictionary session:(MPSession *)session;
- (NSNumber *)previousSessionSuccessfullyClosed;
- (void)setPreviousSessionSuccessfullyClosed:(NSNumber *)previousSessionSuccessfullyClosed;
- (void)processOpenSessionsEndingCurrent:(BOOL)endCurrentSession completionHandler:(dispatch_block_t)completionHandler;
- (void)resetUserIdentitiesFirstTimeUseFlag;
- (void)saveMessage:(MPMessage *)message updateSession:(BOOL)updateSession;
- (void)uploadMessagesFromSession:(MPSession *)session completionHandler:(void(^)(MPSession *uploadedSession))completionHandler;
- (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value error:(out NSError *__autoreleasing *)error;
- (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value maxValueLength:(NSUInteger)maxValueLength error:(out NSError *__autoreleasing *)error;
- (NSArray *)batchMessageArraysFromMessageArray:(NSArray *)messages maxBatchMessages:(NSInteger)maxBatchMessages maxBatchBytes:(NSInteger)maxBatchBytes maxMessageBytes:(NSInteger)maxMessageBytes;
- (void)uploadOpenSessions:(NSMutableArray *)openSessions completionHandler:(void (^)(void))completionHandler;
- (void)backgroundTaskBlock;
- (void)requestConfig:(void(^ _Nullable)(BOOL uploadBatch))completionHandler;
- (MPExecStatus)checkForKitsAndUploadWithCompletionHandler:(void (^ _Nullable)(BOOL didShortCircuit))completionHandler;
- (void)uploadBatchesWithCompletionHandler:(void(^)(BOOL success))completionHandler;
- (NSMutableArray<NSDictionary<NSString *, id> *> *)userIdentitiesForUserId:(NSNumber *)userId;
- (void)cleanUp:(NSTimeInterval)currentTime;
- (void)processDidFinishLaunching:(NSNotification *)notification;

@end

#pragma mark - MPBackendControllerTests unit test class
@interface MPBackendControllerTests : MPBaseTestCase <MPBackendControllerDelegate> {
    dispatch_queue_t messageQueue;
}

@property (nonatomic, strong) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong) MPSession *session;
@property (nonatomic, strong) MPNotificationController_PRIVATE *notificationController;

@end

@implementation MPBackendControllerTests

- (void)setUp {
    [super setUp];
    messageQueue = [MParticle messageQueue];
    
    [MPPersistenceController_PRIVATE setMpid:@1];
    [MParticle sharedInstance].persistenceController = [[MPPersistenceController_PRIVATE alloc] init];
    
    [MParticle sharedInstance].stateMachine.apiKey = @"unit_test_app_key";
    [MParticle sharedInstance].stateMachine.secret = @"unit_test_secret";
    
    [MParticle sharedInstance].kitContainer_PRIVATE = [[MPKitContainer_PRIVATE alloc] init];
    
    [MParticle sharedInstance].backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
    self.backendController = [MParticle sharedInstance].backendController;
    [self notificationController];
}

- (void)tearDown {
    [MParticle sharedInstance].stateMachine.launchInfo = nil;
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

- (MPNotificationController_PRIVATE *)notificationController {
    if (_notificationController) {
        return _notificationController;
    }
    
    _notificationController = [[MPNotificationController_PRIVATE alloc] init];
    
    return _notificationController;
}
#endif

- (void)testBeginSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Begin session test"];
    dispatch_sync(messageQueue, ^{
        [self.backendController beginSession];
        self.session = self.backendController.session;
        MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
        
        NSMutableArray *sessions = [persistence fetchSessions];
        MPSession *session = [sessions lastObject];
        
        XCTAssertEqualObjects(session, self.session, @"Sessions are not equal.");
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
        NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
        NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
        MPMessage *message = [messages lastObject];
        
        XCTAssertEqualObjects(message.messageType, @"ss", @"Message type is not session start.");
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testEndSession {
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"End session test"];
    dispatch_sync(messageQueue, ^{
        [self.backendController beginSession];
        self.session = self.backendController.session;
        NSMutableArray *sessions = [persistence fetchSessions];
        MPSession *session = [sessions lastObject];
        MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
        XCTAssertEqualObjects(session, stateMachine.currentSession, @"Current session and last session in the database are not equal.");
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
        NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
        NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
        NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
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
        sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
        dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
        messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
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
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testAutomaticSessionEnd {
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    MParticle *mParticle = [MParticle sharedInstance];
    id mockBackendController = OCMPartialMock(self.backendController);
    mParticle.backendController = mockBackendController;
    self.backendController = [MParticle sharedInstance].backendController;
    
    dispatch_sync(messageQueue, ^{
        [self.backendController beginSession];
        self.session = self.backendController.session;
        NSMutableArray *sessions = [persistence fetchSessions];
        MPSession *session = [sessions lastObject];
        MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
        XCTAssertEqualObjects(session, stateMachine.currentSession, @"Current session and last session in the database are not equal.");
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
        NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
        NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
        
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
    });
}

- (void)testBackgroundBlock {
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Begin background block test"];
    
    dispatch_sync(messageQueue, ^{
        [self.backendController beginSession];
        self.session = self.backendController.session;
        NSMutableArray *sessions = [persistence fetchSessions];
        MPSession *session = [sessions lastObject];
        MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
        XCTAssertEqualObjects(session, stateMachine.currentSession, @"Current session and last session in the database are not equal.");
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
        NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
        NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
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
        XCTAssertNotNil(self.backendController.session);
        
        MPMessage *message = [persistence fetchSessionEndMessageInSession:session];
        XCTAssertNil(message);
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testSessionStartTimestamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    [self.backendController beginSessionWithIsManual:NO date:date];
    XCTAssertEqual(self.backendController.session.startTime, date.timeIntervalSince1970);
}

- (void)testCheckAttributeValueEmpty {
    NSError *error = nil;
    BOOL success = [MPBackendController_PRIVATE checkAttribute:[NSDictionary dictionary] key:@"foo"
                                                         value:[NSNull null]
                                                         error:&error];
    XCTAssertTrue(success);
    XCTAssertNil(error);
    
    error = nil;
    [MPBackendController_PRIVATE checkAttribute:[NSDictionary dictionary] key:@"foo"
                                          value:@""
                                          error:&error];
    XCTAssertTrue(success);
    XCTAssertNil(error);
}

- (void)testCheckAttributeStringAttribute {
    NSError *error = nil;
    BOOL success = [MPBackendController_PRIVATE checkAttribute:[NSDictionary dictionary] key:@"foo" value:@"bar" error:&error];
    XCTAssert(success);
    XCTAssertNil(error);
}

- (void)testCheckAttributeNumberAttribute {
    NSError *error = nil;
    BOOL success = [MPBackendController_PRIVATE checkAttribute:[NSDictionary dictionary] key:@"foo" value:@123.0 error:&error];
    XCTAssert(success);
    XCTAssertNil(error);
}

- (void)testCheckAttributeArrayAttribute {
    NSError *error = nil;
    NSArray *arrayValue = @[ @"foo", @"bar"];
    BOOL success = [MPBackendController_PRIVATE checkAttribute:[NSDictionary dictionary] key:@"foo" value:arrayValue error:&error];
    XCTAssert(success);
    XCTAssertNil(error);
}

- (void)testCheckAttributeArrayValuesTooLongAttribute {
    NSError *error = nil;
    id mockValue = [OCMockObject mockForClass:[NSString class]];
    OCMStub([mockValue length]).andReturn(LIMIT_ATTR_VALUE_LENGTH);
    NSArray *arrayValue = @[@"foo", mockValue];
    BOOL success = [MPBackendController_PRIVATE checkAttribute:[NSDictionary dictionary] key:@"foo" value:arrayValue error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kExceededAttributeValueMaximumLength, error.code);
}

- (void)testCheckAttributeArrayValueInvalidLongAttribute {
    NSError *error = nil;
    id mockValue = [OCMockObject mockForClass:[NSString class]];
    OCMStub([mockValue length]).andReturn(LIMIT_ATTR_VALUE_LENGTH);
    NSArray *arrayValue = @[@"foo", @10.0];
    BOOL success = [MPBackendController_PRIVATE checkAttribute:[NSDictionary dictionary] key:@"foo" value:arrayValue error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kInvalidDataType, error.code);
}


- (void)testCheckAttributeNoMaximum {
    id mockAttributes = [OCMockObject mockForClass:[NSMutableDictionary class]];
    OCMStub([mockAttributes count]).andReturn(200);
    NSError *error = nil;
    BOOL success = [MPBackendController_PRIVATE checkAttribute:mockAttributes key:@"foo" value:@"bar" error:&error];
    XCTAssertTrue(success);
    XCTAssertNil(error);
}

- (void)testCheckAttributeKeyTooLong {
    id mockKey = [OCMockObject mockForClass:[NSString class]];
    OCMStub([mockKey length]).andReturn(LIMIT_ATTR_KEY_LENGTH+1);
    
    NSError *error = nil;
    BOOL success = [MPBackendController_PRIVATE checkAttribute:[NSDictionary dictionary] key:mockKey value:@"foo" error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kExceededAttributeKeyMaximumLength, error.code);
}

- (void)testCheckAttributeValueTooLong {
    id mockValue = [OCMockObject mockForClass:[NSString class]];
    OCMStub([mockValue length]).andReturn(LIMIT_ATTR_VALUE_LENGTH+1);
    OCMStub([mockValue stringByTrimmingCharactersInSet:OCMOCK_ANY]).andReturn(@"foo");
    NSError *error = nil;
    BOOL success = [MPBackendController_PRIVATE checkAttribute:[NSDictionary dictionary] key:@"foo" value:mockValue error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kExceededAttributeValueMaximumLength, error.code);
}

- (void)testCheckAttributeValueNil {
    NSError *error = nil;
    NSString *nilValue = nil;
    BOOL success = [MPBackendController_PRIVATE checkAttribute:[NSDictionary dictionary] key:@"foo" value:nilValue error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kNilAttributeValue, error.code);
}

- (void)testCheckAttributeKeyNullNil {
    NSError *error = nil;
    NSString *nilKey = (NSString*)[NSNull null];
    BOOL success = [MPBackendController_PRIVATE checkAttribute:[NSDictionary dictionary] key:nilKey value:@"foo" error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kInvalidKey, error.code);
    
    error = nil;
    nilKey = nil;
    success = [MPBackendController_PRIVATE checkAttribute:[NSDictionary dictionary] key:nilKey value:@"foo" error:&error];
    XCTAssertFalse(success);
    XCTAssertNotNil(error);
    XCTAssertEqual(kInvalidKey, error.code);
}

- (void)testBatchCycle {
    [MParticle sharedInstance].dataPlanId = @"test";
    [MParticle sharedInstance].dataPlanVersion = @(1);
    
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPEvent *event = [[MPEvent alloc] initWithName:@"Unit Test Event" type:MPEventTypeOther];
    event.customAttributes = @{@"key":@"value"};
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    [self.backendController logEvent:event
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"test"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:1]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    BOOL eventFound = NO;
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        if ([message.messageType isEqualToString:kMPMessageTypeStringEvent]) {
            eventFound = YES;
        }
    }
    XCTAssertTrue(eventFound, @"Message for logEvent is not being saved.");
    
    
    MPUploadBuilder *uploadBuilder = [[MPUploadBuilder alloc] initWithMpid:[MPPersistenceController_PRIVATE mpId] sessionId:[NSNumber numberWithLong:self->_session.sessionId] messages:messages sessionTimeout:100 uploadInterval:100 dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
    
    [uploadBuilder withUserAttributes:[self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]] deletedUserAttributes:nil];
    [uploadBuilder withUserIdentities:[self.backendController userIdentitiesForUserId:[MPPersistenceController_PRIVATE mpId]]];
    [uploadBuilder build:^(MPUpload *upload) {
        [persistence saveUpload:upload];
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
        NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"test"];
        NSArray *messageArray =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:1]];
        
        XCTAssertNotNil(messageArray, @"There are no messages in session.");
        
        NSArray *uploads = [persistence fetchUploads];
        XCTAssertGreaterThan(uploads.count, 0, @"Messages are not being transfered to the Uploads table.");
        
        for (MPUpload *upload in uploads) {
            [persistence deleteUpload:upload];
        }
        
        uploads = [persistence fetchUploads];
        XCTAssertNil(uploads, @"Uploads are not being deleted.");
    }];
}

- (void)testUploadWithDifferentUser {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    
    //Set up Identity to exist
    [userDefaults setMPObject:[NSDate date] forKey:kMPLastIdentifiedDate userId:@1];
    
    [[MParticle sharedInstance].identity.currentUser setIdentitySync:@"bar-id" identityType:MPIdentityIOSAdvertiserId];
    
    [MParticle sharedInstance].dataPlanId = @"test";
    [MParticle sharedInstance].dataPlanVersion = @(1);
    
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPEvent *event = [[MPEvent alloc] initWithName:@"Unit Test Event" type:MPEventTypeOther];
    event.customAttributes = @{@"key":@"value"};
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    [self.backendController logEvent:event
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"test"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:1]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    BOOL eventFound = NO;
    NSNumber *mpid;
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        if ([message.messageType isEqualToString:kMPMessageTypeStringEvent]) {
            eventFound = YES;
            mpid = message.userId;
        }
    }
    XCTAssertTrue(eventFound, @"Message for logEvent is not being saved.");
    
    [MPPersistenceController_PRIVATE setMpid:@8];
    [userDefaults setMPObject:[NSDate date] forKey:kMPLastIdentifiedDate userId:@8];
    MParticleUser *newUser = [[MParticleUser alloc] init];
    newUser.userId = @8;
    [MParticle sharedInstance].identity.currentUser = newUser;
    XCTAssertEqualObjects([MParticle sharedInstance].identity.currentUser, newUser);
    XCTAssertNil([MParticle sharedInstance].identity.currentUser.identities[@(MPIdentityIOSAdvertiserId)]);
    
    
    MPUploadBuilder *uploadBuilder = [[MPUploadBuilder alloc] initWithMpid:mpid sessionId:[NSNumber numberWithLong:self->_session.sessionId] messages:messages sessionTimeout:100 uploadInterval:100 dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
    
    [uploadBuilder withUserAttributes:[self.backendController userAttributesForUserId:mpid] deletedUserAttributes:nil];
    [uploadBuilder withUserIdentities:[self.backendController userIdentitiesForUserId:mpid]];
    [uploadBuilder build:^(MPUpload *upload) {
        [persistence saveUpload:upload];
        NSDictionary *uploadDictionary = [NSJSONSerialization JSONObjectWithData:upload.uploadData options:0 error:nil];
        XCTAssertEqualObjects(uploadDictionary[kMPDeviceInformationKey][kMPDeviceAdvertiserIdKey], @"bar-id");
    }];
}

- (void)testLoggingCommerceEvent {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionClick];
    commerceEvent.customAttributes = @{@"key":@"value"};
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    [self.backendController logBaseEvent:commerceEvent
                       completionHandler:^(MPBaseEvent *event, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    Boolean testCommerce = false;
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        if ([message.messageType isEqualToString:kMPMessageTypeStringCommerceEvent]) {
            testCommerce = true;
        }
    }
    XCTAssertTrue(testCommerce, @"MPCommerceEvent messages are not being saved.");
}

- (void)testLoggingBaseEvent {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPBaseEvent *event = [[MPBaseEvent alloc] initWithEventType:MPEventTypeOther];
    event.customAttributes = @{@"key":@"value"};
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    [self.backendController logBaseEvent:event
                       completionHandler:^(MPBaseEvent *event, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        XCTAssertTrue(![message.messageType isEqualToString:kMPMessageTypeStringUnknown], @"MPBaseEvent messages are being logged to server.");
    }
}

- (void)testRampUpload {
    [MParticle sharedInstance].dataPlanId = @"test";
    [MParticle sharedInstance].dataPlanVersion = @(1);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ramp upload test"];
    dispatch_async(messageQueue, ^{
        MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
        
        MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                                 session:session
                                                                             messageInfo:@{@"MessageKey1":@"MessageValue1"}];
        MPMessage *message = [messageBuilder build];
        
        MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
        
        [persistence saveMessage:message];
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
        NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"test"];
        NSArray *persistedMessages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:1]];
        MPUploadBuilder *uploadBuilder = [[MPUploadBuilder alloc] initWithMpid:[MPPersistenceController_PRIVATE mpId] sessionId:[NSNumber numberWithLong:self->_session.sessionId] messages:persistedMessages sessionTimeout:100 uploadInterval:100 dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
        XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
        
        if (!uploadBuilder) {
            return;
        }
        
        [uploadBuilder withUserAttributes:[self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]] deletedUserAttributes:nil];
        [uploadBuilder withUserIdentities:[self.backendController userIdentitiesForUserId:[MPPersistenceController_PRIVATE mpId]]];
        [uploadBuilder build:^(MPUpload *upload) {
            [persistence saveUpload:upload];
            
            NSArray *uploads = [persistence fetchUploads];
            XCTAssertGreaterThan(uploads.count, 0, @"Failed to retrieve messages to be uploaded.");
            
            MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
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
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testDidBecomeActiveWithAppLink {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSURL *url = [NSURL URLWithString:@"fb487730798014455://applinks?al_applink_data=%7B%22user_agent%22%3A%22Bolts%20iOS%201.0.0%22%2C%22target_url%22%3A%22http%3A%5C%2F%5C%2Fexample.com%5C%2Fapplinks%22%2C%22extras%22%3A%7B%22myapp_token%22%3A%22t0kEn%22%7D%7D"];
    NSString *sourceApplication = @"com.mParticle.UnitTest";
    NSDictionary *annotation = @{@"foo":@"bar"};
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    [self.backendController handleApplicationDidBecomeActive:nil];
    
    dispatch_sync([MParticle messageQueue], ^{
        NSDictionary *messagesDictionary = [[MParticle sharedInstance].persistenceController fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
        NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
        NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
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
    });
}

- (void)testSetIdentityToNil {
    [[self backendController] setUserIdentity:@"foo" identityType:MPUserIdentityEmail
                                    timestamp:[NSDate date]
                            completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
        
    }];
    NSDictionary *identities = [MParticle sharedInstance].identity.currentUser.identities;
    XCTAssertEqualObjects(@"foo", [identities objectForKey:@(MPUserIdentityEmail)]);
    [[self backendController] setUserIdentity:nil identityType:MPUserIdentityEmail
                                    timestamp:[NSDate date]
                            completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
        
    }];
    
    identities = [MParticle sharedInstance].identity.currentUser.identities;
    XCTAssertNil([identities objectForKey:@(MPUserIdentityEmail)]);
}

- (void)testSetIdentityToNSNull {
    [[self backendController] setUserIdentity:@"foo" identityType:MPUserIdentityEmail
                                    timestamp:[NSDate date]
                            completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
        
    }];
    NSDictionary *identities = [MParticle sharedInstance].identity.currentUser.identities;
    XCTAssertEqualObjects(@"foo", [identities objectForKey:@(MPUserIdentityEmail)]);
    [[self backendController] setUserIdentity:(NSString *)[NSNull null] identityType:MPUserIdentityEmail
                                    timestamp:[NSDate date]
                            completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
        
    }];
    
    identities = [MParticle sharedInstance].identity.currentUser.identities;
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
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSURL *url = [NSURL URLWithString:@"particlebox://unit_test"];
    NSString *sourceApplication = @"com.mParticle.UnitTest";
    NSDictionary *annotation = @{@"key1":@1, @"key2":[NSDate date]};
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    [self.backendController handleApplicationDidBecomeActive:nil];
    
    dispatch_sync([MParticle messageQueue], ^{
        NSDictionary *messagesDictionary = [[MParticle sharedInstance].persistenceController fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
        NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
        NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
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
    });
}

- (void)testPreviousForegroundTime {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSURL *url = [NSURL URLWithString:@"particlebox://unit_test"];
    NSString *sourceApplication = @"com.mParticle.UnitTest";
    NSDictionary *annotation = @{@"key1":@1, @"key2":[NSDate date]};
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    [self.backendController handleApplicationDidBecomeActive:nil];
    [self.backendController handleApplicationDidBecomeActive:nil];
    
    dispatch_sync([MParticle messageQueue], ^{
        NSDictionary *messagesDictionary = [[MParticle sharedInstance].persistenceController fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
        NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
        NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
        XCTAssertEqual(messages.count, 3, @"Launch messages are not being persisted.");
        
        // First event, should be a session start event
        MPMessage *ss = messages[0];
        XCTAssertEqualObjects(ss.messageType, @"ss");
        
        // First AST event, should not have the pft key set since we're just launching the app
        MPMessage *ast1 = messages[1];
        XCTAssertEqualObjects(ast1.messageType, @"ast");
        NSString *ast1String = [[NSString alloc] initWithData:ast1.messageData encoding:NSUTF8StringEncoding];
        NSRange ast1PftRange = [ast1String rangeOfString:@"\"pft\""];
        XCTAssertEqual(ast1PftRange.location, NSNotFound);
        
        // Second AST event, should have the pft key set since we're re-entering the foreground
        MPMessage *ast2 = messages[2];
        XCTAssertEqualObjects(ast2.messageType, @"ast");
        NSString *ast2String = [[NSString alloc] initWithData:ast2.messageData encoding:NSUTF8StringEncoding];
        NSRange ast2PftRange = [ast2String rangeOfString:@"\"pft\""];
        XCTAssertNotEqual(ast2PftRange.location, NSNotFound);
    });
}

- (void)testIsLaunchCheck {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSURL *url = [NSURL URLWithString:@"particlebox://unit_test"];
    NSString *sourceApplication = @"com.mParticle.UnitTest";
    NSDictionary *annotation = @{@"key1":@1, @"key2":[NSDate date]};
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    [self.backendController handleApplicationDidBecomeActive:nil];
    [self.backendController handleApplicationDidBecomeActive:nil];
    
    dispatch_sync([MParticle messageQueue], ^{
        NSDictionary *messagesDictionary = [[MParticle sharedInstance].persistenceController fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
        NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
        NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
        XCTAssertEqual(messages.count, 3, @"Launch messages are not being persisted.");
        
        // First event, should be a session start event
        MPMessage *ss = messages[0];
        XCTAssertEqualObjects(ss.messageType, @"ss");
        
        // First AST event, should have sf key set to true as this is the app launch
        MPMessage *ast1 = messages[1];
        XCTAssertEqualObjects(ast1.messageType, @"ast");
        NSString *ast1String = [[NSString alloc] initWithData:ast1.messageData encoding:NSUTF8StringEncoding];
        NSRange ast1SfTrueRange = [ast1String rangeOfString:@"\"sf\":true"];
        XCTAssertNotEqual(ast1SfTrueRange.location, NSNotFound);
        
        // Second AST event, should have the sf key set to false as this returning from the background
        MPMessage *ast2 = messages[2];
        XCTAssertEqualObjects(ast2.messageType, @"ast");
        NSString *ast2String = [[NSString alloc] initWithData:ast2.messageData encoding:NSUTF8StringEncoding];
        NSRange ast2SfFalseRange = [ast2String rangeOfString:@"\"sf\":false"];
        XCTAssertNotEqual(ast2SfFalseRange.location, NSNotFound);
    });
}

- (void)testSetStringAttribute {
    [self.backendController setUserAttribute:@"foo attribute 1" value:@"foo value 1" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
    NSString *value = attributes[@"foo attribute 1"];
    XCTAssertEqualObjects(value, @"foo value 1");
}

- (void)testSetExistingStringAttribute {
    [self.backendController setUserAttribute:@"foo attribute 1" value:@"foo value 1" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    [self.backendController setUserAttribute:@"foo attribute 1" value:@"foo value 2" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
    NSString *value = attributes[@"foo attribute 1"];
    XCTAssertEqualObjects(value, @"foo value 2");
}

- (void)testSetStringArrayAttribute {
    [self.backendController setUserAttribute:@"foo attribute 1" values:@[@"foo value 1", @"foo value 2"] timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
    NSArray *array = attributes[@"foo attribute 1"];
    NSArray *result = @[@"foo value 1", @"foo value 2"];
    XCTAssertEqualObjects(array, result);
}

- (void)testSetNumberAttribute {
    [self.backendController setUserAttribute:@"foo attribute 2" value:@12.34 timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
    NSNumber *value = attributes[@"foo attribute 2"];
    XCTAssertEqualObjects(value, @12.34);
}

- (void)testSetTooLongAttribute {
    NSMutableString *longValue = [[NSMutableString alloc] initWithCapacity:(LIMIT_ATTR_VALUE_LENGTH + 1)];
    for (int i = 0; i < (LIMIT_ATTR_VALUE_LENGTH + 1); ++i) {
        [longValue appendString:@"T"];
    }
    [self.backendController setUserAttribute:@"foo attribute 2" value:longValue timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
    XCTAssertEqualObjects(attributes, @{});
}

- (void)testSetInvalidDateAttribute {
    NSDate *date = [NSDate date];
    [self.backendController setUserAttribute:@"foo attribute 2" value:date timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
    XCTAssertEqualObjects(attributes, @{});
}

- (void)testSetInvalidNullAttribute {
    NSNull *nullObject = [NSNull null];
    [self.backendController setUserAttribute:@"foo attribute 2" value:nullObject timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
    XCTAssertEqualObjects(attributes, @{});
}

- (void)testIncrementInvalidAttribute {
    [self.backendController setUserAttribute:@"foo attribute 2" value:@"foo value 2" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    [self.backendController incrementUserAttribute:@"foo attribute 2" byValue:@1];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
    NSString *value = attributes[@"foo attribute 2"];
    XCTAssertEqualObjects(value, @"foo value 2");
}

- (void)testRemoveNumberAttribute {
    [self.backendController setUserAttribute:@"foo attribute 2" value:@12.34 timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    [self.backendController removeUserAttribute:@"foo attribute 2" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
    XCTAssertEqualObjects(attributes, @{});
}

- (void)testRemoveStringAttribute {
    [self.backendController setUserAttribute:@"foo attribute 2" value:@"foo value 2" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
    [self.backendController removeUserAttribute:@"foo attribute 2" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
    XCTAssertEqualObjects(attributes, @{});
}

- (void)testSetUserTagFromBackendController {
    XCTestExpectation *expectation = [self expectationWithDescription:@"completion handler"];
    
    [self.backendController setUserTag:@"foo tag 1" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {
        XCTAssertEqual(execStatus, MPExecStatusSuccess);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
    NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
    XCTAssertEqual(attributes.count, 1);
    NSString *value = attributes[@"foo tag 1"];
    XCTAssertEqualObjects(value, [NSNull null]);
}

- (void)testSetUserTagFromUser {
    [[MParticle sharedInstance].identity.currentUser setUserTag:@"foo tag 1"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    
    dispatch_async([MParticle messageQueue], ^{
        NSDictionary *attributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
        XCTAssertEqual(attributes.count, 1);
        NSString *value = attributes[@"foo tag 1"];
        XCTAssertEqualObjects(value, [NSNull null]);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testSetUserAttributeKits {
    if (![MPKitContainer_PRIVATE registeredKits]) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
        [MPKitContainer_PRIVATE registerKit:kitRegister];
        
        kitRegister = [[MPKitRegister alloc] initWithName:@"KitSecondTest" className:@"MPKitSecondTestClass"];
        [MPKitContainer_PRIVATE registerKit:kitRegister];
        
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
        [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:configuration eTag:eTag requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];
    }
    
    [self.backendController setUserAttribute:@"foo attribute 3" value:@"foo value 3" timestamp:[NSDate date] completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
    
    NSDictionary *userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
    XCTAssertEqualObjects(userAttributes, @{@"foo attribute 3":@"foo value 3"});
}

- (void)testUserAttributeChanged {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    [persistence saveSession:self.backendController.session];
    
    [self.backendController setUserAttribute:@"TardisModel" value:@"Police Call Box" timestamp:[NSDate date] completionHandler:nil];
    
    NSDictionary *userAttributes = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]];
    XCTAssertEqualObjects(userAttributes[@"TardisModel"], @"Police Call Box");
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
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
    
    messagesDictionary = [persistence fetchMessagesForUploading];
    sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
    XCTAssertNil(messages);
    
    [self.backendController removeUserAttribute:@"TardisModel" timestamp:[NSDate date] completionHandler:nil];
    
    messagesDictionary = [persistence fetchMessagesForUploading];
    sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
    message = [messages firstObject];
    messageDictionary = [message dictionaryRepresentation];
    XCTAssertEqualObjects(@"uac", messageDictionary[@"dt"]);
    XCTAssertEqualObjects([NSNull null], messageDictionary[@"nv"]);
    XCTAssertEqualObjects(@"Police Call Box", messageDictionary[@"ov"]);
    XCTAssertEqualObjects(@"TardisModel", messageDictionary[@"n"]);
    XCTAssertEqualObjects(@YES, messageDictionary[@"d"]);
}

- (void)testUserAttributeChangedFromIncrement {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    [persistence saveSession:self.backendController.session];
    
    NSString *userAttributeKey = @"Number of time travels";
    NSNumber *userAttributeValue = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]][userAttributeKey];
    XCTAssertNil(userAttributeValue);
    
    userAttributeValue = [self.backendController incrementUserAttribute:userAttributeKey byValue:@1];
    XCTAssertNotNil(userAttributeValue);
    XCTAssertEqualObjects(userAttributeValue, @1);
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
    XCTAssertNotNil(messages);
    XCTAssertEqual(messages.count, 1);
    
    MPMessage *message = [messages firstObject];
    XCTAssertNotNil(message);
    
    NSDictionary *messageDictionary = [message dictionaryRepresentation];
    XCTAssertEqualObjects(@"uac", messageDictionary[@"dt"]);
    XCTAssertEqualObjects([NSNull null], messageDictionary[@"ov"]);
    XCTAssertEqualObjects(@"1", messageDictionary[@"nv"]);
    XCTAssertEqualObjects(@"Number of time travels", messageDictionary[@"n"]);
    XCTAssertEqualObjects(@NO, messageDictionary[@"d"]);
    
    [persistence deleteSession:self.backendController.session];
    
    messagesDictionary = [persistence fetchMessagesForUploading];
    sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
    XCTAssertNil(messages);
    
    userAttributeValue = [self.backendController incrementUserAttribute:userAttributeKey byValue:@2];
    XCTAssertNotNil(userAttributeValue);
    XCTAssertEqualObjects(userAttributeValue, @3);
    
    messagesDictionary = [persistence fetchMessagesForUploading];
    sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
    message = [messages firstObject];
    messageDictionary = [message dictionaryRepresentation];
    XCTAssertEqualObjects(@"uac", messageDictionary[@"dt"]);
    XCTAssertEqualObjects(@1, messageDictionary[@"ov"]);
    XCTAssertEqualObjects(@"3", messageDictionary[@"nv"]);
    XCTAssertEqualObjects(@"Number of time travels", messageDictionary[@"n"]);
    XCTAssertEqualObjects(@NO, messageDictionary[@"d"]);
}

- (void)testUserIdentityChanged {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    XCTestExpectation *expectation = [self expectationWithDescription:@"User identity changed"];
    __weak MPBackendControllerTests *weakSelf = self;
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    [persistence saveSession:weakSelf.session];
    
    [weakSelf.backendController setUserIdentity:@"The Most Interesting Man in the World" identityType:MPUserIdentityCustomerId timestamp:[NSDate date] completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
    }];
    
    __block NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF[%@] == %@", @"n", @(MPUserIdentityCustomerId)];
    __block NSDictionary *userIdentity = [[[self.backendController userIdentitiesForUserId:[MPPersistenceController_PRIVATE mpId]] filteredArrayUsingPredicate:predicate] lastObject];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqualObjects(userIdentity[@"i"], @"The Most Interesting Man in the World");
    XCTAssertEqualObjects(userIdentity[@"n"], @(MPUserIdentityCustomerId));
    
    __block NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    __block NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    __block NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    __block NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    __block NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
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
        
        messagesDictionary = [persistence fetchMessagesForUploading];
        sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
        dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
        messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
        
        XCTAssertEqual(messages.count, 1);
    });
    
    [weakSelf.backendController setUserIdentity:nil identityType:MPUserIdentityCustomerId timestamp:[NSDate date] completionHandler:^(NSString * _Nullable identityString, MPUserIdentity identityType, MPExecStatus execStatus) {
        userIdentity = [[[weakSelf.backendController userIdentitiesForUserId:[MPPersistenceController_PRIVATE mpId]] filteredArrayUsingPredicate:predicate] lastObject];
        XCTAssertNil(userIdentity);
        
        messagesDictionary = [persistence fetchMessagesForUploading];
        sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
        dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
        dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
        messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
        
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
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testIncrementUserAttribute {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Increment user attribute"];
    dispatch_sync(messageQueue, ^{
        NSString *userAttributeKey = @"Number of time travels";
        NSNumber *userAttributeValue = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]][userAttributeKey];
        XCTAssertNil(userAttributeValue);
        
        userAttributeValue = [self.backendController incrementUserAttribute:userAttributeKey byValue:@1];
        XCTAssertNotNil(userAttributeValue);
        XCTAssertEqualObjects(userAttributeValue, @1);
        
        userAttributeValue = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]][userAttributeKey];
        XCTAssertNotNil(userAttributeValue);
        XCTAssertEqualObjects(userAttributeValue, @1);
        
        [self.backendController removeUserAttribute:userAttributeKey timestamp:[NSDate date] completionHandler:nil];
        userAttributeValue = [self.backendController userAttributesForUserId:[MPPersistenceController_PRIVATE mpId]][userAttributeKey];
        XCTAssertNil(userAttributeValue);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testSetLocation {
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    CLLocation *location = [[CLLocation alloc] initWithLatitude:40.738526 longitude:-73.98738];
    [MParticle sharedInstance].stateMachine.location = location;
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Unit Test Event" type:MPEventTypeOther];
    event.shouldBeginSession = NO;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Set location"];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    [self.backendController logEvent:event
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    MPMessage *message = messages.lastObject;
    NSString *messageString = [[NSString alloc] initWithData:message.messageData encoding:NSUTF8StringEncoding];
    NSRange range = [messageString rangeOfString:@"\"lat\":40.738526"];
    XCTAssertNotEqual(range.location, NSNotFound);
    range = [messageString rangeOfString:@"\"lng\":-73.98738"];
    XCTAssertNotEqual(range.location, NSNotFound);
    
    [persistence deleteMessages:messages];
    
    [expectation fulfill];
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
#endif
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
}

- (void)testMessageWithOptOut {
    [MPPersistenceController_PRIVATE setMpid:@2];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    [MParticle sharedInstance].stateMachine.optOut = YES;
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    [[MParticle sharedInstance].backendController saveMessage:message updateSession:NO];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSArray<MPMessage *> *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
    
    XCTAssertEqual(messages.count, 0, @"No Messages should be saved.");
}

- (void)testMessageWithOptOutMessage {
    [MPPersistenceController_PRIVATE setMpid:@2];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    [MParticle sharedInstance].stateMachine.optOut = YES;
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeOptOut session:session messageInfo:@{kMPOptOutStatus:(@"true")}];
    
    MPMessage *message = [messageBuilder build];
    [[MParticle sharedInstance].backendController saveMessage:message updateSession:NO];
    
    XCTAssertTrue(message.messageId > 0, @"Message id not greater than zero: %lld", message.messageId);
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSArray<MPMessage *> *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
    
    XCTAssertEqual(messages.count, 1, @"The Opt Out Message wasn't saved.");
}

- (void)testBatchAndMessageLimitsMessagesPerBatch {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    NSMutableArray *unlimitedMessages = [NSMutableArray array];
    for (int i=0; i<10; i++) {
        MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
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
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    NSMutableArray *unlimitedMessages = [NSMutableArray array];
    for (int i=0; i<10; i++) {
        MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
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
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
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
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    NSString *longString = @"a";
    while (longString.length < 1000) {
        longString = [NSString stringWithFormat:@"%@%@", longString, longString];
    }
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
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

- (MPMessage *)messageWithType:(MPMessageType)type andLength:(NSInteger)length {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    NSString *longString = @"a";
    while (longString.length < length) {
        longString = [NSString stringWithFormat:@"%@%@", longString, longString];
    }
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:type
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":longString}];
    MPMessage *message = [messageBuilder build];
    NSInteger bytesToTruncate = message.messageData.length - length;
    NSInteger bytesLongString = longString.length - bytesToTruncate;
    longString = [longString substringToIndex:bytesLongString];
    
    // NOTE: Previously we used the MPMessageBuilder to build a new message after truncating longString to
    //       the correct length. However, the other data included in the message is not deterministic
    //       as it includes things like CPU and memory usage which fluctuate. This could cause cases
    //       where the final message was larger than expected if any of those other values became longer
    //       (e.g. 9% CPU usage went to 10% CPU usage, adding another byte to the JSON).
    //
    //       To keep things deterministic, we are now directly modifying the contents of the original message
    //       data instead, as that ensures that the final message data size is the size we intended.
    
    NSError *error = nil;
    NSMutableDictionary *dict = [[NSJSONSerialization JSONObjectWithData:message.messageData options:0 error:&error] mutableCopy];
    XCTAssertNil(error, "JSON deserialization failed, error: %@", error);
    XCTAssertNotNil(dict, "messageData dict must not be nil");
    
    dict[@"MessageKey1"] = longString;
    error = nil;
    message.messageData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    XCTAssertNil(error, "JSON serialization failed, error: %@", error);
    XCTAssertNotNil(message.messageData, "messageData must not be nil");
    return message;
}

- (void)testEventBatchAndMessageByteLimits {
    NSInteger maxMessageBytes = 100*1024;
    MPMessage *message = [self messageWithType:MPMessageTypeEvent andLength:maxMessageBytes];
    
    NSMutableArray *unlimitedMessages = [NSMutableArray array];
    for (int i=0; i<9; i++) {
        [unlimitedMessages addObject:message];
    }
    
    NSArray *batchArrays = [self.backendController batchMessageArraysFromMessageArray:unlimitedMessages
                                                                     maxBatchMessages:NSIntegerMax
                                                                        maxBatchBytes:(200*1024)
                                                                      maxMessageBytes:(100*1024)];
    XCTAssertEqual(batchArrays.count, 5);
    for (int i=0; i<batchArrays.count; i++) {
        NSArray *batchMessages = batchArrays[i];
        if (i+1<batchArrays.count) {
            XCTAssertEqual(batchMessages.count, 2);
        } else {
            XCTAssertEqual(batchMessages.count, 1);
        }
    }
}

- (void)testCrashReportBatchAndMessageByteLimits {
    NSInteger maxMessageBytes = 1000*1024;
    MPMessage *message = [self messageWithType:MPMessageTypeCrashReport andLength:maxMessageBytes];
    
    NSMutableArray *unlimitedMessages = [NSMutableArray array];
    for (int i=0; i<9; i++) {
        [unlimitedMessages addObject:message];
    }
    
    NSArray *batchArrays = [self.backendController batchMessageArraysFromMessageArray:unlimitedMessages
                                                                     maxBatchMessages:NSIntegerMax
                                                                        maxBatchBytes:(200*1024)
                                                                      maxMessageBytes:(100*1024)];
    XCTAssertEqual(batchArrays.count, 5);
    for (int i=0; i<batchArrays.count; i++) {
        NSArray *batchMessages = batchArrays[i];
        if (i+1<batchArrays.count) {
            XCTAssertEqual(batchMessages.count, 2);
        } else {
            XCTAssertEqual(batchMessages.count, 1);
        }
    }
}

- (void)testCrashReportExceedsBatchMessageByteLimits {
    NSInteger maxMessageBytes = 1000*1024 + 1;
    MPMessage *message = [self messageWithType:MPMessageTypeCrashReport andLength:maxMessageBytes];
    
    NSMutableArray *unlimitedMessages = [NSMutableArray array];
    for (int i=0; i<10; i++) {
        [unlimitedMessages addObject:message];
    }
    
    NSArray *batchArrays = [self.backendController batchMessageArraysFromMessageArray:unlimitedMessages
                                                                     maxBatchMessages:NSIntegerMax
                                                                        maxBatchBytes:(200*1024)
                                                                      maxMessageBytes:(100*1024)];
    XCTAssertEqual(batchArrays.count, 0);
}

- (void)testMixedBatchAndMessageByteLimits {
    NSInteger maxEventMessageBytes = 100*1024;
    NSInteger maxCrashMessageBytes = 1000*1024;
    MPMessage *eventMessage = [self messageWithType:MPMessageTypeEvent andLength:maxEventMessageBytes];
    MPMessage *crashMessage = [self messageWithType:MPMessageTypeCrashReport andLength:maxCrashMessageBytes];
    
    NSMutableArray *unlimitedMessages = [NSMutableArray array];
    for (int i=0; i<3; i++) {
        [unlimitedMessages addObject:eventMessage];
        [unlimitedMessages addObject:crashMessage];
    }
    [unlimitedMessages addObject:eventMessage];
    
    NSArray *batchArrays = [self.backendController batchMessageArraysFromMessageArray:unlimitedMessages
                                                                     maxBatchMessages:NSIntegerMax
                                                                        maxBatchBytes:(2 * maxEventMessageBytes)
                                                                      maxMessageBytes:maxEventMessageBytes];
    XCTAssertEqual(batchArrays.count, 4);
    for (int i=0; i<batchArrays.count; i++) {
        NSArray *batchMessages = batchArrays[i];
        if (i+1<batchArrays.count) {
            XCTAssertEqual(batchMessages.count, 2);
        } else {
            XCTAssertEqual(batchMessages.count, 1);
        }
    }
}

- (void)testNoUploadOrRetryIfConfigFails {
    id mockBackendController = OCMPartialMock(self.backendController);
    [[mockBackendController reject] uploadBatchesWithCompletionHandler:[OCMArg any]];
    
    [OCMStub([mockBackendController requestConfig:[OCMArg any]]) andDo:^(NSInvocation *invocation) {
        void (^handler)(BOOL uploadBatch);
        [invocation getArgument:&handler atIndex:2];
        handler(NO);
    }];
    
    [mockBackendController checkForKitsAndUploadWithCompletionHandler:^(BOOL didShortCircuit) {
        XCTAssertFalse(didShortCircuit);
    }];
    
    [mockBackendController verifyWithDelay:5.0];
}

#if TARGET_OS_IOS == 1
- (void)testHandleDeviceTokenNotification {
    id mockBackendController = OCMPartialMock(self.backendController);
    
    NSData *testDeviceToken = [@"<000000000000000000000000000000>" dataUsingEncoding:NSUTF8StringEncoding];
    
    [[mockBackendController expect] saveMessage:[OCMArg checkWithBlock:^BOOL(id value) {
        XCTAssert([value isKindOfClass:[MPMessage class]]);
        MPMessage *returnedMessage = ((MPMessage *)value);
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:returnedMessage.messageData options:0 error:nil];
        XCTAssertEqualObjects(dic[@"to"], [MPUserDefaults stringFromDeviceToken:testDeviceToken]);
        
        return YES;
    }] updateSession:YES];
    
    NSNotification *testNotification = [[NSNotification alloc] initWithName:@"tester" object:self userInfo:@{@"foo-notif-key-1":@"foo-notif-value-1", kMPRemoteNotificationDeviceTokenKey:testDeviceToken}];
    
    [mockBackendController handleDeviceTokenNotification:testNotification];
    
    [mockBackendController verifyWithDelay:5.0];
}
#endif

#pragma mark Error, Exception, and Crash Handling Tests

- (void)testLogCrash {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    
    NSString *message = @"crash report";
    NSString *stackTrace = @"stack track from crash report";
    NSString *plCrashReport = @"plcrash report test string";
    NSData *data = [plCrashReport dataUsingEncoding:NSUTF8StringEncoding];
    NSString *plCrashReportBase64 = [data base64EncodedStringWithOptions:0];
    [self.backendController logCrash:message
                          stackTrace:stackTrace
                       plCrashReport:plCrashReport
                   completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:@0]; // no crash session to recover so sessionId = 0
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    Boolean crashReport = false;
    NSDictionary *messageDictionary = nil;
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        if ([message.messageType isEqualToString:kMPMessageTypeStringCrashReport]) {
            crashReport = true;
            messageDictionary = [NSJSONSerialization JSONObjectWithData:message.messageData options:0 error:nil];
        }
    }
    XCTAssertTrue(crashReport, @"MPCrashReport messages are not being saved.");
    XCTAssertTrue([messageDictionary[kMPCrashingSeverity] isEqualToString:@"fatal"], @"Crashing severity is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPCrashWasHandled] isEqualToString:@"false"], @"Crash was handled is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPErrorMessage] isEqualToString:message], @"Error message is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPStackTrace] isEqualToString:stackTrace], @"Stack trace is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPPLCrashReport] isEqualToString:plCrashReportBase64], @"PLCrashReport is not being persisted correctly for crash report.");
}

- (void)testLogCrashNilMessage {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    
    NSString *message = nil;
    NSString *stackTrace = @"stack track from crash report";
    NSString *plCrashReport = @"plcrash report test string";
    NSData *data = [plCrashReport dataUsingEncoding:NSUTF8StringEncoding];
    NSString *plCrashReportBase64 = [data base64EncodedStringWithOptions:0];
    [self.backendController logCrash:message
                          stackTrace:stackTrace
                       plCrashReport:plCrashReport
                   completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:@0]; // no crash session to recover so sessionId = 0
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    Boolean crashReport = false;
    NSDictionary *messageDictionary = nil;
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        if ([message.messageType isEqualToString:kMPMessageTypeStringCrashReport]) {
            crashReport = true;
            messageDictionary = [NSJSONSerialization JSONObjectWithData:message.messageData options:0 error:nil];
        }
    }
    XCTAssertTrue(crashReport, @"MPCrashReport messages are not being saved.");
    XCTAssertTrue([messageDictionary[kMPCrashingSeverity] isEqualToString:@"fatal"], @"Crashing severity is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPCrashWasHandled] isEqualToString:@"false"], @"Crash was handled is not being persisted correctly for crash report.");
    XCTAssertNil([messageDictionary objectForKey:kMPErrorMessage], @"Nil error message is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPStackTrace] isEqualToString:stackTrace], @"Stack trace is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPPLCrashReport] isEqualToString:plCrashReportBase64], @"PLCrashReport is not being persisted correctly for crash report.");
}

- (void)testLogCrashNilStackTrace {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    
    NSString *message = @"crash report";
    NSString *stackTrace = nil;
    NSString *plCrashReport = @"plcrash report test string";
    NSData *data = [plCrashReport dataUsingEncoding:NSUTF8StringEncoding];
    NSString *plCrashReportBase64 = [data base64EncodedStringWithOptions:0];
    [self.backendController logCrash:message
                          stackTrace:stackTrace
                       plCrashReport:plCrashReport
                   completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:@0]; // no crash session to recover so sessionId = 0
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    Boolean crashReport = false;
    NSDictionary *messageDictionary = nil;
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        if ([message.messageType isEqualToString:kMPMessageTypeStringCrashReport]) {
            crashReport = true;
            messageDictionary = [NSJSONSerialization JSONObjectWithData:message.messageData options:0 error:nil];
        }
    }
    XCTAssertTrue(crashReport, @"MPCrashReport messages are not being saved.");
    XCTAssertTrue([messageDictionary[kMPCrashingSeverity] isEqualToString:@"fatal"], @"Crashing severity is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPCrashWasHandled] isEqualToString:@"false"], @"Crash was handled is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPErrorMessage] isEqualToString:message], @"Error message is not being persisted correctly for crash report.");
    XCTAssertNil([messageDictionary objectForKey:kMPStackTrace], @"Nil stack trace is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPPLCrashReport] isEqualToString:plCrashReportBase64], @"PLCrashReport is not being persisted correctly for crash report.");
}

- (void)testLogCrashNilPlCrashReport {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    NSString *message = @"crash report";
    NSString *stackTrace = @"stack track from crash report";
    NSString *plCrashReport = nil;
    [self.backendController logCrash:message
                          stackTrace:stackTrace
                       plCrashReport:plCrashReport
                   completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:@0]; // no crash session to recover so sessionId = 0
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    Boolean crashReport = false;
    NSDictionary *messageDictionary = nil;
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        if ([message.messageType isEqualToString:kMPMessageTypeStringCrashReport]) {
            crashReport = true;
            messageDictionary = [NSJSONSerialization JSONObjectWithData:message.messageData options:0 error:nil];
        }
    }
    XCTAssertTrue(crashReport, @"MPCrashReport messages are not being saved.");
    XCTAssertTrue([messageDictionary[kMPCrashingSeverity] isEqualToString:@"fatal"], @"Crashing severity is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPCrashWasHandled] isEqualToString:@"false"], @"Crash was handled is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPErrorMessage] isEqualToString:message], @"Error message is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPStackTrace] isEqualToString:stackTrace], @"Stack trace is not being persisted correctly for crash report.");
    XCTAssertNil([messageDictionary objectForKey:kMPPLCrashReport], @"Nil PLCrashReport is not being persisted correctly for crash report.");
}

- (void)testLogCrashTruncatePlCrashReport {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    NSString *message = @"crash report";
    NSString *stackTrace = @"stack track from crash report";
    NSString *plCrashReport = @"a";
    while (plCrashReport.length < [MPPersistenceController_PRIVATE maxBytesPerEvent:kMPMessageTypeStringCrashReport]) {
        plCrashReport = [NSString stringWithFormat:@"%@%@", plCrashReport, plCrashReport];
    }
    
    [self.backendController logCrash:message
                          stackTrace:stackTrace
                       plCrashReport:plCrashReport
                   completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:@0]; // no crash session to recover so sessionId = 0
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    Boolean crashReport = false;
    NSData *messageData = nil;
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        if ([message.messageType isEqualToString:kMPMessageTypeStringCrashReport]) {
            crashReport = true;
            messageData = message.messageData;
        }
    }
    XCTAssertTrue(crashReport, @"MPCrashReport messages are not being saved.");
    XCTAssertEqual(messageData.length, 1024000, @"Message data was not truncated to MAX_BYTES_PER_EVENT_CRASH");
}


- (void)testLogCrashTruncatePlCrashReportField {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    
    NSString *message = @"crash report";
    NSString *stackTrace = @"stack track from crash report";
    NSString *plCrashReport = @"plcrash report test string";
    MPStateMachine_PRIVATE *stateMachine = [[MPStateMachine_PRIVATE alloc] init];
    id mockStateMachine = OCMPartialMock(stateMachine);
    
    [[[mockStateMachine stub] andReturnValue:OCMOCK_VALUE(@7)] crashMaxPLReportLength];
    
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockStateMachine] stateMachine];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    NSString *expectedResult = @"plcrash";
    NSData *data = [NSData dataWithBytes:expectedResult.UTF8String length:expectedResult.length];
    NSString *plCrashReportBase64 = [data base64EncodedStringWithOptions:0];
    [self.backendController logCrash:message
                          stackTrace:stackTrace
                       plCrashReport:plCrashReport
                   completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:@0]; // no crash session to recover so sessionId = 0
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    Boolean crashReport = false;
    NSDictionary *messageDictionary = nil;
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        if ([message.messageType isEqualToString:kMPMessageTypeStringCrashReport]) {
            crashReport = true;
            messageDictionary = [NSJSONSerialization JSONObjectWithData:message.messageData options:0 error:nil];
        }
    }
    XCTAssertTrue(crashReport, @"MPCrashReport messages are not being saved.");
    XCTAssertTrue([messageDictionary[kMPCrashingSeverity] isEqualToString:@"fatal"], @"Crashing severity is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPCrashWasHandled] isEqualToString:@"false"], @"Crash was handled is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPErrorMessage] isEqualToString:message], @"Error message is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPStackTrace] isEqualToString:stackTrace], @"Stack trace is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPPLCrashReport] isEqualToString:plCrashReportBase64], @"PLCrashReport is not being persisted correctly for crash report.");
}

- (void)testLogCrashTruncatePlCrashReportFieldNil {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    
    NSString *message = @"crash report";
    NSString *stackTrace = @"stack track from crash report";
    NSString *plCrashReport = @"plcrash report test string";
    MPStateMachine_PRIVATE *stateMachine = [[MPStateMachine_PRIVATE alloc] init];
    id mockStateMachine = OCMPartialMock(stateMachine);
    
    [[[(id)mockStateMachine stub] andReturn:nil] crashMaxPLReportLength];
    
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockStateMachine] stateMachine];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    NSData *data = [NSData dataWithBytes:plCrashReport.UTF8String length:plCrashReport.length];
    NSString *plCrashReportBase64 = [data base64EncodedStringWithOptions:0];
    [self.backendController logCrash:message
                          stackTrace:stackTrace
                       plCrashReport:plCrashReport
                   completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:@0]; // no crash session to recover so sessionId = 0
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    Boolean crashReport = false;
    NSDictionary *messageDictionary = nil;
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        if ([message.messageType isEqualToString:kMPMessageTypeStringCrashReport]) {
            crashReport = true;
            messageDictionary = [NSJSONSerialization JSONObjectWithData:message.messageData options:0 error:nil];
        }
    }
    XCTAssertTrue(crashReport, @"MPCrashReport messages are not being saved.");
    XCTAssertTrue([messageDictionary[kMPCrashingSeverity] isEqualToString:@"fatal"], @"Crashing severity is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPCrashWasHandled] isEqualToString:@"false"], @"Crash was handled is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPErrorMessage] isEqualToString:message], @"Error message is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPStackTrace] isEqualToString:stackTrace], @"Stack trace is not being persisted correctly for crash report.");
    XCTAssertTrue([messageDictionary[kMPPLCrashReport] isEqualToString:plCrashReportBase64], @"PLCrashReport is not being persisted correctly for crash report.");
}

- (void)testUserIdentitiesForUserIdNoInvalidIdTypes {
    NSDictionary *validUserId = @{
        @"n":@7,
        @"i":@"trex@shortarmsdinosaurs.com",
        @"dfs":MPCurrentEpochInMilliseconds,
        @"f":@NO
    };
    
    NSArray *userIdentities = @[validUserId];
    
    MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    [userDefaults setMPObject:userIdentities forKey:kMPUserIdentityArrayKey userId:currentUser.userId];
    
    NSArray *currentUserIdentities = [[[MParticle sharedInstance] backendController] userIdentitiesForUserId:currentUser.userId];
    XCTAssertEqual(currentUserIdentities.count, 1);
    XCTAssertEqualObjects(currentUserIdentities[0], validUserId);
}

- (void)testUserIdentitiesForUserIdOneInvalidIdType {
    NSDictionary *validUserId = @{
        @"n":@7,
        @"i":@"trex@shortarmsdinosaurs.com",
        @"dfs":MPCurrentEpochInMilliseconds,
        @"f":@NO
    };
    
    NSDictionary *invalidUserId = @{
        @"n":@22,
        @"i":@"C56A4180-65AA-42EC-A945-5FD21DEC0538"
    };
    
    NSArray *userIdentities = @[validUserId, invalidUserId];
    
    MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    [userDefaults setMPObject:userIdentities forKey:kMPUserIdentityArrayKey userId:currentUser.userId];
    
    NSArray *currentUserIdentities = [[[MParticle sharedInstance] backendController] userIdentitiesForUserId:currentUser.userId];
    XCTAssertEqual(currentUserIdentities.count, 1);
    XCTAssertEqualObjects(currentUserIdentities[0], validUserId);
}

- (void)testUserIdentitiesForUserIdMultipleInvalidIdTypes {
    NSDictionary *validUserId = @{
        @"n":@7,
        @"i":@"trex@shortarmsdinosaurs.com",
        @"dfs":MPCurrentEpochInMilliseconds,
        @"f":@NO
    };
    
    NSDictionary *invalidUserId = @{
        @"n":@22,
        @"i":@"C56A4180-65AA-42EC-A945-5FD21DEC0538"
    };
    
    NSDictionary *invalidUserId2 = @{
        @"n":@24,
        @"i":@"test token"
    };
    
    NSArray *userIdentities = @[validUserId, invalidUserId, invalidUserId2];
    
    MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    [userDefaults setMPObject:userIdentities forKey:kMPUserIdentityArrayKey userId:currentUser.userId];
    
    NSArray *currentUserIdentities = [[[MParticle sharedInstance] backendController] userIdentitiesForUserId:currentUser.userId];
    XCTAssertEqual(currentUserIdentities.count, 1);
    XCTAssertEqualObjects(currentUserIdentities[0], validUserId);
}

- (void)testPersistanceMaxAgeCleanup {
    NSTimeInterval maxAge = 24 * 60 * 60; // 24 hours
    
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [[MParticleOptions alloc] init];
    options.persistenceMaxAgeSeconds = @(maxAge); // 24 hours
    instance.options = options;
    
    MPBackendController_PRIVATE *backendController = [[MPBackendController_PRIVATE alloc] init];
    MPPersistenceController_PRIVATE *persistenceController = [[MPPersistenceController_PRIVATE alloc] init];
    id mockPersistenceController = OCMPartialMock(persistenceController);
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    [[mockPersistenceController expect] deleteRecordsOlderThan:(currentTime - maxAge)];
    
    instance.backendController = backendController;
    instance.persistenceController = mockPersistenceController;
    
    [instance.backendController cleanUp:currentTime];
    
    [mockPersistenceController verifyWithDelay:1.0];
}

- (void)testProcessDidFinishLaunchingWhenNilWebpageURL {
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [[MParticleOptions alloc] init];
    instance.options = options;
    
    MPBackendController_PRIVATE *backendController = [[MPBackendController_PRIVATE alloc] init];
    instance.backendController = backendController;
    
    NSMutableDictionary *testUserInfo = [[NSMutableDictionary alloc] init];
    testUserInfo[@"example"] = @"test";
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:@"test"];
    //leave webpageURL nil
    testUserInfo[UIApplicationLaunchOptionsUserActivityDictionaryKey] = @{@"UIApplicationLaunchOptionsUserActivityKey": userActivity};
    
    NSNotification *testNotification = [[NSNotification alloc] initWithName:@"testNotification" object:nil userInfo:testUserInfo.mutableCopy];
    
    [backendController processDidFinishLaunching:testNotification];
    
    XCTAssertNil(instance.stateMachine.launchInfo.sourceApplication);
    XCTAssertNil(instance.stateMachine.launchInfo.annotation);
    XCTAssertNil(instance.stateMachine.launchInfo.url);
}

- (void)testProcessDidFinishLaunchingWithWebpageURL  {
    MParticle *instance = [MParticle sharedInstance];
    MParticleOptions *options = [[MParticleOptions alloc] init];
    instance.options = options;
    
    MPBackendController_PRIVATE *backendController = [[MPBackendController_PRIVATE alloc] init];
    instance.backendController = backendController;
    
    NSMutableDictionary *testUserInfo = [[NSMutableDictionary alloc] init];
    testUserInfo[@"example"] = @"test";
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:@"test"];
    NSURL *testURL = [NSURL URLWithString:@"http://www.example.com"];
    if (testURL) {
        userActivity.webpageURL = testURL;
    }
    testUserInfo[UIApplicationLaunchOptionsUserActivityDictionaryKey] = @{@"UIApplicationLaunchOptionsUserActivityKey": userActivity};

    NSNotification *testNotification = [[NSNotification alloc] initWithName:@"testNotification" object:nil userInfo:testUserInfo.mutableCopy];
    
    [backendController processDidFinishLaunching:testNotification];
    
    XCTAssertNil(instance.stateMachine.launchInfo.sourceApplication);
    XCTAssertNil(instance.stateMachine.launchInfo.annotation);
    XCTAssertEqual(instance.stateMachine.launchInfo.url, testURL);
}

@end

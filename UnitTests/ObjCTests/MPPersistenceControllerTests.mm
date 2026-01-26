#import <XCTest/XCTest.h>
#import "MPPersistenceController.h"
#import "MPSession.h"
#import "MPMessage.h"
#import "MPUpload.h"
#import "MPAudience.h"
#import "MPIConstants.h"
#import "MPMessageBuilder.h"
#import "MPIntegrationAttributes.h"
#import "MPConsumerInfo.h"
#import "MPForwardRecord.h"
#import "MPKitExecStatus.h"
#import "mParticle.h"
#import "MPUploadBuilder.h"
#import "MPDatabaseMigrationController.h"
#import <sqlite3.h>
#import "MPBaseTestCase.h"
#import "MPStateMachine.h"
#import "MPKitFilter.h"
#import "MParticleSwift.h"

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;

@end

@interface MPForwardRecord ()
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus stateFlag:(BOOL)stateFlag;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus kitFilter:(nullable MPKitFilter *)kitFilter originalEvent:(nullable MPBaseEvent *)originalEvent;
- (nullable NSData *)dataRepresentation;
- (nonnull instancetype)initWithMessageType:(MPMessageType)messageType execStatus:(nonnull MPKitExecStatus *)execStatus;
@end


@interface MPPersistenceControllerTests : MPBaseTestCase

@end

@implementation MPPersistenceControllerTests

- (void)setUp {
    [super setUp];
    
    // Ensure documents directory exists (may not exist on tvOS simulators)
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    
    [MParticle sharedInstance].persistenceController = [[MPPersistenceController_PRIVATE alloc] init];
    MPStateMachine_PRIVATE *stateMachine = [[MPStateMachine_PRIVATE alloc] init];
    stateMachine.apiKey = @"test_key";
    stateMachine.secret = @"test_secret";
    [MParticle sharedInstance].stateMachine = stateMachine;
}

- (void)testMultiThreadedAccess {
    NSDate *startDate = [NSDate date];
    NSDate *endDate = [startDate dateByAddingTimeInterval:0.1];
    dispatch_block_t workBlock = ^{
        while (-[[NSDate date] timeIntervalSinceDate:endDate] > 0) {
            MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
            
            MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
            [persistence saveSession:session];
            NSMutableArray<MPSession *> *sessions = [persistence fetchSessions];
            [persistence deleteSession:session];
            sessions = [persistence fetchSessions];
        }
    };
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    dispatch_async([MParticle messageQueue], ^{
        workBlock();
        [expectation fulfill];
    });
    workBlock();
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testMigrateMessagesWithNullSessions {
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:nil
                                                                         messageInfo:messageInfo];
    
    [persistence saveMessage:[messageBuilder build]];
    MPDatabaseMigrationController *migrationController = [[MPDatabaseMigrationController alloc] initWithDatabaseVersions:@[@30, @31]];
    [migrationController migrateDatabaseFromVersion:@30];
}

- (void)testMigrateUploadsWithNullSessions {
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:nil
                                                                         messageInfo:messageInfo];
    
    MPUploadBuilder *uploadBuilder = [[MPUploadBuilder alloc] initWithMpid:@123 sessionId:nil messages:@[[messageBuilder build]] sessionTimeout:100 uploadInterval:100 dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    __block BOOL tested = NO;
    [uploadBuilder build:^(MPUpload * _Nullable upload) {
        [persistence saveUpload:upload];
        MPDatabaseMigrationController *migrationController = [[MPDatabaseMigrationController alloc] initWithDatabaseVersions:@[@30, @31]];
        [migrationController migrateDatabaseFromVersion:@30];
        tested = YES;
    }];
    XCTAssertTrue(tested);
}

- (void)testMigrateMessagesWithSessions {
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:@123];
    session.sessionId = 11;
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:messageInfo];
    
    [persistence saveMessage:[messageBuilder build]];
    MPDatabaseMigrationController *migrationController = [[MPDatabaseMigrationController alloc] initWithDatabaseVersions:@[@30, @31]];
    [migrationController migrateDatabaseFromVersion:@30 deleteDbFile:NO];
    [persistence openDatabase];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[@123];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];

    XCTAssertNotNil(messages);
}

- (void)testMigrateUploadsWithSessions {
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:@123];
    session.sessionId = 11;
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:messageInfo];
    
    MPUploadBuilder *uploadBuilder = [[MPUploadBuilder alloc] initWithMpid:@123 sessionId:@11 messages:@[[messageBuilder build]] sessionTimeout:100 uploadInterval:100 dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    __block BOOL tested = NO;
    [uploadBuilder build:^(MPUpload * _Nullable upload) {
        [persistence saveUpload:upload];
        MPDatabaseMigrationController *migrationController = [[MPDatabaseMigrationController alloc] initWithDatabaseVersions:@[@30, @31]];
        [migrationController migrateDatabaseFromVersion:@30 deleteDbFile:NO];
        tested = YES;
    }];
    XCTAssertTrue(tested);
    [persistence openDatabase];
    BOOL found = NO;
    NSArray *uploads = [persistence fetchUploads];
    for (int i = 0; i < uploads.count; i += 1) {
        MPUpload *upload = uploads[i];
        if (upload.sessionId && [upload.sessionId isEqual:@11]) {
            found = YES;
            break;
        }
    }
    XCTAssert(found);
}

- (void)testSession {
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    session.attributesDictionary = [@{@"key1":@"value1"} mutableCopy];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    [persistence saveSession:session];
    
    XCTAssertTrue(session.sessionId > 0, @"Session id not greater than zero: %lld", session.sessionId);
    
    NSMutableArray<MPSession *> *sessions = [persistence fetchSessions];
    MPSession *fetchedSession = [sessions lastObject];
    XCTAssertEqualObjects(session, fetchedSession, @"Session and fetchedSession are not equal.");
    
    [persistence deleteSession:session];
    
    sessions = [persistence fetchSessions];
    if (sessions) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sessionId == %lld", fetchedSession.sessionId];
        sessions = [NSMutableArray arrayWithArray:[sessions filteredArrayUsingPredicate:predicate]];
        XCTAssertTrue(sessions.count == 0, @"Session is not being deleted.");
    }
}

- (void)testMessage {
    [MPPersistenceController_PRIVATE setMpid:@2];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    [persistence saveSession:session];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    [persistence saveMessage:message];
    
    XCTAssertTrue(message.messageId > 0, @"Message id not greater than zero: %lld", message.messageId);
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
    MPMessage *fetchedMessage = [messages lastObject];
    
    XCTAssertEqualObjects(message, fetchedMessage, @"Message and fetchedMessage are not equal.");
    
    [persistence deleteSession:session];
    
    messagesDictionary = [persistence fetchMessagesForUploading];
    messages = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    if (messages) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageId == %lld", fetchedMessage.messageId];
        messages = [messages filteredArrayUsingPredicate:predicate];
        XCTAssertTrue(messages.count == 0, @"Message is not being deleted.");
    }
}

- (void)testMessageWithDataPlan {
    [MParticle sharedInstance].dataPlanId = @"test";
    [MParticle sharedInstance].dataPlanVersion = @(1);
    [MPPersistenceController_PRIVATE setMpid:@2];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    [persistence saveSession:session];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    [persistence saveMessage:message];
    
    XCTAssertTrue(message.messageId > 0, @"Message id not greater than zero: %lld", message.messageId);
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"test"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:1]];
    
    MPMessage *fetchedMessage = [messages lastObject];
    
    XCTAssertEqualObjects(message, fetchedMessage, @"Message and fetchedMessage are not equal.");
    
    [persistence deleteSession:session];
    
    messagesDictionary = [persistence fetchMessagesForUploading];
    messages = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    if (messages) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageId == %lld", fetchedMessage.messageId];
        messages = [messages filteredArrayUsingPredicate:predicate];
        XCTAssertTrue(messages.count == 0, @"Message is not being deleted.");
    }
}

- (void)testMessageWithDataPlanNoVersion {
    [MParticle sharedInstance].dataPlanId = @"test";
    [MPPersistenceController_PRIVATE setMpid:@2];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    [persistence saveSession:session];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    [persistence saveMessage:message];
    
    XCTAssertTrue(message.messageId > 0, @"Message id not greater than zero: %lld", message.messageId);
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"test"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
    MPMessage *fetchedMessage = [messages lastObject];
    
    XCTAssertEqualObjects(message, fetchedMessage, @"Message and fetchedMessage are not equal.");
    
    [persistence deleteSession:session];
    
    messagesDictionary = [persistence fetchMessagesForUploading];
    messages = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    if (messages) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageId == %lld", fetchedMessage.messageId];
        messages = [messages filteredArrayUsingPredicate:predicate];
        XCTAssertTrue(messages.count == 0, @"Message is not being deleted.");
    }
}

- (void)testResetDatabase {
    [MPPersistenceController_PRIVATE setMpid:@2];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    [persistence saveSession:session];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    [persistence saveMessage:message];
    
    XCTAssertTrue(message.messageId > 0, @"Message id not greater than zero: %lld", message.messageId);
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
    MPMessage *fetchedMessage = [messages lastObject];
    
    XCTAssertEqualObjects(message, fetchedMessage, @"Message and fetchedMessage are not equal.");
    
    [[MParticle sharedInstance].persistenceController resetDatabase];
    
    messagesDictionary = [persistence fetchMessagesForUploading];
    messages = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    if (messages) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageId == %lld", fetchedMessage.messageId];
        messages = [messages filteredArrayUsingPredicate:predicate];
        XCTAssertTrue(messages.count == 0, @"Message is not being deleted.");
    }
    
}

- (void)testUpload {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    
    NSDictionary *uploadDictionary = @{kMPOptOutKey:@NO,
                                       kMPSessionTimeoutKey:@120,
                                       kMPUploadIntervalKey:@10,
                                       kMPLifeTimeValueKey:@0,
                                       kMPMessagesKey:@[[message dictionaryRepresentation]],
                                       kMPMessageIdKey:[[NSUUID UUID] UUIDString]};
    
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:[NSNumber numberWithLongLong:session.sessionId] uploadDictionary:uploadDictionary dataPlanId:nil dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    [persistence saveUpload:upload];
    
    XCTAssertTrue(upload.uploadId > 0, @"Upload id not greater than zero: %lld", upload.uploadId);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload test"];
    
    NSArray<MPUpload *> *uploads = [persistence fetchUploads];
    MPUpload *fetchedUpload = [uploads lastObject];
    
    XCTAssertEqualObjects(upload, fetchedUpload, @"Upload and fetchedUpload are not equal.");
    
    [persistence deleteUpload:upload];
    
    uploads = [persistence fetchUploads];
    if (uploads) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uploadId == %lld", fetchedUpload.uploadId];
        uploads = [uploads filteredArrayUsingPredicate:predicate];
        XCTAssertTrue(uploads.count == 0, @"Upload is not being deleted.");
    }
    
    [expectation fulfill];
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testUploadWithDataPlan {
    [MParticle sharedInstance].dataPlanId = @"test";
    [MParticle sharedInstance].dataPlanVersion = @(1);

    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                            session:session
                                                                        messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    
    NSDictionary *uploadDictionary = @{kMPOptOutKey:@NO,
                                       kMPSessionTimeoutKey:@120,
                                       kMPUploadIntervalKey:@10,
                                       kMPLifeTimeValueKey:@0,
                                       kMPMessagesKey:@[[message dictionaryRepresentation]],
                                       kMPMessageIdKey:[[NSUUID UUID] UUIDString]};
    
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:[NSNumber numberWithLongLong:session.sessionId] uploadDictionary:uploadDictionary dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    [persistence saveUpload:upload];
    
    XCTAssertTrue(upload.uploadId > 0, @"Upload id not greater than zero: %lld", upload.uploadId);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload test"];
    
    NSArray<MPUpload *> *uploads = [persistence fetchUploads];
    MPUpload *fetchedUpload = [uploads lastObject];
    
    XCTAssertEqualObjects(upload, fetchedUpload, @"Upload and fetchedUpload are not equal.");
    
    [persistence deleteUpload:upload];
    
    uploads = [persistence fetchUploads];
    if (uploads) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uploadId == %lld", fetchedUpload.uploadId];
        uploads = [uploads filteredArrayUsingPredicate:predicate];
        XCTAssertTrue(uploads.count == 0, @"Upload is not being deleted.");
    }
    
    [expectation fulfill];
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testUploadWithDataPlanNoVersion {
    [MParticle sharedInstance].dataPlanId = @"test";

    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    
    NSDictionary *uploadDictionary = @{kMPOptOutKey:@NO,
                                       kMPSessionTimeoutKey:@120,
                                       kMPUploadIntervalKey:@10,
                                       kMPLifeTimeValueKey:@0,
                                       kMPMessagesKey:@[[message dictionaryRepresentation]],
                                       kMPMessageIdKey:[[NSUUID UUID] UUIDString]};
    
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:[NSNumber numberWithLongLong:session.sessionId] uploadDictionary:uploadDictionary dataPlanId:@"test" dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    [persistence saveUpload:upload];
    
    XCTAssertTrue(upload.uploadId > 0, @"Upload id not greater than zero: %lld", upload.uploadId);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload test"];
    
    NSArray<MPUpload *> *uploads = [persistence fetchUploads];
    MPUpload *fetchedUpload = [uploads lastObject];
    
    XCTAssertEqualObjects(upload, fetchedUpload, @"Upload and fetchedUpload are not equal.");
    
    [persistence deleteUpload:upload];
    
    uploads = [persistence fetchUploads];
    if (uploads) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uploadId == %lld", fetchedUpload.uploadId];
        uploads = [uploads filteredArrayUsingPredicate:predicate];
        XCTAssertTrue(uploads.count == 0, @"Upload is not being deleted.");
    }
    
    [expectation fulfill];
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testUploadWithOptOut {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload Opt Out test"];
    [MParticle sharedInstance].stateMachine.optOut = YES;
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    
    MPUploadBuilder *uploadBuilder = [[MPUploadBuilder alloc] initWithMpid:[MPPersistenceController_PRIVATE mpId] sessionId:@(session.sessionId) messages:@[message] sessionTimeout:120 uploadInterval:10 dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    
    [uploadBuilder build:^(MPUpload *upload) {
        MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
        
        [persistence saveUpload:upload];
        
        NSArray<MPUpload *> *uploads = [persistence fetchUploads];
        
        XCTAssertTrue(uploads.count == 0, @"Uploads are not being blocked by OptOut.");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testUploadWithOptOutMessage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload Opt Out Message test"];
    [MParticle sharedInstance].stateMachine.optOut = YES;
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeOptOut session:session messageInfo:@{kMPOptOutStatus:(@"true")}];
    
    MPMessage *message = [messageBuilder build];
    
    MPUploadBuilder *uploadBuilder = [[MPUploadBuilder alloc] initWithMpid:[MPPersistenceController_PRIVATE mpId] sessionId:@(session.sessionId) messages:@[message] sessionTimeout:120 uploadInterval:10 dataPlanId:nil dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    
    [uploadBuilder build:^(MPUpload *upload) {
        MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
        
        [persistence saveUpload:upload];
        
        XCTAssertTrue(upload.uploadId > 0, @"Upload id not greater than zero: %lld", upload.uploadId);
        
        NSArray<MPUpload *> *uploads = [persistence fetchUploads];
        MPUpload *fetchedUpload = [uploads lastObject];
        
        XCTAssertEqualObjects(upload, fetchedUpload, @"Opt Out event upload is being blocked by OptOut.");
        
        [persistence deleteUpload:upload];
        
        uploads = [persistence fetchUploads];
        if (uploads) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uploadId == %lld", fetchedUpload.uploadId];
            uploads = [uploads filteredArrayUsingPredicate:predicate];
            XCTAssertTrue(uploads.count == 0, @"Upload is not being deleted.");
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testAudiences {
    MPAudience *audience = [[MPAudience alloc] initWithAudienceId:@2];
    XCTAssertTrue(audience.audienceId.intValue == 2);
}

- (void)testFetchIntegrationAttributesForKit {
    NSNumber *integrationId = nil;
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    XCTAssertNil([persistence fetchIntegrationAttributesForId:integrationId]);
    XCTAssertNil([persistence fetchIntegrationAttributesForId:@1000]);
    
    MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:@1000
                                                                                                 attributes:@{@"foo key 1":@"bar value 1",
                                                                                                              @"foo key 2":@"bar value 2"
                                                                                                              }];
    [persistence saveIntegrationAttributes:integrationAttributes];
    
    integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:@2000
                                                                        attributes:@{@"foo key 3":@"bar value 3",
                                                                                     @"foo key 4":@"bar value 4"
                                                                                     }];
    [persistence saveIntegrationAttributes:integrationAttributes];
    
    NSDictionary *storedAttributes = [persistence fetchIntegrationAttributesForId:@1000];
    XCTAssertNotNil(storedAttributes);
    XCTAssertEqual(2, storedAttributes.count);
    XCTAssertEqualObjects(@"bar value 1", [storedAttributes objectForKey:@"foo key 1"]);
    XCTAssertEqualObjects(@"bar value 2", [storedAttributes objectForKey:@"foo key 2"]);
    
    storedAttributes = [persistence fetchIntegrationAttributesForId:@2000];
    XCTAssertNotNil(storedAttributes);
    XCTAssertEqual(2, storedAttributes.count);
    XCTAssertEqualObjects(@"bar value 3", [storedAttributes objectForKey:@"foo key 3"]);
    XCTAssertEqualObjects(@"bar value 4", [storedAttributes objectForKey:@"foo key 4"]);
    
}
- (void)testIntegrationAttributes {
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    [persistence deleteIntegrationAttributesForIntegrationId:@42];
    
    NSNumber *integrationId = @(MPKitInstanceUrbanAirship);
    NSDictionary<NSString *, NSString *> *attributes = @{@"keyUA":@"valueUA"};
    MPIntegrationAttributes *integrationAttributes1 = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    [persistence saveIntegrationAttributes:integrationAttributes1];
    NSArray *integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNotNil(integrationAttributesArray);
    XCTAssertEqual(integrationAttributesArray.count, 1);
    
    integrationId = @(MPKitInstanceButton);
    attributes = @{@"keyButton":@"valueButton"};
    MPIntegrationAttributes *integrationAttributes2 = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    [persistence saveIntegrationAttributes:integrationAttributes2];
    integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNotNil(integrationAttributesArray);
    XCTAssertEqual(integrationAttributesArray.count, 2);
    
    integrationId = @(MPKitInstanceButton);
    attributes = @{@"keyButton2":@"valueButton2"};
    integrationAttributes2 = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    [persistence saveIntegrationAttributes:integrationAttributes2];
    integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNotNil(integrationAttributesArray);
    XCTAssertEqual(integrationAttributesArray.count, 2);
    
    [persistence deleteIntegrationAttributesForIntegrationId:integrationId];
    integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNotNil(integrationAttributesArray);
    XCTAssertEqual(integrationAttributesArray.count, 1);
    
    integrationId = @(MPKitInstanceUrbanAirship);
    [persistence deleteIntegrationAttributesForIntegrationId:integrationId];
    integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNil(integrationAttributesArray);
    
    integrationId = @(MPKitInstanceButton);
    attributes = @{@"keyButton":@"valueButton"};
    integrationAttributes2 = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    [persistence saveIntegrationAttributes:integrationAttributes2];
    integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNotNil(integrationAttributesArray);
    XCTAssertEqual(integrationAttributesArray.count, 1);
    
    [persistence deleteAllIntegrationAttributes];
    integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNil(integrationAttributesArray);
}

- (void)testConsumerInfo {
    [MPPersistenceController_PRIVATE setMpid:@2];
    
    NSDictionary *consumerInfoDictionary = @{
                                             @"ck":@{
                                                     @"rpl":@{
                                                             @"c":@"288160084=2832403&-515079401=2832403&1546594223=2832403&264784951=2832403&4151713=2832403&-1663781220=2832403",
                                                             @"e":@"2015-05-26T22:43:31.505262Z"
                                                             },
                                                     @"uddif":@{
                                                             @"c":@"uah6978=1068490497975183452&uahist=%2524Gender%3Dm%26Tag1%3D",
                                                             @"e":@"2025-05-18T22:43:31.461026Z"
                                                             },
                                                     @"uid":@{
                                                             @"c":@"u=3452189063653540060&cr=2827774&lbri=53CB5411-5BF0-402C-88E4-DFE91F921D82&g=7754fbee-1b83-4cab-9b59-34518c14ae85&ls=2832403&lbe=2832403",
                                                             @"e":@"2025-05-15T17:34:07.450231Z"
                                                             },
                                                     @"uuc6978":@{
                                                             @"c":@"nu=t&et-Unknown=2832403&et-Other=2832403&et-=2832403&et-Transaction=2832198",
                                                             @"e":@"2020-05-16T17:34:07.941843Z"
                                                             }
                                                     },
                                             @"das":@"7754fbee-1b83-4cab-9b59-34518c14ae85",
                                             @"mpid":@2
                                             };
    
    __block MPConsumerInfo *consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:consumerInfoDictionary];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    [persistence saveConsumerInfo:consumerInfo];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Consumer Info"];
    
    dispatch_sync([MParticle messageQueue], ^{
        MPConsumerInfo *fetchedConsumerInfo = [persistence fetchConsumerInfoForUserId:[MPPersistenceController_PRIVATE mpId]];
        XCTAssertNotNil(fetchedConsumerInfo);
        
        NSDictionary *cookiesDictionary = [consumerInfo cookiesDictionaryRepresentation];
        NSDictionary *fetchedCookiesDictionary = [fetchedConsumerInfo cookiesDictionaryRepresentation];
        XCTAssertEqualObjects(cookiesDictionary, fetchedCookiesDictionary);
        
        [persistence deleteConsumerInfo];
        fetchedConsumerInfo = [persistence fetchConsumerInfoForUserId:[MPPersistenceController_PRIVATE mpId]];
        XCTAssertNil(fetchedConsumerInfo);
        
        consumerInfo = [[MPConsumerInfo alloc] init];
        [consumerInfo updateWithConfiguration:consumerInfoDictionary];
        [persistence saveConsumerInfo:consumerInfo];
        [persistence updateConsumerInfo:consumerInfo];
        
        consumerInfo = [persistence fetchConsumerInfoForUserId:[MPPersistenceController_PRIVATE mpId]];
        XCTAssertNotNil(consumerInfo);
        [persistence deleteConsumerInfo];
        
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testForwardRecord {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    
    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushRegistration
                                                                       execStatus:execStatus
                                                                        stateFlag:YES];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    [persistence saveForwardRecord:forwardRecord];
    
    NSArray<MPForwardRecord *> *forwardRecords = [persistence fetchForwardRecords];
    XCTAssertNotNil(forwardRecords);
    XCTAssertEqual(forwardRecords.count, 1);
    
    MPForwardRecord *fetchedForwardRecord = [forwardRecords firstObject];
    XCTAssertEqualObjects(forwardRecord, fetchedForwardRecord);
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent session:session messageInfo:@{}];
    MPMessage *message = [messageBuilder build];
    
    MPUploadBuilder *uploadBuilder = [[MPUploadBuilder alloc] initWithMpid:[MPPersistenceController_PRIVATE mpId]
                                                                 sessionId:[NSNumber numberWithLong:session.sessionId]
                                                                  messages:@[message]
                                                            sessionTimeout:DEFAULT_SESSION_TIMEOUT
                                                            uploadInterval:DEFAULT_UPLOAD_INTERVAL
                                                                dataPlanId:@"test"
                                                           dataPlanVersion:@(1)
                                                            uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    
    [uploadBuilder build: ^(MPUpload * _Nullable upload) {
    }];
    
    forwardRecords = [persistence fetchForwardRecords];
    XCTAssertNil(forwardRecords);
}

- (void)testTooLargeMessageSaving {
    NSString *longString = @"a";
    while (longString.length < 102401) {
        longString = [NSString stringWithFormat:@"%@%@", longString, longString];
    }
    [MPPersistenceController_PRIVATE setMpid:@1];
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":longString}];
    MPMessage *message = [messageBuilder build];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
    [persistence deleteMessages:messages];
    
    [persistence saveMessage:message];
    
    messagesDictionary = [persistence fetchMessagesForUploading];
    sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
    dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
    XCTAssertEqual(messages.count, 0);
}

- (void)testTooLargeCrashMessageSaving {
    NSString *longString = @"a";
    while (longString.length < 1024001) {
        longString = [NSString stringWithFormat:@"%@%@", longString, longString];
    }
    [MPPersistenceController_PRIVATE setMpid:@1];
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeCrashReport
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":longString}];
    MPMessage *message = [messageBuilder build];
    
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
    [persistence deleteMessages:messages];
    
    [persistence saveMessage:message];
    
    messagesDictionary = [persistence fetchMessagesForUploading];
    sessionsDictionary = messagesDictionary[[MPPersistenceController_PRIVATE mpId]];
    dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
    dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    
    XCTAssertEqual(messages.count, 0);
}

- (void)testSaveNilMessage {
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    NSException *e = nil;
    @try {
        [persistence saveMessage:(id _Nonnull)nil];
    } @catch (NSException *ex) {
        e = ex;
    }
    XCTAssertNil(e);
}

- (void)testShouldUploadMessageToMParticle {
    MParticle *instance = [MParticle sharedInstance];
    NSDictionary *messageDictionary = @{
        @"location": @"17 Cherry Tree Lane",
        @"hardwareId": @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702"
    };
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDictionary options:0 error:nil];
    NSNumber *sessionId = @17;
    NSString *uuid = @"uuid";
    MPMessage *message = [[MPMessage alloc] initWithSessionId:sessionId
                                    messageId:1
                                         UUID:uuid
                                  messageType:@"test"
                                  messageData:messageData
                                    timestamp:[[NSDate date] timeIntervalSince1970]
                                 uploadStatus:MPUploadStatusBatch
                                       userId:@1
                                   dataPlanId:nil
                              dataPlanVersion:nil];
    
    [instance.persistenceController saveMessage:message];
    NSDictionary *messages = [instance.persistenceController fetchMessagesForUploading];
    XCTAssertEqual(messages.count, 1);
    NSDictionary *messagesForMpid = messages[message.userId];
    XCTAssertEqual(messagesForMpid.count, 1);
    NSDictionary *messagesForSessionId = messagesForMpid[sessionId];
    XCTAssertEqual(messagesForSessionId.count, 1);
    NSDictionary *messsagesForDataPlanId = messagesForSessionId[@"0"];
    XCTAssertEqual(messsagesForDataPlanId.count, 1);
    NSArray *messagesForDataPlanVersion = messsagesForDataPlanId[@0];
    XCTAssertEqual(messagesForDataPlanVersion.count, 1);
    MPMessage *messageForUpload = messagesForDataPlanVersion[0];
    XCTAssertEqualObjects(message, messageForUpload);
}

- (void)testShouldNotUploadMessageToMParticle {
    MParticle *instance = [MParticle sharedInstance];
    NSDictionary *messageDictionary = @{
        @"location": @"17 Cherry Tree Lane",
        @"hardwareId": @"IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702"
    };
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDictionary options:0 error:nil];
    MPMessage *message = [[MPMessage alloc] initWithSessionId:@17
                                    messageId:1
                                         UUID:@"uuid"
                                  messageType:@"test"
                                  messageData:messageData
                                    timestamp:[[NSDate date] timeIntervalSince1970]
                                 uploadStatus:MPUploadStatusBatch
                                       userId:@1
                                   dataPlanId:nil
                              dataPlanVersion:nil];
    message.shouldUploadEvent = NO;
    
    [instance.persistenceController saveMessage:message];
    NSDictionary *messages = [instance.persistenceController fetchMessagesForUploading];
    XCTAssertEqual(messages.count, 0);
}

- (void)testDeleteRecordsOlderThan_DontDelete {
    NSTimeInterval oneDayAgo = [[NSDate date] timeIntervalSince1970] - 24*60*60;
    NSTimeInterval ninteyDaysAgo = [[NSDate date] timeIntervalSince1970] - 90*24*60*60;
    
    // Store a message
    MParticle *instance = [MParticle sharedInstance];
    NSLog(@"instance: %@", instance);
    NSDictionary *messageDictionary = @{@"test": @"test"};
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDictionary options:0 error:nil];
    MPMessage *message = [[MPMessage alloc] initWithSessionId:@17 messageId:1 UUID:@"uuid" messageType:@"test" messageData:messageData timestamp:oneDayAgo uploadStatus:MPUploadStatusBatch userId:@1 dataPlanId:nil dataPlanVersion:nil];
    [instance.persistenceController saveMessage:message];
    XCTAssertEqual([instance.persistenceController fetchMessagesForUploading].count, 1);
    
    // Store a session
    MPSession *session = [[MPSession alloc] initWithStartTime:oneDayAgo userId:[MPPersistenceController_PRIVATE mpId]];
    session.endTime = oneDayAgo;
    session.attributesDictionary = [@{@"key1":@"value1"} mutableCopy];
    [instance.persistenceController saveSession:session];
    XCTAssertEqual([instance.persistenceController fetchSessions].count, 1);
    
    // Store an upload
    NSDictionary *uploadDictionary = @{kMPOptOutKey:@NO, kMPSessionTimeoutKey:@120, kMPUploadIntervalKey:@10, kMPLifeTimeValueKey:@0, kMPMessagesKey:@[[message dictionaryRepresentation]], kMPMessageIdKey:[[NSUUID UUID] UUIDString]};
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:@(session.sessionId) uploadDictionary:uploadDictionary dataPlanId:nil dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    upload.timestamp = oneDayAgo;
    [instance.persistenceController saveUpload:upload];
    XCTAssertEqual([instance.persistenceController fetchUploads].count, 1);
    
    // Cleanup persistence using default 90 day limit
    [instance.persistenceController deleteRecordsOlderThan:ninteyDaysAgo];
    
    // Check that the records still exist
    XCTAssertEqual([instance.persistenceController fetchMessagesForUploading].count, 1);
    XCTAssertEqual([instance.persistenceController fetchSessions].count, 1);
    XCTAssertEqual([instance.persistenceController fetchUploads].count, 1);
}

- (void)testDeleteRecordsOlderThan_Delete {
    NSTimeInterval sevenDaysAgo = [[NSDate date] timeIntervalSince1970] - 7*24*60*60;
    NSTimeInterval twoDaysAgo = [[NSDate date] timeIntervalSince1970] - 2*24*60*60;
    
    // Store a message
    MParticle *instance = [MParticle sharedInstance];
    NSLog(@"instance: %@", instance);
    NSDictionary *messageDictionary = @{@"test": @"test"};
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDictionary options:0 error:nil];
    MPMessage *message = [[MPMessage alloc] initWithSessionId:@17 messageId:1 UUID:@"uuid" messageType:@"test" messageData:messageData timestamp:sevenDaysAgo uploadStatus:MPUploadStatusBatch userId:@1 dataPlanId:nil dataPlanVersion:nil];
    [instance.persistenceController saveMessage:message];
    XCTAssertEqual([instance.persistenceController fetchMessagesForUploading].count, 1);
    
    // Store a session
    MPSession *session = [[MPSession alloc] initWithStartTime:sevenDaysAgo userId:[MPPersistenceController_PRIVATE mpId]];
    session.endTime = sevenDaysAgo;
    session.attributesDictionary = [@{@"key1":@"value1"} mutableCopy];
    [instance.persistenceController saveSession:session];
    XCTAssertEqual([instance.persistenceController fetchSessions].count, 1);
    
    // Store an upload
    NSDictionary *uploadDictionary = @{kMPOptOutKey:@NO, kMPSessionTimeoutKey:@120, kMPUploadIntervalKey:@10, kMPLifeTimeValueKey:@0, kMPMessagesKey:@[[message dictionaryRepresentation]], kMPMessageIdKey:[[NSUUID UUID] UUIDString]};
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:@(session.sessionId) uploadDictionary:uploadDictionary dataPlanId:nil dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    upload.timestamp = sevenDaysAgo;
    [instance.persistenceController saveUpload:upload];
    XCTAssertEqual([instance.persistenceController fetchUploads].count, 1);
    
    // Cleanup persistence using 2 day limit
    [instance.persistenceController deleteRecordsOlderThan:twoDaysAgo];
    
    // Check that the records no longer exist
    XCTAssertEqual([instance.persistenceController fetchMessagesForUploading].count, 0);
    XCTAssertEqual([instance.persistenceController fetchSessions].count, 0);
    XCTAssertEqual([instance.persistenceController fetchUploads].count, 0);
}

- (void)testClearDatabaseForWorkspaceSwitching {
    NSTimeInterval sevenDaysAgo = [[NSDate date] timeIntervalSince1970] - 7*24*60*60;
    
    // Store a message
    MParticle *instance = [MParticle sharedInstance];
    NSLog(@"instance: %@", instance);
    NSDictionary *messageDictionary = @{@"test": @"test"};
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDictionary options:0 error:nil];
    MPMessage *message = [[MPMessage alloc] initWithSessionId:@17 messageId:1 UUID:@"uuid" messageType:@"test" messageData:messageData timestamp:sevenDaysAgo uploadStatus:MPUploadStatusBatch userId:@1 dataPlanId:nil dataPlanVersion:nil];
    [instance.persistenceController saveMessage:message];
    XCTAssertEqual([instance.persistenceController fetchMessagesForUploading].count, 1);
    
    // Store a session
    MPSession *session = [[MPSession alloc] initWithStartTime:sevenDaysAgo userId:[MPPersistenceController_PRIVATE mpId]];
    session.endTime = sevenDaysAgo;
    session.attributesDictionary = [@{@"key1":@"value1"} mutableCopy];
    [instance.persistenceController saveSession:session];
    XCTAssertEqual([instance.persistenceController fetchSessions].count, 1);
    
    // Store an upload
    NSDictionary *uploadDictionary = @{kMPOptOutKey:@NO, kMPSessionTimeoutKey:@120, kMPUploadIntervalKey:@10, kMPLifeTimeValueKey:@0, kMPMessagesKey:@[[message dictionaryRepresentation]], kMPMessageIdKey:[[NSUUID UUID] UUIDString]};
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:@(session.sessionId) uploadDictionary:uploadDictionary dataPlanId:nil dataPlanVersion:nil uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    upload.timestamp = sevenDaysAgo;
    [instance.persistenceController saveUpload:upload];
    XCTAssertEqual([instance.persistenceController fetchUploads].count, 1);
    
    // Cleanup all records except uploads
    [instance.persistenceController resetDatabaseForWorkspaceSwitching];
    [instance.persistenceController openDatabase];
    
    // Check that the records no longer exist
    XCTAssertEqual([instance.persistenceController fetchMessagesForUploading].count, 0);
    XCTAssertEqual([instance.persistenceController fetchSessions].count, 0);
    XCTAssertEqual([instance.persistenceController fetchUploads].count, 1);
}

#pragma mark - Database Migration Tests

- (void)testNeedsMigration_NoOldDatabaseExists {
    // Ensure no v30 database exists
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *oldDbPath = [documentsDirectory stringByAppendingPathComponent:@"mParticle30.db"];
    [[NSFileManager defaultManager] removeItemAtPath:oldDbPath error:nil];
    
    MPDatabaseMigrationController *migrationController = [[MPDatabaseMigrationController alloc] initWithDatabaseVersions:@[@30, @31]];
    NSNumber *needsMigration = [migrationController needsMigration];
    
    XCTAssertNil(needsMigration, @"needsMigration should return nil when no old database exists");
}

- (void)testNeedsMigration_OldDatabaseExists {
    // Create a v30 database file
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *oldDbPath = [documentsDirectory stringByAppendingPathComponent:@"mParticle30.db"];
    
    // Create a file with content to simulate old database
    NSData *dummyData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    BOOL created = [[NSFileManager defaultManager] createFileAtPath:oldDbPath contents:dummyData attributes:nil];
    XCTAssertTrue(created, @"Failed to create test database file at %@", oldDbPath);
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:oldDbPath], @"Test database file should exist after creation");
    
    MPDatabaseMigrationController *migrationController = [[MPDatabaseMigrationController alloc] initWithDatabaseVersions:@[@30, @31]];
    NSNumber *needsMigration = [migrationController needsMigration];
    
    XCTAssertNotNil(needsMigration, @"needsMigration should return a version when old database exists");
    XCTAssertEqualObjects(needsMigration, @30, @"needsMigration should return 30 for v30 database");
    
    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:oldDbPath error:nil];
}

- (void)testMigrationDeletesOldDatabase {
    // Setup: Create a v30 database with the correct schema
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *oldDbPath = [documentsDirectory stringByAppendingPathComponent:@"mParticle30.db"];
    NSString *newDbPath = [documentsDirectory stringByAppendingPathComponent:@"mParticle31.db"];
    
    // Cleanup any existing databases
    [[NSFileManager defaultManager] removeItemAtPath:oldDbPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:newDbPath error:nil];
    
    // Create v30 database with proper schema
    sqlite3 *oldDb;
    if (sqlite3_open_v2([oldDbPath UTF8String], &oldDb, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK) {
        // Create minimal tables needed for migration
        const char *createSessions = "CREATE TABLE IF NOT EXISTS sessions (uuid TEXT, start_time REAL, end_time REAL, attributes_data BLOB, session_number INTEGER, background_time REAL, number_interruptions INTEGER, event_count INTEGER, suspend_time REAL, length REAL, mpid INTEGER, session_user_ids TEXT, app_info BLOB, device_info BLOB, _id INTEGER PRIMARY KEY AUTOINCREMENT)";
        const char *createMessages = "CREATE TABLE IF NOT EXISTS messages (message_type TEXT, session_id INTEGER, uuid TEXT, timestamp REAL, message_data TEXT, upload_status INTEGER, data_plan_id TEXT, data_plan_version INTEGER, mpid INTEGER, _id INTEGER PRIMARY KEY AUTOINCREMENT)";
        const char *createUploads = "CREATE TABLE IF NOT EXISTS uploads (uuid TEXT, message_data TEXT, timestamp REAL, session_id INTEGER, upload_type INTEGER, data_plan_id TEXT, data_plan_version INTEGER, _id INTEGER PRIMARY KEY AUTOINCREMENT)";
        const char *createForwarding = "CREATE TABLE IF NOT EXISTS forwarding_records (_id INTEGER PRIMARY KEY, forwarding_data BLOB, mpid INTEGER)";
        const char *createConsumerInfo = "CREATE TABLE IF NOT EXISTS consumer_info (_id INTEGER PRIMARY KEY, mpid INTEGER, unique_identifier TEXT)";
        const char *createCookies = "CREATE TABLE IF NOT EXISTS cookies (_id INTEGER PRIMARY KEY, consumer_info_id INTEGER, content TEXT, domain TEXT, expiration TEXT, name TEXT, mpid INTEGER)";
        const char *createIntegration = "CREATE TABLE IF NOT EXISTS integration_attributes (_id INTEGER PRIMARY KEY, kit_code INTEGER, attributes_data BLOB)";
        
        sqlite3_exec(oldDb, createSessions, NULL, NULL, NULL);
        sqlite3_exec(oldDb, createMessages, NULL, NULL, NULL);
        sqlite3_exec(oldDb, createUploads, NULL, NULL, NULL);
        sqlite3_exec(oldDb, createForwarding, NULL, NULL, NULL);
        sqlite3_exec(oldDb, createConsumerInfo, NULL, NULL, NULL);
        sqlite3_exec(oldDb, createCookies, NULL, NULL, NULL);
        sqlite3_exec(oldDb, createIntegration, NULL, NULL, NULL);
        sqlite3_close(oldDb);
    }
    
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:oldDbPath], @"Old database should exist before migration");
    
    // Run migration with deleteDbFile:YES (default)
    MPDatabaseMigrationController *migrationController = [[MPDatabaseMigrationController alloc] initWithDatabaseVersions:@[@30, @31]];
    [migrationController migrateDatabaseFromVersion:@30 deleteDbFile:YES];
    
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:oldDbPath], @"Old database should be deleted after migration");
    
    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:newDbPath error:nil];
}

- (void)testMigrationPreservesOldDatabaseWhenRequested {
    // Setup: Create a v30 database with the correct schema
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *oldDbPath = [documentsDirectory stringByAppendingPathComponent:@"mParticle30.db"];
    NSString *newDbPath = [documentsDirectory stringByAppendingPathComponent:@"mParticle31.db"];
    
    // Cleanup any existing databases
    [[NSFileManager defaultManager] removeItemAtPath:oldDbPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:newDbPath error:nil];
    
    // Create v30 database with proper schema
    sqlite3 *oldDb;
    if (sqlite3_open_v2([oldDbPath UTF8String], &oldDb, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK) {
        const char *createSessions = "CREATE TABLE IF NOT EXISTS sessions (uuid TEXT, start_time REAL, end_time REAL, attributes_data BLOB, session_number INTEGER, background_time REAL, number_interruptions INTEGER, event_count INTEGER, suspend_time REAL, length REAL, mpid INTEGER, session_user_ids TEXT, app_info BLOB, device_info BLOB, _id INTEGER PRIMARY KEY AUTOINCREMENT)";
        const char *createMessages = "CREATE TABLE IF NOT EXISTS messages (message_type TEXT, session_id INTEGER, uuid TEXT, timestamp REAL, message_data TEXT, upload_status INTEGER, data_plan_id TEXT, data_plan_version INTEGER, mpid INTEGER, _id INTEGER PRIMARY KEY AUTOINCREMENT)";
        const char *createUploads = "CREATE TABLE IF NOT EXISTS uploads (uuid TEXT, message_data TEXT, timestamp REAL, session_id INTEGER, upload_type INTEGER, data_plan_id TEXT, data_plan_version INTEGER, _id INTEGER PRIMARY KEY AUTOINCREMENT)";
        const char *createForwarding = "CREATE TABLE IF NOT EXISTS forwarding_records (_id INTEGER PRIMARY KEY, forwarding_data BLOB, mpid INTEGER)";
        const char *createConsumerInfo = "CREATE TABLE IF NOT EXISTS consumer_info (_id INTEGER PRIMARY KEY, mpid INTEGER, unique_identifier TEXT)";
        const char *createCookies = "CREATE TABLE IF NOT EXISTS cookies (_id INTEGER PRIMARY KEY, consumer_info_id INTEGER, content TEXT, domain TEXT, expiration TEXT, name TEXT, mpid INTEGER)";
        const char *createIntegration = "CREATE TABLE IF NOT EXISTS integration_attributes (_id INTEGER PRIMARY KEY, kit_code INTEGER, attributes_data BLOB)";
        
        sqlite3_exec(oldDb, createSessions, NULL, NULL, NULL);
        sqlite3_exec(oldDb, createMessages, NULL, NULL, NULL);
        sqlite3_exec(oldDb, createUploads, NULL, NULL, NULL);
        sqlite3_exec(oldDb, createForwarding, NULL, NULL, NULL);
        sqlite3_exec(oldDb, createConsumerInfo, NULL, NULL, NULL);
        sqlite3_exec(oldDb, createCookies, NULL, NULL, NULL);
        sqlite3_exec(oldDb, createIntegration, NULL, NULL, NULL);
        sqlite3_close(oldDb);
    }
    
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:oldDbPath], @"Old database should exist before migration");
    
    // Run migration with deleteDbFile:NO
    MPDatabaseMigrationController *migrationController = [[MPDatabaseMigrationController alloc] initWithDatabaseVersions:@[@30, @31]];
    [migrationController migrateDatabaseFromVersion:@30 deleteDbFile:NO];
    
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:oldDbPath], @"Old database should be preserved when deleteDbFile:NO");
    
    // Cleanup
    [[NSFileManager defaultManager] removeItemAtPath:oldDbPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:newDbPath error:nil];
}

- (void)testMigrationPreservesSessionData {
    // This test verifies that session data is preserved when migrating via the persistence controller
    // Use the existing pattern from testMigrateMessagesWithSessions
    MPPersistenceController_PRIVATE *persistence = [MParticle sharedInstance].persistenceController;
    
    NSString *testUUID = [[NSUUID UUID] UUIDString];
    NSTimeInterval testStartTime = [[NSDate date] timeIntervalSince1970];
    int64_t testMpid = 12345;
    
    // Create and save a session
    MPSession *session = [[MPSession alloc] initWithStartTime:testStartTime userId:@(testMpid)];
    session.uuid = testUUID;
    [persistence saveSession:session];
    
    // Verify session was saved
    NSMutableArray<MPSession *> *sessions = [persistence fetchSessions];
    XCTAssertEqual(sessions.count, 1, @"Should have one session before migration");
    
    MPSession *savedSession = sessions.firstObject;
    XCTAssertEqualObjects(savedSession.uuid, testUUID, @"Session UUID should match");
    XCTAssertEqual(savedSession.userId.longLongValue, testMpid, @"MPID should match");
    
    // Run migration (this tests that migration preserves existing data)
    MPDatabaseMigrationController *migrationController = [[MPDatabaseMigrationController alloc] initWithDatabaseVersions:@[@30, @31]];
    [migrationController migrateDatabaseFromVersion:@30 deleteDbFile:NO];
    [persistence openDatabase];
    
    // Verify session still exists after migration
    sessions = [persistence fetchSessions];
    XCTAssertGreaterThanOrEqual(sessions.count, 1, @"Should have at least one session after migration");
    
    // Cleanup
    [persistence deleteSession:session];
}

- (void)testMigrationVersionArrayWithSingleVersion {
    // Test edge case: databaseVersions with only the current version (no migration needed)
    MPDatabaseMigrationController *migrationController = [[MPDatabaseMigrationController alloc] initWithDatabaseVersions:@[@31]];
    NSNumber *needsMigration = [migrationController needsMigration];
    
    XCTAssertNil(needsMigration, @"needsMigration should return nil when no old versions in array");
}

- (void)testMigrationDeletesStaleRecordsButPreservesRecentRecords {
    // This test verifies that deleteRecordsOlderThan correctly removes stale records
    // while preserving recent records during migration cleanup
    
    MParticle *instance = [MParticle sharedInstance];
    MPPersistenceController_PRIVATE *persistence = instance.persistenceController;
    
    // Timestamps for test data
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval twoDaysAgo = now - (2 * 24 * 60 * 60);      // Recent - should be preserved
    NSTimeInterval tenDaysAgo = now - (10 * 24 * 60 * 60);     // Stale - should be deleted
    NSTimeInterval sevenDaysAgo = now - (7 * 24 * 60 * 60);    // Threshold for deletion
    
    // Create and save a RECENT message (2 days old - should be preserved)
    NSDictionary *recentMessageDict = @{@"test": @"recent"};
    NSData *recentMessageData = [NSJSONSerialization dataWithJSONObject:recentMessageDict options:0 error:nil];
    MPMessage *recentMessage = [[MPMessage alloc] initWithSessionId:@17 messageId:1 UUID:@"recent-uuid" messageType:@"e" messageData:recentMessageData timestamp:twoDaysAgo uploadStatus:MPUploadStatusBatch userId:@1 dataPlanId:nil dataPlanVersion:nil];
    [persistence saveMessage:recentMessage];
    
    // Create and save a STALE message (10 days old - should be deleted)
    NSDictionary *staleMessageDict = @{@"test": @"stale"};
    NSData *staleMessageData = [NSJSONSerialization dataWithJSONObject:staleMessageDict options:0 error:nil];
    MPMessage *staleMessage = [[MPMessage alloc] initWithSessionId:@18 messageId:2 UUID:@"stale-uuid" messageType:@"e" messageData:staleMessageData timestamp:tenDaysAgo uploadStatus:MPUploadStatusBatch userId:@1 dataPlanId:nil dataPlanVersion:nil];
    [persistence saveMessage:staleMessage];
    
    // Create and save a RECENT session (2 days old - should be preserved)
    MPSession *recentSession = [[MPSession alloc] initWithStartTime:twoDaysAgo userId:[MPPersistenceController_PRIVATE mpId]];
    recentSession.endTime = twoDaysAgo + 100;
    [persistence saveSession:recentSession];
    
    // Create and save a STALE session (10 days old - should be deleted)
    MPSession *staleSession = [[MPSession alloc] initWithStartTime:tenDaysAgo userId:[MPPersistenceController_PRIVATE mpId]];
    staleSession.endTime = tenDaysAgo + 100;
    [persistence saveSession:staleSession];
    
    // Verify we have 2 sessions before cleanup
    NSMutableArray<MPSession *> *sessionsBefore = [persistence fetchSessions];
    XCTAssertEqual(sessionsBefore.count, 2, @"Should have 2 sessions before cleanup");
    
    // Run deleteRecordsOlderThan (this is what migration calls internally)
    [persistence deleteRecordsOlderThan:sevenDaysAgo];
    
    // Verify only recent records remain
    NSDictionary *messagesDict = [persistence fetchMessagesForUploading];
    NSMutableArray<MPSession *> *sessionsAfter = [persistence fetchSessions];
    
    // Check sessions - should only have the recent one
    XCTAssertEqual(sessionsAfter.count, 1, @"Should have only 1 session after cleanup (recent one)");
    if (sessionsAfter.count > 0) {
        MPSession *remainingSession = sessionsAfter.firstObject;
        XCTAssertEqualWithAccuracy(remainingSession.startTime, twoDaysAgo, 1.0, @"Remaining session should be the recent one");
    }
    
    // Check messages - count total messages across all users/sessions
    __block NSInteger totalMessages = 0;
    [messagesDict enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary *sessionDict, BOOL *stop) {
        [sessionDict enumerateKeysAndObjectsUsingBlock:^(id sessionKey, NSDictionary *dataPlanDict, BOOL *stop2) {
            [dataPlanDict enumerateKeysAndObjectsUsingBlock:^(id planKey, NSDictionary *versionDict, BOOL *stop3) {
                [versionDict enumerateKeysAndObjectsUsingBlock:^(id versionKey, NSArray *messages, BOOL *stop4) {
                    totalMessages += messages.count;
                }];
            }];
        }];
    }];
    XCTAssertEqual(totalMessages, 1, @"Should have only 1 message after cleanup (recent one)");
    
    // Cleanup
    [persistence deleteSession:recentSession];
}

@end

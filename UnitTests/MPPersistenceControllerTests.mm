#import <XCTest/XCTest.h>
#import "MPPersistenceController.h"
#import "MPSession.h"
#import "MPMessage.h"
#import "MPUpload.h"
#import "MPSegment.h"
#import "MPSegmentMembership.h"
#import "MPIConstants.h"
#import "MPMessageBuilder.h"
#import "MParticleUserNotification.h"
#import "MPIntegrationAttributes.h"
#import "MPConsumerInfo.h"
#import "MPForwardRecord.h"
#import "MPKitExecStatus.h"
#import "mParticle.h"
#import "MPUploadBuilder.h"

#define DATABASE_TESTS_EXPECTATIONS_TIMEOUT 1

@interface MParticle ()
+ (dispatch_queue_t)messageQueue;
@end

@interface MPPersistenceControllerTests : XCTestCase {
    dispatch_queue_t messageQueue;
}

@end


@implementation MPPersistenceControllerTests

- (void)setUp {
    [super setUp];
    [MParticle sharedInstance];
    messageQueue = [MParticle messageQueue];
    [[MPPersistenceController sharedInstance] openDatabase];
}

- (void)tearDown {
    dispatch_sync(messageQueue, ^{
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        [persistence deleteRecordsOlderThan:[[NSDate date] timeIntervalSince1970]];
        [persistence closeDatabase];
    });
    
    [super tearDown];
}

- (NSDictionary *)nonmParticleRemoteNotificationDictionary {
    NSDictionary *remoteNotificationDictionary = @{@"aps":@{
                                                           @"alert":@{
                                                                   @"body":@"Your regular transportation has arrived.",
                                                                   @"show-view":@NO
                                                                   },
                                                           @"badge":@1,
                                                           @"sound":@"engine_sound.aiff"
                                                           }
                                                   };
    
    return remoteNotificationDictionary;
}

- (void)testSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Session test"];
    
    dispatch_async(messageQueue, ^{
        MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
        session.attributesDictionary = [@{@"key1":@"value1"} mutableCopy];
        
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
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
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DATABASE_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testMessage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Message test"];
    
    dispatch_async(messageQueue, ^{
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        
        MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
        [persistence saveSession:session];
        
        MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                               session:session
                                                                           messageInfo:@{@"MessageKey1":@"MessageValue1"}];
        MPMessage *message = (MPMessage *)[messageBuilder build];
        [persistence saveMessage:message];
        
        XCTAssertTrue(message.messageId > 0, @"Message id not greater than zero: %lld", message.messageId);
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        NSArray<MPMessage *> *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
        MPMessage *fetchedMessage = [messages lastObject];
        
        XCTAssertEqualObjects(message, fetchedMessage, @"Message and fetchedMessage are not equal.");
        
        [persistence deleteSession:session];
        
        messagesDictionary = [persistence fetchMessagesForUploading];
        messages = messagesDictionary[[MPPersistenceController mpId]];
        if (messages) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageId == %lld", fetchedMessage.messageId];
            messages = [messages filteredArrayUsingPredicate:predicate];
            XCTAssertTrue(messages.count == 0, @"Message is not being deleted.");
        }
        
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:DATABASE_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testDeleteMessages {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Message test"];
    dispatch_async(messageQueue, ^{
        MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
        MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
        
        for (int i = 0; i < 10; ++i) {
            NSString *key = [NSString stringWithFormat:@"Key%@", @(i)];
            NSString *value = [NSString stringWithFormat:@"Value%@", @(i)];
            
            MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                                   session:session
                                                                               messageInfo:@{key:value}];
            MPMessage *message = (MPMessage *)[messageBuilder build];
            [persistence saveMessage:message];
        }
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
        NSArray *messages =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:session.sessionId]];
        [persistence deleteMessages:messages];
        
        messagesDictionary = [persistence fetchMessagesForUploading];
        messages = messagesDictionary[[MPPersistenceController mpId]];
        XCTAssertNil(messages, @"Should have been nil.");
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DATABASE_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testUpload {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    NSDictionary *uploadDictionary = @{kMPOptOutKey:@NO,
                                       kMPSessionTimeoutKey:@120,
                                       kMPUploadIntervalKey:@10,
                                       kMPLifeTimeValueKey:@0,
                                       kMPMessagesKey:@[[message dictionaryRepresentation]],
                                       kMPMessageIdKey:[[NSUUID UUID] UUIDString]};
    
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:[NSNumber numberWithLongLong:session.sessionId] uploadDictionary:uploadDictionary];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    NSArray *nilArray = nil;
    [persistence saveUpload:upload messageIds:nilArray operation:MPPersistenceOperationFlag];
    
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
    
    [self waitForExpectationsWithTimeout:DATABASE_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testSegments {
    NSDictionary *segmentDictionary = @{@"id":@101,
                                        @"n":@"External Name 101",
                                        @"c":@[@{@"ct":@1395014265365,
                                                 @"a":@"add"
                                                 },
                                               @{@"ct":@1395100665367,
                                                 @"a":@"drop"
                                                 },
                                               @{@"ct":@1395187065367,
                                                 @"a":@"add"
                                                 }
                                               ],
                                        @"s":@[@"aaa", @"bbb", @"ccc"]
                                        };
    
    MPSegment *segment = [[MPSegment alloc] initWithDictionary:segmentDictionary];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence saveSegment:segment];
    
    XCTAssertTrue([segment.segmentId integerValue] > 0, @"Segment id not greater than zero: %@", segment.segmentId);
    
    MPSegment *fetchedSegment = [[persistence fetchSegments] lastObject];
    
    XCTAssertEqualObjects(segment, fetchedSegment, @"Segment and fetchedSegment are not equal.");
    
    [persistence deleteSegments];
    
    NSArray *segments = [persistence fetchSegments];
    if (segments) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"segmentId == %@", fetchedSegment.segmentId];
        segments = [segments filteredArrayUsingPredicate:predicate];
        XCTAssertTrue(segments.count == 0, @"Segment is not being deleted.");
    }
}

- (void)testIntegrationAttributes {
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence deleteIntegrationAttributesForKitCode:@42];
    
    NSNumber *kitCode = @(MPKitInstanceUrbanAirship);
    NSDictionary<NSString *, NSString *> *attributes = @{@"keyUA":@"valueUA"};
    MPIntegrationAttributes *integrationAttributes1 = [[MPIntegrationAttributes alloc] initWithKitCode:kitCode attributes:attributes];
    [persistence saveIntegrationAttributes:integrationAttributes1];
    NSArray *integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNotNil(integrationAttributesArray);
    XCTAssertEqual(integrationAttributesArray.count, 1);
    
    kitCode = @(MPKitInstanceButton);
    attributes = @{@"keyButton":@"valueButton"};
    MPIntegrationAttributes *integrationAttributes2 = [[MPIntegrationAttributes alloc] initWithKitCode:kitCode attributes:attributes];
    [persistence saveIntegrationAttributes:integrationAttributes2];
    integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNotNil(integrationAttributesArray);
    XCTAssertEqual(integrationAttributesArray.count, 2);
    
    kitCode = @(MPKitInstanceButton);
    attributes = @{@"keyButton2":@"valueButton2"};
    integrationAttributes2 = [[MPIntegrationAttributes alloc] initWithKitCode:kitCode attributes:attributes];
    [persistence saveIntegrationAttributes:integrationAttributes2];
    integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNotNil(integrationAttributesArray);
    XCTAssertEqual(integrationAttributesArray.count, 2);
    
    [persistence deleteIntegrationAttributes:integrationAttributes2];
    integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNotNil(integrationAttributesArray);
    XCTAssertEqual(integrationAttributesArray.count, 1);
    
    kitCode = @(MPKitInstanceUrbanAirship);
    [persistence deleteIntegrationAttributesForKitCode:kitCode];
    integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNil(integrationAttributesArray);
    
    kitCode = @(MPKitInstanceButton);
    attributes = @{@"keyButton":@"valueButton"};
    integrationAttributes2 = [[MPIntegrationAttributes alloc] initWithKitCode:kitCode attributes:attributes];
    [persistence saveIntegrationAttributes:integrationAttributes2];
    integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNotNil(integrationAttributesArray);
    XCTAssertEqual(integrationAttributesArray.count, 1);
    
    [persistence deleteAllIntegrationAttributes];
    integrationAttributesArray = [persistence fetchIntegrationAttributes];
    XCTAssertNil(integrationAttributesArray);
}

- (void)testConsumerInfo {
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
                                             @"mpid":@3452189063653540060
                                             };
    
    MPConsumerInfo *consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:consumerInfoDictionary];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence saveConsumerInfo:consumerInfo];
    
    MPConsumerInfo *fetchedConsumerInfo = [persistence fetchConsumerInfoForUserId:[MPPersistenceController mpId]];
    XCTAssertNotNil(fetchedConsumerInfo);
    
    NSDictionary *cookiesDictionary = [consumerInfo cookiesDictionaryRepresentation];
    NSDictionary *fetchedCookiesDictionary = [fetchedConsumerInfo cookiesDictionaryRepresentation];
    XCTAssertEqualObjects(cookiesDictionary, fetchedCookiesDictionary);
    
    [persistence deleteConsumerInfo];
    fetchedConsumerInfo = [persistence fetchConsumerInfoForUserId:[MPPersistenceController mpId]];
    XCTAssertNil(fetchedConsumerInfo);
    
    consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:consumerInfoDictionary];
    [persistence saveConsumerInfo:consumerInfo];
    [persistence updateConsumerInfo:consumerInfo];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Consumer Info"];
    
    consumerInfo = [persistence fetchConsumerInfoForUserId:[MPPersistenceController mpId]];
    XCTAssertNotNil(consumerInfo);
    [persistence deleteConsumerInfo];
    
    [expectation fulfill];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testForwardRecord {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAppboy) returnCode:MPKitReturnCodeSuccess];
    
    MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypePushRegistration
                                                                       execStatus:execStatus
                                                                        stateFlag:YES];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence saveForwardRecord:forwardRecord];
    
    NSArray<MPForwardRecord *> *forwardRecords = [persistence fetchForwardRecords];
    XCTAssertNotNil(forwardRecords);
    XCTAssertEqual(forwardRecords.count, 1);
    
    MPForwardRecord *fetchedForwardRecord = [forwardRecords firstObject];
    XCTAssertEqualObjects(forwardRecord, fetchedForwardRecord);
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder    newBuilderWithMpid:[MPPersistenceController mpId]
                                                                  sessionId:[NSNumber numberWithLong:session.sessionId]
                                                                   messages:@[]
                                                             sessionTimeout:DEFAULT_SESSION_TIMEOUT
                                                             uploadInterval:DEFAULT_DEBUG_UPLOAD_INTERVAL];

    [uploadBuilder build: ^(MPUpload * _Nullable upload) {
    }];
    
    forwardRecords = [persistence fetchForwardRecords];
    XCTAssertNil(forwardRecords);
}

@end

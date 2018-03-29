//
//  MPPersistenceControllerTests.mm
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
#import "MPPersistenceController.h"
#import "MPSession.h"
#import "MPMessage.h"
#import "MPUpload.h"
#import "MPSegment.h"
#import "MPSegmentMembership.h"
#import "MPIConstants.h"
#import "MPStandaloneMessage.h"
#import "MPStandaloneUpload.h"
#import "MPMessageBuilder.h"
#import "MParticleUserNotification.h"
#import "MPIntegrationAttributes.h"
#import "MPConsumerInfo.h"
#import "MPForwardRecord.h"
#import "MPKitExecStatus.h"

#define DATABASE_TESTS_EXPECTATIONS_TIMEOUT 1

@interface MPPersistenceControllerTests : XCTestCase

@end


@implementation MPPersistenceControllerTests

- (void)setUp {
    [super setUp];
    
    [[MPPersistenceController sharedInstance] openDatabase];
}

- (void)tearDown {
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence deleteRecordsOlderThan:[[NSDate date] timeIntervalSince1970]];
    [persistence closeDatabase];
    
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
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    session.attributesDictionary = [@{@"key1":@"value1"} mutableCopy];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence saveSession:session];
    
    XCTAssertTrue(session.sessionId > 0, @"Session id not greater than zero: %lld", session.sessionId);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Session test"];
    
    [persistence fetchSessions:^(NSMutableArray<MPSession *> *sessions) {
        MPSession *fetchedSession = [sessions lastObject];
        XCTAssertEqualObjects(session, fetchedSession, @"Session and fetchedSession are not equal.");
        
        [persistence deleteSession:session];
        
        [persistence fetchSessions:^(NSMutableArray *sessions) {
            if (sessions) {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sessionId == %lld", fetchedSession.sessionId];
                sessions = [NSMutableArray arrayWithArray:[sessions filteredArrayUsingPredicate:predicate]];
                XCTAssertTrue(sessions.count == 0, @"Session is not being deleted.");
            }
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:DATABASE_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testMessage {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence saveMessage:message];
    
    XCTAssertTrue(message.messageId > 0, @"Message id not greater than zero: %lld", message.messageId);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Message test"];
    
    [persistence fetchMessagesForUploadingInSession:session
                                  completionHandler:^(NSArray<MPMessage *> *messages) {
                                      MPMessage *fetchedMessage = [messages lastObject];
                                      
                                      XCTAssertEqualObjects(message, fetchedMessage, @"Message and fetchedMessage are not equal.");
                                      
                                      [persistence deleteSession:session];
                                      
                                      [persistence fetchMessagesForUploadingInSession:session
                                                                    completionHandler:^(NSArray *messages) {
                                                                        if (messages) {
                                                                            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageId == %lld", fetchedMessage.messageId];
                                                                            messages = [messages filteredArrayUsingPredicate:predicate];
                                                                            XCTAssertTrue(messages.count == 0, @"Message is not being deleted.");
                                                                        }
                                                                        
                                                                        [expectation fulfill];
                                                                    }];
                                  }];
    
    [self waitForExpectationsWithTimeout:DATABASE_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testDeleteMessages {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
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
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Message test"];
    
    [persistence fetchMessagesForUploadingInSession:session
                                  completionHandler:^(NSArray<MPMessage *> *messages) {
                                      [persistence deleteMessages:messages];
                                      
                                      [persistence fetchMessagesForUploadingInSession:session
                                                                    completionHandler:^(NSArray *messages) {
                                                                        XCTAssertNil(messages, @"Should have been nil.");
                                                                        
                                                                        [expectation fulfill];
                                                                    }];
                                  }];
    
    [self waitForExpectationsWithTimeout:DATABASE_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testUpload {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    
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
    
    MPUpload *upload = [[MPUpload alloc] initWithSession:session uploadDictionary:uploadDictionary];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    NSArray *nilArray = nil;
    [persistence saveUpload:upload messageIds:nilArray operation:MPPersistenceOperationFlag];
    
    XCTAssertTrue(upload.uploadId > 0, @"Upload id not greater than zero: %lld", upload.uploadId);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload test"];
    
    [persistence fetchUploadsInSession:session
                     completionHandler:^(NSArray<MPUpload *> *uploads) {
                         MPUpload *fetchedUpload = [uploads lastObject];
                         
                         XCTAssertEqualObjects(upload, fetchedUpload, @"Upload and fetchedUpload are not equal.");
                         
                         [persistence deleteUpload:upload];
                         
                         [persistence fetchUploadsInSession:session
                                          completionHandler:^(NSArray *uploads) {
                                              if (uploads) {
                                                  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uploadId == %lld", fetchedUpload.uploadId];
                                                  uploads = [uploads filteredArrayUsingPredicate:predicate];
                                                  XCTAssertTrue(uploads.count == 0, @"Upload is not being deleted.");
                                              }
                                              
                                              [expectation fulfill];
                                          }];
                         
                     }];
    
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

- (void)testStandaloneMessage {
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    NSArray<MPStandaloneMessage *> *standaloneMessages = [persistence fetchStandaloneMessages];
    MPStandaloneMessage *standaloneMessage;
    
    for (standaloneMessage in standaloneMessages) {
        [persistence deleteStandaloneMessage:standaloneMessage];
    }

    NSDictionary *messageInfo = @{kMPDeviceTokenKey:@"<Device Token>",
                                  kMPPushMessageProviderKey:kMPPushMessageProviderValue};
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypePushNotification session:nil messageInfo:messageInfo];
    MPDataModelAbstract *message = [messageBuilder build];
    XCTAssertNotNil(message, @"Stand-alone message should not have been nil.");
    XCTAssertTrue([message isKindOfClass:[MPStandaloneMessage class]], @"Instance should have been of kind MPStandaloneMessage.");
    
    [persistence saveStandaloneMessage:(MPStandaloneMessage *)message];
    
    standaloneMessages = [persistence fetchStandaloneMessages];
    XCTAssertEqual(standaloneMessages.count, 1, @"There should have been only 1 fetched stand-alone message.");
    
    standaloneMessage = [standaloneMessages firstObject];
    XCTAssertNotNil(standaloneMessage, @"Stand-alone message should not have been nil.");
    XCTAssertEqualObjects(standaloneMessage.messageType, @"pm", @"Stand-alone message type should have been 'pm.'");
    XCTAssertGreaterThan(standaloneMessage.messageId, 0, @"Stand-alone message id should have been greater than 0.");
    XCTAssertEqual(standaloneMessage.uploadStatus, MPUploadStatusBatch, @"Upload status should have been 'batch.'");
    XCTAssertNotNil(standaloneMessage.messageData, @"Stand-alone message should contain data.");
    XCTAssertNotNil(standaloneMessage.uuid, @"Stand-alone message should have a uuid.");
    XCTAssertGreaterThan(standaloneMessage.timestamp, 0.0, @"Stand-alone message timestamp should have been greater than 0.");
    
    NSDictionary *dictionary = [standaloneMessage dictionaryRepresentation];
    XCTAssertNotNil(dictionary, @"Stand-alone message dictionary representation should not have been nil.");
    XCTAssertNotNil(dictionary[kMPDeviceTokenKey], @"Dictionary key should not have been nil.");
    XCTAssertNotNil(dictionary[kMPPushMessageProviderKey], @"Dictionary key should not have been nil.");
    XCTAssertNotNil(dictionary[kMPMessageIdKey], @"Dictionary key should not have been nil.");
    XCTAssertNotNil(dictionary[kMPMessageTypeKey], @"Dictionary key should not have been nil.");
    XCTAssertNotNil(dictionary[kMPTimestampKey], @"Dictionary key should not have been nil.");
    XCTAssertNotNil(dictionary[@"cs"], @"Dictionary key should not have been nil.");
    
    MPStandaloneMessage *copyStandaloneMessage = [standaloneMessage copy];
    XCTAssertNotEqual(copyStandaloneMessage, standaloneMessage, @"Pointer addresses should not have been the same.");
    XCTAssertEqualObjects(copyStandaloneMessage, standaloneMessage, @"Stand-alone message is not being copied properly.");
    
    NSData *serializedObject = [NSKeyedArchiver archivedDataWithRootObject:standaloneMessage];
    XCTAssertNotNil(serializedObject, @"Should not have been nil.");
    
    MPStandaloneMessage *deserializedObject = [NSKeyedUnarchiver unarchiveObjectWithData:serializedObject];
    XCTAssertNotNil(deserializedObject, @"Should not have been nil.");
    XCTAssertEqualObjects(standaloneMessage, deserializedObject, @"Should have been equal.");
    
    [persistence deleteStandaloneMessage:standaloneMessage];
    standaloneMessage = [[persistence fetchStandaloneMessages] firstObject];
    XCTAssertNil(standaloneMessage, @"Stand-alone message should have been deleted.");
}

- (void)testStandaloneUpload {
    NSDictionary *messageInfo = @{kMPDeviceTokenKey:@"<Device Token>",
                                  kMPPushMessageProviderKey:kMPPushMessageProviderValue};
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypePushNotification session:nil messageInfo:messageInfo];
    MPDataModelAbstract *message = [messageBuilder build];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence saveStandaloneMessage:(MPStandaloneMessage *)message];
    
    NSArray<MPStandaloneMessage *> *persistedMessages = [persistence fetchStandaloneMessages];
    NSUInteger numberOfMessages = persistedMessages.count;
    NSMutableArray *standaloneMessages = [[NSMutableArray alloc] initWithCapacity:numberOfMessages];
    NSMutableArray *preparedMessageIds = [[NSMutableArray alloc] initWithCapacity:numberOfMessages];
    for (MPStandaloneMessage *standaloneMessage in persistedMessages) {
        [preparedMessageIds addObject:@(standaloneMessage.messageId)];
        [standaloneMessages addObject:[standaloneMessage dictionaryRepresentation]];
    }
    
    NSDictionary *uploadDictionary = @{kMPOptOutKey:@NO,
                                       kMPUploadIntervalKey:@600,
                                       kMPLifeTimeValueKey:@0,
                                       kMPMessagesKey:standaloneMessages,
                                       kMPMessageIdKey:[[NSUUID UUID] UUIDString],
                                       kMPTimestampKey:MPCurrentEpochInMilliseconds};
    
    MPStandaloneUpload *standaloneUpload = [[MPStandaloneUpload alloc] initWithUploadDictionary:uploadDictionary];
    XCTAssertNotNil(standaloneUpload, @"Stand-alone upload should not have been nil.");
    [persistence saveStandaloneUpload:standaloneUpload];
    
    [persistence deleteStandaloneMessageIds:preparedMessageIds];
    NSArray *fetchedStandaloneMessages = [persistence fetchStandaloneMessages];
    XCTAssertNil(fetchedStandaloneMessages, @"Stand-alone messages should had been deleted.");
    
    NSArray<MPStandaloneUpload *> *standaloneUploads = [persistence fetchStandaloneUploads];
    
    for (MPStandaloneUpload *stAlnUpld in standaloneUploads) {
        [persistence deleteStandaloneUpload:stAlnUpld];
    }
    
    standaloneUpload = [standaloneUploads firstObject];
    XCTAssertNotNil(standaloneUpload, @"Stand-alone upload should not have been nil.");
    XCTAssertGreaterThan(standaloneUpload.uploadId, 0, @"Stand-alone upload id should have been greater than 0.");
    XCTAssertGreaterThan(standaloneUpload.timestamp, 0.0, @"Stand-alone upload timestamp should have been greater than 0.");
    XCTAssertNotNil(standaloneUpload.uploadData, @"Stand-alone upload should contain data.");
    XCTAssertNotNil(standaloneUpload.uuid, @"Stand-alone upload should have a uuid.");
    
    NSDictionary *dictionary = [standaloneUpload dictionaryRepresentation];
    XCTAssertNotNil(dictionary, @"Stand-alone upload dictionary representation should not have been nil.");
    XCTAssertNotNil(dictionary[kMPTimestampKey], @"Dictionary key should not have been nil.");
    XCTAssertNotNil(dictionary[kMPMessageIdKey], @"Dictionary key should not have been nil.");
    XCTAssertNotNil(dictionary[kMPLifeTimeValueKey], @"Dictionary key should not have been nil.");
    XCTAssertNotNil(dictionary[kMPMessagesKey], @"Dictionary key should not have been nil.");
    XCTAssertNotNil(dictionary[kMPOptOutKey], @"Dictionary key should not have been nil.");
    XCTAssertNotNil(dictionary[kMPUploadIntervalKey], @"Dictionary key should not have been nil.");
    
    MPStandaloneUpload *copyStandaloneUpload = [standaloneUpload copy];
    XCTAssertNotEqual(copyStandaloneUpload, standaloneUpload, @"Pointer addresses should not have been the same.");
    XCTAssertEqualObjects(copyStandaloneUpload, standaloneUpload, @"Stand-alone upload is not being copied properly.");
    
    NSString *serializedString = [standaloneUpload serializedString];
    XCTAssertNotNil(serializedString, @"Should not have been nil.");
    
    [persistence deleteStandaloneUpload:standaloneUpload];
    standaloneUpload = [[persistence fetchStandaloneUploads] firstObject];
    XCTAssertNil(standaloneUpload, @"Stand-alone upload should have been deleted.");
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

- (void)testMessageCount {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];

    NSUInteger messageCount = [persistence countMesssagesForUploadInSession:session];
    XCTAssertEqual(messageCount, 0);

    [persistence saveMessage:message];
    
    messageCount = [persistence countMesssagesForUploadInSession:session];
    XCTAssertEqual(messageCount, 1);
    
    [persistence deleteSession:session];
    
    NSDictionary *messageInfo = @{kMPDeviceTokenKey:@"<Device Token>",
                                  kMPPushMessageProviderKey:kMPPushMessageProviderValue};
    
    messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypePushNotification session:nil messageInfo:messageInfo];
    MPStandaloneMessage *standaloneMessage = (MPStandaloneMessage *)[messageBuilder build];

    messageCount = [persistence countStandaloneMessages];
    XCTAssertEqual(messageCount, 0);

    [persistence saveStandaloneMessage:standaloneMessage];

    messageCount = [persistence countStandaloneMessages];
    XCTAssertEqual(messageCount, 1);
    
    [persistence deleteStandaloneMessage:standaloneMessage];
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
    
    MPConsumerInfo *fetchedConsumerInfo = [persistence fetchConsumerInfo];
    XCTAssertNotNil(fetchedConsumerInfo);
    
    NSDictionary *cookiesDictionary = [consumerInfo cookiesDictionaryRepresentation];
    NSDictionary *fetchedCookiesDictionary = [fetchedConsumerInfo cookiesDictionaryRepresentation];
    XCTAssertEqualObjects(cookiesDictionary, fetchedCookiesDictionary);
    
    [persistence deleteConsumerInfo];
    fetchedConsumerInfo = [persistence fetchConsumerInfo];
    XCTAssertNil(fetchedConsumerInfo);
    
    consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:consumerInfoDictionary];
    [persistence saveConsumerInfo:consumerInfo];
    [persistence updateConsumerInfo:consumerInfo];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Consumer Info"];
    
    [persistence fetchConsumerInfo:^(MPConsumerInfo * _Nullable consumerInfo) {
        XCTAssertNotNil(consumerInfo);
        [persistence deleteConsumerInfo];
        
        [expectation fulfill];
    }];
    
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
    
    NSArray *ids = nil;
    [persistence deleteForwardRecordsIds:ids];
    [persistence deleteForwardRecordsIds:@[]];
    [persistence deleteForwardRecordsIds:@[@(forwardRecord.forwardRecordId)]];
    
    forwardRecords = [persistence fetchForwardRecords];
    XCTAssertNil(forwardRecords);
}

@end

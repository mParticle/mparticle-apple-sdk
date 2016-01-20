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
#import "MPCommand.h"
#import "MPSegment.h"
#import "MPSegmentMembership.h"
#import "MPIConstants.h"
#import "MPStandaloneMessage.h"
#import "MPStandaloneUpload.h"
#import "MPStandaloneCommand.h"
#import "MPMessageBuilder.h"
#import "MParticleUserNotification.h"

#define DATABASE_TESTS_EXPECATIONS_TIMEOUT 1

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

- (NSDictionary *)remoteNotificationDictionary:(BOOL)expired {
    NSTimeInterval increment = expired ? -100 : 100;
    
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
                                                   @"m_expy":MPMilliseconds([[NSDate date] timeIntervalSince1970] + increment),
                                                   @"m_uid":@(arc4random_uniform(INT_MAX))
                                                   };
    
    return remoteNotificationDictionary;
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
    
    [self waitForExpectationsWithTimeout:DATABASE_TESTS_EXPECATIONS_TIMEOUT handler:nil];
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
    
    [self waitForExpectationsWithTimeout:DATABASE_TESTS_EXPECATIONS_TIMEOUT handler:nil];
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
    
    [self waitForExpectationsWithTimeout:DATABASE_TESTS_EXPECATIONS_TIMEOUT handler:nil];
}

- (void)testCommand {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    
    NSDictionary *commandDictionary = @{@"ct":@1397231725992,
                                        @"dt":@"hc",
                                        @"h":@{@"User-Agent":@"Mozilla/5.0 (iPhone; CPU iPhone OS 7_1 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) Mobile/11D167 mParticle/2.3.1"},
                                        @"id":@"ac813ca3-3236-457a-9edd-fe0b9965f7f6",
                                        @"m":@"GET",
                                        @"u":@"https://ssl.google-analytics.com/collect?sc=start&ht=1397226437508&cid=31383639353030303030&ul=en-us&sr=640x1136&an=Particlebox&av=2.3.1&aid=com.mparticle.Particlebox&tid=UA-46924309-3&t=appview&v=1&_v=mi3.0.3&qt=5288484&z=D0151150-BAB9-482D-9826-5713145E0263"
                                        };
    
    MPCommand *command = [[MPCommand alloc] initWithSession:session commandDictionary:commandDictionary];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence saveCommand:command];
    
    XCTAssertTrue(command.commandId > 0, @"Command id not greater than zero: %lld", command.commandId);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Command test"];
    
    [persistence fetchCommandsInSession:session
                      completionHandler:^(NSArray<MPCommand *> *commands) {
                          MPCommand *fetchedCommand = [commands lastObject];
                          
                          XCTAssertEqualObjects(command, fetchedCommand, @"Command and fetchedCommand are not equal.");
                          
                          [persistence deleteCommand:command];
                          
                          [persistence fetchCommandsInSession:session
                                            completionHandler:^(NSArray *commands) {
                                                if (commands) {
                                                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"commandId == %lld", fetchedCommand.commandId];
                                                    commands = [commands filteredArrayUsingPredicate:predicate];
                                                    XCTAssertTrue(commands.count == 0, @"Command is not being deleted.");
                                                }
                                                
                                                [expectation fulfill];
                                            }];
                      }];
    
    [self waitForExpectationsWithTimeout:DATABASE_TESTS_EXPECATIONS_TIMEOUT handler:nil];
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
    NSDictionary *messageInfo = @{kMPDeviceTokenKey:@"<Device Token>",
                                  kMPPushMessageProviderKey:kMPPushMessageProviderValue};
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypePushNotification session:nil messageInfo:messageInfo];
    MPDataModelAbstract *message = [messageBuilder build];
    XCTAssertNotNil(message, @"Stand-alone message should not have been nil.");
    XCTAssertTrue([message isKindOfClass:[MPStandaloneMessage class]], @"Instance should have been of kind MPStandaloneMessage.");
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence saveStandaloneMessage:(MPStandaloneMessage *)message];
    
    NSArray<MPStandaloneMessage *> *standaloneMessages = [persistence fetchStandaloneMessages];
    XCTAssertEqual(standaloneMessages.count, 1, @"There should have been only 1 fetched stand-alone message.");
    
    MPStandaloneMessage *standaloneMessage = [standaloneMessages firstObject];
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
    
    [persistence deleteStandaloneUpload:standaloneUpload];
    standaloneUpload = [[persistence fetchStandaloneUploads] firstObject];
    XCTAssertNil(standaloneUpload, @"Stand-alone upload should have been deleted.");
}

- (void)testRemoteNotification {
    NSDictionary *remoteNotificationDictionary = [self remoteNotificationDictionary:NO];
    
    MParticleUserNotification *userNotification = [[MParticleUserNotification alloc] initWithDictionary:remoteNotificationDictionary
                                                                                       actionIdentifier:nil
                                                                                                  state:kMPPushNotificationStateBackground
                                                                                               behavior:MPUserNotificationBehaviorDirectOpen
                                                                                                   mode:MPUserNotificationModeRemote
                                                                                            runningMode:MPUserNotificationRunningModeBackground];
    
    XCTAssertNotNil(userNotification, @"Remote notification should not have been nil.");
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence saveUserNotification:userNotification];
    
    XCTAssertGreaterThan(userNotification.userNotificationId, 0, @"Remote notification id is not being assign.");
    
    MParticleUserNotification *latestRemoteNotification = [[persistence fetchDisplayedRemoteUserNotifications] firstObject];
    XCTAssertNotNil(latestRemoteNotification, @"Latest remote notification should not have been nil.");
    XCTAssertEqualObjects(userNotification, latestRemoteNotification);
    XCTAssertFalse(userNotification.hasBeenUsedInInfluencedOpen, @"Should not have been marked as used in influenced open.");
    
    userNotification.hasBeenUsedInInfluencedOpen = YES;
    [persistence updateUserNotification:userNotification];
    
    latestRemoteNotification = [[persistence fetchDisplayedRemoteUserNotifications] firstObject];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Remote notification test"];
    
    [persistence fetchUserNotificationCampaignHistory:^(NSArray<MParticleUserNotification *> *userNotificationCampaignHistory) {
        MParticleUserNotification *fetchedRemoteNotification = [userNotificationCampaignHistory lastObject];
        XCTAssertNotNil(fetchedRemoteNotification, @"Fetched remote notification should not have been nil.");
        XCTAssertTrue(fetchedRemoteNotification.hasBeenUsedInInfluencedOpen, @"Should have been marked as used in influenced open.");
        XCTAssertTrue(latestRemoteNotification.hasBeenUsedInInfluencedOpen, @"Should have been marked as used in influenced open.");
        
        [persistence deleteUserNotification:userNotification];
        
        [persistence fetchUserNotificationCampaignHistory:^(NSArray *userNotificationCampaignHistory) {
            MParticleUserNotification *fetchedRemoteNotification = [userNotificationCampaignHistory lastObject];
            XCTAssertNil(fetchedRemoteNotification, @"Remote notification should have been deleted.");
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:DATABASE_TESTS_EXPECATIONS_TIMEOUT handler:nil];
}

- (void)testExpiredRemoteNotification {
    NSDictionary *remoteNotificationDictionary = [self remoteNotificationDictionary:YES];
    
    MParticleUserNotification *userNotification = [[MParticleUserNotification alloc] initWithDictionary:remoteNotificationDictionary
                                                                                       actionIdentifier:nil
                                                                                                  state:kMPPushNotificationStateBackground
                                                                                               behavior:MPUserNotificationBehaviorReceived
                                                                                                   mode:MPUserNotificationModeRemote
                                                                                            runningMode:MPUserNotificationRunningModeBackground];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence saveUserNotification:userNotification];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expired remote notification test"];
    
    [persistence fetchUserNotificationCampaignHistory:^(NSArray<MParticleUserNotification *> *userNotificationCampaignHistory) {
        MParticleUserNotification *fetchedRemoteNotification = [userNotificationCampaignHistory lastObject];
        XCTAssertNil(fetchedRemoteNotification, @"Fetched remote notification should have been nil.");
        
        fetchedRemoteNotification = [[persistence fetchUserNotifications] firstObject];
        XCTAssertNotNil(fetchedRemoteNotification, @"Fetched remote notification should not have been nil.");
        
        [persistence deleteExpiredUserNotifications];
        fetchedRemoteNotification = [[persistence fetchUserNotifications] firstObject];
        XCTAssertNil(fetchedRemoteNotification, @"Fetched remote notification should have been nil.");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:DATABASE_TESTS_EXPECATIONS_TIMEOUT handler:nil];
}

- (void)testNonmParticleRemoteNotification {
    NSDictionary *remoteNotificationDictionary = [self nonmParticleRemoteNotificationDictionary];
    
    MParticleUserNotification *userNotification = [[MParticleUserNotification alloc] initWithDictionary:remoteNotificationDictionary
                                                                                       actionIdentifier:nil
                                                                                                  state:kMPPushNotificationStateBackground
                                                                                               behavior:(MPUserNotificationBehaviorDirectOpen | MPUserNotificationBehaviorRead)
                                                                                                   mode:MPUserNotificationModeRemote
                                                                                            runningMode:MPUserNotificationRunningModeBackground];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence saveUserNotification:userNotification];
    MParticleUserNotification *latestRemoteNotification = [[persistence fetchDisplayedRemoteUserNotifications] firstObject];
    
    if (latestRemoteNotification) {
        XCTAssertNotEqual(userNotification, latestRemoteNotification, @"Non mParticle user notifications should not have been persisted.");
    } else {
        XCTAssertNil(latestRemoteNotification, @"Non mParticle user notifications should not be persisted.");
    }
}

@end

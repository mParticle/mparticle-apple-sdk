//
//  MPDataModelTests.m
//
//  Copyright 2016 mParticle, Inc.
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
#import "MPSession.h"
#import "MPMessage.h"
#import "MPMessageBuilder.h"
#import "MPUpload.h"
#import "MPBreadcrumb.h"
#import "MPSessionHistory.h"
#import "MPStateMachine.h"

@interface MPDataModelTests : XCTestCase

@end

@implementation MPDataModelTests

- (void)setUp {
    [super setUp];
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.apiKey = @"unit_test_app_key";
    stateMachine.secret = @"unit_test_secret";
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSessionInstance {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    XCTAssertNotNil(session, @"Should not have been nil");
    
    MPSession *sessionCopy = [session copy];
    XCTAssertNotNil(sessionCopy, @"Should not have been nil");
    XCTAssertEqualObjects(session, sessionCopy, @"Should have been equal.");
    
    XCTAssertEqual(session.eventCounter, 0, @"Should have been equal.");
    [session incrementCounter];
    XCTAssertEqual(session.eventCounter, 1, @"Should have been equal.");
    
    XCTAssertEqual(session.numberOfInterruptions, 0, @"Should have been equal.");
    [session suspendSession];
    XCTAssertEqual(session.numberOfInterruptions, 1, @"Should have been equal.");
    
    XCTAssertEqual(session.sessionId, 0, @"Should have been equal");
    XCTAssertFalse(session.persisted, @"Should have been false");
    
    XCTAssertNotEqualObjects(session, sessionCopy, @"Should not have been equal.");
    sessionCopy = (MPSession *)[NSNull null];
    XCTAssertNotEqualObjects(session, sessionCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(sessionCopy, session, @"Should not have been equal.");
    sessionCopy = (MPSession *)@"This is not a valid session object.";
    XCTAssertNotEqualObjects(session, sessionCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(sessionCopy, session, @"Should not have been equal.");
    sessionCopy = nil;
    XCTAssertNotEqualObjects(session, sessionCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(sessionCopy, session, @"Should not have been equal.");
}

- (void)testMessageInstance {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    XCTAssertNotNil(messageBuilder, @"Should not have been nil.");
    
    MPMessage *message = (MPMessage *)[messageBuilder build];
    XCTAssertNotNil(message, @"Should not have been nil.");
    
    MPMessage *messageCopy = [message copy];
    XCTAssertNotNil(messageCopy, @"Should not have been nil.");
    XCTAssertEqualObjects(message, messageCopy, @"Should have been equal.");
    messageCopy.timestamp = [[NSDate date] timeIntervalSince1970];
    XCTAssertNotEqualObjects(message, messageCopy, @"Should not have been equal.");

    messageCopy = (MPMessage *)[NSNull null];
    XCTAssertNotEqualObjects(message, messageCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(messageCopy, message, @"Should not have been equal.");
    messageCopy = (MPMessage *)@"This is not a valid message object.";
    XCTAssertNotEqualObjects(message, messageCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(messageCopy, message, @"Should not have been equal.");
    messageCopy = nil;
    XCTAssertNotEqualObjects(message, messageCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(messageCopy, message, @"Should not have been equal.");

    NSData *messageData = [NSKeyedArchiver archivedDataWithRootObject:message];
    XCTAssertNotNil(messageData, @"Should not have been nil.");
    MPMessage *deserializedMessage = [NSKeyedUnarchiver unarchiveObjectWithData:messageData];
    XCTAssertNotNil(deserializedMessage, @"Should not have been nil.");
    XCTAssertEqualObjects(message, deserializedMessage, @"Should have been equal.");
    
    NSDictionary *dictionaryRepresentation = [message dictionaryRepresentation];
    XCTAssertNotNil(dictionaryRepresentation, @"Should not have been nil.");
}

- (void)testUploadInstance {
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
    XCTAssertNotNil(upload, @"Should not have been nil.");
    
    NSString *serializedString = [upload serializedString];
    XCTAssertNotNil(serializedString, @"Should not have been nil.");
    
    MPUpload *uploadCopy = [upload copy];
    XCTAssertNotNil(uploadCopy, @"Should not have been nil.");
    XCTAssertEqualObjects(upload, uploadCopy, @"Should have been equal.");
    
    uploadCopy.timestamp = [[NSDate date] timeIntervalSince1970];
    XCTAssertNotEqualObjects(upload, uploadCopy, @"Should not have been equal.");
    
    uploadCopy = (MPUpload *)[NSNull null];
    XCTAssertNotEqualObjects(upload, uploadCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(uploadCopy, upload, @"Should not have been equal.");
    uploadCopy = (MPUpload *)@"This is not a valid upload object";
    XCTAssertNotEqualObjects(upload, uploadCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(uploadCopy, upload, @"Should not have been equal.");
    uploadCopy = nil;
    XCTAssertNotEqualObjects(upload, uploadCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(uploadCopy, upload, @"Should not have been equal.");
}

- (void)testBreadcrumbInstance {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    MPBreadcrumb *breadcrumb = [[MPBreadcrumb alloc] initWithSessionUUID:session.uuid
                                                            breadcrumbId:0
                                                                    UUID:[[NSUUID UUID] UUIDString]
                                                          breadcrumbData:message.messageData
                                                           sessionNumber:session.sessionNumber
                                                               timestamp:[[NSDate date] timeIntervalSince1970]];
    XCTAssertNotNil(breadcrumb, @"Should not have been nil.");
    
    NSString *description = [breadcrumb description];
    XCTAssertNotNil(description, @"Should not have been nil.");
    
    description = [breadcrumb serializedString];
    XCTAssertNotNil(description, @"Should not have been nil.");
    
    MPBreadcrumb *breadcrumbCopy = [breadcrumb copy];
    XCTAssertNotNil(breadcrumbCopy, @"Should not have been nil.");
    XCTAssertEqualObjects(breadcrumb, breadcrumbCopy, @"Should have been equal.");
    
    breadcrumbCopy.timestamp = [[NSDate date] timeIntervalSince1970];
    XCTAssertNotEqualObjects(breadcrumb, breadcrumbCopy, @"Should not have been equal.");
    
    breadcrumbCopy = (MPBreadcrumb *)[NSNull null];
    XCTAssertNotEqualObjects(breadcrumb, breadcrumbCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(breadcrumbCopy, breadcrumb, @"Should not have been equal.");
    breadcrumbCopy = (MPBreadcrumb *)@"This is not a valid breadcrumb object.";
    XCTAssertNotEqualObjects(breadcrumb, breadcrumbCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(breadcrumbCopy, breadcrumb, @"Should not have been equal.");
    breadcrumbCopy = nil;
    XCTAssertNotEqualObjects(breadcrumb, breadcrumbCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(breadcrumbCopy, breadcrumb, @"Should not have been equal.");
    
    NSData *breadcrumbData = [NSKeyedArchiver archivedDataWithRootObject:breadcrumb];
    XCTAssertNotNil(breadcrumbData, @"Should not have been nil.");
    MPBreadcrumb *deserializedBreadcrumb = [NSKeyedUnarchiver unarchiveObjectWithData:breadcrumbData];
    XCTAssertNotNil(deserializedBreadcrumb, @"Should not have been nil.");
    XCTAssertEqualObjects(breadcrumb, deserializedBreadcrumb, @"Should have been equal.");
    
    NSDictionary *dictionaryRepresentation = [breadcrumb dictionaryRepresentation];
    XCTAssertNotNil(dictionaryRepresentation, @"Should not have been nil.");
}

- (void)testSessionHistory {
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
    
    MPSessionHistory *sessionHistory = [[MPSessionHistory alloc] initWithSession:session uploads:@[upload]];
    sessionHistory.userAttributes = @{@"user":@"attribute"};
    sessionHistory.userIdentities = @[@{@"user":@"identity"}];
    
    XCTAssertNotNil(sessionHistory, @"Should not have been nil.");
    XCTAssertEqualObjects(sessionHistory.session, session, @"Should have been equal.");
    XCTAssertEqual(sessionHistory.uploads.count, 1, @"Should have been equal");
    XCTAssertEqual(sessionHistory.uploadIds.count, 1, @"Should have been equal");
    
    NSArray *expectedKeys = @[@"a", @"ai", @"ct", @"di", @"dt", @"sdk", @"sh", @"sid", @"ua", @"ui"];
    
    NSDictionary *dictionary = [sessionHistory dictionaryRepresentation];
    XCTAssertNotNil(dictionary, @"Should not have been nil.");
    
    NSString *serializedString = [sessionHistory serializedString];
    XCTAssertNotNil(serializedString, @"Should not have been nil.");
    
    for (NSString *key in expectedKeys) {
        XCTAssertNotNil(dictionary[key], @"Should not have been nil.");
        
        NSRange searchRange = [serializedString rangeOfString:key];
        XCTAssertNotEqual(searchRange.location, NSNotFound, @"Should have been different");
    }
    
    sessionHistory.uploads = nil;
    dictionary = [sessionHistory dictionaryRepresentation];
    XCTAssertNotNil(dictionary, @"Should not have been nil.");
    
    serializedString = [sessionHistory serializedString];
    XCTAssertNotNil(serializedString, @"Should not have been nil.");
    
    sessionHistory = [[MPSessionHistory alloc] init];
    XCTAssertNil(sessionHistory, @"Should have been nil.");
}

@end

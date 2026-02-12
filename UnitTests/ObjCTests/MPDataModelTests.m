#import <XCTest/XCTest.h>
#import "MPSession.h"
#import "MPMessage.h"
#import "MPMessageBuilder.h"
#import "MPUpload.h"
#import "MPBreadcrumb.h"
#import "MPStateMachine.h"
#import "MPPersistenceController.h"
#import "MPBaseTestCase.h"
#import "mParticle.h"
#import "MParticleSwift.h"

@interface MParticle ()

@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;

@end

@interface MPDataModelTests : MPBaseTestCase

@end

@implementation MPDataModelTests

- (void)setUp {
    [super setUp];
    
    [MParticle sharedInstance].stateMachine.apiKey = @"unit_test_app_key";
    [MParticle sharedInstance].stateMachine.secret = @"unit_test_secret";
}

- (void)testSessionInstance {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
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
    
    NSString *description = [session description];
    XCTAssertNotNil(description, @"Should not have been nil");
    
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
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    XCTAssertNotNil(messageBuilder, @"Should not have been nil.");
    
    MPMessage *message = [messageBuilder build];
    XCTAssertNotNil(message, @"Should not have been nil.");
    
    NSString *description = [message description];
    XCTAssertNotNil(description, @"Should not have been nil.");
    
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

    NSDictionary *dictionaryRepresentation = [message dictionaryRepresentation];
    XCTAssertNotNil(dictionaryRepresentation, @"Should not have been nil.");
}

- (void)testFixInvalidKeysInDictionary {
    double four = 4.0;
    double zed = 0.0;
    
    NSDictionary *messageInfo = @{@"MessageKey1": @"MessageValue1",
                                  @"MessageKey2": @"MessageValue2"};
    NSMutableDictionary *messageDictionary = messageInfo.mutableCopy;
    [MPMessage fixInvalidKeysInDictionary:messageDictionary messageInfo:messageInfo];
    XCTAssertEqualObjects(messageInfo, messageDictionary);
    
    messageInfo = @{@"MessageKey1": @"MessageValue1",
                    @"MessageKey2": @(four/zed)};
    messageDictionary = messageInfo.mutableCopy;
    [MPMessage fixInvalidKeysInDictionary:messageDictionary messageInfo:messageInfo];
    XCTAssertEqual([messageDictionary objectForKey:@"MessageKey2"], nil);
    XCTAssertEqual([messageDictionary objectForKey:@"MessageKey1"], @"MessageValue1");
    
    messageInfo = @{@"MessageKey1": @"MessageValue1",
                    @"MessageKey2": @{
                        @"NestedKey1": @(four/zed),
                        @"NestedKey2": @"test"}};
    messageDictionary = messageInfo.mutableCopy;
    [MPMessage fixInvalidKeysInDictionary:messageDictionary messageInfo:messageInfo];
    XCTAssertEqual([messageDictionary[@"MessageKey2"] objectForKey:@"NestedKey1"], nil);
    XCTAssertEqual([messageDictionary[@"MessageKey2"] objectForKey:@"NestedKey2"], @"test");

    messageInfo = @{@"MessageKey1": @"MessageValue1",
                    @"MessageKey2": @{
                        @"NestedKey1": @{ @"NestedKeyA": @(four/zed),
                                          @"NestedKeyB": @"test"},
                        @"NestedKey2": @"test"}
                    
    };
    messageDictionary = messageInfo.mutableCopy;
    [MPMessage fixInvalidKeysInDictionary:messageDictionary messageInfo:messageInfo];
    XCTAssertEqual([messageDictionary[@"MessageKey2"][@"NestedKey1"] objectForKey:@"NestedKeyA"], nil);
    XCTAssertEqual([messageDictionary[@"MessageKey2"][@"NestedKey1"] objectForKey:@"NestedKeyB"], @"test");
    
    messageInfo = @{@"MessageKey1": @(four/zed),
                    @"MessageKey2": @{
                        @"NestedKey1": @{ @"NestedKeyA": @(four/zed),
                                          @"NestedKeyB": @"test"},
                        @"NestedKey2": @(four/zed)}};
    messageDictionary = messageInfo.mutableCopy;
    [MPMessage fixInvalidKeysInDictionary:messageDictionary messageInfo:messageInfo];
    XCTAssertEqual([messageDictionary objectForKey:@"MessageKey1"], nil);
    XCTAssertEqual([messageDictionary[@"MessageKey2"] objectForKey:@"NestedKey2"], nil);
    XCTAssertEqual([messageDictionary[@"MessageKey2"][@"NestedKey1"] objectForKey:@"NestedKeyA"], nil);
    XCTAssertEqual([messageDictionary[@"MessageKey2"][@"NestedKey1"] objectForKey:@"NestedKeyB"], @"test");
    
}

- (void)testMessageInstanceWithInfinite {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    double four = 4.0;
    double zed = 0.0;
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":@(four/zed)}];
    XCTAssertNotNil(messageBuilder, @"Should not have been nil.");
    
    MPMessage *message = [messageBuilder build];
    XCTAssertNotNil(message, @"Should not have been nil.");
    
    NSString *description = [message description];
    XCTAssertNotNil(description, @"Should not have been nil.");
    
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

    NSDictionary *dictionaryRepresentation = [message dictionaryRepresentation];
    XCTAssertNotNil(dictionaryRepresentation, @"Should not have been nil.");
}

- (void)testUploadInstance {
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
    XCTAssertNotNil(upload, @"Should not have been nil.");
    
    NSString *description = [upload description];
    XCTAssertNotNil(description, @"Should not have been nil.");
    
    description = [upload serializedString];
    XCTAssertNotNil(description, @"Should not have been nil.");
    
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
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    
    MPBreadcrumb *breadcrumb = [[MPBreadcrumb alloc] initWithSessionUUID:session.uuid
                                                            breadcrumbId:0
                                                                    UUID:[[NSUUID UUID] UUIDString]
                                                          breadcrumbData:message.messageData
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

- (void)testMessageEncoding {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    
    XCTAssertNotNil(message, @"Should not have been nil.");
    
    
    MPMessage *persistedMessage = [self attemptSecureEncodingwithClass:[MPMessage class] Object:message];
    XCTAssertEqualObjects(message, persistedMessage, @"Message should have been a match.");
}

- (void)testBreadcrumbEncoding {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId]];
    
    MPMessageBuilder *messageBuilder = [[MPMessageBuilder alloc] initWithMessageType:MPMessageTypeEvent
                                                                             session:session
                                                                         messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = [messageBuilder build];
    
    MPBreadcrumb *breadcrumb = [[MPBreadcrumb alloc] initWithSessionUUID:session.uuid
                                                            breadcrumbId:0
                                                                    UUID:[[NSUUID UUID] UUIDString]
                                                          breadcrumbData:message.messageData
                                                               timestamp:[[NSDate date] timeIntervalSince1970]];
    XCTAssertNotNil(breadcrumb, @"Should not have been nil.");

    
    MPBreadcrumb *persistedBreadcrumb = [self attemptSecureEncodingwithClass:[MPBreadcrumb class] Object:breadcrumb];
    XCTAssertEqualObjects(breadcrumb, persistedBreadcrumb, @"Breadcrumb should have been a match.");
}

@end

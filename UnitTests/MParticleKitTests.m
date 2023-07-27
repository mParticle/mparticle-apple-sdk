//
//  MParticleKitTests.m
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 7/5/23.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MParticleKit.h"
#import "MPBaseTestCase.h"
#import "MParticle.h"
#import "MPBackendController.h"
#import "MPPersistenceController.h"
#import "MPStateMachine.h"
#import "MPKitContainer.h"
#import "MPMessage.h"
#import "MPIConstants.h"
#import "MPUploadBuilder.h"
#import "MPSession.h"
#import "MPIUserDefaults.h"
#import "MParticleUser.h"
#import "MPUpload.h"
#import "MPDevice.h"
#import "MPEventLogging.h"
#import "MPMediator.h"
#import "MPMessageBuilder.h"

#define MPARTICLEKIT_TESTS_EXPECTATIONS_TIMEOUT 10

#pragma mark - Categories to access internal methods/variables

@interface MPMessage(Tests)
@property (nonatomic, strong, readwrite, nonnull) NSData *messageData;
@end

@interface MParticleUser(Tests)
- (void)setIdentitySync:(NSString *)identityString identityType:(MPIdentity)identityType;
- (void)setUserId:(NSNumber *)userId;
@end

@interface MPIdentityApi(Tests)
@property(nonatomic, strong, readwrite, nonnull) MParticleUser *currentUser;
@end

@interface MParticle(Tests)
@property (nonatomic, strong, readonly) MPMediator *mediator;
@property (nonatomic, strong, nonnull) MPBackendController *backendController;
@property (nonatomic, strong) MPPersistenceController *persistenceController;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong) MPKitContainer *kitContainer;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
+ (dispatch_queue_t)messageQueue;
- (void)handleWebviewCommand:(NSString *)command dictionary:(NSDictionary *)dictionary;
@end

@interface MPBackendController(Tests)
- (void)requestConfig:(void(^ _Nullable)(BOOL uploadBatch))completionHandler;
- (MPExecStatus)checkForKitsAndUploadWithCompletionHandler:(void (^ _Nullable)(BOOL didShortCircuit))completionHandler;
@end

@interface MPKitContainer(Tests)
- (void)registerMParticleKit;
@end

@interface MParticleKit(Tests)
- (NSArray *)batchMessageArraysFromMessageArray:(NSArray *)messages maxBatchMessages:(NSInteger)maxBatchMessages maxBatchBytes:(NSInteger)maxBatchBytes maxMessageBytes:(NSInteger)maxMessageBytes;
@end

#pragma mark - MParticleKitTests

@interface MParticleKitTests : MPBaseTestCase {
    dispatch_queue_t messageQueue;
}
@property (nonatomic, strong) MPBackendController *backendController;
@property (nonatomic, strong) MPSession *session;
@property (nonatomic, strong) MPEventLogging *eventLogging;
@property (nonatomic, strong) MParticleKit *mpKit;
@end

@implementation MParticleKitTests

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
    [[MParticle sharedInstance].kitContainer registerMParticleKit];
    
    MParticle *mParticle = [MParticle sharedInstance];
    mParticle.backendController = [[MPBackendController alloc] initWithDelegate:(id<MPBackendControllerDelegate>)mParticle];
    self.backendController = [MParticle sharedInstance].backendController;
    
    self.eventLogging = mParticle.mediator.eventLogging;
    
    [mParticle.kitContainer registerMParticleKit];
    self.mpKit = [mParticle kitInstance:[MParticleKit kitCode]];
    
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


- (void)testBatchCycle {
    [MParticle sharedInstance].dataPlanId = @"test";
    [MParticle sharedInstance].dataPlanVersion = @(1);

    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPEvent *event = [[MPEvent alloc] initWithName:@"Unit Test Event" type:MPEventTypeOther];
    event.customAttributes = @{@"key":@"value"};
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    [self.eventLogging logEvent:event
              completionHandler:^(MPEvent *event, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
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

    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithMpid:[MPPersistenceController mpId] sessionId:[NSNumber numberWithLong:self->_session.sessionId] messages:messages sessionTimeout:100 uploadInterval:100 dataPlanId:@"test" dataPlanVersion:@(1)];
    XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
    
    [uploadBuilder withUserAttributes:[self.backendController userAttributesForUserId:[MPPersistenceController mpId]] deletedUserAttributes:nil];
    [uploadBuilder withUserIdentities:[self.backendController userIdentitiesForUserId:[MPPersistenceController mpId]]];
    [uploadBuilder build:^(MPUpload *upload) {
        [persistence saveUpload:upload];
        
        NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
        NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
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
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    
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
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    [self.eventLogging logEvent:event
              completionHandler:^(MPEvent *event, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
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

    [MPPersistenceController setMpid:@8];
    [userDefaults setMPObject:[NSDate date] forKey:kMPLastIdentifiedDate userId:@8];
    MParticleUser *newUser = [[MParticleUser alloc] init];
    newUser.userId = @8;
    [MParticle sharedInstance].identity.currentUser = newUser;
    XCTAssertEqualObjects([MParticle sharedInstance].identity.currentUser, newUser);
    XCTAssertNil([MParticle sharedInstance].identity.currentUser.identities[@(MPIdentityIOSAdvertiserId)]);


    MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithMpid:mpid sessionId:[NSNumber numberWithLong:self->_session.sessionId] messages:messages sessionTimeout:100 uploadInterval:100 dataPlanId:@"test" dataPlanVersion:@(1)];
    XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
    
    [uploadBuilder withUserAttributes:[self.backendController userAttributesForUserId:mpid] deletedUserAttributes:nil];
    [uploadBuilder withUserIdentities:[self.backendController userIdentitiesForUserId:mpid]];
    [uploadBuilder build:^(MPUpload *upload) {
        [persistence saveUpload:upload];
        NSDictionary *uploadDictionary = [NSJSONSerialization JSONObjectWithData:upload.uploadData options:0 error:nil];
        XCTAssertEqualObjects(uploadDictionary[kMPDeviceInformationKey][kMPDeviceAdvertiserIdKey], @"bar-id");
    }];
}

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
    [self.eventLogging logCrash:message
                     stackTrace:stackTrace
                  plCrashReport:plCrashReport
              completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
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

- (void)testLoggingCommerceEvent {
    dispatch_sync([MParticle messageQueue], ^{
        [self.backendController beginSession];
    });
    self.session = self.backendController.session;
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionClick];
    commerceEvent.customAttributes = @{@"key":@"value"};
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    [self.eventLogging logBaseEvent:commerceEvent
                  completionHandler:^(MPBaseEvent *event, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
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
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    [self.eventLogging logBaseEvent:event
                  completionHandler:^(MPBaseEvent *event, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
    NSMutableDictionary *dataPlanIdDictionary =  [sessionsDictionary objectForKey:[NSNumber numberWithLong:self->_session.sessionId]];
    NSMutableDictionary *dataPlanVersionDictionary =  [dataPlanIdDictionary objectForKey:@"0"];
    NSArray *messages =  [dataPlanVersionDictionary objectForKey:[NSNumber numberWithInt:0]];
    XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
    
    for (MPMessage *message in messages) {
        XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
        XCTAssertTrue(![message.messageType isEqualToString:kMPMessageTypeStringUnknown], @"MPBaseEvent messages are being logged to server.");
    }
}

- (void)testSetLocation {
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    CLLocation *location = [[CLLocation alloc] initWithLatitude:40.738526 longitude:-73.98738];
    [MParticle sharedInstance].stateMachine.location = location;
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Unit Test Event" type:MPEventTypeOther];
    event.shouldBeginSession = NO;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Set location"];
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    [self.eventLogging logEvent:event
              completionHandler:^(MPEvent *event, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
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
    
    [self waitForExpectationsWithTimeout:MPARTICLEKIT_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
#endif
#endif
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
    [self.eventLogging logCrash:message
                     stackTrace:stackTrace
                  plCrashReport:plCrashReport
              completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
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
    [self.eventLogging logCrash:message
                     stackTrace:stackTrace
                  plCrashReport:plCrashReport
              completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
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
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    NSString *message = @"crash report";
    NSString *stackTrace = @"stack track from crash report";
    NSString *plCrashReport = nil;
    [self.eventLogging logCrash:message
                     stackTrace:stackTrace
                  plCrashReport:plCrashReport
              completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
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
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    NSString *message = @"crash report";
    NSString *stackTrace = @"stack track from crash report";
    NSString *plCrashReport = @"a";
    while (plCrashReport.length < [MPPersistenceController maxBytesPerEvent:kMPMessageTypeStringCrashReport]) {
        plCrashReport = [NSString stringWithFormat:@"%@%@", plCrashReport, plCrashReport];
    }
    
    [self.eventLogging logCrash:message
                     stackTrace:stackTrace
                  plCrashReport:plCrashReport
              completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
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
    MPStateMachine *stateMachine = [[MPStateMachine alloc] init];
    id mockStateMachine = OCMPartialMock(stateMachine);
    
    [[[mockStateMachine stub] andReturnValue:OCMOCK_VALUE(@7)] crashMaxPLReportLength];
 
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockStateMachine] stateMachine];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    NSString *expectedResult = @"plcrash";
    NSData *data = [NSData dataWithBytes:expectedResult.UTF8String length:expectedResult.length];
    NSString *plCrashReportBase64 = [data base64EncodedStringWithOptions:0];
    [self.eventLogging logCrash:message
                     stackTrace:stackTrace
                  plCrashReport:plCrashReport
              completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
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
    MPStateMachine *stateMachine = [[MPStateMachine alloc] init];
    id mockStateMachine = OCMPartialMock(stateMachine);
    
    [[[(id)mockStateMachine stub] andReturn:nil] crashMaxPLReportLength];
 
    MParticle *instance = [MParticle sharedInstance];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockStateMachine] stateMachine];
    [[[mockInstance stub] andReturn:mockInstance] sharedInstance];
    
    NSData *data = [NSData dataWithBytes:plCrashReport.UTF8String length:plCrashReport.length];
    NSString *plCrashReportBase64 = [data base64EncodedStringWithOptions:0];
    [self.eventLogging logCrash:message
                     stackTrace:stackTrace
                  plCrashReport:plCrashReport
              completionHandler:^(NSString * _Nullable message, MPExecStatus execStatus) {}];
    
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    NSDictionary *messagesDictionary = [persistence fetchMessagesForUploading];
    NSMutableDictionary *sessionsDictionary = messagesDictionary[[MPPersistenceController mpId]];
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

#pragma mark Web View Tests

#if TARGET_OS_IOS == 1

- (void)testWebviewLogEvent {
    id mockEventLogging = OCMClassMock([MPEventLogging class]);
    
    MPEvent *testEvent = [[MPEvent alloc] initWithName:@"foo webview event 1" type:MPEventTypeNavigation];
    testEvent.customAttributes = @{@"foo webview event attribute 1":@"foo webview event attribute value 1"};
    [testEvent addCustomFlags:@[@"test1", @"test2"] withKey:@"testKeys"];
    
    [[[mockEventLogging expect] ignoringNonObjectArgs] logEvent:[OCMArg checkWithBlock:^BOOL(id value) {
        XCTAssert([value isKindOfClass:[MPEvent class]]);
        MPEvent *returnedEvent = ((MPEvent *)value);
        XCTAssertEqualObjects(returnedEvent.name, testEvent.name);
        XCTAssertEqual(returnedEvent.type, testEvent.type);
        XCTAssertEqualObjects(returnedEvent.customAttributes, testEvent.customAttributes);
        XCTAssertEqualObjects(returnedEvent.customFlags, testEvent.customFlags);
        
        return YES;
    }] completionHandler:[OCMArg any]];
    
    MPMediator *mediator = [[MPMediator alloc] init];
    id mockMediator = OCMPartialMock(mediator);
    [[[mockMediator stub] andReturn:mockEventLogging] eventLogging];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockMediator] mediator];
    
    NSString *command = @"logEvent";
    NSDictionary *dictionary = @{@"EventDataType":@(MPJavascriptMessageTypePageEvent), @"EventName":@"foo webview event 1", @"EventCategory":@(MPEventTypeNavigation), @"CustomFlags":@{@"testKeys":@[@"test1", @"test2"]}, @"EventAttributes":@{@"foo webview event attribute 1":@"foo webview event attribute value 1"}};
    [instance handleWebviewCommand:command dictionary:dictionary];
    
    [mockEventLogging verifyWithDelay:5];
}

- (void)testWebviewLogScreenEvent {
    id mockEventLogging = OCMClassMock([MPEventLogging class]);

    MPEvent *testEvent = [[MPEvent alloc] initWithName:@"foo Page View" type:MPEventTypeNavigation];
    testEvent.customAttributes = @{@"foo webview event attribute 1":@"foo webview event attribute value 1"};
    [testEvent addCustomFlag:@"test1" withKey:@"testKeys"];

    [[[mockEventLogging expect] ignoringNonObjectArgs] logScreen:[OCMArg checkWithBlock:^BOOL(id value) {
        XCTAssert([value isKindOfClass:[MPEvent class]]);
        MPEvent *returnedEvent = ((MPEvent *)value);
        XCTAssertEqualObjects(returnedEvent.name, testEvent.name);
        XCTAssertEqual(returnedEvent.type, testEvent.type);
        XCTAssertEqualObjects(returnedEvent.customAttributes, testEvent.customAttributes);
        XCTAssertEqualObjects(returnedEvent.customFlags, testEvent.customFlags);

        return YES;
    }] completionHandler:[OCMArg any]];

    MPMediator *mediator = [[MPMediator alloc] init];
    id mockMediator = OCMPartialMock(mediator);
    [[[mockMediator stub] andReturn:mockEventLogging] eventLogging];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockMediator] mediator];

    NSString *command = @"logEvent";
    NSDictionary *dictionary = @{@"EventDataType":@(MPJavascriptMessageTypePageView), @"EventName":@"foo Page View", @"EventCategory":@(MPEventTypeNavigation), @"CustomFlags":@{@"testKeys":@[@"test1"]}, @"EventAttributes":@{@"foo webview event attribute 1":@"foo webview event attribute value 1"}};
    [instance handleWebviewCommand:command dictionary:dictionary];

    [mockEventLogging verifyWithDelay:5];
}

- (void)testWebviewLogCommerceAttributes {
    id mockEventLogging = OCMClassMock([MPEventLogging class]);

    MPProduct *testProduct = [[MPProduct alloc] initWithName:@"foo product 1" sku:@"12345" quantity:@1 price:@19.95];
    MPCommerceEvent *testEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:testProduct];
    testEvent.customAttributes = @{@"foo webview event attribute 1":@"foo webview event attribute value 1"};

    [[[mockEventLogging expect] ignoringNonObjectArgs] logCommerceEvent:[OCMArg checkWithBlock:^BOOL(id value) {
        XCTAssert([value isKindOfClass:[MPCommerceEvent class]]);
        MPCommerceEvent *returnedEvent = ((MPCommerceEvent *)value);
        XCTAssertEqualObjects(returnedEvent.products[0].name, testProduct.name);
        XCTAssertEqualObjects(returnedEvent.products[0].sku, testProduct.sku);
        XCTAssertEqualObjects(returnedEvent.products[0].quantity, testProduct.quantity);
        XCTAssertEqualObjects(returnedEvent.products[0].price, testProduct.price);
        XCTAssertEqualObjects(returnedEvent.customAttributes, testEvent.customAttributes);

        return YES;
    }] completionHandler:[OCMArg any]];

    MPMediator *mediator = [[MPMediator alloc] init];
    id mockMediator = OCMPartialMock(mediator);
    [[[mockMediator stub] andReturn:mockEventLogging] eventLogging];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockMediator] mediator];

    NSString *command = @"logEvent";
    NSDictionary *dictionary = @{
        @"EventDataType":@(MPJavascriptMessageTypeCommerce),
        @"ProductAction":@{
                @"ProductActionType":@0,
                @"ProductList":@[
                        @{
                            @"Name":@"foo product 1",
                            @"Sku":@"12345",
                            @"Quantity":@1,
                            @"Price": @19.95
                        }
                ]
        },
        @"EventAttributes":@{
                @"foo webview event attribute 1":@"foo webview event attribute value 1"
        }
    };
    [instance handleWebviewCommand:command dictionary:dictionary];

    [mockEventLogging verifyWithDelay:5];
}

- (void)testWebviewLogCommerceInvalidArray {
    id mockEventLogging = OCMClassMock([MPEventLogging class]);

    [[mockEventLogging reject] logCommerceEvent:[OCMArg any] completionHandler:[OCMArg any]];

    MPMediator *mediator = [[MPMediator alloc] init];
    id mockMediator = OCMPartialMock(mediator);
    [[[mockMediator stub] andReturn:mockEventLogging] eventLogging];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockMediator] mediator];

    NSString *command = @"logEvent";
    NSDictionary *dictionary = (NSDictionary *)@[
        @{
            @"EventDataType":@(MPJavascriptMessageTypeCommerce),
            @"ProductAction":@{
                    @"ProductActionType":@0,
                    @"ProductList":@[
                            @{
                                @"Name":@"foo product 1",
                                @"Sku":@"12345",
                                @"Quantity":@1,
                                @"Price": @19.95
                            }
                    ]
            },
            @"EventAttributes":@{
                    @"foo webview event attribute 1":@"foo webview event attribute value 1"
            }
        }];
    [instance handleWebviewCommand:command dictionary:dictionary];

    [mockEventLogging verifyWithDelay:5];
}

- (void)testWebviewLogCommerceInvalidArrayValues {
    id mockEventLogging = OCMClassMock([MPEventLogging class]);

    [[mockEventLogging reject] logCommerceEvent:[OCMArg any] completionHandler:[OCMArg any]];

    MPMediator *mediator = [[MPMediator alloc] init];
    id mockMediator = OCMPartialMock(mediator);
    [[[mockMediator stub] andReturn:mockEventLogging] eventLogging];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockMediator] mediator];


    NSString *command = @"logEvent";
    NSDictionary *dictionary = @{
            @"EventDataType":@(MPJavascriptMessageTypeCommerce),
            @"ProductAction":@{
                    @"ProductActionType":@[],
                    @"ProductList":@[
                            @{
                                @"Name":@[],
                                @"Sku":@[],
                                @"Quantity":@[],
                                @"Price": @[]
                            }
                    ]
            },
            @"EventAttributes":@{
                    @"foo webview event attribute 1":@[]
            }
        };
    [instance handleWebviewCommand:command dictionary:dictionary];

    [mockEventLogging verifyWithDelay:5];
}

- (void)testWebviewLogCommerceNull {
    id mockEventLogging = OCMClassMock([MPEventLogging class]);

    [[[mockEventLogging expect] ignoringNonObjectArgs] logCommerceEvent:[OCMArg checkWithBlock:^BOOL(id value) {
        XCTAssert([value isKindOfClass:[MPCommerceEvent class]]);
        MPCommerceEvent *returnedEvent = ((MPCommerceEvent *)value);
        XCTAssertNotEqual((NSNull *)returnedEvent.currency, [NSNull null]);

        return YES;
    }] completionHandler:[OCMArg any]];

    MPMediator *mediator = [[MPMediator alloc] init];
    id mockMediator = OCMPartialMock(mediator);
    [[[mockMediator stub] andReturn:mockEventLogging] eventLogging];
    
    MParticle *instance = [[MParticle alloc] init];
    id mockInstance = OCMPartialMock(instance);
    [[[mockInstance stub] andReturn:mockMediator] mediator];

    NSString *command = @"logEvent";
    NSDictionary *dictionary = @{
        @"EventDataType":@(MPJavascriptMessageTypeCommerce),
        @"ProductAction":@{
                @"ProductActionType":@0,
                @"ProductList":@[
                        @{
                            @"Name":@"foo product 1",
                            @"Sku":@"12345",
                            @"Quantity":@1,
                            @"Price": @19.95
                        }
                ]
        },
        @"CurrencyCode":[NSNull null],
        @"EventAttributes":@{
                @"foo webview event attribute 1":@"foo webview event attribute value 1"
        }
    };

    [instance handleWebviewCommand:command dictionary:dictionary];

    [mockEventLogging verifyWithDelay:5];
}

#endif

#pragma mark Batch Tests

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
        
    NSArray *batchArrays = [self.mpKit batchMessageArraysFromMessageArray:unlimitedMessages maxBatchMessages:1 maxBatchBytes:NSIntegerMax maxMessageBytes:NSIntegerMax];
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

    NSArray *batchArrays = [self.mpKit batchMessageArraysFromMessageArray:unlimitedMessages maxBatchMessages:2 maxBatchBytes:NSIntegerMax maxMessageBytes:NSIntegerMax];
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

    NSArray *batchArrays = [self.mpKit batchMessageArraysFromMessageArray:unlimitedMessages maxBatchMessages:NSIntegerMax maxBatchBytes:message.messageData.length*3 maxMessageBytes:NSIntegerMax];
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

    NSArray *batchArrays = [self.mpKit batchMessageArraysFromMessageArray:unlimitedMessages maxBatchMessages:NSIntegerMax maxBatchBytes:NSIntegerMax maxMessageBytes:message.messageData.length-1];
    XCTAssertEqual(batchArrays.count, 0);

    batchArrays = [self.mpKit batchMessageArraysFromMessageArray:unlimitedMessages maxBatchMessages:NSIntegerMax maxBatchBytes:NSIntegerMax maxMessageBytes:message.messageData.length];
    XCTAssertEqual(batchArrays.count, 1);
    XCTAssertEqual(((NSArray *)batchArrays[0]).count, 10);


    batchArrays = [self.mpKit batchMessageArraysFromMessageArray:unlimitedMessages maxBatchMessages:NSIntegerMax maxBatchBytes:message.messageData.length maxMessageBytes:NSIntegerMax];
    XCTAssertEqual(batchArrays.count, 10);
    for (int i=0; i<10; i++) {
        XCTAssertEqual(((NSArray *)batchArrays[i]).count, 1);
    }

}

- (MPMessage *)messageWithType:(MPMessageType)type andLength:(NSInteger)length {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    NSString *longString = @"a";
    while (longString.length < length) {
        longString = [NSString stringWithFormat:@"%@%@", longString, longString];
    }
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:type
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

    NSArray *batchArrays = [self.mpKit batchMessageArraysFromMessageArray:unlimitedMessages
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

    NSArray *batchArrays = [self.mpKit batchMessageArraysFromMessageArray:unlimitedMessages
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

    NSArray *batchArrays = [self.mpKit batchMessageArraysFromMessageArray:unlimitedMessages
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

    NSArray *batchArrays = [self.mpKit batchMessageArraysFromMessageArray:unlimitedMessages
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
    id mockMpKit = OCMPartialMock(self.mpKit);
    [[mockMpKit reject] uploadBatchesWithCompletionHandler:[OCMArg any]];

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

@end

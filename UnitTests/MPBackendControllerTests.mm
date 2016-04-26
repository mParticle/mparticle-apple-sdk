//
//  MPBackendControllerTests.mm
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
#import "MPBackendController+Tests.h"
#import "MPIConstants.h"
#import "MPSession.h"
#import "MPStateMachine.h"
#import "MPPersistenceController.h"
#import "MPMessage.h"
#import <CoreLocation/CoreLocation.h>
#import "MPUpload.h"
#import "MPNotificationController.h"
#import "MPEvent.h"
#import "MParticleUserNotification.h"
#import "MPMediaTrackContainer.h"
#import "MPMediaTrack.h"
#import "MPMediaTrack+Internal.h"
#import "MPUploadBuilder.h"
#import "MPMessageBuilder.h"

#define BACKEND_TESTS_EXPECATIONS_TIMEOUT 1

@interface MPBackendControllerTests : XCTestCase <MPBackendControllerDelegate>

@property (nonatomic, strong) MPBackendController *backendController;
@property (nonatomic, strong) MPSession *session;
@property (nonatomic, strong) MPNotificationController *notificationController;

@end

@implementation MPBackendControllerTests

- (void)setUp {
    [super setUp];
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.apiKey = @"unit_test_app_key";
    stateMachine.secret = @"unit_test_secret";

    [self addObserver:self forKeyPath:@"backendController.session" options:NSKeyValueObservingOptionNew context:NULL];
    
    [[MPPersistenceController sharedInstance] openDatabase];
    [self.backendController setInitializationStatus:MPInitializationStatusStarted];
    [self.backendController beginSession:^(MPSession *session, MPSession *previousSession, MPExecStatus execStatus) {
        _session = session;
    }];
    
    [self notificationController];
}

- (void)tearDown {
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    [persistence deleteRecordsOlderThan:[[NSDate date] timeIntervalSince1970]];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tear down"];
    
    [persistence fetchSessions:^(NSMutableArray *sessions) {
        for (MPSession *session in sessions) {
            [persistence deleteSession:session];
        }
        
        [persistence fetchSessions:^(NSMutableArray *sessions) {
            XCTAssertEqual(sessions.count, 0, @"Sessions have not been deleted.");
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECATIONS_TIMEOUT handler:nil];
    
    [persistence closeDatabase];
    
    [self removeObserver:self forKeyPath:@"backendController.session" context:NULL];
    
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
                                                           },
                                                   @"m_cmd":@1,
                                                   @"m_cid":@2,
                                                   @"m_cntid":@3,
                                                   @"m_expy":MPMilliseconds([[NSDate date] timeIntervalSince1970] + 100),
                                                   @"m_uid":@(arc4random_uniform(INT_MAX))
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
    
    _session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    return _session;
}

- (NSDictionary *)silentNotificationDictionary {
    NSDictionary *silentNotificationDictionary = @{@"aps":@{
                                                           @"content-available":@1,
                                                           @"sound":@""
                                                           }
                                                   };
    
    return silentNotificationDictionary;
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
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [persistence fetchSessions:^(NSMutableArray *sessions) {
        MPSession *session = [sessions lastObject];
        
        XCTAssertEqualObjects(session, self.session, @"Sessions are not equal.");
        
        [persistence fetchMessagesForUploadingInSession:session
                                      completionHandler:^(NSArray *messages) {
                                          MPMessage *message = [messages lastObject];
                                          
                                          XCTAssertEqualObjects(message.messageType, @"ss", @"Message tipe is not session start.");
                                          
                                          [expectation fulfill];
                                      }];
    }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECATIONS_TIMEOUT handler:nil];
}

- (void)testEndSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"End session test"];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [persistence fetchSessions:^(NSMutableArray *sessions) {
        MPSession *session = [sessions lastObject];
        MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
        XCTAssertEqualObjects(session, stateMachine.currentSession, @"Current session and last session in the database are not equal.");
        
        [persistence fetchMessagesForUploadingInSession:session
                                      completionHandler:^(NSArray *messages) {
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
                                          
                                          [persistence fetchMessagesForUploadingInSession:session
                                                                        completionHandler:^(NSArray *messages) {
                                                                            NSUInteger endSessionCount = 0;
                                                                            for (MPMessage *message in messages) {
                                                                                if ([message.messageType isEqualToString:@"se"]) {
                                                                                    ++endSessionCount;
                                                                                }
                                                                            }
                                                                            
                                                                            XCTAssertEqual(endSessionCount, 1, @"Logging session end multiple times.");
                                                                            
                                                                            [persistence deletePreviousSession];
                                                                            
                                                                            [persistence fetchPreviousSession:^(MPSession *previousSession) {
                                                                                XCTAssertNil(previousSession, @"Previous session is not being removed.");
                                                                                
                                                                                [expectation fulfill];
                                                                            }];
                                                                        }];
                                      }];
    }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECATIONS_TIMEOUT handler:nil];
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
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [self.backendController logEvent:event
                             attempt:0
                   completionHandler:^(MPEvent *event, MPExecStatus execStatus) {}];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [persistence fetchMessagesForUploadingInSession:self.session
                                      completionHandler:^(NSArray *messages) {
                                          NSLog(@"messages.count: %d", (int)messages.count);
                                          XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
                                          
                                          for (MPMessage *message in messages) {
                                              XCTAssertTrue(message.uploadStatus != MPUploadStatusUploaded, @"Messages are being prematurely being marked as uploaded.");
                                          }
                                          
                                          MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithSession:self.session messages:messages sessionTimeout:100 uploadInterval:100];
                                          XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
                                          
                                          if (!uploadBuilder) {
                                              return;
                                          }
                                          
                                          [uploadBuilder withUserAttributes:self.backendController.userAttributes deletedUserAttributes:nil];
                                          [uploadBuilder withUserIdentities:self.backendController.userIdentities];
                                          [uploadBuilder build:^(MPDataModelAbstract *upload) {
                                              [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationFlag];
                                              
                                              NSArray *messages = [persistence fetchMessagesInSession:self.session];
                                              
                                              XCTAssertNotNil(messages, @"There are no messages in session.");
                                              
                                              for (MPMessage *message in messages) {
                                                  XCTAssertTrue(message.uploadStatus == MPUploadStatusUploaded, @"Messages are not being marked as uploaded.");
                                              }
                                              
                                              [persistence fetchUploadsInSession:self.session
                                                               completionHandler:^(NSArray *uploads) {
                                                                   XCTAssertGreaterThan(uploads.count, 0, @"Messages are not being transfered to the Uploads table.");
                                                                   
                                                                   for (MPUpload *upload in uploads) {
                                                                       [persistence deleteUpload:upload];
                                                                   }
                                                                   
                                                                   [persistence fetchUploadsInSession:self.session
                                                                                    completionHandler:^(NSArray *uploads) {
                                                                                        XCTAssertNil(uploads, @"Uploads are not being deleted.");
                                                                                        
                                                                                        [expectation fulfill];
                                                                                    }];
                                                               }];
                                          }];
                                      }];
    });
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECATIONS_TIMEOUT handler:nil];
}

- (void)testRampUpload {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:@{@"MessageKey1":@"MessageValue1"}];
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    [persistence saveMessage:message];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Ramp upload test"];
    
    [persistence fetchMessagesForUploadingInSession:session
                                  completionHandler:^(NSArray *persistedMessages) {
                                      MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithSession:session messages:persistedMessages sessionTimeout:100 uploadInterval:100];
                                      XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
                                      
                                      if (!uploadBuilder) {
                                          return;
                                      }
                                      
                                      [uploadBuilder withUserAttributes:self.backendController.userAttributes deletedUserAttributes:nil];
                                      [uploadBuilder withUserIdentities:self.backendController.userIdentities];
                                      [uploadBuilder build:^(MPDataModelAbstract *upload) {
                                          [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationFlag];
                                          
                                          [persistence fetchUploadsInSession:session
                                                           completionHandler:^(NSArray *uploads) {
                                                               XCTAssertGreaterThan(uploads.count, 0, @"Failed to retrieve messages to be uploaded.");
                                                               
                                                               MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
                                                               [stateMachine configureRampPercentage:@100];
                                                               
                                                               XCTAssertFalse(stateMachine.dataRamped, @"Data ramp is not respecting 100 percent upper limit.");
                                                               
                                                               for (MPUpload *upload in uploads) {
                                                                   [persistence deleteUpload:upload];
                                                               }
                                                               
                                                               [persistence fetchUploadsInSession:session
                                                                                completionHandler:^(NSArray *uploads) {
                                                                                    XCTAssertNil(uploads, @"Not deleting ramped upload messages.");
                                                                                    
                                                                                    [persistence fetchUploadedMessagesInSession:session
                                                                                              excludeNetworkPerformanceMessages:NO
                                                                                                              completionHandler:^(NSArray *persistedMessages) {
                                                                                                                  MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithSession:self.session messages:persistedMessages sessionTimeout:100 uploadInterval:100];
                                                                                                                  XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
                                                                                                                  
                                                                                                                  if (!uploadBuilder) {
                                                                                                                      return;
                                                                                                                  }
                                                                                                                  
                                                                                                                  [uploadBuilder withUserAttributes:self.backendController.userAttributes deletedUserAttributes:nil];
                                                                                                                  [uploadBuilder withUserIdentities:self.backendController.userIdentities];
                                                                                                                  [uploadBuilder build:^(MPDataModelAbstract *upload) {
                                                                                                                      [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationDelete];
                                                                                                                      
                                                                                                                      [persistence fetchUploadedMessagesInSession:session
                                                                                                                                excludeNetworkPerformanceMessages:NO
                                                                                                                                                completionHandler:^(NSArray *persistedMessages) {
                                                                                                                                                    XCTAssertNil(persistedMessages, @"Messages are not being deleted are being moved to the uploads table.");
                                                                                                                                                    
                                                                                                                                                    [expectation fulfill];
                                                                                                                                                }];
                                                                                                                  }];
                                                                                                              }];
                                                                                }];
                                                           }];
                                      }];
                                  }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECATIONS_TIMEOUT handler:nil];
}

#if TARGET_OS_IOS == 1
- (void)testLogInteractionWithAction {
    [self backendController];
    
    NSDictionary *remoteNotificationDictionary = @{kMPUserNotificationDictionaryKey:[self remoteNotificationDictionary],
                                                   kMPUserNotificationActionKey:@"DINO_CAB_ACTION_IDENTIFIER",
                                                   kMPPushNotificationActionTileKey:@"Dino Cab"};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMPRemoteNotificationReceivedNotification
                                                        object:self
                                                      userInfo:remoteNotificationDictionary];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Log interaction with action test"];
    
    [[MPPersistenceController sharedInstance] fetchMessagesForUploadingInSession:self.session
                                                               completionHandler:^(NSArray *messages) {
                                                                   BOOL containsPushNotificationMessage = NO;
                                                                   if (messages) {
                                                                       for (MPMessage *message in messages) {
                                                                           if ([message.messageType isEqualToString:@"pm"]) {
                                                                               containsPushNotificationMessage = YES;
                                                                               NSDictionary *messageDictionary = [message dictionaryRepresentation];
                                                                               
                                                                               XCTAssertNotNil(messageDictionary, @"Not able to deserialize message dictionary.");
                                                                               XCTAssertEqualObjects(messageDictionary[kMPPushMessageTypeKey], kMPPushMessageAction, @"Type should have been 'action.'");
                                                                               XCTAssertNotNil(messageDictionary[kMPPushNotificationActionIdentifierKey], @"Action identifier is not being set.");
                                                                               XCTAssertEqualObjects(messageDictionary[kMPPushNotificationActionIdentifierKey], @"DINO_CAB_ACTION_IDENTIFIER", @"Action identifier is being set incorrectly.");
                                                                               XCTAssertEqualObjects(messageDictionary[kMPPushNotificationBehaviorKey], @(MPUserNotificationBehaviorRead | MPUserNotificationBehaviorReceived), @"Behavior should have been '1 << 2 | 1 << 0.'");
                                                                           }
                                                                       }
                                                                       
                                                                       XCTAssertTrue(containsPushNotificationMessage, @"Not logging interaction with received remote notifications.");
                                                                   }
                                                                   
                                                                   [expectation fulfill];
                                                               }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECATIONS_TIMEOUT handler:nil];
}

- (void)testLogSilentNotification {
    [self backendController];
    [self notificationController];
    
    NSDictionary *remoteNotificationDictionary = @{kMPUserNotificationDictionaryKey:[self silentNotificationDictionary]};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMPRemoteNotificationReceivedNotification
                                                        object:self
                                                      userInfo:remoteNotificationDictionary];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Log silent notification test"];
    
    [[MPPersistenceController sharedInstance] fetchMessagesForUploadingInSession:self.session
                                                               completionHandler:^(NSArray *messages) {
                                                                   XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
                                                                   
                                                                   BOOL containsPushNotificationMessage = NO;
                                                                   MPMessage *message;
                                                                   for (message in messages) {
                                                                       if ([message.messageType isEqualToString:@"pm"]) {
                                                                           containsPushNotificationMessage = YES;
                                                                           NSDictionary *messageDictionary = [message dictionaryRepresentation];
                                                                           
                                                                           XCTAssertEqualObjects(messageDictionary[kMPPushMessageTypeKey], kMPPushMessageReceived, @"Type should have been 'received.'");
                                                                           XCTAssertNil(messageDictionary[kMPPushNotificationActionIdentifierKey], @"Action should not have been set.");
                                                                           XCTAssertEqualObjects(messageDictionary[kMPPushNotificationBehaviorKey], @(MPUserNotificationBehaviorReceived | MPUserNotificationBehaviorDisplayed), @"Behavior should have been '1 << 4 | 1 << 0.'");
                                                                           
                                                                           NSString *messageString = messageDictionary[kMPPushMessagePayloadKey];
                                                                           NSArray *pushComponents = @[@"aps", @"content-available", @"sound"];
                                                                           for (NSString *pushComponent in pushComponents) {
                                                                               NSRange pushRange = [messageString rangeOfString:pushComponent];
                                                                               XCTAssertNotEqual(pushRange.location, NSNotFound, @"Silent notification payload component %@ is not part of the message.", pushComponent);
                                                                           }
                                                                       }
                                                                   }
                                                                   
                                                                   XCTAssertTrue(containsPushNotificationMessage, @"Not logging received silent notifications.");
                                                                   
                                                                   [expectation fulfill];
                                                               }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECATIONS_TIMEOUT handler:nil];
}

- (void)testLogNonmParticleRemoteNotification {
    [self backendController];
    [self notificationController];
    
    NSDictionary *remoteNotificationDictionary = @{kMPUserNotificationDictionaryKey:[self nonmParticleRemoteNotificationDictionary]};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMPRemoteNotificationReceivedNotification
                                                        object:self
                                                      userInfo:remoteNotificationDictionary];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Log non mParticle remote notification test"];
    
    [[MPPersistenceController sharedInstance] fetchMessagesForUploadingInSession:self.session
                                                               completionHandler:^(NSArray *messages) {
                                                                   XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
                                                                   
                                                                   BOOL containsPushNotificationMessage = NO;
                                                                   MPMessage *message;
                                                                   for (message in messages) {
                                                                       if ([message.messageType isEqualToString:@"pm"]) {
                                                                           containsPushNotificationMessage = YES;
                                                                           NSDictionary *messageDictionary = [message dictionaryRepresentation];
                                                                           
                                                                           XCTAssertEqualObjects(messageDictionary[kMPPushMessageTypeKey], kMPPushMessageReceived, @"Type should have been 'received.'");
                                                                           XCTAssertNil(messageDictionary[kMPPushNotificationActionIdentifierKey], @"Action should not have been set.");
                                                                           XCTAssertEqualObjects(messageDictionary[kMPPushNotificationBehaviorKey], @(MPUserNotificationBehaviorReceived | MPUserNotificationBehaviorDisplayed), @"Behavior should have been '1 << 4 | 1 << 0.'");
                                                                           
                                                                           NSString *messageString = messageDictionary[kMPPushMessagePayloadKey];
                                                                           NSArray *pushComponents = @[@"aps", @"alert", @"badge", @"sound"];
                                                                           for (NSString *pushComponent in pushComponents) {
                                                                               NSRange pushRange = [messageString rangeOfString:pushComponent];
                                                                               XCTAssertNotEqual(pushRange.location, NSNotFound, @"Push notification payload component %@ is not part of the message.", pushComponent);
                                                                           }
                                                                       }
                                                                   }
                                                                   
                                                                   XCTAssertTrue(containsPushNotificationMessage, @"Not logging received push notifications upon launch.");
                                                                   
                                                                   [expectation fulfill];
                                                               }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECATIONS_TIMEOUT handler:nil];
}
#endif

- (void)testDidBecomeActiveWithAppLink {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    NSURL *url = [NSURL URLWithString:@"fb487730798014455://applinks?al_applink_data=%7B%22user_agent%22%3A%22Bolts%20iOS%201.0.0%22%2C%22target_url%22%3A%22http%3A%5C%2F%5C%2Fexample.com%5C%2Fapplinks%22%2C%22extras%22%3A%7B%22myapp_token%22%3A%22t0kEn%22%7D%7D"];
    NSString *sourceApplication = @"com.mParticle.UnitTest";
    NSDictionary *annotation = @{@"foo":@"bar"};
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    [self.backendController forceAppFinishedLaunching];
    [self.backendController handleApplicationDidBecomeActive:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Did become active with AppLink test"];
    
    [[MPPersistenceController sharedInstance] fetchMessagesForUploadingInSession:self.session
                                                               completionHandler:^(NSArray *messages) {
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
                                                                           
                                                                           testRange = [messageString rangeOfString:@"\"lpr\":{\"foo\":\"bar\"}"];
                                                                           XCTAssertNotEqual(testRange.location, NSNotFound, @"Launch parameters are not present.");
                                                                       }
                                                                   }
                                                                   
                                                                   [expectation fulfill];
                                                               }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECATIONS_TIMEOUT handler:nil];
}

- (void)testDidBecomeActive {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    NSURL *url = [NSURL URLWithString:@"particlebox://unit_test"];
    NSString *sourceApplication = @"com.mParticle.UnitTest";
    NSDictionary *annotation = @{@"key1":@1, @"key2":[NSDate date]};
    
    stateMachine.launchInfo = [[MPLaunchInfo alloc] initWithURL:url
                                              sourceApplication:sourceApplication
                                                     annotation:annotation];
    
    [self.backendController forceAppFinishedLaunching];
    [self.backendController handleApplicationDidBecomeActive:nil];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Did become active test"];
    
    [[MPPersistenceController sharedInstance] fetchMessagesForUploadingInSession:self.session
                                                               completionHandler:^(NSArray *messages) {
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
                                                                           
                                                                           testRange = [messageString rangeOfString:@"\"lpr\":{\"key1\":1}"];
                                                                           XCTAssertNotEqual(testRange.location, NSNotFound, @"Launch parameters are not present.");
                                                                           
                                                                           testRange = [messageString rangeOfString:@"key2"];
                                                                           XCTAssertEqual(testRange.location, NSNotFound, @"Not filtering launch parameters.");
                                                                       }
                                                                   }
                                                                   
                                                                   [expectation fulfill];
                                                               }];
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECATIONS_TIMEOUT handler:nil];
}

- (void)testSessionEventCounter {
    MPSession *session = [self.session copy];
    
    XCTAssertEqualObjects(session, self.session, @"Session instances are not being copied correctly.");
    
    NSUInteger upperLimit = EVENT_LIMIT + 1;
    for (NSUInteger i = 0; i != upperLimit; ++i) {
        [self.session incrementCounter];
    }
    
    XCTAssertNotEqualObjects(session, self.session, @"New session has not began after reaching the maximum number of events limit.");
}

- (void)testMediaTrackContainerBasics {
    MPMediaTrack *mediaTrack = [[MPMediaTrack alloc] initWithChannel:@"Jurassic Park"];
    XCTAssertNotNil(mediaTrack, @"Instance should not have been nil.");
    mediaTrack.metadata = @{@"type":@"content", @"assetid":@"112358"};
    mediaTrack.timedMetadata = @"2468";
    mediaTrack.playbackPosition = 3.14159;
    
    [self.backendController beginPlaying:mediaTrack attempt:0 completionHandler:^(MPMediaTrack *mediaTrack, MPExecStatus execStatus) {}];
    XCTAssertTrue(mediaTrack.playing, @"Media track should have been marked as playing.");
    XCTAssertEqual(self.backendController.mediaTrackContainer.count, 1, @"There should have been 1 media track in the container.");
    
    [self.backendController endPlaying:mediaTrack attempt:0 completionHandler:^(MPMediaTrack *mediaTrack, MPExecStatus execStatus) {}];
    XCTAssertFalse(mediaTrack.playing, @"Media track should have been marked as not playing.");
    
    mediaTrack = [self.backendController mediaTrackWithChannel:@"Jurassic Fart"];
    XCTAssertNil(mediaTrack, @"There should be no such media track.");
    
    mediaTrack = [self.backendController mediaTrackWithChannel:@"Jurassic Park"];
    XCTAssertNotNil(mediaTrack, @"There should have been a media track returned.");
    
    NSArray *mediaTracks = [self.backendController mediaTracks];
    XCTAssertEqual(mediaTracks.count, 1, @"There should have been 1 media track in the array.");
    XCTAssertEqualObjects(mediaTrack, [mediaTracks firstObject], @"Media tracks should have been equal.");
    
    [self.backendController discardMediaTrack:mediaTrack];
    XCTAssertEqual(self.backendController.mediaTrackContainer.count, 0, @"There should have been no media tracks in the container.");
}

- (void)testPlayMediaTrack {
    MPMediaTrack *mediaTrack = [[MPMediaTrack alloc] initWithChannel:@"Jurassic Park"];
    mediaTrack.format = MPMediaTrackFormatVideo;
    mediaTrack.quality = MPMediaTrackQualityMediumDefinition;
    
    mediaTrack.metadata = @{@"dataSrc":@"cms",
                            @"type":@"content",
                            @"assetid":@"AkamaiVOD1",
                            @"tv":@"true",
                            @"title":@"Akamai VOD 1",
                            @"category":@"Test Program Akamai",
                            @"length":@"3141"};
    
    [self.backendController beginPlaying:mediaTrack attempt:0 completionHandler:^(MPMediaTrack *mediaTrack, MPExecStatus execStatus) {}];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Play media track test"];
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [persistence fetchMessagesForUploadingInSession:self.session
                                      completionHandler:^(NSArray *messages) {
                                          XCTAssertGreaterThan(messages.count, 0, @"Messages are not being persisted.");
                                          
                                          BOOL containsMediaTrackMessage = NO;
                                          for (MPMessage *message in messages) {
                                              if ([message.messageType isEqualToString:@"e"]) {
                                                  containsMediaTrackMessage = YES;
                                                  NSDictionary *messageDictionary = [message dictionaryRepresentation];
                                                  NSDictionary *mediaInfo = messageDictionary[MPMediaTrackMediaInfoKey];
                                                  
                                                  XCTAssertNotNil(messageDictionary, @"Not able to deserialize message dictionary.");
                                                  XCTAssertEqualObjects(mediaInfo[MPMediaTrackChannelKey], mediaTrack.channel, @"Channel does not match.");
                                                  XCTAssertEqualObjects(mediaInfo[MPMediaTrackMetadataKey], mediaTrack.metadata, @"Metadata does not match.");
                                                  XCTAssertNil(mediaInfo[MPMediaTrackTimedMetadataKey], @"Timed metadata should have been empty.");
                                                  XCTAssertEqualObjects(mediaInfo[MPMediaTrackPlaybackPositionKey], @0, @"Playback position is not being initialized.");
                                                  XCTAssertEqualObjects(mediaInfo[MPMediaTrackFormatKey], @(MPMediaTrackFormatVideo), @"Media format should have been 'video.'");
                                                  XCTAssertEqualObjects(mediaInfo[MPMediaTrackQualityKey], @(MPMediaTrackQualityMediumDefinition), @"Media quality should have been 'medium.'");
                                              }
                                          }
                                          
                                          XCTAssertTrue(containsMediaTrackMessage, @"Not logging playing of a media track.");
                                          
                                          MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithSession:self.session messages:messages sessionTimeout:100 uploadInterval:100];
                                          XCTAssertNotNil(uploadBuilder, @"Upload builder should not have been nil.");
                                          
                                          if (!uploadBuilder) {
                                              return;
                                          }
                                          
                                          [uploadBuilder withUserAttributes:self.backendController.userAttributes deletedUserAttributes:nil];
                                          [uploadBuilder withUserIdentities:self.backendController.userIdentities];
                                          [uploadBuilder build:^(MPDataModelAbstract *upload) {
                                              [persistence saveUpload:(MPUpload *)upload messageIds:uploadBuilder.preparedMessageIds operation:MPPersistenceOperationFlag];
                                              
                                              NSArray *messages = [persistence fetchMessagesInSession:self.session];
                                              
                                              XCTAssertNotNil(messages, @"There are no messages in session.");
                                              
                                              for (MPMessage *message in messages) {
                                                  XCTAssertTrue(message.uploadStatus == MPUploadStatusUploaded, @"Messages are not being marked as uploaded.");
                                              }
                                              
                                              [persistence deleteUpload:(MPUpload *)upload];
                                              
                                              [persistence fetchUploadsInSession:self.session
                                                               completionHandler:^(NSArray *uploads) {
                                                                   XCTAssertNil(uploads, @"Uploads are not being deleted.");
                                                                   
                                                                   [self.backendController discardMediaTrack:mediaTrack];
                                                                   MPMediaTrack *retrievedMediaTrack = [self.backendController mediaTrackWithChannel:@"Jurassic Park"];
                                                                   XCTAssertNil(retrievedMediaTrack, @"There should be no media track left.");
                                                                   
                                                                   [expectation fulfill];
                                                               }];
                                          }];
                                      }];
    });
    
    [self waitForExpectationsWithTimeout:BACKEND_TESTS_EXPECATIONS_TIMEOUT handler:nil];
}

@end

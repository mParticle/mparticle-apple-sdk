#import <XCTest/XCTest.h>
#import "MPUploadBuilder.h"
#import "MPSession.h"
#import "MPMessage.h"
#import "MPMessageBuilder.h"
#import "MPIConstants.h"
#import "MPUpload.h"
#import "MPStateMachine.h"
#import "MPIntegrationAttributes.h"
#import "MPPersistenceController.h"
#import "MPBaseTestCase.h"
#import "MPDevice.h"
#import "mParticle.h"

@interface MParticle ()

@property (nonatomic, strong) MPPersistenceController *persistenceController;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
@property (nonatomic, strong) MParticleOptions *options;

@end

@interface MPUploadBuilderTests : MPBaseTestCase

@end

@implementation MPUploadBuilderTests

- (void)setUp {
    [super setUp];
    
    [MParticle sharedInstance].stateMachine = [[MPStateMachine alloc] init];

    [MParticle sharedInstance].persistenceController = [[MPPersistenceController alloc] init];
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    NSNumber *integrationId = @(MPKitInstanceUrbanAirship);
    NSDictionary<NSString *, NSString *> *attributes = @{@"clientID":@"123abc",
                                                         @"key":@"value"};
    
    MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    [persistence saveIntegrationAttributes:integrationAttributes];

    integrationId = @(MPKitInstanceButton);
    attributes = @{@"keyB":@"valueB"};
    integrationAttributes = [[MPIntegrationAttributes alloc] initWithIntegrationId:integrationId attributes:attributes];
    [persistence saveIntegrationAttributes:integrationAttributes];
}

- (void)tearDown {
    [super tearDown];
    
    [[MParticle sharedInstance].persistenceController deleteAllIntegrationAttributes];
}

- (void)configureCustomModules {
    NSArray<NSDictionary *> *customModuleSettings = @[
                                                      @{
                                                          @"id":@11,
                                                          @"pr":@[
                                                                  @{
                                                                      @"f":@"NSUserDefaults",
                                                                      @"m":@0,
                                                                      @"ps":@[
                                                                              @{
                                                                                  @"k":@"APP_MEASUREMENT_VISITOR_ID",
                                                                                  @"t":@1,
                                                                                  @"n":@"vid",
                                                                                  @"d":@"%gn%"
                                                                                  },
                                                                              @{
                                                                                  @"k":@"ADOBEMOBILE_STOREDDEFAULTS_AID",
                                                                                  @"t":@1,
                                                                                  @"n":@"aid",
                                                                                  @"d":@"%oaid%"
                                                                                  },
                                                                              @{
                                                                                  @"k":@"GLSB",
                                                                                  @"t":@1,
                                                                                  @"n":@"aid",
                                                                                  @"d":@"%glsb%"
                                                                                  },
                                                                              @{
                                                                                  @"k":@"ADB_LIFETIME_VALUE",
                                                                                  @"t":@1,
                                                                                  @"n":@"ltv",
                                                                                  @"d":@"0"
                                                                                  },
                                                                              @{
                                                                                  @"k":@"OMCK1",
                                                                                  @"t":@1,
                                                                                  @"n":@"id",
                                                                                  @"d":@"%dt%"
                                                                                  },
                                                                              @{
                                                                                  @"k":@"OMCK6",
                                                                                  @"t":@2,
                                                                                  @"n":@"l",
                                                                                  @"d":@"0"
                                                                                  },
                                                                              @{
                                                                                  @"k":@"OMCK5",
                                                                                  @"t":@1,
                                                                                  @"n":@"lud",
                                                                                  @"d":@"%dt%"
                                                                                  }
                                                                              ]
                                                                      }
                                                                  ]
                                                          }];
    
    [[MParticle sharedInstance].stateMachine configureCustomModules:customModuleSettings];
}

- (void)testInstanceWithSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload builder instance (session)"];
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];

    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    [self configureCustomModules];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:messageInfo];
    
    messageBuilder = [messageBuilder withTimestamp:[[NSDate date] timeIntervalSince1970]];
    MPMessage *message = [messageBuilder build];
    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder    newBuilderWithMpid:[MPPersistenceController mpId]
                                                                    sessionId:[NSNumber numberWithLong:session.sessionId]
                                                                   messages:@[message]
                                                             sessionTimeout:DEFAULT_SESSION_TIMEOUT
                                                             uploadInterval:DEFAULT_DEBUG_UPLOAD_INTERVAL
                                                                 dataPlanId:message.dataPlanId
                                                            dataPlanVersion:message.dataPlanVersion
                                      ];
    
    XCTAssertNotNil(uploadBuilder);
    
    NSDictionary *userAttributes = @{@"Dinosaur":@"T-Rex",
                                     @"Arm length":@"Short",
                                     @"Height":@20,
                                     @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};
    
    NSSet *deletedUserAttributes = [NSSet setWithObjects:@"Push ups", nil];
    
    [uploadBuilder withUserAttributes:userAttributes deletedUserAttributes:deletedUserAttributes];
    
    NSArray *userIdentities = @[@{
                                    @"n":@7,
                                    @"i":@"trex@shortarmsdinosaurs.com",
                                    @"dfs":MPCurrentEpochInMilliseconds,
                                    @"f":@NO
                                    }
                                ];
    
    [uploadBuilder withUserIdentities:userIdentities];
    
    NSString *description = [uploadBuilder description];
    XCTAssertNotNil(description);
    
    [uploadBuilder build:^(MPUpload * _Nullable upload) {
        XCTAssertNotNil(upload);
        Class uploadClass = [MPUpload class];
        XCTAssertEqualObjects([upload class], uploadClass);
        
        NSDictionary *uploadDictionary = [(MPUpload *)upload dictionaryRepresentation];
        XCTAssertNotNil(uploadDictionary);

        NSDictionary *referenceUserDictionary = @{@"Dinosaur":@"T-Rex",
                                                  @"Arm length":@"Short",
                                                  @"Height":@"20",
                                                  @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};

        XCTAssertEqualObjects(uploadDictionary[kMPUserAttributeKey], referenceUserDictionary);
        
        NSDictionary *deviceInfoDictionary = uploadDictionary[kMPDeviceInformationKey];
        XCTAssertNotNil(deviceInfoDictionary);
        XCTAssertNil(deviceInfoDictionary[kMPDeviceAdvertiserIdKey]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testInstanceWithoutSession {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload builder instance (no session)"];
    
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    [self configureCustomModules];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:nil
                                                                       messageInfo:messageInfo];
    
    messageBuilder = [messageBuilder withTimestamp:[[NSDate date] timeIntervalSince1970]];
    MPMessage *message = [messageBuilder build];
    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithMpid:[MPPersistenceController mpId]
                                                                messages:@[message]
                                                          uploadInterval:DEFAULT_DEBUG_UPLOAD_INTERVAL
                                                              dataPlanId:message.dataPlanId
                                                         dataPlanVersion:message.dataPlanVersion
                                      ];
    
    XCTAssertNotNil(uploadBuilder);
    
    NSDictionary *userAttributes = @{@"Dinosaur":@"T-Rex",
                                     @"Arm length":@"Short",
                                     @"Height":@20,
                                     @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};
    
    NSSet *deletedUserAttributes = [NSSet setWithObjects:@"Push ups", nil];
    
    [uploadBuilder withUserAttributes:userAttributes deletedUserAttributes:deletedUserAttributes];
    
    NSArray *userIdentities = @[@{
                                    @"n":@7,
                                    @"i":@"trex@shortarmsdinosaurs.com",
                                    @"dfs":MPCurrentEpochInMilliseconds,
                                    @"f":@NO
                                    }
                                ];
    
    [uploadBuilder withUserIdentities:userIdentities];
    
    NSString *description = [uploadBuilder description];
    XCTAssertNotNil(description);
    
    [uploadBuilder build:^(MPUpload * _Nullable upload) {
        XCTAssertNotNil(upload);
        Class uploadClass = [MPUpload class];
        XCTAssertEqualObjects([upload class], uploadClass);
        
        NSDictionary *uploadDictionary = [(MPUpload *)upload dictionaryRepresentation];
        XCTAssertNotNil(uploadDictionary);
        
        NSDictionary *referenceUserAttributes = @{@"Dinosaur":@"T-Rex",
                                                  @"Arm length":@"Short",
                                                  @"Height":@"20",
                                                  @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};
        
        XCTAssertEqualObjects(uploadDictionary[@"ua"], referenceUserAttributes);
        XCTAssertNil(upload.dataPlanId);
        XCTAssertNil(upload.dataPlanVersion);
        
        NSDictionary *deviceInfoDictionary = uploadDictionary[kMPDeviceInformationKey];
        XCTAssertNotNil(deviceInfoDictionary);
        XCTAssertNil(deviceInfoDictionary[kMPDeviceAdvertiserIdKey]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testInstanceWithDataPlanId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload builder instance (dataPlanId)"];
    
    [MParticle sharedInstance].dataPlanId = @"test";
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];

    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    [self configureCustomModules];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:messageInfo];
    
    messageBuilder = [messageBuilder withTimestamp:[[NSDate date] timeIntervalSince1970]];
    MPMessage *message = [messageBuilder build];
    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder    newBuilderWithMpid:[MPPersistenceController mpId]
                                                                    sessionId:[NSNumber numberWithLong:session.sessionId]
                                                                   messages:@[message]
                                                             sessionTimeout:DEFAULT_SESSION_TIMEOUT
                                                             uploadInterval:DEFAULT_DEBUG_UPLOAD_INTERVAL
                                                                 dataPlanId:message.dataPlanId
                                                            dataPlanVersion:message.dataPlanVersion
                                      ];
    
    XCTAssertNotNil(uploadBuilder);
    
    NSDictionary *userAttributes = @{@"Dinosaur":@"T-Rex",
                                     @"Arm length":@"Short",
                                     @"Height":@20,
                                     @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};
    
    NSSet *deletedUserAttributes = [NSSet setWithObjects:@"Push ups", nil];
    
    [uploadBuilder withUserAttributes:userAttributes deletedUserAttributes:deletedUserAttributes];
    
    NSArray *userIdentities = @[@{
                                    @"n":@7,
                                    @"i":@"trex@shortarmsdinosaurs.com",
                                    @"dfs":MPCurrentEpochInMilliseconds,
                                    @"f":@NO
                                    }
                                ];
    
    [uploadBuilder withUserIdentities:userIdentities];
    
    NSString *description = [uploadBuilder description];
    XCTAssertNotNil(description);
    
    [uploadBuilder build:^(MPUpload * _Nullable upload) {
        XCTAssertNotNil(upload);
        Class uploadClass = [MPUpload class];
        XCTAssertEqualObjects([upload class], uploadClass);
        
        NSDictionary *uploadDictionary = [(MPUpload *)upload dictionaryRepresentation];
        XCTAssertNotNil(uploadDictionary);

        NSDictionary *referenceUserDictionary = @{@"Dinosaur":@"T-Rex",
                                                  @"Arm length":@"Short",
                                                  @"Height":@"20",
                                                  @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};

        XCTAssertEqualObjects(uploadDictionary[kMPUserAttributeKey], referenceUserDictionary);
        
        XCTAssertEqualObjects(upload.dataPlanId, @"test");
        XCTAssertNil(upload.dataPlanVersion);

        NSDictionary *deviceInfoDictionary = uploadDictionary[kMPDeviceInformationKey];
        XCTAssertNotNil(deviceInfoDictionary);
        XCTAssertNil(deviceInfoDictionary[kMPDeviceAdvertiserIdKey]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testInstanceWithDataPlanVersion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload builder instance (dataPlanId)"];
    
    [MParticle sharedInstance].dataPlanId = @"test";
    [MParticle sharedInstance].dataPlanVersion = @1;
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];

    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    [self configureCustomModules];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:messageInfo];
    
    messageBuilder = [messageBuilder withTimestamp:[[NSDate date] timeIntervalSince1970]];
    MPMessage *message = [messageBuilder build];
    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder    newBuilderWithMpid:[MPPersistenceController mpId]
                                                                    sessionId:[NSNumber numberWithLong:session.sessionId]
                                                                   messages:@[message]
                                                             sessionTimeout:DEFAULT_SESSION_TIMEOUT
                                                             uploadInterval:DEFAULT_DEBUG_UPLOAD_INTERVAL
                                                                 dataPlanId:message.dataPlanId
                                                            dataPlanVersion:message.dataPlanVersion
                                      ];
    
    XCTAssertNotNil(uploadBuilder);
    
    NSDictionary *userAttributes = @{@"Dinosaur":@"T-Rex",
                                     @"Arm length":@"Short",
                                     @"Height":@20,
                                     @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};
    
    NSSet *deletedUserAttributes = [NSSet setWithObjects:@"Push ups", nil];
    
    [uploadBuilder withUserAttributes:userAttributes deletedUserAttributes:deletedUserAttributes];
    
    NSArray *userIdentities = @[@{
                                    @"n":@7,
                                    @"i":@"trex@shortarmsdinosaurs.com",
                                    @"dfs":MPCurrentEpochInMilliseconds,
                                    @"f":@NO
                                    }
                                ];
    
    [uploadBuilder withUserIdentities:userIdentities];
    
    NSString *description = [uploadBuilder description];
    XCTAssertNotNil(description);
    
    [uploadBuilder build:^(MPUpload * _Nullable upload) {
        XCTAssertNotNil(upload);
        Class uploadClass = [MPUpload class];
        XCTAssertEqualObjects([upload class], uploadClass);
        
        NSDictionary *uploadDictionary = [(MPUpload *)upload dictionaryRepresentation];
        XCTAssertNotNil(uploadDictionary);

        NSDictionary *referenceUserDictionary = @{@"Dinosaur":@"T-Rex",
                                                  @"Arm length":@"Short",
                                                  @"Height":@"20",
                                                  @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};

        XCTAssertEqualObjects(uploadDictionary[kMPUserAttributeKey], referenceUserDictionary);
        
        XCTAssertEqualObjects(upload.dataPlanId, @"test");
        XCTAssertEqualObjects(upload.dataPlanVersion, @1);

        NSDictionary *deviceInfoDictionary = uploadDictionary[kMPDeviceInformationKey];
        XCTAssertNotNil(deviceInfoDictionary);
        XCTAssertNil(deviceInfoDictionary[kMPDeviceAdvertiserIdKey]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testInstanceWithAdvertiserIdInSessionNoAttStatus {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload builder instance (session)"];
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    [self configureCustomModules];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:messageInfo];
    
    messageBuilder = [messageBuilder withTimestamp:[[NSDate date] timeIntervalSince1970]];
    MPMessage *message = [messageBuilder build];
    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder    newBuilderWithMpid:[MPPersistenceController mpId]
                                                                  sessionId:[NSNumber numberWithLong:session.sessionId]
                                                                   messages:@[message]
                                                             sessionTimeout:DEFAULT_SESSION_TIMEOUT
                                                             uploadInterval:DEFAULT_DEBUG_UPLOAD_INTERVAL
                                                                 dataPlanId:message.dataPlanId
                                                            dataPlanVersion:message.dataPlanVersion
    ];
    
    XCTAssertNotNil(uploadBuilder);
    
    NSDictionary *userAttributes = @{@"Dinosaur":@"T-Rex",
                                     @"Arm length":@"Short",
                                     @"Height":@20,
                                     @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};
    
    NSSet *deletedUserAttributes = [NSSet setWithObjects:@"Push ups", nil];
    
    [uploadBuilder withUserAttributes:userAttributes deletedUserAttributes:deletedUserAttributes];
    
    NSArray *userIdentities = @[@{
        @"n":@7,
        @"i":@"trex@shortarmsdinosaurs.com",
        @"dfs":MPCurrentEpochInMilliseconds,
        @"f":@NO
    },
                                @{
                                    @"n":@22,
                                    @"i":@"C56A4180-65AA-42EC-A945-5FD21DEC0538"
                                }
    ];
    
    [uploadBuilder withUserIdentities:userIdentities];
    
    NSString *description = [uploadBuilder description];
    XCTAssertNotNil(description);
    
    [uploadBuilder build:^(MPUpload * _Nullable upload) {
        XCTAssertNotNil(upload);
        Class uploadClass = [MPUpload class];
        XCTAssertEqualObjects([upload class], uploadClass);
        
        NSDictionary *uploadDictionary = [(MPUpload *)upload dictionaryRepresentation];
        XCTAssertNotNil(uploadDictionary);
        
        NSDictionary *referenceUserDictionary = @{@"Dinosaur":@"T-Rex",
                                                  @"Arm length":@"Short",
                                                  @"Height":@"20",
                                                  @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};
        
        XCTAssertEqualObjects(uploadDictionary[kMPUserAttributeKey], referenceUserDictionary);
        
        NSDictionary *deviceInfoDictionary = uploadDictionary[kMPDeviceInformationKey];
        XCTAssertNotNil(deviceInfoDictionary);
        XCTAssertNil(deviceInfoDictionary[kMPDeviceAdvertiserIdKey]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testInstanceWithAdvertiserIdInSessionAuthorizedAttStatus {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload builder instance (session)"];
    
    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusAuthorized withATTStatusTimestampMillis:nil];
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    [self configureCustomModules];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:messageInfo];
    
    messageBuilder = [messageBuilder withTimestamp:[[NSDate date] timeIntervalSince1970]];
    MPMessage *message = [messageBuilder build];
    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder    newBuilderWithMpid:[MPPersistenceController mpId]
                                                                  sessionId:[NSNumber numberWithLong:session.sessionId]
                                                                   messages:@[message]
                                                             sessionTimeout:DEFAULT_SESSION_TIMEOUT
                                                             uploadInterval:DEFAULT_DEBUG_UPLOAD_INTERVAL
                                                                 dataPlanId:message.dataPlanId
                                                            dataPlanVersion:message.dataPlanVersion
    ];
    
    XCTAssertNotNil(uploadBuilder);
    
    NSDictionary *userAttributes = @{@"Dinosaur":@"T-Rex",
                                     @"Arm length":@"Short",
                                     @"Height":@20,
                                     @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};
    
    NSSet *deletedUserAttributes = [NSSet setWithObjects:@"Push ups", nil];
    
    [uploadBuilder withUserAttributes:userAttributes deletedUserAttributes:deletedUserAttributes];
    
    NSArray *userIdentities = @[@{
        @"n":@7,
        @"i":@"trex@shortarmsdinosaurs.com",
        @"dfs":MPCurrentEpochInMilliseconds,
        @"f":@NO
    },
                                @{
                                    @"n":@22,
                                    @"i":@"C56A4180-65AA-42EC-A945-5FD21DEC0538"
                                }
    ];
    
    [uploadBuilder withUserIdentities:userIdentities];
    
    NSString *description = [uploadBuilder description];
    XCTAssertNotNil(description);
    
    [uploadBuilder build:^(MPUpload * _Nullable upload) {
        XCTAssertNotNil(upload);
        Class uploadClass = [MPUpload class];
        XCTAssertEqualObjects([upload class], uploadClass);
        
        NSDictionary *uploadDictionary = [(MPUpload *)upload dictionaryRepresentation];
        XCTAssertNotNil(uploadDictionary);
        
        NSDictionary *referenceUserDictionary = @{@"Dinosaur":@"T-Rex",
                                                  @"Arm length":@"Short",
                                                  @"Height":@"20",
                                                  @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};
        
        XCTAssertEqualObjects(uploadDictionary[kMPUserAttributeKey], referenceUserDictionary);
        
        NSDictionary *deviceInfoDictionary = uploadDictionary[kMPDeviceInformationKey];
        XCTAssertNotNil(deviceInfoDictionary);
        XCTAssertEqualObjects(deviceInfoDictionary[kMPDeviceAdvertiserIdKey], @"C56A4180-65AA-42EC-A945-5FD21DEC0538");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testInstanceWithAdvertiserIdInSessionDeniedAttStatus {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload builder instance (session)"];
    
    [[MParticle sharedInstance] setATTStatus:MPATTAuthorizationStatusDenied withATTStatusTimestampMillis:nil];
    
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    [self configureCustomModules];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:messageInfo];
    
    messageBuilder = [messageBuilder withTimestamp:[[NSDate date] timeIntervalSince1970]];
    MPMessage *message = [messageBuilder build];
    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder    newBuilderWithMpid:[MPPersistenceController mpId]
                                                                  sessionId:[NSNumber numberWithLong:session.sessionId]
                                                                   messages:@[message]
                                                             sessionTimeout:DEFAULT_SESSION_TIMEOUT
                                                             uploadInterval:DEFAULT_DEBUG_UPLOAD_INTERVAL
                                                                 dataPlanId:message.dataPlanId
                                                            dataPlanVersion:message.dataPlanVersion
    ];
    
    XCTAssertNotNil(uploadBuilder);
    
    NSDictionary *userAttributes = @{@"Dinosaur":@"T-Rex",
                                     @"Arm length":@"Short",
                                     @"Height":@20,
                                     @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};
    
    NSSet *deletedUserAttributes = [NSSet setWithObjects:@"Push ups", nil];
    
    [uploadBuilder withUserAttributes:userAttributes deletedUserAttributes:deletedUserAttributes];
    
    NSArray *userIdentities = @[@{
        @"n":@7,
        @"i":@"trex@shortarmsdinosaurs.com",
        @"dfs":MPCurrentEpochInMilliseconds,
        @"f":@NO
    },
                                @{
                                    @"n":@22,
                                    @"i":@"C56A4180-65AA-42EC-A945-5FD21DEC0538"
                                }
    ];
    
    [uploadBuilder withUserIdentities:userIdentities];
    
    NSString *description = [uploadBuilder description];
    XCTAssertNotNil(description);
    
    [uploadBuilder build:^(MPUpload * _Nullable upload) {
        XCTAssertNotNil(upload);
        Class uploadClass = [MPUpload class];
        XCTAssertEqualObjects([upload class], uploadClass);
        
        NSDictionary *uploadDictionary = [(MPUpload *)upload dictionaryRepresentation];
        XCTAssertNotNil(uploadDictionary);
        
        NSDictionary *referenceUserDictionary = @{@"Dinosaur":@"T-Rex",
                                                  @"Arm length":@"Short",
                                                  @"Height":@"20",
                                                  @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};
        
        XCTAssertEqualObjects(uploadDictionary[kMPUserAttributeKey], referenceUserDictionary);
        
        NSDictionary *deviceInfoDictionary = uploadDictionary[kMPDeviceInformationKey];
        XCTAssertNotNil(deviceInfoDictionary);
        XCTAssertNil(deviceInfoDictionary[kMPDeviceAdvertiserIdKey]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (MPUploadBuilder *)createTestUploadBuilder {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    
    NSDictionary *messageInfo = @{@"key1":@"value1",
                                  @"key2":@"value2",
                                  @"key3":@"value3"};
    
    [self configureCustomModules];
    
    MPMessageBuilder *messageBuilder = [MPMessageBuilder newBuilderWithMessageType:MPMessageTypeEvent
                                                                           session:session
                                                                       messageInfo:messageInfo];
    
    messageBuilder = [messageBuilder withTimestamp:[[NSDate date] timeIntervalSince1970]];
    MPMessage *message = [messageBuilder build];
    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder    newBuilderWithMpid:[MPPersistenceController mpId]
                                                                  sessionId:[NSNumber numberWithLong:session.sessionId]
                                                                   messages:@[message]
                                                             sessionTimeout:DEFAULT_SESSION_TIMEOUT
                                                             uploadInterval:DEFAULT_DEBUG_UPLOAD_INTERVAL
                                                                 dataPlanId:message.dataPlanId
                                                            dataPlanVersion:message.dataPlanVersion
    ];
    
    XCTAssertNotNil(uploadBuilder);
    
    NSDictionary *userAttributes = @{@"Dinosaur":@"T-Rex",
                                     @"Arm length":@"Short",
                                     @"Height":@20,
                                     @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};
    
    NSSet *deletedUserAttributes = [NSSet setWithObjects:@"Push ups", nil];
    
    [uploadBuilder withUserAttributes:userAttributes deletedUserAttributes:deletedUserAttributes];
    
    NSArray *userIdentities = @[
        @{
            @"n":@7,
            @"i":@"trex@shortarmsdinosaurs.com",
            @"dfs":MPCurrentEpochInMilliseconds,
            @"f":@NO
        },
        @{
            @"n":@22,
            @"i":@"C56A4180-65AA-42EC-A945-5FD21DEC0538"
        }
    ];
    
    [uploadBuilder withUserIdentities:userIdentities];
    
    NSString *description = [uploadBuilder description];
    XCTAssertNotNil(description);
    return uploadBuilder;
}

- (void)testBatchMutation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload builder instance (session)"];
    MParticleOptions *options = [[MParticleOptions alloc] init];
    options.onCreateBatch = ^NSDictionary * _Nullable(NSDictionary * _Nonnull batch) {
        NSMutableDictionary *mutableBatch = [batch mutableCopy];
        mutableBatch[@"Test key"] = @"Test value";
        return mutableBatch;
    };
    MParticle.sharedInstance.options = options;
    
    MPUploadBuilder *uploadBuilder = [self createTestUploadBuilder];
    
    [uploadBuilder build:^(MPUpload * _Nullable upload) {
        XCTAssertNotNil(upload);
        Class uploadClass = [MPUpload class];
        XCTAssertEqualObjects([upload class], uploadClass);
        
        NSDictionary *uploadDictionary = [(MPUpload *)upload dictionaryRepresentation];
        XCTAssertNotNil(uploadDictionary);
        
        XCTAssertEqualObjects(uploadDictionary[@"Test key"], @"Test value");
        XCTAssertEqual(uploadDictionary[@"mb"], @YES);
        
        NSDictionary *deviceInfoDictionary = uploadDictionary[kMPDeviceInformationKey];
        XCTAssertNotNil(deviceInfoDictionary);
        XCTAssertNil(deviceInfoDictionary[kMPDeviceAdvertiserIdKey]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testNoBatchMutation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Upload builder instance (session)"];
    MParticleOptions *options = [[MParticleOptions alloc] init];
    options.onCreateBatch = ^NSDictionary * _Nullable(NSDictionary * _Nonnull batch) {
        return [NSDictionary dictionaryWithDictionary:batch];
    };
    MParticle.sharedInstance.options = options;
    
    MPUploadBuilder *uploadBuilder = [self createTestUploadBuilder];
    
    [uploadBuilder build:^(MPUpload * _Nullable upload) {
        XCTAssertNotNil(upload);
        Class uploadClass = [MPUpload class];
        XCTAssertEqualObjects([upload class], uploadClass);
        
        NSDictionary *uploadDictionary = [(MPUpload *)upload dictionaryRepresentation];
        XCTAssertNotNil(uploadDictionary);
        
        XCTAssertNil(uploadDictionary[@"Test key"]);
        XCTAssertNil(uploadDictionary[@"mb"]);
        
        NSDictionary *deviceInfoDictionary = uploadDictionary[kMPDeviceInformationKey];
        XCTAssertNotNil(deviceInfoDictionary);
        XCTAssertNil(deviceInfoDictionary[kMPDeviceAdvertiserIdKey]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testBatchBlocking {
    MParticleOptions *options = [[MParticleOptions alloc] init];
    options.onCreateBatch = ^NSDictionary * _Nullable(NSDictionary * _Nonnull batch) {
        return nil;
    };
    MParticle.sharedInstance.options = options;
    
    MPUploadBuilder *uploadBuilder = [self createTestUploadBuilder];
    
    [uploadBuilder build:^(MPUpload * _Nullable upload) {
        XCTAssert(NO, @"Builder completion should not have been called since batch was blocked by customer");
    }];
}


@end

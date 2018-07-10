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
#import "mParticle.h"

@interface MParticle ()

@property (nonatomic, strong) MPPersistenceController *persistenceController;
@property (nonatomic, strong) MPStateMachine *stateMachine;

@end

@interface MPUploadBuilderTests : MPBaseTestCase

@end

@implementation MPUploadBuilderTests

- (void)setUp {
    [super setUp];
    
    [MParticle sharedInstance].stateMachine = [[MPStateMachine alloc] init];

    [MParticle sharedInstance].persistenceController = [[MPPersistenceController alloc] init];
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    NSNumber *kitCode = @(MPKitInstanceUrbanAirship);
    NSDictionary<NSString *, NSString *> *attributes = @{@"clientID":@"123abc",
                                                         @"key":@"value"};
    
    MPIntegrationAttributes *integrationAttributes = [[MPIntegrationAttributes alloc] initWithKitCode:kitCode attributes:attributes];
    [persistence saveIntegrationAttributes:integrationAttributes];

    kitCode = @(MPKitInstanceButton);
    attributes = @{@"keyB":@"valueB"};
    integrationAttributes = [[MPIntegrationAttributes alloc] initWithKitCode:kitCode attributes:attributes];
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
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder    newBuilderWithMpid:[MPPersistenceController mpId]
                                                                    sessionId:[NSNumber numberWithLong:session.sessionId]
                                                                   messages:@[message]
                                                             sessionTimeout:DEFAULT_SESSION_TIMEOUT
                                                             uploadInterval:DEFAULT_DEBUG_UPLOAD_INTERVAL];
    
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
    MPMessage *message = (MPMessage *)[messageBuilder build];
    
    MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithMpid:[MPPersistenceController mpId] messages:@[message] uploadInterval:DEFAULT_DEBUG_UPLOAD_INTERVAL];
    
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
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end

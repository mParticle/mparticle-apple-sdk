@import mParticle_Apple_SDK;

#import <XCTest/XCTest.h>
#import "MPBaseTestCase.h"
#import "MPBackendController.h"
#import "MPPersistenceController.h"
#import "MPKitContainer+MParticlePrivate.h"
#import "MPKitConfiguration.h"
#import "MPIConstants.h"
#import "MPUserDefaultsConnector.h"
@import mParticle_Apple_SDK_Swift;

@interface MPKitContainer_PRIVATE ()

- (id<MPKitProtocol>)startKit:(NSNumber *)integrationId configuration:(MPKitConfiguration *)kitConfiguration;

@end

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;

@end

@interface MPBackendController_PRIVATE ()


- (void)clearUserAttributes;

@end

@interface FilteredMParticleUser (RoktFilteringTests)
- (NSDictionary<NSString *, id> *)mp_filteredUserAttributesByMergingAttributes:(NSDictionary<NSString *, id> *)attributes;
@end


@interface MPKitAPI ()

- (id)initWithKitCode:(NSNumber *)integrationId;
- (NSString *)kitName;

@end

#pragma mark - MPKitAPITests unit test class
@interface MPKitAPITests : MPBaseTestCase  <MPKitProtocol>

@property (nonatomic) MPKitAPI *kitApi;
@property (nonatomic) MPKitContainer_PRIVATE *kitContainer;

@end

@implementation MPKitAPITests

- (void)setUp {
    [super setUp];
    
    [MParticle sharedInstance].kitContainer_PRIVATE = [[MPKitContainer_PRIVATE alloc] init];
    _kitContainer = [MParticle sharedInstance].kitContainer_PRIVATE;
    
    [MParticle sharedInstance].persistenceController = [[MPPersistenceController_PRIVATE alloc] init];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    if (!registeredKits) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
        [MPKitContainer_PRIVATE registerKit:kitRegister];
        
        NSDictionary *configuration = @{
                                        @"id":@42,
                                        @"as":@{
                                                @"appId":@"MyAppId"
                                                }
                                        };
        
        MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
        [_kitContainer startKit:@42 configuration:kitConfiguration];
    }
        
    _kitApi = [[MPKitAPI alloc] initWithKitCode:@42];
}

- (void)testIntegrationAttributes {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Integration attributes"];
    MParticle *mParticle = [MParticle sharedInstance];
    
    mParticle.backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)mParticle];
    
    [[MParticle sharedInstance] setIntegrationAttributes:@{@"Test key":@"Test value"} forKit:@42];
    dispatch_sync([MParticle messageQueue], ^{
        NSDictionary *integrationAttributes = [self->_kitApi integrationAttributes];
        NSString *value = integrationAttributes[@"Test key"];
        XCTAssertEqualObjects(value, @"Test value");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (nonnull MPKitExecStatus *)didFinishLaunchingWithConfiguration:(nonnull NSDictionary *)configuration {
    return [[MPKitExecStatus alloc] initWithSDKCode:@1 returnCode:MPKitReturnCodeSuccess];
}

+ (nonnull NSNumber *)kitCode {
    return @42;
}

- (void)testUserIdentities {
    MParticleUser *currentUser = [[MParticle sharedInstance].identity currentUser];

    NSArray *userIdentities = @[@{
                                    @"n":@(MPUserIdentityEmail),
                                    @"i":@"example@example.com",
                                    @"dfs":MPCurrentEpochInMilliseconds,
                                    @"f":@NO
                                    },
                                @{
                                    @"n":@(MPUserIdentityCustomerId),
                                    @"i":@"12345",
                                    @"dfs":MPCurrentEpochInMilliseconds,
                                    @"f":@NO
                                    }
                                ];
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    [userDefaults setMPObject:userIdentities forKey:kMPUserIdentityArrayKey userId:currentUser.userId];
    [userDefaults removeMPObjectForKey:@"ua"];
    
    NSString *identityTypeString = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)MPUserIdentityEmail];
    
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"testConfigKey":@"testConfigValue"
                                            },
                                    @"hs":@{
                                            @"uid":@{identityTypeString:@0}
                                            }
                                    }
                                ];
    
    [_kitContainer configureKits:nil];
    [_kitContainer configureKits:configurations];
    
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] initWithKitCode:@42];
    FilteredMParticleUser *kitUser = [kitAPI getCurrentUserWithKit:self];
    NSDictionary *identities = kitUser.userIdentities;
    NSString *email = identities[@(MPUserIdentityEmail)];
    NSString *customerId = identities[@(MPUserIdentityCustomerId)];
    
    XCTAssertNil(email, @"Kit api is not filtering user identities");
    XCTAssertEqualObjects(customerId, @"12345", @"Kit api is filtering user identities when it shouldn't");
    XCTAssertTrue([identities isKindOfClass:[NSMutableDictionary class]], @"Filtered user identities must remain mutable");
}

- (void)testUserAttributeFromCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Integration attributes"];
    MParticle *mParticle = [MParticle sharedInstance];
    mParticle.backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)mParticle];
    MParticleUser *currentUser = [[MParticle sharedInstance].identity currentUser];
    
    NSDictionary *userAttributes = @{
                                @"good data":@"67890",
                                @"better data":@"ABC",
                                @"bad data":@"12345"
                                };
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    [userDefaults setMPObject:userAttributes forKey:kMPUserAttributeKey userId:currentUser.userId];
    MParticle* mparticle = MParticle.sharedInstance;
    MPLog* logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
    logger.customLogger = mparticle.customLogger;
    MPIHasher* hasher = [[MPIHasher alloc] initWithLogger:logger];
    NSString *goodHashedKey = [hasher hashString:@"good data"];
    NSString *badHashedKey = [hasher hashString:@"bad data"];
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"testConfigKey":@"testConfigValue"
                                            },
                                    @"hs":@{
                                            @"ua":@{goodHashedKey:@1,
                                                    badHashedKey:@0}
                                            }
                                    }
                                ];
    
    [_kitContainer configureKits:nil];
    [_kitContainer configureKits:configurations];
    
    dispatch_sync([MParticle messageQueue], ^{
        MPKitAPI *kitAPI = [[MPKitAPI alloc] initWithKitCode:@42];
        FilteredMParticleUser *kitUser = [kitAPI getCurrentUserWithKit:self];
        NSDictionary *attributes = kitUser.userAttributes;
        
        XCTAssertNil(attributes[@"bad data"], @"Kit api is not filtering user attributes");
        XCTAssertEqualObjects(attributes[@"good data"], @"67890", @"Kit api is filtering user attributes when it shouldn't");
        XCTAssertEqualObjects(attributes[@"better data"], @"ABC", @"Kit api is filtering user attributes when it shouldn't");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testMergedCandidateAttributesUseConnectionAttributeHashes {
    MParticle *mparticle = MParticle.sharedInstance;
    mparticle.backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)mparticle];
    MParticleUser *currentUser = mparticle.identity.currentUser;
    [MPUserDefaultsConnector.userDefaults setMPObject:@{@"stored": @"profile"}
                                               forKey:kMPUserAttributeKey
                                               userId:currentUser.userId];

    MPLog *logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
    MPIHasher *hasher = [[MPIHasher alloc] initWithLogger:logger];
    NSString *allowedHash = [hasher hashString:@"allowed"];
    NSString *blockedHash = [hasher hashString:@"blocked"];
    [_kitContainer configureKits:nil];
    [_kitContainer configureKits:@[
        @{
            @"id": @42,
            @"as": @{},
            @"hs": @{@"ua": @{allowedHash: @1, blockedHash: @0}}
        }
    ]];

    MPKitAPI *kitAPI = [[MPKitAPI alloc] initWithKitCode:@42];
    FilteredMParticleUser *kitUser = [kitAPI getCurrentUserWithKit:self];
    NSDictionary *attributes = [kitUser mp_filteredUserAttributesByMergingAttributes:@{
        @"allowed": @"forward",
        @"blocked": @"withhold"
    }];

    XCTAssertEqualObjects(attributes[@"stored"], @"profile");
    XCTAssertEqualObjects(attributes[@"allowed"], @"forward");
    XCTAssertNil(attributes[@"blocked"]);
}

- (void)testUserAttributeManuallySet {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Integration attributes"];
    MParticle *mParticle = [MParticle sharedInstance];
    mParticle.backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)mParticle];
    MParticleUser *currentUser = [[MParticle sharedInstance].identity currentUser];
    
    NSDictionary *userAttributes = @{
                                     @"good data":@"67890",
                                     @"better data":@"ABC",
                                     @"bad data":@"12345"
                                     };
    
    MParticle* mparticle = MParticle.sharedInstance;
    MPLog* logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
    logger.customLogger = mparticle.customLogger;
    [currentUser setUserAttributes:userAttributes];
    MPIHasher* hasher = [[MPIHasher alloc] initWithLogger:logger];
    NSString *goodHashedKey = [hasher hashString:@"good data"];
    NSString *badHashedKey = [hasher hashString:@"bad data"];
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"testConfigKey":@"testConfigValue"
                                            },
                                    @"hs":@{
                                            @"ua":@{goodHashedKey:@1,
                                                    badHashedKey:@0}
                                            }
                                    }
                                ];
    
    [_kitContainer configureKits:nil];
    [_kitContainer configureKits:configurations];
    
    dispatch_sync([MParticle messageQueue], ^{
        MPKitAPI *kitAPI = [[MPKitAPI alloc] initWithKitCode:@42];
        FilteredMParticleUser *kitUser = [kitAPI getCurrentUserWithKit:self];
        NSDictionary *attributes = kitUser.userAttributes;
        
        XCTAssertNil(attributes[@"bad data"], @"Kit api is not filtering user attributes");
        XCTAssertEqualObjects(attributes[@"good data"], @"67890", @"Kit api is filtering user attributes when it shouldn't");
        XCTAssertEqualObjects(attributes[@"better data"], @"ABC", @"Kit api is filtering user attributes when it shouldn't");
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

#pragma mark - Kit name

- (void)testKitNameResolvesARegisteredCode {
    XCTAssertEqualObjects([_kitApi kitName], @"KitTest");
}

- (void)testKitNameIsNilForAnUnregisteredCode {
    MPKitAPI *unregistered = [[MPKitAPI alloc] initWithKitCode:@999];

    XCTAssertNil([unregistered kitName]);
}

#pragma mark - Attribution

// The Swift helper mirrors these three constants because it cannot import the
// ObjC module. This test is what fails if either side drifts.
- (void)testAttributionErrorCarriesTheObjCConstants {
    __block NSError *reportedError = nil;
    __block MPAttributionResult *reportedResult = nil;
    _kitContainer.attributionCompletionHandler = ^(MPAttributionResult *result, NSError *error) {
        reportedResult = result;
        reportedError = error;
    };

    NSError *underlying = [NSError errorWithDomain:@"test" code:7 userInfo:nil];
    [_kitApi onAttributionCompleteWithResult:nil error:underlying];

    XCTAssertNil(reportedResult);
    XCTAssertEqualObjects(reportedError.domain, MPKitAPIErrorDomain);
    XCTAssertEqual(reportedError.code, 0);
    XCTAssertEqualObjects(reportedError.userInfo[mParticleKitInstanceKey], @42);
    XCTAssertEqualObjects(reportedError.userInfo[NSUnderlyingErrorKey], underlying);
    XCTAssertEqualObjects(reportedError.userInfo[MPKitAPIErrorKey],
                          @"mParticle Kit Attribution handler was called with nil info and no error");
}

- (void)testAttributionErrorOmitsTheInstanceKeyWithoutAKitCode {
    __block NSError *reportedError = nil;
    _kitContainer.attributionCompletionHandler = ^(MPAttributionResult *result, NSError *error) {
        reportedError = error;
    };

    [[[MPKitAPI alloc] initWithKitCode:nil] onAttributionCompleteWithResult:nil error:nil];

    XCTAssertNil(reportedError.userInfo[mParticleKitInstanceKey]);
    XCTAssertNil(reportedError.userInfo[NSUnderlyingErrorKey]);
    XCTAssertEqualObjects(reportedError.userInfo[MPKitAPIErrorKey],
                          @"mParticle Kit Attribution handler was called with nil info and no error");
}

- (void)testAttributionSuccessStampsTheKitCodeAndName {
    __block MPAttributionResult *reportedResult = nil;
    __block NSError *reportedError = nil;
    _kitContainer.attributionCompletionHandler = ^(MPAttributionResult *result, NSError *error) {
        reportedResult = result;
        reportedError = error;
    };

    MPAttributionResult *result = [[MPAttributionResult alloc] init];
    result.linkInfo = @{@"key":@"value"};
    [_kitApi onAttributionCompleteWithResult:result error:nil];

    XCTAssertNil(reportedError);
    XCTAssertEqualObjects(reportedResult.kitCode, @42);
    XCTAssertEqualObjects(reportedResult.kitName, @"KitTest");
    XCTAssertEqualObjects(reportedResult.linkInfo, @{@"key":@"value"});
}

#pragma mark - Logging

// The only coverage of the va_list path itself.
- (void)testCustomLoggerReceivesTheKitPrefixedMessage {
    MPILogLevel originalLevel = [MParticle sharedInstance].logLevel;
    void (^originalLogger)(NSString *) = [MParticle sharedInstance].customLogger;

    __block NSMutableArray<NSString *> *messages = [NSMutableArray array];
    [MParticle sharedInstance].logLevel = MPILogLevelVerbose;
    [MParticle sharedInstance].customLogger = ^(NSString *message) {
        [messages addObject:message];
    };

    [_kitApi logDebug:@"count %d", 3];

    [MParticle sharedInstance].logLevel = originalLevel;
    [MParticle sharedInstance].customLogger = originalLogger;

    XCTAssertEqualObjects(messages, (@[@"mParticle -> KitTest Kit: count 3"]));
}

- (void)testLoggingIsSuppressedAtLevelNone {
    MPILogLevel originalLevel = [MParticle sharedInstance].logLevel;
    void (^originalLogger)(NSString *) = [MParticle sharedInstance].customLogger;

    __block NSMutableArray<NSString *> *messages = [NSMutableArray array];
    [MParticle sharedInstance].logLevel = MPILogLevelNone;
    [MParticle sharedInstance].customLogger = ^(NSString *message) {
        [messages addObject:message];
    };

    [_kitApi logError:@"boom"];
    [_kitApi logWarning:@"boom"];
    [_kitApi logDebug:@"boom"];
    [_kitApi logVerbose:@"boom"];

    [MParticle sharedInstance].logLevel = originalLevel;
    [MParticle sharedInstance].customLogger = originalLogger;

    XCTAssertEqual(messages.count, 0);
}

- (void)testSwiftLogLevelRawValuesMatchObjC {
    XCTAssertEqual((NSUInteger)MPILogLevelSwiftNone, (NSUInteger)MPILogLevelNone);
    XCTAssertEqual((NSUInteger)MPILogLevelSwiftError, (NSUInteger)MPILogLevelError);
    XCTAssertEqual((NSUInteger)MPILogLevelSwiftWarning, (NSUInteger)MPILogLevelWarning);
    XCTAssertEqual((NSUInteger)MPILogLevelSwiftDebug, (NSUInteger)MPILogLevelDebug);
    XCTAssertEqual((NSUInteger)MPILogLevelSwiftVerbose, (NSUInteger)MPILogLevelVerbose);
}

@synthesize started;

@end

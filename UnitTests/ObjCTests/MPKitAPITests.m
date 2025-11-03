#ifndef MPARTICLE_LOCATION_DISABLE
@import mParticle_Apple_SDK;
#else
@import mParticle_Apple_SDK_NoLocation;
#endif

#import <XCTest/XCTest.h>
#import "MPBaseTestCase.h"
#import "MPBackendController.h"
#import "MPPersistenceController.h"
#import "MPKitContainer.h"
#import "MPKitConfiguration.h"
#import "MPIConstants.h"

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


@interface MPKitAPI ()

- (id)initWithKitCode:(NSNumber *)integrationId;
    
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
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
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
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    [userDefaults setMPObject:userAttributes forKey:kMPUserAttributeKey userId:currentUser.userId];
    
    NSString *goodHashedKey = [MPIHasher hashString:@"good data"];
    NSString *badHashedKey = [MPIHasher hashString:@"bad data"];
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
    [currentUser setUserAttributes:userAttributes];
    
    NSString *goodHashedKey = [MPIHasher hashString:@"good data"];
    NSString *badHashedKey = [MPIHasher hashString:@"bad data"];
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

@synthesize started;

@end

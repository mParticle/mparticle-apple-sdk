#import <XCTest/XCTest.h>
#import "MPKitApi.h"
#import "MPKitContainer.h"
#import "mParticle.h"
#import "MPBackendController.h"
#import "MPKitConfiguration.h"
#import "MPKitInstanceValidator.h"
#import "MPPersistenceController.h"
#import "MPIUserDefaults.h"

@interface MPKitInstanceValidator(BackendControllerTests)

+ (void)includeUnitTestKits:(NSArray<NSNumber *> *)kitCodes;

@end


@interface MPKitContainer ()

- (id<MPKitProtocol>)startKit:(NSNumber *)kitCode configuration:(MPKitConfiguration *)kitConfiguration;

@end

@interface MParticle ()

@property (nonatomic, strong, nonnull) MPBackendController *backendController;

@end

@interface MPBackendController ()

@property (nonatomic, unsafe_unretained, readwrite) MPInitializationStatus initializationStatus;

- (void)clearUserAttributes;

@end


@interface MPKitAPI ()

- (id)initWithKitCode:(NSNumber *)kitCode;
    
@end

@interface MPKitAPITests : XCTestCase

@property (nonatomic) MPKitAPI *kitApi;
@property (nonatomic) MPKitContainer *kitContainer;

@end

@implementation MPKitAPITests

- (void)setUp {
    [super setUp];
    
    [MParticle sharedInstance].backendController.initializationStatus = MPInitializationStatusStarted;

    [MPKitInstanceValidator includeUnitTestKits:@[@42]];
    _kitContainer = [MPKitContainer sharedInstance];
    
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
    if (!registeredKits) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClass" startImmediately:NO];
        [MPKitContainer registerKit:kitRegister];
        
        NSDictionary *configuration = @{
                                        @"id":@42,
                                        @"as":@{
                                                @"appId":@"MyAppId"
                                                }
                                        };
        
        MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
        [_kitContainer startKit:@42 configuration:kitConfiguration];
    }
    
    [[MPPersistenceController sharedInstance] openDatabase];
    
    _kitApi = [[MPKitAPI alloc] initWithKitCode:@42];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testIntegrationAttributes {
    [[MParticle sharedInstance] setIntegrationAttributes:@{@"Test key":@"Test value"} forKit:@42];

    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"testConfigKey":@"testConfigValue"
                                            }
                                }
                                ];
    
    [_kitContainer configureKits:nil];
    [_kitContainer configureKits:configurations];
    
    NSDictionary *integrationAttributes = [_kitApi integrationAttributes];
    NSString *value = integrationAttributes[@"Test key"];
    XCTAssertEqualObjects(value, @"Test value");
}

- (void)testUserIdentities {
    [[MParticle sharedInstance] setUserIdentity:@"example@example.com" identityType:MPUserIdentityEmail];
    [[MParticle sharedInstance] setUserIdentity:@"12345" identityType:MPUserIdentityCustomerId];
    
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
    
    NSDictionary *identities = _kitApi.userIdentities;
    NSString *email = identities[@(MPUserIdentityEmail)];
    NSString *customerId = identities[@(MPUserIdentityCustomerId)];
    
    XCTAssertNil(email, @"Kit api is not filtering user identities");
    XCTAssertEqualObjects(customerId, @"12345", @"Kit api is filtering user identities when it shouldn't");
}

- (void)testUserAttributes {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test"];
    MPBackendController *backendController = [MParticle sharedInstance].backendController;
    [backendController clearUserAttributes];
    
    [[MParticle sharedInstance].backendController setUserAttribute:@"$Age" value:@24 attempt:0 completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {
        [[MParticle sharedInstance].backendController setUserAttribute:@"teeth" value:@"sharp" attempt:0 completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {
            
            
            NSArray *configurations = @[
                                        @{
                                            @"id":@(42),
                                            @"as":@{
                                                    @"testConfigKey":@"testConfigValue"
                                                    },
                                            @"hs":@{
                                                    @"ua":@{
                                                            @"1168987":@0 // $Age
                                                            }
                                                    }
                                            }
                                        ];
            
            [_kitContainer configureKits:nil];
            [_kitContainer configureKits:configurations];
            
            NSDictionary<NSString *, id> *userAttributes = [_kitApi userAttributes];
            NSString *age = userAttributes[@"$Age"];
            NSString *teeth = userAttributes[@"teeth"];
            
            XCTAssertEqual(userAttributes.count, 1);
            XCTAssertNil(age, @"User attribute should have been filtered.");
            XCTAssertNotNil(teeth, @"User attribute should not have been filtered.");
            [backendController clearUserAttributes];
            [expectation fulfill];
        }];
    }];
    
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end

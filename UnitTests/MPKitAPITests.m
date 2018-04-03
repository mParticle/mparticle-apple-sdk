#import <XCTest/XCTest.h>
#import "MPKitApi.h"
#import "MPKitContainer.h"
#import "mParticle.h"
#import "MPBackendController.h"
#import "MPKitConfiguration.h"
#import "MPKitInstanceValidator.h"
#import "MPPersistenceController.h"
#import "MPIUserDefaults.h"
#import "MPIConstants.h"
#import "FilteredMParticleUser.h"

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

#pragma mark - MPKitAPITests unit test class
@interface MPKitAPITests : XCTestCase  <MPKitProtocol>

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
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
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

- (nonnull MPKitExecStatus *)didFinishLaunchingWithConfiguration:(nonnull NSDictionary *)configuration {
    return [[MPKitExecStatus alloc] initWithSDKCode:@1 returnCode:MPKitReturnCodeSuccess];
}

+ (nonnull NSNumber *)kitCode {
    return @42;
}

- (void)testUserIdentities {
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
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    [userDefaults setMPObject:userIdentities forKey:@"ui" userId:[MPPersistenceController mpId]];
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

- (void)testUserAttributes {
    [MPKitInstanceValidator includeUnitTestKits:@[@42, @314]];
    
    NSDictionary *configuration1 = @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"testConfigKey":@"testConfigValue"
                                            },
                                    @"hs":@{
                                            @"ua":@{
                                                    @"1168987":@0 // $Age
                                                    }
                                            }
                                    };
    
    NSDictionary *configuration2 = @{
                                     @"id":@314,
                                     @"as":@{
                                             @"appId":@"unique id"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1, configuration2];
    [[MPKitContainer sharedInstance] configureKits:nil];
    [[MPKitContainer sharedInstance] configureKits:kitConfigs];
    
    MPBackendController *backendController = [MParticle sharedInstance].backendController;
    
    MPInitializationStatus originalInitializationStatus = backendController.initializationStatus;
    backendController.initializationStatus = MPInitializationStatusStarted;
    
    MParticle *mParticle = [MParticle sharedInstance];
    mParticle.backendController.initializationStatus = MPInitializationStatusStarted;
    
    NSDictionary *attributes = @{@"TardisKey1":@"Master",
                                 @"TardisKey2":@"Guest",
                                 @"TardisKey3":@42,
                                 @"TardisKey4":@[@"alohomora", @"open sesame"],
                                 @"1168987": @"The Doctor"
                                 };
    
    [attributes enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSArray class]]) {
            [mParticle.identity.currentUser setUserAttributeList:key values:obj];
            [backendController setUserAttribute:key values:obj attempt:0 completionHandler:^(NSString * _Nonnull key, NSArray<NSString *> * _Nullable values, MPExecStatus execStatus) {}];
        } else {
            [mParticle.identity.currentUser setUserAttribute:key value:obj];
            [backendController setUserAttribute:key value:obj attempt:0 completionHandler:^(NSString * _Nonnull key, id  _Nullable value, MPExecStatus execStatus) {}];
        }
    }];
        
    //Test getCurrentUser
    MPKitAPI *kitAPI = [[MPKitAPI alloc] initWithKitCode:@42];
    FilteredMParticleUser *kitUser = [kitAPI getCurrentUserWithKit:self];
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    [userDefaults setMPObject:[NSDate date] forKey:kMPLastIdentifiedDate userId:kitUser.userId];
    
    NSDictionary *userAttributes = kitUser.userAttributes;
    attributes = @{@"TardisKey1":@"Master",
                   @"TardisKey2":@"Guest",
                   @"TardisKey3":@42,
                   @"TardisKey4":@[@"alohomora", @"open sesame"]
                   };
    
    XCTAssertEqualObjects(userAttributes, attributes);
    
    //Test incrementUserAttribute
    [kitAPI incrementUserAttribute:@"TardisKey4" byValue:@1 forUser:kitUser];
    kitUser = [kitAPI getCurrentUserWithKit:self];
    userAttributes = kitUser.userAttributes;
    
    XCTAssertEqualObjects(userAttributes, attributes);
    
    [backendController incrementUserAttribute:@"TardisKey3" byValue:@1];
    kitUser = [kitAPI getCurrentUserWithKit:self];
    userAttributes = kitUser.userAttributes;
    
    attributes = @{@"TardisKey1":@"Master",
                   @"TardisKey2":@"Guest",
                   @"TardisKey3":@43,
                   @"TardisKey4":@[@"alohomora", @"open sesame"]
                   };
    
    XCTAssertEqualObjects(userAttributes, attributes);
    
    //Test setUserAttribute
    [kitAPI setUserAttribute:@"TardisKey4" value:@"Door" forUser:kitUser];
    kitUser = [kitAPI getCurrentUserWithKit:self];
    userAttributes = kitUser.userAttributes;
    XCTAssertNotEqualObjects(userAttributes, attributes);
    XCTAssertEqualObjects(userAttributes[@"TardisKey4"], @"Door");
    
    attributes = @{@"TardisKey1":@"Master",
                   @"TardisKey2":@"Guest",
                   @"TardisKey3":@43,
                   @"TardisKey4":@"Door"
                   };
    
    XCTAssertEqualObjects(userAttributes, attributes);
    
    NSMutableString *longString = [[NSMutableString alloc] initWithCapacity:(LIMIT_USER_ATTR_LENGTH + 1)];
    for (int i = 0; i < (LIMIT_USER_ATTR_LENGTH + 1); ++i) {
        [longString appendString:@"T"];
    }
    
    [kitAPI setUserAttribute:@"TardisKey1" value:longString forUser:kitUser];
    kitUser = [kitAPI getCurrentUserWithKit:self];
    userAttributes = kitUser.userAttributes;
    XCTAssertEqualObjects(userAttributes, attributes);
    
    [kitAPI setUserAttribute:@"TardisKey1" value:@"" forUser:kitUser];
    kitUser = [kitAPI getCurrentUserWithKit:self];
    userAttributes = kitUser.userAttributes;
    XCTAssertNotEqualObjects(userAttributes, attributes);
    XCTAssertNil(userAttributes[@"TardisKey1"]);
    
    attributes = @{@"TardisKey2":@"Guest",
                   @"TardisKey3":@43,
                   @"TardisKey4":@"Door"
                   };
    
    XCTAssertEqualObjects(userAttributes, attributes);
    
    //Test setUserAttributeList
    NSArray *values = @[@"alohomora", @314];
    [kitAPI setUserAttributeList:@"TardisKey4" values:values forUser:kitUser];
    XCTAssertEqualObjects(userAttributes[@"TardisKey4"], @"Door");
    kitUser = [kitAPI getCurrentUserWithKit:self];
    userAttributes = kitUser.userAttributes;
    
    XCTAssertEqualObjects(userAttributes, attributes);
    
    //Test removeUserAttribute
    [kitAPI removeUserAttribute:@"TardisKey2" forUser:kitUser];
    kitUser = [kitAPI getCurrentUserWithKit:self];
    userAttributes = kitUser.userAttributes;
    XCTAssertNotEqualObjects(userAttributes, attributes);
    XCTAssertNil(userAttributes[@"TardisKey1"]);
    
    attributes = @{@"TardisKey3":@43,
                   @"TardisKey4":@"Door"
                   };
    
    XCTAssertEqualObjects(userAttributes, attributes);

    backendController.initializationStatus = originalInitializationStatus;
    mParticle.backendController.initializationStatus = originalInitializationStatus;
    [[MPKitContainer sharedInstance] configureKits:nil];
}

@synthesize started;

@end

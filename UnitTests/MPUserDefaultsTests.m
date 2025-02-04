#import <XCTest/XCTest.h>
#import "MPIConstants.h"
#import "mParticle.h"
#import "MPPersistenceController.h"
#import "MPBaseTestCase.h"
#import "MPKitContainer.h"
#import "MPStateMachine.h"
#import "MParticleSwift.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController_PRIVATE *persistenceController;
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;

@end

@interface MPUserDefaultsTests : MPBaseTestCase {
    MPKitContainer_PRIVATE *kitContainer;
}

@end

@implementation MPUserDefaultsTests

- (void)setUp {
    [super setUp];
    
    [MParticle sharedInstance].stateMachine.apiKey = @"unit_test_app_key";
    [MParticle sharedInstance].stateMachine.secret = @"unit_test_secret";
    
    [MParticle sharedInstance].kitContainer_PRIVATE = [[MPKitContainer_PRIVATE alloc] init];
    kitContainer = [MParticle sharedInstance].kitContainer_PRIVATE;
    
    [MParticle sharedInstance].backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
}

- (void)tearDown {
    for (MPKitRegister *kitRegister in [MPKitContainer_PRIVATE registeredKits]) {
        kitRegister.wrapperInstance = nil;
    }
    kitContainer = nil;

    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setSharedGroupIdentifier:nil];

    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] resetDefaults];

    [super tearDown];
}

- (void)testUserIDsInUserDefaults {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    
    [userDefaults setMPObject:[NSDate date] forKey:@"lud" userId:@1];
    [userDefaults setMPObject:[NSDate date] forKey:@"lud" userId:[NSNumber numberWithLongLong:INT64_MAX]];
    [userDefaults setMPObject:[NSDate date] forKey:@"lud" userId:[NSNumber numberWithLongLong:INT64_MIN]];
    [userDefaults synchronize];
    
    NSArray<NSNumber *> *array = [userDefaults userIDsInUserDefaults];
    
    XCTAssert([array containsObject:@1]);
    XCTAssert([array containsObject:[NSNumber numberWithLongLong:INT64_MAX]]);
    XCTAssert([array containsObject:[NSNumber numberWithLongLong:INT64_MIN]]);
}

- (void)testResetDefaults {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    
    [userDefaults setMPObject:[NSDate date] forKey:@"lud" userId:@1];
    [userDefaults setMPObject:[NSDate date] forKey:@"lud" userId:[NSNumber numberWithLongLong:INT64_MAX]];
    [userDefaults setMPObject:[NSDate date] forKey:@"lud" userId:[NSNumber numberWithLongLong:INT64_MIN]];
    
    [[NSUserDefaults standardUserDefaults] setObject:@"userSetting" forKey:@"userKey"];
    
    [userDefaults resetDefaults];
        
    NSArray<NSNumber *> *array = [userDefaults userIDsInUserDefaults];
    
    XCTAssert(![array containsObject:@1]);
    XCTAssert(![array containsObject:[NSNumber numberWithLongLong:INT64_MAX]]);
    XCTAssert(![array containsObject:[NSNumber numberWithLongLong:INT64_MIN]]);
    
    XCTAssert([[NSUserDefaults standardUserDefaults] objectForKey:@"userKey"]);
}

- (void)testMigrate {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    
    [userDefaults setObject:@"test" forKeyedSubscript:@"mparticleKey"];
    
    [userDefaults synchronize];
    
    [userDefaults setSharedGroupIdentifier:@"groupID"];
        
    NSUserDefaults *groupDefaults = [[NSUserDefaults alloc] initWithSuiteName: @"groupID"];
    XCTAssertEqualObjects(([groupDefaults objectForKey:@"mParticle::mparticleKey"]), @"test");
}

- (void)testMigrateGroupDoesNotMigrateClientDefaults {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    
    [[NSUserDefaults standardUserDefaults] setObject:@"clientSetting" forKey:@"clientKey"];
    
    [userDefaults setSharedGroupIdentifier:@"groupID"];

    XCTAssert([[NSUserDefaults standardUserDefaults] objectForKey:@"clientKey"]);
    XCTAssert(![[[NSUserDefaults alloc] initWithSuiteName: @"groupID"] objectForKey:@"clientKey"]);
}

- (void)testMigrateGroupWithMultipleUsers {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    
    [userDefaults setMPObject:[NSDate date] forKey:@"lud" userId:@1];
    [userDefaults setMPObject:[NSDate date] forKey:@"lud" userId:[NSNumber numberWithLongLong:INT64_MAX]];
    [userDefaults setMPObject:[NSDate date] forKey:@"lud" userId:[NSNumber numberWithLongLong:INT64_MIN]];
    
    [userDefaults setSharedGroupIdentifier:@"groupID"];

    NSArray<NSNumber *> *array = [userDefaults userIDsInUserDefaults];
    
    XCTAssert([array containsObject:@1]);
    XCTAssert([array containsObject:[NSNumber numberWithLongLong:INT64_MAX]]);
    XCTAssert([array containsObject:[NSNumber numberWithLongLong:INT64_MIN]]);
}

- (void)testValidConfiguration {
    [MPPersistenceController_PRIVATE setMpid:@12];
    
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };
    
    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1, configuration2];
    
    NSString *eTag = @"1.618-2.718-3.141-42";
    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    
    NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];
    
    XCTAssertEqualObjects(responseConfiguration, [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration]);
}

- (void)testUpdateConfigurations {
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key Update Test"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1];
    
    NSString *eTag = @"1.618-2.718-3.141-42";
    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    
    NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];
    
    XCTAssertNotEqualObjects(nil, [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration]);
    XCTAssertEqualObjects(responseConfiguration, [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration]);

    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };
    kitConfigs = @[configuration1, configuration2];
    
    NSDictionary *responseConfiguration2 = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:responseConfiguration2 eTag:eTag requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];
    
    XCTAssertNotEqualObjects(responseConfiguration, [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration]);
    XCTAssertEqualObjects(responseConfiguration2, [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration]);
}

- (void)testValidExpandedConfiguration {
    [MPPersistenceController_PRIVATE setMpid:@12];
    
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };
    
    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1, configuration2];
    
    NSString *eTag = @"1.618-2.718-3.141-42";
    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    
    MPUserDefaults *standardDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
    [standardDefaults setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:4000 maxAge:@90000];
    
    XCTAssertEqualObjects(responseConfiguration, [standardDefaults getConfiguration]);
    XCTAssertEqualObjects(standardDefaults[kMPConfigProvisionedTimestampKey], @(requestTimestamp - 4000));
    XCTAssertEqualObjects(standardDefaults[kMPConfigMaxAgeHeaderKey], @90000);
}

- (void)testValidExpandedConfigurationWithNilCurrentAge {
    [MPPersistenceController_PRIVATE setMpid:@12];
    
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };
    
    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1, configuration2];
    
    NSString *eTag = @"1.618-2.718-3.141-42";
    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    
    MPUserDefaults *standardDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString *currentAge;
    [standardDefaults setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:currentAge.doubleValue maxAge:@90000];
    
    XCTAssertEqualObjects(responseConfiguration, [standardDefaults getConfiguration]);
    XCTAssertEqualObjects(standardDefaults[kMPConfigProvisionedTimestampKey], @(requestTimestamp));
    XCTAssertEqualObjects(standardDefaults[kMPConfigMaxAgeHeaderKey], @90000);
}

- (void)testValidExpandedConfigurationNoMaxAge {
    [MPPersistenceController_PRIVATE setMpid:@12];
    
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };
    
    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1, configuration2];
    
    NSString *eTag = @"1.618-2.718-3.141-42";
    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    
    MPUserDefaults *standardDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
    [standardDefaults setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:4000 maxAge:@90000];
    
    XCTAssertEqualObjects(responseConfiguration, [standardDefaults getConfiguration]);
    XCTAssertEqualObjects(standardDefaults[kMPConfigProvisionedTimestampKey], @(requestTimestamp - 4000));
    XCTAssertEqualObjects(standardDefaults[kMPConfigMaxAgeHeaderKey], @90000);
    
    [standardDefaults setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:4000 maxAge:nil];
    XCTAssertEqualObjects(responseConfiguration, [standardDefaults getConfiguration]);
    XCTAssertEqualObjects(standardDefaults[kMPConfigProvisionedTimestampKey], @(requestTimestamp - 4000));
    XCTAssertEqualObjects(standardDefaults[kMPConfigMaxAgeHeaderKey], nil);
}

- (void)testDeleteConfiguration {
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] deleteConfiguration];
    
    XCTAssertNil([[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration]);
}

- (void)testBadDataConfiguration {
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] deleteConfiguration];
    NSNumber *userID = [[[MParticle sharedInstance] identity] currentUser].userId;

    unsigned char ch1[] = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x04, 0x01, 0x00, 0x0F };
    NSData *badData = [[NSData alloc] initWithBytes:ch1
                                           length:sizeof(ch1)];
    
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setMPObject:badData forKey:kMResponseConfigurationKey userId:userID];

    XCTAssertNil([[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration]);
}

- (void)testMigrateConfiguration {
    NSNumber *userID = [[[MParticle sharedInstance] identity] currentUser].userId;

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMResponseConfigurationMigrationKey];
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] removeMPObjectForKey:kMPHTTPETagHeaderKey userId:userID];
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration];
    
    XCTAssertNotNil([[NSUserDefaults standardUserDefaults] objectForKey:kMResponseConfigurationMigrationKey]);
}

- (void)testNullConfig {
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key Update Test",
                                             @"foo": [NSNull null]
                                             }
                                     };
    NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:configuration1 eTag:@"bar" requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];
    
    XCTAssertEqualObjects(configuration1, [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration]);
}

- (void)testSetConfigurationWhenNil {
    XCTAssertEqualObjects(nil, [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration]);
    
    [MPPersistenceController_PRIVATE setMpid:@12];
    
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };
    
    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1, configuration2];
    
    NSString *eTag = @"1.618-2.718-3.141-42";
    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    
    NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];
    
    XCTAssertEqualObjects(responseConfiguration, [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration]);
}

- (void)testStringFromDeviceToken {
    NSData *data = [[NSData alloc] init];
    NSString *tokenString = [MPUserDefaults stringFromDeviceToken:data];
    
    XCTAssertNil(tokenString);
    
    data = [NSData dataWithBytes:(unsigned char[]){0x0F} length:1];
    tokenString = [MPUserDefaults stringFromDeviceToken:data];

    XCTAssertEqualObjects(tokenString, @"0f");
}

@end

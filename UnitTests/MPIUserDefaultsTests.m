#import <XCTest/XCTest.h>
#import "MPIUserDefaults.h"
#import "MPIConstants.h"
#import "mParticle.h"
#import "MPPersistenceController.h"
#import "MPBaseTestCase.h"
#import "MPKitContainer.h"
#import "MPStateMachine.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPPersistenceController *persistenceController;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong) MPKitContainer *kitContainer;

@end

@interface MPIUserDefaultsTests : MPBaseTestCase {
    MPKitContainer *kitContainer;
}

@end

@implementation MPIUserDefaultsTests

- (void)setUp {
    [super setUp];
    
    [MParticle sharedInstance].stateMachine = [[MPStateMachine alloc] init];
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    stateMachine.apiKey = @"unit_test_app_key";
    stateMachine.secret = @"unit_test_secret";
    
    [MParticle sharedInstance].kitContainer = [[MPKitContainer alloc] init];
    kitContainer = [MParticle sharedInstance].kitContainer;
}

- (void)tearDown {
    for (MPKitRegister *kitRegister in [MPKitContainer registeredKits]) {
        kitRegister.wrapperInstance = nil;
    }
    kitContainer = nil;

    [[MPIUserDefaults standardUserDefaults] setSharedGroupIdentifier:nil];

    [[MPIUserDefaults standardUserDefaults] resetDefaults];

    [super tearDown];
}

- (void)testUserIDsInUserDefaults {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    
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
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    
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
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    
    [userDefaults setObject:@"test" forKeyedSubscript:@"mparticleKey"];
    
    [userDefaults synchronize];
    
    [userDefaults setSharedGroupIdentifier:@"groupID"];
        
    NSUserDefaults *groupDefaults = [[NSUserDefaults alloc] initWithSuiteName: @"groupID"];
    XCTAssertEqualObjects(([groupDefaults objectForKey:@"mParticle::mparticleKey"]), @"test");
}

- (void)testMigrateGroupDoesNotMigrateClientDefaults {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    
    [[NSUserDefaults standardUserDefaults] setObject:@"clientSetting" forKey:@"clientKey"];
    
    [userDefaults setSharedGroupIdentifier:@"groupID"];

    XCTAssert([[NSUserDefaults standardUserDefaults] objectForKey:@"clientKey"]);
    XCTAssert(![[[NSUserDefaults alloc] initWithSuiteName: @"groupID"] objectForKey:@"clientKey"]);
}

- (void)testMigrateGroupWithMultipleUsers {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    
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
    [MPPersistenceController setMpid:@12];
    
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
    [[MPIUserDefaults standardUserDefaults] setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];
    
    XCTAssertEqualObjects(responseConfiguration, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
}

- (void)testInvalidConfigurations {
    [MPPersistenceController setMpid:@12];
    
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
    [[MPIUserDefaults standardUserDefaults] setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];
    NSDictionary *responseDictionary = nil;
    
    [[MPIUserDefaults standardUserDefaults] setConfiguration:responseDictionary eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];
    
    XCTAssertEqualObjects(responseConfiguration, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
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
    [[MPIUserDefaults standardUserDefaults] setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];
    
    XCTAssertNotEqualObjects(nil, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
    XCTAssertEqualObjects(responseConfiguration, [[MPIUserDefaults standardUserDefaults] getConfiguration]);

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
    
    [[MPIUserDefaults standardUserDefaults] setConfiguration:responseConfiguration2 eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];
    
    XCTAssertNotEqualObjects(responseConfiguration, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
    XCTAssertEqualObjects(responseConfiguration2, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
}

- (void)testValidExpandedConfiguration {
    [MPPersistenceController setMpid:@12];
    
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
    
    MPIUserDefaults *standardDefaults = [MPIUserDefaults standardUserDefaults];
    NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
    [standardDefaults setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"4000" maxAge:@90000];
    
    XCTAssertEqualObjects(responseConfiguration, [standardDefaults getConfiguration]);
    XCTAssertEqualObjects(standardDefaults[kMPConfigProvisionedTimestampKey], @(requestTimestamp - 4000));
    XCTAssertEqualObjects(standardDefaults[kMPConfigMaxAgeKey], @90000);
}

- (void)testValidExpandedConfigurationWithNilCurrentAge {
    [MPPersistenceController setMpid:@12];
    
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
    
    MPIUserDefaults *standardDefaults = [MPIUserDefaults standardUserDefaults];
    NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString *currentAge;
    [standardDefaults setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:currentAge maxAge:@90000];
    
    XCTAssertEqualObjects(responseConfiguration, [standardDefaults getConfiguration]);
    XCTAssertEqualObjects(standardDefaults[kMPConfigProvisionedTimestampKey], @(requestTimestamp));
    XCTAssertEqualObjects(standardDefaults[kMPConfigMaxAgeKey], @90000);
}

- (void)testValidExpandedConfigurationNoMaxAge {
    [MPPersistenceController setMpid:@12];
    
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
    
    MPIUserDefaults *standardDefaults = [MPIUserDefaults standardUserDefaults];
    NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
    [standardDefaults setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"4000" maxAge:@90000];
    
    XCTAssertEqualObjects(responseConfiguration, [standardDefaults getConfiguration]);
    XCTAssertEqualObjects(standardDefaults[kMPConfigProvisionedTimestampKey], @(requestTimestamp - 4000));
    XCTAssertEqualObjects(standardDefaults[kMPConfigMaxAgeKey], @90000);
    
    [standardDefaults setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"4000" maxAge:nil];
    XCTAssertEqualObjects(responseConfiguration, [standardDefaults getConfiguration]);
    XCTAssertEqualObjects(standardDefaults[kMPConfigProvisionedTimestampKey], @(requestTimestamp - 4000));
    XCTAssertEqualObjects(standardDefaults[kMPConfigMaxAgeKey], nil);
}

- (void)testInvalidExpandedConfiguration {
    [MPPersistenceController setMpid:@12];
    
    NSString *eTag = @"1.618-2.718-3.141-42";
    NSDictionary *responseConfiguration;
    
    MPIUserDefaults *standardDefaults = [MPIUserDefaults standardUserDefaults];
    NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [standardDefaults setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:@90000];
#pragma clang diagnostic pop
    
    XCTAssertEqualObjects(nil, [standardDefaults getConfiguration]);
    XCTAssertEqualObjects(standardDefaults[kMPConfigProvisionedTimestampKey], nil);
    XCTAssertEqualObjects(standardDefaults[kMPConfigMaxAgeKey],  nil);
}

- (void)testDeleteConfiguration {
    [[MPIUserDefaults standardUserDefaults] deleteConfiguration];
    
    XCTAssertNil([[MPIUserDefaults standardUserDefaults] getConfiguration]);
}

- (void)testBadDataConfiguration {
    [[MPIUserDefaults standardUserDefaults] deleteConfiguration];
    NSNumber *userID = [[[MParticle sharedInstance] identity] currentUser].userId;

    unsigned char ch1[] = { 0x01, 0x02, 0x03, 0x04, 0x05, 0x04, 0x01, 0x00, 0x0F };
    NSData *badData = [[NSData alloc] initWithBytes:ch1
                                           length:sizeof(ch1)];
    
    [[MPIUserDefaults standardUserDefaults] setMPObject:badData forKey:kMResponseConfigurationKey userId:userID];

    XCTAssertNil([[MPIUserDefaults standardUserDefaults] getConfiguration]);
}

- (void)testMigrateConfiguration {
    NSNumber *userID = [[[MParticle sharedInstance] identity] currentUser].userId;

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMResponseConfigurationMigrationKey];
    [[MPIUserDefaults standardUserDefaults] removeMPObjectForKey:kMPHTTPETagHeaderKey userId:userID];
    [[MPIUserDefaults standardUserDefaults] getConfiguration];
    
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
    [[MPIUserDefaults standardUserDefaults] setConfiguration:configuration1 eTag:@"bar" requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];
    
    XCTAssertEqualObjects(configuration1, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
}

- (void)testSetConfigurationWhenNil {
    XCTAssertEqualObjects(nil, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
    
    [MPPersistenceController setMpid:@12];
    
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
    [[MPIUserDefaults standardUserDefaults] setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];
    
    XCTAssertEqualObjects(responseConfiguration, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
}

- (void)testConfigParameters {
    XCTAssertEqualObjects(nil, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
    XCTAssert([[MPIUserDefaults standardUserDefaults] isConfigurationParametersOutdated]);
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSString *initialParameters = userDefaults[kMPConfigParameters];
    XCTAssertEqualObjects(nil, initialParameters);
    
    [MPPersistenceController setMpid:@12];
    
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
    [[MPIUserDefaults standardUserDefaults] setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];
    
    XCTAssertEqualObjects(responseConfiguration, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
    XCTAssertFalse([[MPIUserDefaults standardUserDefaults] isConfigurationParametersOutdated]);
    
    NSString *firstParameters = userDefaults[kMPConfigParameters];
    XCTAssertNotNil(firstParameters);
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
    [MPKitContainer registerKit:kitRegister];
    
    XCTAssertEqualObjects(responseConfiguration, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
    XCTAssertTrue([[MPIUserDefaults standardUserDefaults] isConfigurationParametersOutdated]);
    
    [[MPIUserDefaults standardUserDefaults] setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];
    
    XCTAssertEqualObjects(responseConfiguration, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
    XCTAssertFalse([[MPIUserDefaults standardUserDefaults] isConfigurationParametersOutdated]);
}

- (void)testStringFromDeviceToken {
    NSData *data = [[NSData alloc] init];
    NSString *tokenString = [MPIUserDefaults stringFromDeviceToken:data];
    
    XCTAssertNil(tokenString);
    
    data = [NSData dataWithBytes:(unsigned char[]){0x0F} length:1];
    tokenString = [MPIUserDefaults stringFromDeviceToken:data];

    XCTAssertEqualObjects(tokenString, @"0f");
}

@end

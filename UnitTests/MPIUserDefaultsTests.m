#import <XCTest/XCTest.h>
#import "MPIUserDefaults.h"
#import "MPIConstants.h"
#import "mParticle.h"
#import "MPPersistenceController.h"
#import "MPBaseTestCase.h"

@interface MPIUserDefaultsTests : MPBaseTestCase
@property (nonatomic, strong) NSDictionary *initialResponseConfiguration;

@end

@implementation MPIUserDefaultsTests

- (void)setUp {
    [super setUp];
    
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
    _initialResponseConfiguration = responseConfiguration;
    
    [[MPIUserDefaults standardUserDefaults] setConfiguration:responseConfiguration andETag:eTag];
}

- (void)tearDown {
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
    XCTAssertEqualObjects(self.initialResponseConfiguration, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
}

- (void)testInvalidConfigurations {
    NSString *eTag = nil;
    
    [[MPIUserDefaults standardUserDefaults] setConfiguration:self.initialResponseConfiguration andETag:eTag];
    
    NSNumber *userID = [[[MParticle sharedInstance] identity] currentUser].userId;
    NSString *currentEtag = [[MPIUserDefaults standardUserDefaults] mpObjectForKey:kMPHTTPETagHeaderKey userId:userID];
    
    XCTAssertNotNil(currentEtag);
    
    eTag = @"1.618-2.718-3.141-42";
    NSDictionary *responseDictionary = nil;
    
    [[MPIUserDefaults standardUserDefaults] setConfiguration:responseDictionary andETag:eTag];
    
    XCTAssertEqualObjects(self.initialResponseConfiguration, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
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
    
    [[MPIUserDefaults standardUserDefaults] setConfiguration:responseConfiguration andETag:eTag];
    
    XCTAssertNotEqualObjects(self.initialResponseConfiguration, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
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
    
    [[MPIUserDefaults standardUserDefaults] setConfiguration:responseConfiguration2 andETag:eTag];
    
    XCTAssertNotEqualObjects(responseConfiguration, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
    XCTAssertEqualObjects(responseConfiguration2, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
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
    [[MPIUserDefaults standardUserDefaults] setConfiguration:configuration1 andETag:@"bar"];
    
    XCTAssertEqualObjects(configuration1, [[MPIUserDefaults standardUserDefaults] getConfiguration]);
}

@end

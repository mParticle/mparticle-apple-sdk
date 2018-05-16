#import <XCTest/XCTest.h>
#import "MPIUserDefaults.h"
#import "MPIConstants.h"
#import "mParticle.h"

@interface MPIUserDefaultsTests : XCTestCase
@property (nonatomic, strong) NSDictionary *initialResponseConfiguration;

@end

@implementation MPIUserDefaultsTests

- (void)setUp {
    [super setUp];
    
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
    [[MPIUserDefaults standardUserDefaults] deleteConfiguration];
    [[MPIUserDefaults standardUserDefaults] synchronize];

    [super tearDown];
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

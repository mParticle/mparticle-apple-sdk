#import <XCTest/XCTest.h>
#import "MPKitConfiguration.h"
#import "MPBaseTestCase.h"

@interface MPKitConfigurationTests : MPBaseTestCase {
    MPKitConfiguration *kitConfiguration;
}

@end

@implementation MPKitConfigurationTests

- (void)setUp {
    [super setUp];
    
    NSDictionary *configuration = @{
                                    @"id":@37,
                                    @"avf":@{
                                            @"i":@YES,
                                            @"a":@12345,
                                            @"v":@54321
                                            },
                                    @"as":@{
                                            @"appId":@"MyAppId",
                                            @"currency":@"USD",
                                            @"useCustomerId":@"True",
                                            @"passAllOtherIdentities":@"True",
                                            @"retrieveAttributionData":@"true",
                                            @"enableLogging":@"False",
                                            @"limitAdTracking":@"True"
                                            },
                                    @"bk":@{
                                            @"lo":@10,
                                            @"hi":@20
                                            },
                                    @"hs":@{
                                            @"mt":@{
                                                    @"ss":@0
                                                    },
                                            @"et":@{
                                                    @"52":@0
                                                    },
                                            @"ec":@{
                                                    @"1594525888":@0
                                                    },
                                            @"ea":@{
                                                    @"1217787541":@0
                                                    },
                                            @"svec":@{
                                                    @"1594525888":@0
                                                    },
                                            @"svea":@{
                                                    @"1217787541":@0
                                                    },
                                            @"uid":@{
                                                    @"2":@0
                                                    },
                                            @"ua":@{
                                                    @"1217787541":@0
                                                    },
                                            @"eaa":@{
                                                    @"330558866":@"Tap Count"
                                                    },
                                            @"ear":@{
                                                    @"330558866":@"Tap Count"
                                                    },
                                            @"eas":@{
                                                    @"-94160813":@"Amount"
                                                    }
                                            }
                                    };
    
    kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
}

- (void)tearDown {
    kitConfiguration = nil;
    
    [super tearDown];
}

- (void)testInstance {
    XCTAssertNotNil(kitConfiguration);
    XCTAssertEqualObjects(kitConfiguration.configurationHash, @(762651950));
    XCTAssertEqualObjects(kitConfiguration.integrationId, @37);
    XCTAssertEqualObjects(kitConfiguration.attributeValueFilteringHashedAttribute, @"12345");
    XCTAssertEqualObjects(kitConfiguration.attributeValueFilteringHashedValue, @"54321");
    
    XCTAssertNotNil(kitConfiguration.filters);
    XCTAssertNotNil(kitConfiguration.eventTypeFilters);
    XCTAssertNotNil(kitConfiguration.eventNameFilters);
    XCTAssertNotNil(kitConfiguration.eventAttributeFilters);
    XCTAssertNotNil(kitConfiguration.messageTypeFilters);
    XCTAssertNotNil(kitConfiguration.screenNameFilters);
    XCTAssertNotNil(kitConfiguration.screenAttributeFilters);
    XCTAssertNotNil(kitConfiguration.userIdentityFilters);
    XCTAssertNotNil(kitConfiguration.userAttributeFilters);
    XCTAssertNotNil(kitConfiguration.addEventAttributeList);
    XCTAssertNotNil(kitConfiguration.removeEventAttributeList);
    XCTAssertNotNil(kitConfiguration.singleItemEventAttributeList);
    XCTAssertNotNil(kitConfiguration.bracketConfiguration);
    
    XCTAssertNil(kitConfiguration.commerceEventAttributeFilters);
    XCTAssertNil(kitConfiguration.commerceEventEntityTypeFilters);
    XCTAssertNil(kitConfiguration.commerceEventAppFamilyAttributeFilters);
    XCTAssertNil(kitConfiguration.configuredMessageTypeProjections);
    XCTAssertNil(kitConfiguration.defaultProjections);
    XCTAssertNil(kitConfiguration.projections);
    
    XCTAssertTrue(kitConfiguration.attributeValueFilteringIsActive);
    XCTAssertTrue(kitConfiguration.attributeValueFilteringShouldIncludeMatches);
    XCTAssertFalse(kitConfiguration.excludeAnonymousUsers);
}

- (void)testCopyAndCoding {
    MPKitConfiguration *copyKitConfiguration = [kitConfiguration copy];
    XCTAssertEqualObjects(kitConfiguration, copyKitConfiguration);
    
    NSData *kitConfigurationData = [NSKeyedArchiver archivedDataWithRootObject:kitConfiguration];
    XCTAssertNotNil(kitConfigurationData);
    
    MPKitConfiguration *deserializedKitConfiguration = [NSKeyedUnarchiver unarchiveObjectWithData:kitConfigurationData];
    XCTAssertNotNil(deserializedKitConfiguration);
    XCTAssertEqualObjects(deserializedKitConfiguration, copyKitConfiguration);
}

- (void)testInvalidConfiguration {
    NSDictionary *configuration = nil;
    MPKitConfiguration *kitConfig = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    XCTAssertNil(kitConfig);
    
    configuration = (NSDictionary *)[NSNull null];
    kitConfig = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    XCTAssertNil(kitConfig);
    
    configuration = @{
                      @"id":[NSNull null],
                      @"avf":@{
                              @"i":[NSNull null],
                              @"a":[NSNull null],
                              @"v":[NSNull null]
                              },
                      @"as":@{
                              @"appId":@"MyAppId",
                              @"currency":@"USD",
                              @"useCustomerId":@"True",
                              @"passAllOtherIdentities":@"True",
                              @"retrieveAttributionData":@"true",
                              @"enableLogging":@"False",
                              @"limitAdTracking":@"True"
                              },
                      @"bk":@{
                              @"lo":[NSNull null],
                              @"hi":[NSNull null]
                              },
                      @"hs":@{
                              @"mt":[NSNull null],
                              @"et":[NSNull null],
                              @"ec":[NSNull null],
                              @"ea":[NSNull null],
                              @"svec":[NSNull null],
                              @"svea":[NSNull null],
                              @"uid":[NSNull null],
                              @"ua":[NSNull null],
                              @"eaa":[NSNull null],
                              @"ear":[NSNull null],
                              @"eas":[NSNull null]
                              }
                      };
    
    kitConfig = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    XCTAssertNil(kitConfig);
    
    configuration = @{
                      @"id":@80,
                      @"avf":[NSNull null],
                      @"as":@{
                              @"appId":@"MyAppId"
                              },
                      @"bk":[NSNull null],
                      @"hs":[NSNull null]
                      };
    
    kitConfig = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    XCTAssertNotNil(kitConfig);
    XCTAssertEqualObjects(kitConfig.configurationHash, @(1495473349));
    XCTAssertEqualObjects(kitConfig.integrationId, @80);
    
    XCTAssertNil(kitConfig.filters);
    XCTAssertNil(kitConfig.eventTypeFilters);
    XCTAssertNil(kitConfig.eventNameFilters);
    XCTAssertNil(kitConfig.eventAttributeFilters);
    XCTAssertNil(kitConfig.messageTypeFilters);
    XCTAssertNil(kitConfig.screenNameFilters);
    XCTAssertNil(kitConfig.screenAttributeFilters);
    XCTAssertNil(kitConfig.userIdentityFilters);
    XCTAssertNil(kitConfig.userAttributeFilters);
    XCTAssertNil(kitConfig.addEventAttributeList);
    XCTAssertNil(kitConfig.removeEventAttributeList);
    XCTAssertNil(kitConfig.singleItemEventAttributeList);
    XCTAssertNil(kitConfig.bracketConfiguration);
    XCTAssertNil(kitConfig.commerceEventAttributeFilters);
    XCTAssertNil(kitConfig.commerceEventEntityTypeFilters);
    XCTAssertNil(kitConfig.commerceEventAppFamilyAttributeFilters);
    XCTAssertNil(kitConfig.configuredMessageTypeProjections);
    XCTAssertNil(kitConfig.defaultProjections);
    XCTAssertNil(kitConfig.projections);
    XCTAssertNil(kitConfig.attributeValueFilteringHashedAttribute);
    XCTAssertNil(kitConfig.attributeValueFilteringHashedValue);
    
    XCTAssertFalse(kitConfig.attributeValueFilteringIsActive);
    XCTAssertFalse(kitConfig.attributeValueFilteringShouldIncludeMatches);
    XCTAssertFalse(kitConfig.excludeAnonymousUsers);
}

- (void)testKitConfigurationEncoding {
    MPKitConfiguration *persistedKitConfiguration = [self attemptSecureEncodingwithClass:[MPKitConfiguration class] Object:kitConfiguration];
    XCTAssertEqualObjects(kitConfiguration, persistedKitConfiguration);
}

- (void)testStripNullsInConfig {
    NSDictionary *configuration = @{
                      @"id":@80,
                      @"avf":[NSNull null],
                      @"as":@{
                              @"foo":@"bar",
                              @"appId":[NSNull null]
                              },
                      @"bk":[NSNull null],
                      @"hs":[NSNull null]
                      };
    MPKitConfiguration *kitConfig = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    NSDictionary *config = kitConfig.configuration;
    XCTAssertNotNil(config);
    XCTAssertEqualObjects(config[@"foo"], @"bar");
    NSString *value = config[@"appId"];
    XCTAssertNil(value);
}

@end

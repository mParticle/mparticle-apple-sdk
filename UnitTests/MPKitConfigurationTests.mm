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
    XCTAssertNotNil(kitConfiguration, @"Should not have been nil.");
    XCTAssertEqualObjects(kitConfiguration.configurationHash, @(-2046674642), @"Should have been equal.");
    XCTAssertEqualObjects(kitConfiguration.kitCode, @37, @"Should have been equal.");
    XCTAssertEqualObjects(kitConfiguration.attributeValueFilteringHashedAttribute, @"12345", @"Should have been equal.");
    XCTAssertEqualObjects(kitConfiguration.attributeValueFilteringHashedValue, @"54321", @"Should have been equal.");
    
    XCTAssertNotNil(kitConfiguration.filters, @"Should not have been nil.");
    XCTAssertNotNil(kitConfiguration.eventTypeFilters, @"Should not have been nil.");
    XCTAssertNotNil(kitConfiguration.eventNameFilters, @"Should not have been nil.");
    XCTAssertNotNil(kitConfiguration.eventAttributeFilters, @"Should not have been nil.");
    XCTAssertNotNil(kitConfiguration.messageTypeFilters, @"Should not have been nil.");
    XCTAssertNotNil(kitConfiguration.screenNameFilters, @"Should not have been nil.");
    XCTAssertNotNil(kitConfiguration.screenAttributeFilters, @"Should not have been nil.");
    XCTAssertNotNil(kitConfiguration.userIdentityFilters, @"Should not have been nil.");
    XCTAssertNotNil(kitConfiguration.userAttributeFilters, @"Should not have been nil.");
    XCTAssertNotNil(kitConfiguration.addEventAttributeList, @"Should not have been nil.");
    XCTAssertNotNil(kitConfiguration.removeEventAttributeList, @"Should not have been nil.");
    XCTAssertNotNil(kitConfiguration.singleItemEventAttributeList, @"Should not have been nil.");
    XCTAssertNotNil(kitConfiguration.bracketConfiguration, @"Should not have been nil.");

    XCTAssertNil(kitConfiguration.commerceEventAttributeFilters, @"Should have been nil.");
    XCTAssertNil(kitConfiguration.commerceEventEntityTypeFilters, @"Should have been nil.");
    XCTAssertNil(kitConfiguration.commerceEventAppFamilyAttributeFilters, @"Should have been nil.");
    XCTAssertNil(kitConfiguration.configuredMessageTypeProjections, @"Should have been nil.");
    XCTAssertNil(kitConfiguration.defaultProjections, @"Should have been nil.");
    XCTAssertNil(kitConfiguration.projections, @"Should have been nil.");
    
    XCTAssertTrue(kitConfiguration.attributeValueFilteringIsActive, @"Should have been true.");
    XCTAssertTrue(kitConfiguration.attributeValueFilteringShouldIncludeMatches, @"Should have been true.");
}

- (void)testCopyAndCoding {
    MPKitConfiguration *copyKitConfiguration = [kitConfiguration copy];
    XCTAssertEqualObjects(kitConfiguration, copyKitConfiguration, @"Should have been equal.");
    
    NSData *kitConfigurationData = [NSKeyedArchiver archivedDataWithRootObject:kitConfiguration];
    XCTAssertNotNil(kitConfigurationData, @"Should not have been nil.");
    
    MPKitConfiguration *deserializedKitConfiguration = [NSKeyedUnarchiver unarchiveObjectWithData:kitConfigurationData];
    XCTAssertNotNil(deserializedKitConfiguration, @"Should not have been nil.");
    XCTAssertEqualObjects(deserializedKitConfiguration, copyKitConfiguration, @"Should have been equal.");
}

- (void)testInvalidConfiguration {
    NSDictionary *configuration = nil;
    MPKitConfiguration *kitConfig = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    XCTAssertNil(kitConfig, @"Should have been nil");
    
    configuration = (NSDictionary *)[NSNull null];
    kitConfig = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    XCTAssertNil(kitConfig, @"Should have been nil");
    
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
    XCTAssertNil(kitConfig, @"Should have been nil");

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
    XCTAssertNotNil(kitConfig, @"Should not have been nil");
    XCTAssertEqualObjects(kitConfig.configurationHash, @(-299494203), @"Should have been equal.");
    XCTAssertEqualObjects(kitConfig.kitCode, @80, @"Should have been equal.");
    
    XCTAssertNil(kitConfig.filters, @"Should have been nil.");
    XCTAssertNil(kitConfig.eventTypeFilters, @"Should have been nil.");
    XCTAssertNil(kitConfig.eventNameFilters, @"Should have been nil.");
    XCTAssertNil(kitConfig.eventAttributeFilters, @"Should have been nil.");
    XCTAssertNil(kitConfig.messageTypeFilters, @"Should have been nil.");
    XCTAssertNil(kitConfig.screenNameFilters, @"Should have been nil.");
    XCTAssertNil(kitConfig.screenAttributeFilters, @"Should have been nil.");
    XCTAssertNil(kitConfig.userIdentityFilters, @"Should have been nil.");
    XCTAssertNil(kitConfig.userAttributeFilters, @"Should have been nil.");
    XCTAssertNil(kitConfig.addEventAttributeList, @"Should have been nil.");
    XCTAssertNil(kitConfig.removeEventAttributeList, @"Should have been nil.");
    XCTAssertNil(kitConfig.singleItemEventAttributeList, @"Should have been nil.");
    XCTAssertNil(kitConfig.bracketConfiguration, @"Should have been nil.");
    XCTAssertNil(kitConfig.commerceEventAttributeFilters, @"Should have been nil.");
    XCTAssertNil(kitConfig.commerceEventEntityTypeFilters, @"Should have been nil.");
    XCTAssertNil(kitConfig.commerceEventAppFamilyAttributeFilters, @"Should have been nil.");
    XCTAssertNil(kitConfig.configuredMessageTypeProjections, @"Should have been nil.");
    XCTAssertNil(kitConfig.defaultProjections, @"Should have been nil.");
    XCTAssertNil(kitConfig.projections, @"Should have been nil.");
    XCTAssertNil(kitConfig.attributeValueFilteringHashedAttribute, @"Should have been nil.");
    XCTAssertNil(kitConfig.attributeValueFilteringHashedValue, @"Should have been nil.");
    
    XCTAssertFalse(kitConfig.attributeValueFilteringIsActive, @"Should have been false.");
    XCTAssertFalse(kitConfig.attributeValueFilteringShouldIncludeMatches, @"Should have been false.");
}

@end

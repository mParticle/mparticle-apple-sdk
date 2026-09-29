#import <XCTest/XCTest.h>
#import "MPKitConfiguration.h"
#import "MPBaseTestCase.h"
#import "MPEnums.h"

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
    XCTAssertEqualObjects(kitConfiguration.configurationHash, @(969680750));
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
    XCTAssertEqualObjects(kitConfig.configurationHash, @(-1872513399));
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

- (void)testNonDictionaryConfigurationIsRejected {
    // A kit entry that is not an object survives the outer `eks` cast on the cached path, so the
    // parser is the first place its type is known. Indexing it, or handing it to
    // NSJSONSerialization for the configuration hash, raises.
    NSArray *nonDictionaries = @[@"kit", @[@"kit"], @37];

    for (id notADictionary in nonDictionaries) {
        MPKitConfiguration *kitConfig = nil;
        XCTAssertNoThrow(kitConfig = [[MPKitConfiguration alloc] initWithDictionary:notADictionary],
                         @"A %@ configuration must be rejected, not raise", [notADictionary class]);
        XCTAssertNil(kitConfig);
    }
}

- (void)testWrongTypedExcludeAnonymousUsersIsIgnored {
    NSArray *notBooleans = @[[NSNull null], @{@"a": @1}, @[@1]];

    for (id notABoolean in notBooleans) {
        NSDictionary *configuration = @{@"id": @80, @"eau": notABoolean};
        MPKitConfiguration *kitConfig = nil;

        XCTAssertNoThrow(kitConfig = [[MPKitConfiguration alloc] initWithDictionary:configuration],
                         @"An `eau` of %@ must be ignored, not raise", [notABoolean class]);
        XCTAssertNotNil(kitConfig, @"The rest of the entry is still usable");
        XCTAssertFalse(kitConfig.excludeAnonymousUsers);
    }
}

- (void)testWrongTypedBracketConfigurationIsIgnored {
    // bracketConfiguration is subscripted for `lo` and `hi` by the container, which is why a
    // non-object value must not reach the property.
    NSArray *notDictionaries = @[@"bracket", @[@10, @20], @10];

    for (id notADictionary in notDictionaries) {
        NSDictionary *configuration = @{@"id": @80, @"bk": notADictionary};
        MPKitConfiguration *kitConfig = nil;

        XCTAssertNoThrow(kitConfig = [[MPKitConfiguration alloc] initWithDictionary:configuration],
                         @"A `bk` of %@ must be ignored, not raise", [notADictionary class]);
        XCTAssertNotNil(kitConfig);
        XCTAssertNil(kitConfig.bracketConfiguration);
    }
}

- (void)testWrongTypedIntegrationIdIsRejected {
    // integrationId keys a dictionary declared NSNumber-keyed and is compared with
    // isEqualToNumber:, so an entry carrying anything else is unusable rather than partly usable.
    NSArray *notNumbers = @[@"80", @[@80], @{@"id": @80}];

    for (id notANumber in notNumbers) {
        NSDictionary *configuration = @{@"id": notANumber};
        MPKitConfiguration *kitConfig = nil;

        XCTAssertNoThrow(kitConfig = [[MPKitConfiguration alloc] initWithDictionary:configuration],
                         @"An `id` of %@ must be rejected, not raise", [notANumber class]);
        XCTAssertNil(kitConfig);
    }
}

- (void)testWrongTypedSubFiltersAreDropped {
    // The container subscripts these by hash, so a member that is not an object must not be
    // published under a property declared NSDictionary.
    NSDictionary *configuration = @{
                                    @"id": @80,
                                    @"hs": @{
                                            @"et": @"not-a-filter",
                                            @"uid": @[@0],
                                            @"reg": @1,
                                            @"ua": @{@"1217787541": @0}
                                            }
                                    };

    MPKitConfiguration *kitConfig = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    XCTAssertNotNil(kitConfig);

    XCTAssertNil(kitConfig.eventTypeFilters);
    XCTAssertNil(kitConfig.userIdentityFilters);
    XCTAssertNil(kitConfig.consentRegulationFilters);

    // A well-formed sibling in the same `hs` is still honoured.
    XCTAssertEqualObjects(kitConfig.userAttributeFilters, @{@"1217787541": @0});
}

- (void)testWrongTypedProjectionsAreIgnored {
    // `pr` crosses into Swift as an array, so a non-array is messaged with count or objectAtIndex:
    // inside the bridge rather than being rejected by it.
    NSArray *notArrays = @[@"pr", @{@"a": @1}, @7];

    for (id notAnArray in notArrays) {
        NSDictionary *configuration = @{@"id": @80, @"pr": notAnArray};
        MPKitConfiguration *kitConfig = nil;

        XCTAssertNoThrow(kitConfig = [[MPKitConfiguration alloc] initWithDictionary:configuration],
                         @"A `pr` of %@ must be ignored, not raise", [notAnArray class]);
        XCTAssertNotNil(kitConfig, @"The rest of the entry is still usable");
        XCTAssertNil(kitConfig.projections);
    }
}

- (void)testWrongTypedProjectionElementsAreSkipped {
    // A well-formed `pr` carrying junk alongside a real projection keeps the real one.
    NSDictionary *configuration = @{
                                    @"id": @80,
                                    @"pr": @[
                                            @"not-a-projection",
                                            @[@1],
                                            @{@"behavior": @{@"append_unmapped_as_is": @YES},
                                              @"action": @{@"projected_event_name": @"Test",
                                                           @"attribute_maps": @[]},
                                              @"matches": @[@{@"message_type": @4,
                                                              @"event_match_type": @"String",
                                                              @"event": @"Test"}],
                                              @"id": @97}
                                            ]
                                    };

    MPKitConfiguration *kitConfig = nil;
    XCTAssertNoThrow(kitConfig = [[MPKitConfiguration alloc] initWithDictionary:configuration]);
    XCTAssertNotNil(kitConfig);
    XCTAssertEqual(kitConfig.projections.count, 1);
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

// message_type indexes two arrays holding +[MPEnum messageTypeSize] (20) entries.
// -setObject:atIndexedSubscript: allows index == count and appends, so
// MPMessageTypeMedia (20) has always been registered into a 21st slot. This
// pins that, so the out-of-range guard cannot regress it.
- (void)testMediaMessageTypeProjectionIsStillConfigured {
    NSDictionary *configuration = @{
        @"id":@42,
        @"pr":@[@{
            @"id":@1,
            @"action":@{@"projected_event_name":@"Media Event"},
            @"matches":@[@{@"message_type":@(MPMessageTypeMedia)}]
        }]
    };

    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];

    XCTAssertNotNil(kitConfiguration);
    XCTAssertEqual(kitConfiguration.configuredMessageTypeProjections.count, (NSUInteger)(MPMessageTypeMedia + 1));
    XCTAssertTrue([kitConfiguration.configuredMessageTypeProjections[MPMessageTypeMedia] boolValue]);
}

// Beyond index == count the subscript assignment really does raise
// NSRangeException, and message_type is unvalidated remote configuration.
- (void)testOutOfRangeMessageTypeProjectionIsIgnored {
    NSDictionary *configuration = @{
        @"id":@42,
        @"pr":@[@{
            @"id":@1,
            @"action":@{@"projected_event_name":@"Bogus Event"},
            @"matches":@[@{@"message_type":@99}]
        }]
    };

    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];

    XCTAssertNotNil(kitConfiguration);
    XCTAssertEqual(kitConfiguration.configuredMessageTypeProjections.count, [MPEnum messageTypeSize]);
    for (NSNumber *configured in kitConfiguration.configuredMessageTypeProjections) {
        XCTAssertFalse([configured boolValue], @"No message type slot should have been configured.");
    }
}

// A negative message_type wraps to a huge NSUInteger on the way through.
- (void)testNegativeMessageTypeProjectionIsIgnored {
    NSDictionary *configuration = @{
        @"id":@42,
        @"pr":@[@{
            @"id":@1,
            @"action":@{@"projected_event_name":@"Negative Event"},
            @"matches":@[@{@"message_type":@"-1"}]
        }]
    };

    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];

    XCTAssertNotNil(kitConfiguration);
    XCTAssertNil(kitConfiguration.projections);
}

- (void)testInRangeMessageTypeProjectionIsStillConfigured {
    NSDictionary *configuration = @{
        @"id":@42,
        @"pr":@[@{
            @"id":@1,
            @"action":@{@"projected_event_name":@"Renamed Event"},
            @"matches":@[@{@"message_type":@(MPMessageTypeEvent)}]
        }]
    };

    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];

    XCTAssertTrue([kitConfiguration.configuredMessageTypeProjections[MPMessageTypeEvent] boolValue]);
}

@end

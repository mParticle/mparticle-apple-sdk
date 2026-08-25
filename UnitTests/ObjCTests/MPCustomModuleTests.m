#import <XCTest/XCTest.h>
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "MPBaseTestCase.h"
#import "MPUserDefaultsConnector.h"
@import mParticle_Apple_SDK_Swift;

@interface MPCustomModuleTests : MPBaseTestCase

@property (nonatomic, strong) NSString *customModulesString;
@property (nonatomic, strong) NSDictionary *customModuleConfiguration;

@end

@implementation MPCustomModuleTests

/// MPCustomModule takes its MPUserDefaults connector by injection now that it is a Swift type:
/// the Swift module cannot reach the ObjC singleton, so the call site supplies it.
- (MPCustomModule *)customModuleWithDictionary:(NSDictionary *)dictionary {
    return [[MPCustomModule alloc] initWithDictionary:dictionary
                                            connector:[[MPUserDefaultsConnector alloc] init]];
}

- (NSString *)customModulesString {
    if (_customModulesString) {
        return _customModulesString;
    }
    
    _customModulesString = @"{\"cms\":[\
                                        { \
                                            \"id\": 11, \
                                            \"pr\": [ \
                                                   { \
                                                       \"f\": \"NSUserDefaults\", \
                                                       \"m\": 0, \
                                                       \"ps\": [ \
                                                              { \
                                                                  \"k\": \"APP_MEASUREMENT_VISITOR_ID\", \
                                                                  \"t\": 1, \
                                                                  \"n\": \"vid\", \
                                                                  \"d\": \"%gn%\" \
                                                              }, \
                                                              { \
                                                                  \"k\": \"ADOBEMOBILE_STOREDDEFAULTS_AID\", \
                                                                  \"t\": 1, \
                                                                  \"n\": \"aid\", \
                                                                  \"d\": \"%oaid%\" \
                                                              }, \
                                                              { \
                                                                  \"k\": \"GLSB\", \
                                                                  \"t\": 1, \
                                                                  \"n\": \"aid\", \
                                                                  \"d\": \"%glsb%\" \
                                                              }, \
                                                              { \
                                                                  \"k\": \"ADB_LIFETIME_VALUE\", \
                                                                  \"t\": 1, \
                                                                  \"n\": \"ltv\", \
                                                                  \"d\": \"0\" \
                                                              }, \
                                                              { \
                                                                  \"k\": \"OMCK1\", \
                                                                  \"t\": 1, \
                                                                  \"n\": \"id\", \
                                                                  \"d\": \"%dt%\" \
                                                              }, \
                                                              { \
                                                                  \"k\": \"OMCK6\", \
                                                                  \"t\": 2, \
                                                                  \"n\": \"l\", \
                                                                  \"d\": \"0\" \
                                                              }, \
                                                              { \
                                                                  \"k\": \"OMCK5\", \
                                                                  \"t\": 1, \
                                                                  \"n\": \"lud\", \
                                                                  \"d\": \"%dt%\" \
                                                              } \
                                                              ] \
                                                   } \
                                                   ] \
                                        }]}";
    
    return _customModulesString;
}

- (NSDictionary *)customModuleConfiguration {
    if (_customModuleConfiguration) {
        return _customModuleConfiguration;
    }
    
    NSData *customModuleData = [self.customModulesString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *customModuleJSONDictionary = [NSJSONSerialization JSONObjectWithData:customModuleData options:0 error:nil];
    NSArray *customModules = customModuleJSONDictionary[kMPRemoteConfigCustomModuleSettingsKey];
    _customModuleConfiguration = [customModules lastObject];
    
    return _customModuleConfiguration;
}

- (void)setUp {
    [super setUp];
    [MPPersistenceController_PRIVATE setMpid:@1];
}

- (void)testConfiguration {
    NSData *customModuleData = [self.customModulesString dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNotNil(customModuleData, @"Should not have been nil.");
    
    NSError *error = nil;
    NSDictionary *customModuleJSONDictionary = [NSJSONSerialization JSONObjectWithData:customModuleData options:0 error:&error];
    XCTAssertNil(error, @"Should have been nil.");
    XCTAssertNotNil(customModuleJSONDictionary, @"Should not have been nil.");
    
    NSArray *customModules = customModuleJSONDictionary[kMPRemoteConfigCustomModuleSettingsKey];
    XCTAssertNotNil(customModules, @"Missing key.");
    
    NSDictionary *customModuleDictionary = [customModules lastObject];
    XCTAssertNotNil(customModuleDictionary, @"Missing configuration.");
}

- (void)testCustomModule {
    NSDate *referenceDate = [[NSDate date] dateByAddingTimeInterval:-1.0];
    NSDate *futureReferenceDate = [referenceDate dateByAddingTimeInterval:2.0];
    NSDate *preferenceDate;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss Z"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    MPCustomModule *customModule = [self customModuleWithDictionary:self.customModuleConfiguration];
    XCTAssertNotNil(customModule.customModuleId, @"Custom module id is not being set.");
    XCTAssertGreaterThan(customModule.preferences.count, 0, @"Custom module preferences are not being created.");
    
    MPCustomModule *copyCustomModule = [customModule copy];
    XCTAssertNotNil(copyCustomModule, @"Custom module not complying with NSCopying protocol.");
    XCTAssertEqualObjects(copyCustomModule.customModuleId, customModule.customModuleId, @"Custom module copy does not have the correct module id.");
    XCTAssertEqualObjects(copyCustomModule.preferences, customModule.preferences, @"Custom module copy does not have the correct preferences.");
    
    for (MPCustomModulePreference *preference in customModule.preferences) {
        XCTAssertNotNil(preference.defaultValue, @"Default value for custom module preference is not being set.");
        
        if ([preference.readKey isEqualToString:@"OMCK1"] || [preference.readKey isEqualToString:@"OMCK5"]) {
            preferenceDate = [dateFormatter dateFromString:preference.defaultValue];
            XCTAssertGreaterThan(preferenceDate.timeIntervalSinceReferenceDate, referenceDate.timeIntervalSinceReferenceDate, @"Custom module preference date default values are too low.");
            XCTAssertLessThan(preferenceDate.timeIntervalSinceReferenceDate, futureReferenceDate.timeIntervalSinceReferenceDate, @"Custom module preference date default values are too low.");
        } else if ([preference.readKey isEqualToString:@"APP_MEASUREMENT_VISITOR_ID"]) {
            XCTAssertGreaterThan(preference.defaultValue.length, 0, @"GUID default value is not being set.");
            XCTAssertEqual([preference.defaultValue rangeOfString:@"-"].location, NSNotFound, @"Dashes are not being removed from GUID");
        } else if ([preference.readKey isEqualToString:@"ADOBEMOBILE_STOREDDEFAULTS_AID"]) {
            XCTAssertEqual(preference.defaultValue.length, 33, @"OAID is not being set or has the wrong length.");
            XCTAssertEqualObjects([preference.defaultValue substringWithRange:NSMakeRange(16, 1)], @"-", @"OAID's middle character is not a dash.");
            XCTAssertLessThanOrEqual([[preference.defaultValue substringWithRange:NSMakeRange(0, 1)] integerValue], 8, @"OAID's first digit is too large.");
            XCTAssertLessThanOrEqual([[preference.defaultValue substringWithRange:NSMakeRange(17, 1)] integerValue], 4, @"OAID's seventeenth digit is too large.");
        }
    }
    
    NSString *description = [customModule description];
    XCTAssertNotNil(description, @"Should not have been nil");
}

- (void)testInvalidConfiguration {
    NSMutableDictionary *customModuleConfiguration = [@{
                                                        @"id":[NSNull null],
                                                        @"pr":[NSNull null]
                                                        } mutableCopy];
    
    MPCustomModule *customModule = [self customModuleWithDictionary:customModuleConfiguration];
    XCTAssertNil(customModule, @"Should have been nil.");

    customModuleConfiguration[@"id"] = @"Invalid. This is not a number.";
    customModule = [self customModuleWithDictionary:customModuleConfiguration];
    XCTAssertNil(customModule, @"Should have been nil.");

    customModuleConfiguration[@"id"] = @11;
    customModule = [self customModuleWithDictionary:customModuleConfiguration];
    XCTAssertNil(customModule, @"Should have been nil.");

    customModuleConfiguration[@"pr"] = @{@"Invalid":@"This is not an array."};
    customModule = [self customModuleWithDictionary:customModuleConfiguration];
    XCTAssertNil(customModule, @"Should have been nil.");
    
    customModuleConfiguration[@"pr"] = @[[NSNull null]];
    customModule = [self customModuleWithDictionary:customModuleConfiguration];
    XCTAssertNotNil(customModule, @"Should not have been nil.");
    XCTAssertNil(customModule.preferences, @"Should have been nil.");
    
    customModuleConfiguration[@"pr"] = @[@"This is not a dictionary."];
    customModule = [self customModuleWithDictionary:customModuleConfiguration];
    XCTAssertNotNil(customModule, @"Should not have been nil.");
    XCTAssertNil(customModule.preferences, @"Should have been nil.");
    
    customModuleConfiguration[@"pr"] = @[];
    customModule = [self customModuleWithDictionary:customModuleConfiguration];
    XCTAssertNotNil(customModule, @"Should not have been nil.");
    XCTAssertNil(customModule.preferences, @"Should have been nil.");
    
    customModuleConfiguration[@"pr"] = @[
                                         @{@"f":@"NSUserDefaults",
                                           @"m":@0,
                                           @"ps":@[
                                                   @{@"k":@"APP_MEASUREMENT_VISITOR_ID",
                                                     @"t":@1,
                                                     @"n":@"vid",
                                                     @"d":[NSNull null]
                                                     },
                                                   @{@"k":@"ADOBEMOBILE_STOREDDEFAULTS_AID",
                                                     @"t":@1,
                                                     @"n":[NSNull null],
                                                     @"d":@"%oaid%"
                                                     },
                                                   @{@"k":@"GLSB",
                                                     @"n":@"aid",
                                                     @"d":@"%glsb%"
                                                     },
                                                   @{@"k":[NSNull null],
                                                     @"t":@1,
                                                     @"n":@"ltv",
                                                     @"d":@"0"
                                                     },
                                                   @{},
                                                   @{@"k":@"OMCK6",
                                                     @"t":[NSNull null],
                                                     @"n":@"l",
                                                     @"d":@"0"
                                                     },
                                                   @{@"k":@"OMCK5",
                                                     @"t":@1,
                                                     @"n":@"lud",
                                                     @"d":@"%dt%"
                                                     }
                                                   ]
                                           }
                                         ];
    customModule = [self customModuleWithDictionary:customModuleConfiguration];
    XCTAssertNotNil(customModule, @"Should not have been nil.");
    XCTAssertEqual(customModule.preferences.count, 4, @"Should have been equal.");
}


- (void)testCustomModuleSerialization {
    MPCustomModule *customModule = [self customModuleWithDictionary:self.customModuleConfiguration];
    
    NSData *customModuleData = [NSKeyedArchiver archivedDataWithRootObject:customModule];
    XCTAssertNotNil(customModuleData, @"Should not have been nil.");
    
    MPCustomModule *deserializedCustomModule = [NSKeyedUnarchiver unarchiveObjectWithData:customModuleData];
    XCTAssertNotNil(deserializedCustomModule, @"Should not have been nil.");
    XCTAssertEqualObjects(customModule, deserializedCustomModule, @"Should have been equal.");
}

- (void)testEquality {
    MPCustomModule *customModule = [self customModuleWithDictionary:self.customModuleConfiguration];
    XCTAssertNotNil(customModule, @"Should not have been nil.");
    XCTAssertNotEqualObjects(customModule, nil, @"Should have been different.");
    XCTAssertNotEqualObjects(customModule, [NSNull null], @"Should have been different.");
}

- (void)testDictionaryRepresentation {
    MPCustomModule *customModule = [self customModuleWithDictionary:self.customModuleConfiguration];
    NSDictionary *customModuleDictionary = [customModule dictionaryRepresentation];
    XCTAssertNotNil(customModuleDictionary, @"Should not have been nil.");
    XCTAssertNotNil(customModuleDictionary[@"aid"], @"Should not have been nil.");
    XCTAssertNotNil(customModuleDictionary[@"id"], @"Should not have been nil.");
    XCTAssertNotNil(customModuleDictionary[@"l"], @"Should not have been nil.");
    XCTAssertNotNil(customModuleDictionary[@"ltv"], @"Should not have been nil.");
    XCTAssertNotNil(customModuleDictionary[@"lud"], @"Should not have been nil.");
    XCTAssertNotNil(customModuleDictionary[@"vid"], @"Should not have been nil.");
}

- (void)testValue {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    void (^removeKeysFromUserDefaults)(void) = ^{
        [userDefaults removeObjectForKey:@"mParticle_UNIT_TEST_CustomModule_1"];
        [userDefaults removeObjectForKey:@"mParticle_UNIT_TEST_CustomModule_2"];
        [userDefaults removeObjectForKey:@"mParticle_UNIT_TEST_CustomModule_3"];
        [userDefaults removeObjectForKey:@"mParticle::cms::vid"];
        [userDefaults removeObjectForKey:@"mParticle::cms::aid"];
        [userDefaults removeObjectForKey:@"mParticle::cms::ltv"];
        [userDefaults removeObjectForKey:@"mParticle::cms::11::vid"];
        [userDefaults removeObjectForKey:@"mParticle::cms::11::aid"];
        [userDefaults removeObjectForKey:@"mParticle::cms::11::ltv"];
        [userDefaults synchronize];
    };

    removeKeysFromUserDefaults();
    
    NSDictionary *customModuleConfiguration = @{
                                                @"id":@11,
                                                @"pr":@[
                                                        @{@"f":@"NSUserDefaults",
                                                          @"m":@0,
                                                          @"ps":@[
                                                                  @{@"k":@"mParticle_UNIT_TEST_CustomModule_1",
                                                                    @"t":@1,
                                                                    @"n":@"vid",
                                                                    @"d":@"%oaid%"
                                                                    },
                                                                  @{@"k":@"mParticle_UNIT_TEST_CustomModule_2",
                                                                    @"t":@1,
                                                                    @"n":@"aid",
                                                                    @"d":@"%oaid%"
                                                                    },
                                                                  @{@"k":@"mParticle_UNIT_TEST_CustomModule_3",
                                                                    @"t":@2,
                                                                    @"n":@"ltv",
                                                                    @"d":@"0"
                                                                    }
                                                                  ]
                                                          }
                                                        ]
                                                };

    MPCustomModule *customModule = [self customModuleWithDictionary:customModuleConfiguration];
    removeKeysFromUserDefaults();
    for (MPCustomModulePreference *preference in customModule.preferences) {
        XCTAssertNotNil(preference.value, @"Should not have been nil.");
    }
        
    customModule = [self customModuleWithDictionary:customModuleConfiguration];
    removeKeysFromUserDefaults();
    [userDefaults setObject:@"Value1" forKey:@"mParticle_UNIT_TEST_CustomModule_1"];
    [userDefaults setObject:@"Value2" forKey:@"mParticle_UNIT_TEST_CustomModule_2"];
    [userDefaults setObject:@"Value3" forKey:@"mParticle_UNIT_TEST_CustomModule_3"];
    for (MPCustomModulePreference *preference in customModule.preferences) {
        XCTAssertNotNil(preference.value, @"Should not have been nil.");
    }
    
    removeKeysFromUserDefaults();
}

- (void)testCustomModuleEncoding {
    NSDictionary *customModuleConfiguration = @{
                                                @"id":@11,
                                                @"pr":@[
                                                        @{@"f":@"NSUserDefaults",
                                                          @"m":@0,
                                                          @"ps":@[
                                                                  @{@"k":@"mParticle_UNIT_TEST_CustomModule_1",
                                                                    @"t":@1,
                                                                    @"n":@"vid",
                                                                    @"d":@"%oaid%"
                                                                    },
                                                                  @{@"k":@"mParticle_UNIT_TEST_CustomModule_2",
                                                                    @"t":@1,
                                                                    @"n":@"aid",
                                                                    @"d":@"%oaid%"
                                                                    },
                                                                  @{@"k":@"mParticle_UNIT_TEST_CustomModule_3",
                                                                    @"t":@2,
                                                                    @"n":@"ltv",
                                                                    @"d":@"0"
                                                                    }
                                                                  ]
                                                          }
                                                        ]
                                                };
    
    MPCustomModule *customModule = [self customModuleWithDictionary:customModuleConfiguration];
    
    MPCustomModule *persistedCustomModule = [self attemptSecureEncodingwithClass:[MPCustomModule class] Object:customModule];
    XCTAssertEqualObjects(customModule, persistedCustomModule, @"Custom Module should have been a match.");
}

// The data type comes straight from config, so an out of range value leaves the preference
// with no default. Resolving the value must leave it unset rather than raising.
- (void)testUnrecognizedDataTypeLeavesValueUnset {
    NSDictionary *customModuleConfiguration = @{
                                                @"id":@11,
                                                @"pr":@[
                                                        @{@"f":@"NSUserDefaults",
                                                          @"m":@0,
                                                          @"ps":@[
                                                                  @{@"k":@"mParticle_UNIT_TEST_CustomModule_Unrecognized",
                                                                    @"t":@99,
                                                                    @"n":@"unrecognized"
                                                                    }
                                                                  ]
                                                          }
                                                        ]
                                                };

    MPCustomModule *customModule = [self customModuleWithDictionary:customModuleConfiguration];
    XCTAssertNotNil(customModule, @"Should not have been nil.");
    XCTAssertEqual(customModule.preferences.count, 1, @"Should have been equal.");

    MPCustomModulePreference *preference = customModule.preferences.firstObject;
    XCTAssertNil(preference.defaultValue, @"Should have been nil.");

    id value = nil;
    XCTAssertNoThrow(value = [preference value]);
    XCTAssertNil(value, @"Should have been nil.");
    XCTAssertNoThrow([customModule dictionaryRepresentation]);
}

/// The Swift preference mirrors the kMPRemoteConfigCustomModule* keys, which it cannot import.
/// Building the config from the real constants means a change to either side fails here rather
/// than silently parsing nothing.
- (void)testSwiftPreferenceReadsEveryKeyFromMPIConstants {
    NSDictionary *preferenceSetting = @{
        kMPRemoteConfigCustomModuleReadKey: @"parity_read",
        kMPRemoteConfigCustomModuleWriteKey: @"parity_write",
        kMPRemoteConfigCustomModuleDataTypeKey: @(MPDataTypeInt),
        kMPRemoteConfigCustomModuleDefaultKey: @"42"
    };
    NSDictionary *customModuleConfiguration = @{
        kMPRemoteConfigCustomModuleIdKey: @28,
        kMPRemoteConfigCustomModulePreferencesKey: @[@{
            kMPRemoteConfigCustomModuleLocationKey: @"NSUserDefaults",
            kMPRemoteConfigCustomModulePreferenceSettingsKey: @[preferenceSetting]
        }]
    };

    MPCustomModule *customModule = [self customModuleWithDictionary:customModuleConfiguration];
    XCTAssertEqual(customModule.preferences.count, 1, @"Should have been equal.");

    MPCustomModulePreference *preference = customModule.preferences.firstObject;
    XCTAssertEqualObjects(preference.readKey, @"parity_read");
    XCTAssertEqualObjects(preference.writeKey, @"parity_write");
    XCTAssertEqualObjects(preference.moduleId, @28);
    XCTAssertEqual(preference.dataType, MPDataTypeInt);
    XCTAssertEqualObjects(preference.defaultValue, @"42");
}

@end

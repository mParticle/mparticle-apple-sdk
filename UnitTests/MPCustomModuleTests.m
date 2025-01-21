#import <XCTest/XCTest.h>
#import "MPCustomModule.h"
#import "MPCustomModulePreference.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "MPBaseTestCase.h"

@interface MPCustomModuleTests : MPBaseTestCase

@property (nonatomic, strong) NSString *customModulesString;
@property (nonatomic, strong) NSDictionary *customModuleConfiguration;

@end

@implementation MPCustomModuleTests

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
    
    MPCustomModule *customModule = [[MPCustomModule alloc] initWithDictionary:self.customModuleConfiguration];
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
    
    MPCustomModule *customModule = [[MPCustomModule alloc] initWithDictionary:customModuleConfiguration];
    XCTAssertNil(customModule, @"Should have been nil.");

    customModuleConfiguration[@"id"] = @"Invalid. This is not a number.";
    customModule = [[MPCustomModule alloc] initWithDictionary:customModuleConfiguration];
    XCTAssertNil(customModule, @"Should have been nil.");

    customModuleConfiguration[@"id"] = @11;
    customModule = [[MPCustomModule alloc] initWithDictionary:customModuleConfiguration];
    XCTAssertNil(customModule, @"Should have been nil.");

    customModuleConfiguration[@"pr"] = @{@"Invalid":@"This is not an array."};
    customModule = [[MPCustomModule alloc] initWithDictionary:customModuleConfiguration];
    XCTAssertNil(customModule, @"Should have been nil.");
    
    customModuleConfiguration[@"pr"] = @[[NSNull null]];
    customModule = [[MPCustomModule alloc] initWithDictionary:customModuleConfiguration];
    XCTAssertNotNil(customModule, @"Should not have been nil.");
    XCTAssertNil(customModule.preferences, @"Should have been nil.");
    
    customModuleConfiguration[@"pr"] = @[@"This is not a dictionary."];
    customModule = [[MPCustomModule alloc] initWithDictionary:customModuleConfiguration];
    XCTAssertNotNil(customModule, @"Should not have been nil.");
    XCTAssertNil(customModule.preferences, @"Should have been nil.");
    
    customModuleConfiguration[@"pr"] = @[];
    customModule = [[MPCustomModule alloc] initWithDictionary:customModuleConfiguration];
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
    customModule = [[MPCustomModule alloc] initWithDictionary:customModuleConfiguration];
    XCTAssertNotNil(customModule, @"Should not have been nil.");
    XCTAssertEqual(customModule.preferences.count, 4, @"Should have been equal.");
}


- (void)testCustomModuleSerialization {
    MPCustomModule *customModule = [[MPCustomModule alloc] initWithDictionary:self.customModuleConfiguration];
    
    NSData *customModuleData = [NSKeyedArchiver archivedDataWithRootObject:customModule];
    XCTAssertNotNil(customModuleData, @"Should not have been nil.");
    
    MPCustomModule *deserializedCustomModule = [NSKeyedUnarchiver unarchiveObjectWithData:customModuleData];
    XCTAssertNotNil(deserializedCustomModule, @"Should not have been nil.");
    XCTAssertEqualObjects(customModule, deserializedCustomModule, @"Should have been equal.");
}

- (void)testEquality {
    MPCustomModule *customModule = [[MPCustomModule alloc] initWithDictionary:self.customModuleConfiguration];
    XCTAssertNotNil(customModule, @"Should not have been nil.");
    XCTAssertNotEqualObjects(customModule, nil, @"Should have been different.");
    XCTAssertNotEqualObjects(customModule, [NSNull null], @"Should have been different.");
}

- (void)testDictionaryRepresentation {
    MPCustomModule *customModule = [[MPCustomModule alloc] initWithDictionary:self.customModuleConfiguration];
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

    MPCustomModule *customModule = [[MPCustomModule alloc] initWithDictionary:customModuleConfiguration];
    removeKeysFromUserDefaults();
    for (MPCustomModulePreference *preference in customModule.preferences) {
        XCTAssertNotNil(preference.value, @"Should not have been nil.");
    }
        
    customModule = [[MPCustomModule alloc] initWithDictionary:customModuleConfiguration];
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
    
    MPCustomModule *customModule = [[MPCustomModule alloc] initWithDictionary:customModuleConfiguration];
    
    MPCustomModule *persistedCustomModule = [self attemptSecureEncodingwithClass:[MPCustomModule class] Object:customModule];
    XCTAssertEqualObjects(customModule, persistedCustomModule, @"Custom Module should have been a match.");
}

@end

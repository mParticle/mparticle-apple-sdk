//
//  MPCustomModuleTests.m
//
//  Copyright 2015 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <XCTest/XCTest.h>
#import "MPCustomModule.h"
#import "MPCustomModulePreference.h"
#import "MPConstants.h"

@interface MPCustomModuleTests : XCTestCase

@property (nonatomic, strong) NSString *customMudulesString;
@property (nonatomic, strong) NSDictionary *customModuleConfiguration;

@end

@implementation MPCustomModuleTests

- (NSString *)customMudulesString {
    if (_customMudulesString) {
        return _customMudulesString;
    }
    
    _customMudulesString = @"{\"cms\":[\
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
    
    return _customMudulesString;
}

- (NSDictionary *)customModuleConfiguration {
    if (_customModuleConfiguration) {
        return _customModuleConfiguration;
    }
    
    NSData *customModuleData = [self.customMudulesString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *customModuleJSONDictionary = [NSJSONSerialization JSONObjectWithData:customModuleData options:0 error:nil];
    NSArray *customModules = customModuleJSONDictionary[kMPRemoteConfigCustomModuleSettingsKey];
    _customModuleConfiguration = [customModules lastObject];
    
    return _customModuleConfiguration;
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testConfiguration {
    NSData *customModuleData = [self.customMudulesString dataUsingEncoding:NSUTF8StringEncoding];
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
    NSDate *referenceDate = [NSDate date];
    NSDate *futureReferenceDate = [referenceDate dateByAddingTimeInterval:2];
    NSDate *preferenceDate;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss Z"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    sleep(1);
    
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
            XCTAssert([preferenceDate compare:referenceDate] == NSOrderedDescending, @"Custom module preference date default values are too low.");
            XCTAssert([preferenceDate compare:futureReferenceDate] == NSOrderedAscending, @"Custom module preference date default values are too high.");
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

@end

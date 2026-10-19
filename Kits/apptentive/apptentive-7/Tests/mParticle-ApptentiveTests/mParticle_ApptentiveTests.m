//
//  mParticle_ApptentiveTests.m
//  mParticle-ApptentiveTests
//
//  Created by Alex Lementuev on 5/2/21.
//  Copyright © 2021 mParticle. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MPKitApptentive.h"
#import "MPKitApptentiveUtils.h"

@interface MPKitApptentive() 

- (NSDictionary *)parseEventInfoDictionary:(NSDictionary *)info;
- (NSString *)configurationStringForKey:(NSString *)key;
- (void)updateConfiguredSettings;
@property (assign, nonatomic) BOOL enableTypeDetection;

@end

@interface mParticle_ApptentiveTests : XCTestCase

@end

// Server configuration is parsed JSON, so any value can arrive as a number, boolean or container.
static NSArray *MPKitApptentiveTestNonStringValues(void) {
    return @[[NSNull null], @42, @YES, @[], @{}];
}

@implementation mParticle_ApptentiveTests

- (void)testMPKitApptentiveParseEventInfo {
    NSDictionary *data = @{
        // boolean
        @"key-1": @"true",
        @"key-2": @"True",
        @"key-3": @"false",
        @"key-4": @"False",

        // integer
        @"key-5": @"12345",
        @"key-6": @"-12345",

        // double
        @"key-7": @"3.14",
        @"key-8": @"-3.14",

        // string
        @"key-9": @"123test456"
        
    };
    
    NSDictionary *expected = @{
        @"key-1": @"true",
        @"key-2": @"True",
        @"key-3": @"false",
        @"key-4": @"False",
        @"key-1_flag": @YES,
        @"key-2_flag": @YES,
        @"key-3_flag": @NO,
        @"key-4_flag": @NO,
        @"key-5": @"12345",
        @"key-5_number": @12345,
        @"key-6": @"-12345",
        @"key-6_number": @(-12345),
        @"key-7": @"3.14",
        @"key-7_number": @3.14,
        @"key-8": @"-3.14",
        @"key-8_number": @(-3.14),
        @"key-9": @"123test456"
    };

    MPKitApptentive *kit = [MPKitApptentive new];
    kit.enableTypeDetection = YES;
    NSDictionary *actual = [kit parseEventInfoDictionary:data];
    XCTAssertEqualObjects(expected, actual);
}

- (void)testNormalizeServiceRegionDefaultsToUS {
    XCTAssertEqualObjects(@"us", MPKitApptentiveNormalizeServiceRegion(nil));
    XCTAssertEqualObjects(@"us", MPKitApptentiveNormalizeServiceRegion(@""));
    XCTAssertEqualObjects(@"us", MPKitApptentiveNormalizeServiceRegion(@"   "));
    XCTAssertEqualObjects(@"us", MPKitApptentiveNormalizeServiceRegion(@"US"));
    XCTAssertEqualObjects(@"us", MPKitApptentiveNormalizeServiceRegion(@"us"));
}

- (void)testNormalizeServiceRegionMapsSupportedRegions {
    XCTAssertEqualObjects(@"eu", MPKitApptentiveNormalizeServiceRegion(@"EU"));
    XCTAssertEqualObjects(@"eu", MPKitApptentiveNormalizeServiceRegion(@"eu"));
    XCTAssertEqualObjects(@"au", MPKitApptentiveNormalizeServiceRegion(@"AU"));
    XCTAssertEqualObjects(@"au", MPKitApptentiveNormalizeServiceRegion(@"au"));
}

- (void)testNormalizeServiceRegionFallsBackForUnsupportedValues {
    XCTAssertEqualObjects(@"us", MPKitApptentiveNormalizeServiceRegion(@"CA"));
    XCTAssertEqualObjects(@"us", MPKitApptentiveNormalizeServiceRegion(@"ca"));
    XCTAssertEqualObjects(@"us", MPKitApptentiveNormalizeServiceRegion(@"APAC"));
}

#pragma mark - Malformed server configuration

// None of these launches with valid credentials: that starts the real Apptentive SDK, once per process.

- (void)testLaunchWithNonStringCredentialsReportsRequirementsNotMet {
    for (id value in MPKitApptentiveTestNonStringValues()) {
        for (NSString *key in @[@"apptentiveAppKey", @"apptentiveAppSignature"]) {
            NSMutableDictionary *configuration = [@{@"apptentiveAppKey": @"key", @"apptentiveAppSignature": @"signature"} mutableCopy];
            configuration[key] = value;

            MPKitExecStatus *status = [[MPKitApptentive new] didFinishLaunchingWithConfiguration:configuration];

            XCTAssertEqual(status.returnCode, MPKitReturnCodeRequirementsNotMet, @"%@ of %@ should not start the kit", key, [value class]);
        }
    }
}

- (void)testNonStringSettingsAreTreatedAsUnset {
    for (id value in MPKitApptentiveTestNonStringValues()) {
        MPKitApptentive *kit = [MPKitApptentive new];
        kit.configuration = @{@"apptentiveAppKey": value, @"apptentiveAppSignature": value, @"serviceRegion": value};

        for (NSString *key in kit.configuration) {
            XCTAssertNil([kit configurationStringForKey:key], @"%@ of %@ should be ignored", key, [value class]);
        }
    }

    MPKitApptentive *kit = [MPKitApptentive new];
    kit.configuration = @{@"serviceRegion": @"EU"};

    XCTAssertEqualObjects([kit configurationStringForKey:@"serviceRegion"], @"EU");
}

- (void)testNonScalarEnableTypeDetectionKeepsTheDefault {
    for (id value in @[[NSNull null], @[], @{}]) {
        MPKitApptentive *kit = [MPKitApptentive new];
        kit.configuration = @{@"enableTypeDetection": value};
        [kit updateConfiguredSettings];

        XCTAssertTrue(kit.enableTypeDetection, @"enableTypeDetection of %@ should be ignored", [value class]);
    }

    MPKitApptentive *kit = [MPKitApptentive new];
    kit.configuration = @{@"enableTypeDetection": @"false"};
    [kit updateConfiguredSettings];

    XCTAssertFalse(kit.enableTypeDetection);
}

// The core calls -start even after a launch reports RequirementsNotMet. Without usable credentials
// it must return before the once-per-launch registration, so a later configuration can still start it.
- (void)testStartWithoutStringCredentialsLeavesTheKitStopped {
    for (NSDictionary *configuration in @[@{}, @{@"apptentiveAppKey": @42, @"apptentiveAppSignature": @"signature"}]) {
        MPKitApptentive *kit = [MPKitApptentive new];
        kit.configuration = configuration;

        [kit start];

        XCTAssertFalse(kit.started, @"-start with configuration %@ should not start the kit", configuration);
    }
}

@end

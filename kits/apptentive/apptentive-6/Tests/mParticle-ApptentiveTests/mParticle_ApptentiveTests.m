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
@property (assign, nonatomic) BOOL enableTypeDetection;

@end

@interface mParticle_ApptentiveTests : XCTestCase

@end

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

@end

//
//  mParticle_ApptentiveTests.m
//  mParticle-ApptentiveTests
//
//  Created by Alex Lementuev on 5/2/21.
//  Copyright © 2021 mParticle. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MPKitApptentiveUtils.h"

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
        // boolean
        @"key-1": @YES,
        @"key-2": @YES,
        @"key-3": @NO,
        @"key-4": @NO,

        // integer
        @"key-5": @12345,
        @"key-6": @-12345,

        // double
        @"key-7": @3.14,
        @"key-8": @-3.14,

        // string
        @"key-9": @"123test456",
    };

    NSDictionary *actual = MPKitApptentiveParseEventInfo(data);
    XCTAssertEqualObjects(expected, actual);
}

@end

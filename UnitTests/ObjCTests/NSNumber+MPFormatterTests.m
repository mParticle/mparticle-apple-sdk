//
//  NSNumber+MPFormatterTests.m
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 3/9/23.
//  Copyright © 2023 mParticle, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPBaseTestCase.h"
#import "MParticleSwift.h"

@interface NSNumber_MPFormatterTests : MPBaseTestCase

@end

@implementation NSNumber_MPFormatterTests

- (void)testFormatZero {
    NSNumber *number = @(0);
    NSNumber *formattedNumber = [number formatWithNonScientificNotation];
    XCTAssertEqualObjects(formattedNumber, @(0));
}

- (void)testFormatCloseToZero {
    NSNumber *number = @(1.0E-6);
    NSNumber *formattedNumber = [number formatWithNonScientificNotation];
    XCTAssertEqualObjects(formattedNumber, @(0));
}

- (void)testFormatOneDecimalPlace {
    NSNumber *number = @(0.1);
    NSNumber *formattedNumber = [number formatWithNonScientificNotation];
    XCTAssertEqualObjects(formattedNumber, @(0.1));
}

- (void)testFormatTwoDecimalPlaces {
    NSNumber *number = @(0.01);
    NSNumber *formattedNumber = [number formatWithNonScientificNotation];
    XCTAssertEqualObjects(formattedNumber, @(0.01));
}

- (void)testFormatRoundUp {
    NSNumber *number = @(10.01534634);
    NSNumber *formattedNumber = [number formatWithNonScientificNotation];
    XCTAssertEqualObjects(formattedNumber, @(10.02));
}

- (void)testFormatRoundDown {
    NSNumber *number = @(10.01434634);
    NSNumber *formattedNumber = [number formatWithNonScientificNotation];
    XCTAssertEqualObjects(formattedNumber, @(10.01));
}

@end

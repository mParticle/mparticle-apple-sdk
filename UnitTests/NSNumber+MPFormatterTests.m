//
//  NSNumber+MPFormatterTests.m
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 3/9/23.
//  Copyright © 2023 mParticle, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MPBaseTestCase.h"
#import <mParticle_Apple_SDK/mParticle_Apple_SDK-Swift.h>

@interface NSNumber_MPFormatterTests : MPBaseTestCase

@end

@implementation NSNumber_MPFormatterTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

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

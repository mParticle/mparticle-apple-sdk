#import <XCTest/XCTest.h>

@import mParticle_Apple_SDK_Swift;

@interface NSNumber_MPFormatterTests : XCTestCase

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

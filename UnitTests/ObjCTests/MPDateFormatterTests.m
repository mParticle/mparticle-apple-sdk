#import <XCTest/XCTest.h>
#import "MParticleSwift.h"
#import "MPBaseTestCase.h"

@interface MPDateFormatterTests : MPBaseTestCase {
    NSDate *referenceDate;
}

@end

@implementation MPDateFormatterTests

- (void)setUp {
    [super setUp];

    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 1955;
    dateComponents.month = 11;
    dateComponents.day = 5;
    dateComponents.hour = 1;
    dateComponents.minute = 15;
    dateComponents.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"PST"];
    dateComponents.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    referenceDate = [dateComponents date];
}

- (void)testDatesFromString {
    NSDate *date = [MPDateFormatter dateFromString:@"1955-11-5T01:15:00-8"];
    XCTAssertNotNil(date, @"Should not have been nil.");
    XCTAssertEqualObjects(date, referenceDate, @"Should have been equal.");
    
    date = [MPDateFormatter dateFromString:@"Sat, 5 Nov 1955 01:15:00 -8"];
    XCTAssertNotNil(date, @"Should not have been nil.");
    XCTAssertEqualObjects(date, referenceDate, @"Should have been equal.");
    
    date = [MPDateFormatter dateFromString:@"Saturday, 5-Nov-55 01:15:00 -8"];
    XCTAssertNotNil(date, @"Should not have been nil.");
    XCTAssertEqualObjects(date, referenceDate, @"Should have been equal.");
    
    date = [MPDateFormatter dateFromStringRFC3339:@"1955-11-5T01:15:00-8"];
    XCTAssertNotNil(date, @"Should not have been nil.");
    XCTAssertEqualObjects(date, referenceDate, @"Should have been equal.");
    
    date = [MPDateFormatter dateFromStringRFC1123:@"Sat, 5 Nov 1955 01:15:00 -8"];
    XCTAssertNotNil(date, @"Should not have been nil.");
    XCTAssertEqualObjects(date, referenceDate, @"Should have been equal.");
}

- (void)testStringFromDates {
    NSString *dateString = [MPDateFormatter stringFromDateRFC1123:referenceDate];
    XCTAssertNotNil(dateString, @"Should not have been nil.");
    XCTAssertEqualObjects(dateString, @"Sat, 05 Nov 1955 09:15:00 GMT", @"Should have been equal.");
    
    dateString = [MPDateFormatter stringFromDateRFC3339:referenceDate];
    XCTAssertNotNil(dateString, @"Should not have been nil.");
    XCTAssertEqualObjects(dateString, @"1955-11-05T09:15:00+0000", @"Should have been equal.");
}

- (void)testInvalidDatesFromString {
    NSString *dateString = @"";
    NSDate *date = [MPDateFormatter dateFromString:dateString];
    XCTAssertNil(date, @"Should have been nil.");
    
    date = [MPDateFormatter dateFromStringRFC3339:dateString];
    XCTAssertNil(date, @"Should have been nil.");
    
    date = [MPDateFormatter dateFromStringRFC1123:dateString];
    XCTAssertNil(date, @"Should have been nil.");
    
    dateString = nil;
    date = [MPDateFormatter dateFromString:dateString];
    XCTAssertNil(date, @"Should have been nil.");
    
    dateString = @"2016-02-30T23:61:00-5";
    date = [MPDateFormatter dateFromString:dateString];
    XCTAssertNil(date, @"Should have been nil.");
    
    dateString = @"The day the flux capacitor was invented.";
    date = [MPDateFormatter dateFromString:dateString];
    XCTAssertNil(date, @"Should have been nil.");
}

@end

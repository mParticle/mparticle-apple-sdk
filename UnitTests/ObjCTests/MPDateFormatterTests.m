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

#pragma mark - Thread Safety Tests

- (void)testDateFormatterThreadSafety {
    // This stress test verifies that MPDateFormatter doesn't crash when
    // called concurrently from multiple threads. DateFormatter is NOT
    // thread-safe, so without synchronization this test would likely crash.
    // Race conditions are non-deterministic, so this test increases the
    // likelihood of catching issues but cannot guarantee detection.
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Thread safety stress test"];
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.mparticle.test.dateformatter", DISPATCH_QUEUE_CONCURRENT);
    
    NSInteger iterations = 100;
    __block BOOL encounteredError = NO;
    
    NSArray *rfc3339Strings = @[
        @"2024-01-15T10:30:00+0000",
        @"2023-06-20T15:45:30-0500",
        @"1955-11-05T01:15:00-0800"
    ];
    
    NSArray *rfc1123Strings = @[
        @"Mon, 15 Jan 2024 10:30:00 GMT",
        @"Tue, 20 Jun 2023 15:45:30 GMT",
        @"Sat, 05 Nov 1955 09:15:00 GMT"
    ];
    
    // Multiple threads parsing RFC3339 dates
    for (NSInteger i = 0; i < 3; i++) {
        dispatch_group_async(group, concurrentQueue, ^{
            for (NSInteger j = 0; j < iterations && !encounteredError; j++) {
                @try {
                    NSString *dateString = rfc3339Strings[j % rfc3339Strings.count];
                    NSDate *date = [MPDateFormatter dateFromStringRFC3339:dateString];
                    (void)date; // Use the result to prevent optimization
                } @catch (NSException *exception) {
                    encounteredError = YES;
                    XCTFail(@"Exception in dateFromStringRFC3339: %@", exception);
                }
            }
        });
    }
    
    // Multiple threads parsing RFC1123 dates
    for (NSInteger i = 0; i < 3; i++) {
        dispatch_group_async(group, concurrentQueue, ^{
            for (NSInteger j = 0; j < iterations && !encounteredError; j++) {
                @try {
                    NSString *dateString = rfc1123Strings[j % rfc1123Strings.count];
                    NSDate *date = [MPDateFormatter dateFromStringRFC1123:dateString];
                    (void)date;
                } @catch (NSException *exception) {
                    encounteredError = YES;
                    XCTFail(@"Exception in dateFromStringRFC1123: %@", exception);
                }
            }
        });
    }
    
    // Multiple threads formatting dates to strings
    for (NSInteger i = 0; i < 2; i++) {
        dispatch_group_async(group, concurrentQueue, ^{
            for (NSInteger j = 0; j < iterations && !encounteredError; j++) {
                @try {
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(j * 86400)];
                    NSString *rfc3339 = [MPDateFormatter stringFromDateRFC3339:date];
                    NSString *rfc1123 = [MPDateFormatter stringFromDateRFC1123:date];
                    (void)rfc3339;
                    (void)rfc1123;
                } @catch (NSException *exception) {
                    encounteredError = YES;
                    XCTFail(@"Exception in stringFromDate: %@", exception);
                }
            }
        });
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        XCTAssertFalse(encounteredError, @"Thread safety test should complete without errors");
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

@end

//
//  MPDateFormatterTests.m
//
//  Copyright 2016 mParticle, Inc.
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
#import "MPDateFormatter.h"

@interface MPDateFormatterTests : XCTestCase {
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

- (void)tearDown {
    [super tearDown];
}

- (void)testDatesFromString {
    NSDate *date = [MPDateFormatter dateFromStringRFC3339:@"1955-11-5T01:15:00-8"];
    XCTAssertNotNil(date);
    XCTAssertEqualObjects(date, referenceDate);
    
    date = [MPDateFormatter dateFromStringRFC1123:@"Sat, 5 Nov 1955 01:15:00 -8"];
    XCTAssertNotNil(date);
    XCTAssertEqualObjects(date, referenceDate);
}

- (void)testStringFromDates {
    NSString *dateString = [MPDateFormatter stringFromDateRFC1123:referenceDate];
    XCTAssertNotNil(dateString);
    XCTAssertEqualObjects(dateString, @"Sat, 05 Nov 1955 09:15:00 GMT");
    
    dateString = [MPDateFormatter stringFromDateRFC3339:referenceDate];
    XCTAssertNotNil(dateString);
    XCTAssertEqualObjects(dateString, @"1955-11-05T09:15:00+0000");
}

- (void)testIndalidDatesFromString {
    NSString *dateString = (NSString *)[NSNull null];
    NSDate *date = [MPDateFormatter dateFromStringRFC3339:dateString];
    XCTAssertNil(date);
    
    date = [MPDateFormatter dateFromStringRFC1123:dateString];
    XCTAssertNil(date);
}

- (void)testInvalidStringFromDates {
    NSDate *date = (NSDate *)[NSNull null];
    NSString *dateString = [MPDateFormatter stringFromDateRFC1123:date];
    XCTAssertNil(dateString);
    
    date = nil;
    dateString = [MPDateFormatter stringFromDateRFC3339:date];
    XCTAssertNil(dateString);
}

@end

//
//  MPUserAttributeChangeTests.m
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
#import "MPUserAttributeChange.h"

@interface MPUserAttributeChangeTests : XCTestCase

@end

@implementation MPUserAttributeChangeTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInstance {
    NSArray *val2Array = @[@"item1", @"item2"];
    NSDictionary<NSString *, id> *userAttributes = @{@"key1":@"val1",
                                                     @"key2":val2Array};
    
    MPUserAttributeChange *userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:userAttributes key:@"key3" value:@"val3"];
    XCTAssertNotNil(userAttributeChange);
    XCTAssertEqualObjects(userAttributeChange.key, @"key3");
    XCTAssertNil(userAttributeChange.timestamp);
    XCTAssertEqualObjects(userAttributeChange.userAttributes, userAttributes);
    XCTAssertEqualObjects(userAttributeChange.value, @"val3");
    XCTAssertEqualObjects(userAttributeChange.valueToLog, @"val3");
    XCTAssertEqual(userAttributeChange.deleted, NO);
    XCTAssertEqual(userAttributeChange.isArray, NO);
    
    userAttributeChange.timestamp = [NSDate date];
    XCTAssertNotNil(userAttributeChange.timestamp);
    
    userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:userAttributes key:@"key2" value:nil];
    userAttributeChange.deleted = YES;
    XCTAssertNotNil(userAttributeChange);
    XCTAssertEqualObjects(userAttributeChange.key, @"key2");
    XCTAssertNil(userAttributeChange.timestamp);
    XCTAssertEqualObjects(userAttributeChange.userAttributes, userAttributes);
    XCTAssertNil(userAttributeChange.value);
    XCTAssertEqualObjects(userAttributeChange.valueToLog, [NSNull null]);
    XCTAssertEqual(userAttributeChange.deleted, YES);
    XCTAssertEqual(userAttributeChange.isArray, YES);
    
    userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:nil key:@"key2" value:@[@"item1", @"item2"]];
    XCTAssertNotNil(userAttributeChange);
    XCTAssertEqualObjects(userAttributeChange.key, @"key2");
    XCTAssertNil(userAttributeChange.timestamp);
    XCTAssertNil(userAttributeChange.userAttributes);
    XCTAssertEqualObjects(userAttributeChange.value, val2Array);
    XCTAssertEqualObjects(userAttributeChange.valueToLog, val2Array);
    XCTAssertEqual(userAttributeChange.deleted, NO);
    XCTAssertEqual(userAttributeChange.isArray, YES);
    
    userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:nil key:@"key2" value:nil];
    XCTAssertNil(userAttributeChange);
}

@end

//
//  MPUserIdentityChangeTests.m
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
#import "MPUserIdentityChange.h"
#import "MPIConstants.h"

@interface MPUserIdentityChangeTests : XCTestCase

@end

@implementation MPUserIdentityChangeTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testUserIdentityInstance {
    NSDate *date = [NSDate date];
    
    // New user identity
    MPUserIdentityInstance *userIdentity = [[MPUserIdentityInstance alloc] initWithType:MPUserIdentityCustomerId value:@"The Most Interesting Man in the World" dateFirstSet:date isFirstTimeSet:YES];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqual(userIdentity.type, MPUserIdentityCustomerId);
    XCTAssertEqualObjects(userIdentity.value, @"The Most Interesting Man in the World");
    XCTAssertEqualObjects(userIdentity.dateFirstSet, date);
    XCTAssertTrue(userIdentity.isFirstTimeSet);
    
    NSDictionary *dictionary = [userIdentity dictionaryRepresentation];
    XCTAssertNotNil(dictionary);
    XCTAssertEqualObjects(dictionary[@"n"], @(MPUserIdentityCustomerId));
    XCTAssertEqualObjects(dictionary[@"i"], @"The Most Interesting Man in the World");
    XCTAssertEqualObjects(dictionary[@"dfs"], MPMilliseconds([date timeIntervalSince1970]));
    XCTAssertEqualObjects(dictionary[@"f"], @(YES));
    
    // Delete user identity
    userIdentity = [[MPUserIdentityInstance alloc] initWithType:MPUserIdentityCustomerId value:nil dateFirstSet:date isFirstTimeSet:NO];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqual(userIdentity.type, MPUserIdentityCustomerId);
    XCTAssertNil(userIdentity.value);
    XCTAssertEqualObjects(userIdentity.dateFirstSet, date);
    XCTAssertFalse(userIdentity.isFirstTimeSet);
    
    dictionary = [userIdentity dictionaryRepresentation];
    XCTAssertNotNil(dictionary);
    XCTAssertEqualObjects(dictionary[@"n"], @(MPUserIdentityCustomerId));
    XCTAssertNil(dictionary[@"i"]);
    XCTAssertEqualObjects(dictionary[@"dfs"], MPMilliseconds([date timeIntervalSince1970]));
    XCTAssertEqualObjects(dictionary[@"f"], @(NO));
}

- (void)testUserIdentityInstanceWithDictionary {
    NSDate *date = [NSDate date];

    NSDictionary<NSString *, id> *userIdentityDictionary = @{@"n":@(MPUserIdentityCustomerId),
                                                             @"i":@"The Most Interesting Man in the World",
                                                             @"dfs":MPMilliseconds([date timeIntervalSince1970]),
                                                             @"f":@YES};

    MPUserIdentityInstance *userIdentity = [[MPUserIdentityInstance alloc] initWithUserIdentityDictionary:userIdentityDictionary];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqual(userIdentity.type, MPUserIdentityCustomerId);
    XCTAssertEqualObjects(userIdentity.value, @"The Most Interesting Man in the World");
    XCTAssertEqualWithAccuracy([userIdentity.dateFirstSet timeIntervalSince1970], [date timeIntervalSince1970], 0.01);
    XCTAssertTrue(userIdentity.isFirstTimeSet);
}

- (void)testUserIdentityChange {
    NSDate *date = [NSDate date];
    MPUserIdentityInstance *userIdentityNew = [[MPUserIdentityInstance alloc] initWithType:MPUserIdentityCustomerId value:@"The Most Interesting Man in the World" dateFirstSet:date isFirstTimeSet:NO];
    MPUserIdentityInstance *userIdentityOld = [[MPUserIdentityInstance alloc] initWithType:MPUserIdentityCustomerId value:@"The Least Interesting Man in the World" dateFirstSet:[NSDate distantPast] isFirstTimeSet:YES];

    MPUserIdentityChange *userIdentityChange = [[MPUserIdentityChange alloc] initWithNewUserIdentity:userIdentityNew oldUserIdentity:userIdentityOld timestamp:date];
    XCTAssertNotNil(userIdentityChange);
    XCTAssertNotNil(userIdentityChange.userIdentityNew);
    XCTAssertNotNil(userIdentityChange.userIdentityOld);
    XCTAssertNotNil(userIdentityChange.timestamp);
    
    userIdentityChange = [[MPUserIdentityChange alloc] initWithNewUserIdentity:userIdentityNew oldUserIdentity:nil timestamp:nil];
    XCTAssertNotNil(userIdentityChange);
    XCTAssertNotNil(userIdentityChange.userIdentityNew);
    XCTAssertNil(userIdentityChange.userIdentityOld);
    XCTAssertNotNil(userIdentityChange.timestamp);
}

@end

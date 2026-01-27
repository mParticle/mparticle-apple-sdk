#import <XCTest/XCTest.h>
@import mParticle_Apple_SDK_Swift;

@interface MPUserIdentityChangeTests : XCTestCase

@end

@implementation MPUserIdentityChangeTests

- (void)testUserIdentityInstance {
    NSDate *date = [NSDate date];
    
    // New user identity
    MPUserIdentityInstancePRIVATE *userIdentity = [[MPUserIdentityInstancePRIVATE alloc] initWithType:MPUserIdentitySwiftCustomerId value:@"The Most Interesting Man in the World" dateFirstSet:date isFirstTimeSet:YES];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqual(userIdentity.type, MPUserIdentitySwiftCustomerId);
    XCTAssertEqualObjects(userIdentity.value, @"The Most Interesting Man in the World");
    XCTAssertEqualObjects(userIdentity.dateFirstSet, date);
    XCTAssertTrue(userIdentity.isFirstTimeSet);
    
    NSDictionary *dictionary = [userIdentity dictionaryRepresentation];
    XCTAssertNotNil(dictionary);
    XCTAssertEqualObjects(dictionary[@"n"], @(MPUserIdentitySwiftCustomerId));
    XCTAssertEqualObjects(dictionary[@"i"], @"The Most Interesting Man in the World");
    NSNumber *timestamp = @([MPTimeUtils millisecondsWithTimestamp:[date timeIntervalSince1970]]);
    XCTAssertEqualObjects(dictionary[@"dfs"], timestamp);
    XCTAssertEqualObjects(dictionary[@"f"], @(YES));
    
    // Delete user identity
    userIdentity = [[MPUserIdentityInstancePRIVATE alloc] initWithType:MPUserIdentitySwiftCustomerId value:nil dateFirstSet:date isFirstTimeSet:NO];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqual(userIdentity.type, MPUserIdentitySwiftCustomerId);
    XCTAssertNil(userIdentity.value);
    XCTAssertEqualObjects(userIdentity.dateFirstSet, date);
    XCTAssertFalse(userIdentity.isFirstTimeSet);
    
    dictionary = [userIdentity dictionaryRepresentation];
    XCTAssertNotNil(dictionary);
    XCTAssertEqualObjects(dictionary[@"n"], @(MPUserIdentitySwiftCustomerId));
    XCTAssertNil(dictionary[@"i"]);
    XCTAssertEqualObjects(dictionary[@"dfs"], timestamp);
    XCTAssertEqualObjects(dictionary[@"f"], @(NO));
}

- (void)testUserIdentityInstanceWithDictionary {
    NSDate *date = [NSDate date];

    NSNumber *timestamp = @([MPTimeUtils millisecondsWithTimestamp:[date timeIntervalSince1970]]);
    NSDictionary<NSString *, id> *userIdentityDictionary = @{
        @"n":@(MPUserIdentitySwiftCustomerId),
        @"i":@"The Most Interesting Man in the World",
        @"dfs":timestamp,
        @"f":@YES
    };

    MPUserIdentityInstancePRIVATE *userIdentity = [[MPUserIdentityInstancePRIVATE alloc] initWithUserIdentityDictionary:userIdentityDictionary];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqual(userIdentity.type, MPUserIdentitySwiftCustomerId);
    XCTAssertEqualObjects(userIdentity.value, @"The Most Interesting Man in the World");
    XCTAssertEqualWithAccuracy([userIdentity.dateFirstSet timeIntervalSince1970], [date timeIntervalSince1970], 0.01);
    XCTAssertTrue(userIdentity.isFirstTimeSet);
    
    
    userIdentityDictionary = @{
        @"n":@(MPUserIdentitySwiftOther2),
        @"i":@"34353234",
        @"dfs":timestamp,
        @"f":@YES
    };

    userIdentity = [[MPUserIdentityInstancePRIVATE alloc] initWithUserIdentityDictionary:userIdentityDictionary];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqual(userIdentity.type, MPUserIdentitySwiftOther2);
    XCTAssertEqualObjects(userIdentity.value, @"34353234");
    XCTAssertEqualWithAccuracy([userIdentity.dateFirstSet timeIntervalSince1970], [date timeIntervalSince1970], 0.01);
    XCTAssertTrue(userIdentity.isFirstTimeSet);
}

- (void)testUserIdentityChange {
    NSDate *date = [NSDate date];
    MPUserIdentityInstancePRIVATE *newUserIdentity = [[MPUserIdentityInstancePRIVATE alloc] initWithType:MPUserIdentitySwiftCustomerId value:@"The Most Interesting Man in the World" dateFirstSet:date isFirstTimeSet:NO];
    MPUserIdentityInstancePRIVATE *oldUserIdentity = [[MPUserIdentityInstancePRIVATE alloc] initWithType:MPUserIdentitySwiftCustomerId value:@"The Least Interesting Man in the World" dateFirstSet:[NSDate distantPast] isFirstTimeSet:YES];

    MPUserIdentityChangePRIVATE *userIdentityChange = [[MPUserIdentityChangePRIVATE alloc] initWithNewUserIdentity:newUserIdentity oldUserIdentity:oldUserIdentity timestamp:date userIdentities:nil];
    XCTAssertNotNil(userIdentityChange);
    XCTAssertNotNil(userIdentityChange.newUserIdentity);
    XCTAssertNotNil(userIdentityChange.oldUserIdentity);
    XCTAssertNotNil(userIdentityChange.timestamp);
    XCTAssertTrue(userIdentityChange.changed);
    
    userIdentityChange = [[MPUserIdentityChangePRIVATE alloc] initWithNewUserIdentity:newUserIdentity oldUserIdentity:nil timestamp:nil userIdentities:nil];
    XCTAssertNotNil(userIdentityChange);
    XCTAssertNotNil(userIdentityChange.newUserIdentity);
    XCTAssertNil(userIdentityChange.oldUserIdentity);
    XCTAssertNotNil(userIdentityChange.timestamp);
    XCTAssertTrue(userIdentityChange.changed);
}

- (void)testIdenticalUserIdentityChange {
    NSString* kMPUserIdentityTypeKey = @"n";
    NSString* kMPUserIdentityIdKey = @"i";
    NSArray<NSDictionary<NSString *, id> *> *userIdentities = @[
        @{
            kMPUserIdentityTypeKey:@(MPUserIdentitySwiftCustomerId),
            kMPUserIdentityIdKey:@"The Most Interesting Man in the World"
        }
    ];

    MPUserIdentityInstancePRIVATE *newUserIdentity = [[MPUserIdentityInstancePRIVATE alloc] initWithType:MPUserIdentitySwiftCustomerId value:@"The Most Interesting Man in the World" dateFirstSet:[NSDate date] isFirstTimeSet:NO];
    MPUserIdentityChangePRIVATE *userIdentityChange = [[MPUserIdentityChangePRIVATE alloc] initWithNewUserIdentity:newUserIdentity userIdentities:userIdentities];
    XCTAssertNotNil(userIdentityChange);
    XCTAssertNotNil(userIdentityChange.newUserIdentity);
    XCTAssertNil(userIdentityChange.oldUserIdentity);
    XCTAssertNotNil(userIdentityChange.timestamp);
    XCTAssertFalse(userIdentityChange.changed);
}

- (void)testUserIdentityChangeTimestampBehavior {
    
    MPUserIdentityInstancePRIVATE *newUserIdentity = [[MPUserIdentityInstancePRIVATE alloc] initWithType:MPUserIdentitySwiftCustomerId value:@"test1" dateFirstSet:[NSDate date] isFirstTimeSet:NO];
    MPUserIdentityInstancePRIVATE *oldUserIdentity = [[MPUserIdentityInstancePRIVATE alloc] initWithType:MPUserIdentitySwiftCustomerId value:@"test2" dateFirstSet:[NSDate distantPast] isFirstTimeSet:YES];

    // Set date on init
    NSDate *date1 = [NSDate date];
    MPUserIdentityChangePRIVATE *userIdentityChange1 = [[MPUserIdentityChangePRIVATE alloc] initWithNewUserIdentity:newUserIdentity oldUserIdentity:oldUserIdentity timestamp:date1 userIdentities:nil];
    XCTAssertEqualObjects(userIdentityChange1.timestamp, date1);
    
    // Date is created on get
    MPUserIdentityChangePRIVATE *userIdentityChange2 = [[MPUserIdentityChangePRIVATE alloc] initWithNewUserIdentity:newUserIdentity oldUserIdentity:oldUserIdentity timestamp:nil userIdentities:nil];
    NSTimeInterval timestamp = userIdentityChange2.timestamp.timeIntervalSince1970;
    XCTAssertNotNil(userIdentityChange2.timestamp);
    [NSThread sleepForTimeInterval:0.5];
    XCTAssertEqual(timestamp, userIdentityChange2.timestamp.timeIntervalSince1970);
    XCTAssertNotNil(userIdentityChange2.timestamp);
}

@end

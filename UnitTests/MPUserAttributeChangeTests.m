#import <XCTest/XCTest.h>
#import "MParticleSwift.h"
#import "MPBaseTestCase.h"

@interface MPUserAttributeChangeTests : MPBaseTestCase

@end

@implementation MPUserAttributeChangeTests

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
    XCTAssertTrue(userAttributeChange.changed);
    XCTAssertFalse(userAttributeChange.deleted);
    XCTAssertFalse(userAttributeChange.isArray);
    
    userAttributeChange.timestamp = [NSDate date];
    XCTAssertNotNil(userAttributeChange.timestamp);
    
    userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:userAttributes key:@"key2" value:nil];
    userAttributeChange.deleted = YES;
    XCTAssertNotNil(userAttributeChange);
    XCTAssertEqualObjects(userAttributeChange.key, @"key2");
    XCTAssertNil(userAttributeChange.timestamp);
    XCTAssertEqualObjects(userAttributeChange.userAttributes, userAttributes);
    XCTAssertNil(userAttributeChange.value);
    XCTAssertNil(userAttributeChange.valueToLog);
    XCTAssertTrue(userAttributeChange.changed);
    XCTAssertTrue(userAttributeChange.deleted);
    XCTAssertTrue(userAttributeChange.isArray);
    
    userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:userAttributes key:@"key2" value:@[@"item1", @"item2"]];
    XCTAssertNotNil(userAttributeChange);
    XCTAssertEqualObjects(userAttributeChange.key, @"key2");
    XCTAssertNil(userAttributeChange.timestamp);
    XCTAssertNotNil(userAttributeChange.userAttributes);
    XCTAssertEqualObjects(userAttributeChange.value, val2Array);
    XCTAssertEqualObjects(userAttributeChange.valueToLog, val2Array);
    XCTAssertFalse(userAttributeChange.changed);
    XCTAssertFalse(userAttributeChange.deleted);
    XCTAssertTrue(userAttributeChange.isArray);

    userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:nil key:@"key2" value:@[@"item1", @"item2"]];
    XCTAssertNotNil(userAttributeChange);
    XCTAssertEqualObjects(userAttributeChange.key, @"key2");
    XCTAssertNil(userAttributeChange.timestamp);
    XCTAssertNil(userAttributeChange.userAttributes);
    XCTAssertEqualObjects(userAttributeChange.value, val2Array);
    XCTAssertEqualObjects(userAttributeChange.valueToLog, val2Array);
    XCTAssertTrue(userAttributeChange.changed);
    XCTAssertFalse(userAttributeChange.deleted);
    XCTAssertTrue(userAttributeChange.isArray);

    userAttributeChange = [[MPUserAttributeChange alloc] initWithUserAttributes:nil key:@"key2" value:nil];
    XCTAssertNil(userAttributeChange);
}

@end

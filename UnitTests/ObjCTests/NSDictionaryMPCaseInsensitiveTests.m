#import <XCTest/XCTest.h>
#import "NSDictionary+MPCaseInsensitive.h"
@import mParticle_Apple_SDK_Swift;

@interface NSDictionaryMPCaseInsensitiveTests : XCTestCase

@end

@implementation NSDictionaryMPCaseInsensitiveTests

#pragma mark - caseInsensitiveKey:

- (void)testCaseInsensitiveKeyExactMatch {
    NSDictionary *dictionary = @{@"Key1": @"value1"};
    XCTAssertEqualObjects([dictionary caseInsensitiveKey:@"Key1"], @"Key1");
}

- (void)testCaseInsensitiveKeyReturnsStoredKeyNotQueriedKey {
    NSDictionary *dictionary = @{@"KeY1": @"value1"};
    XCTAssertEqualObjects([dictionary caseInsensitiveKey:@"kEy1"], @"KeY1");
}

- (void)testCaseInsensitiveKeyFallsBackToQueriedKeyWhenAbsent {
    NSDictionary *dictionary = @{@"Key1": @"value1"};
    XCTAssertEqualObjects([dictionary caseInsensitiveKey:@"This key does not exist"], @"This key does not exist");
}

- (void)testCaseInsensitiveKeyFallsBackToQueriedKeyWhenEmpty {
    XCTAssertEqualObjects([@{} caseInsensitiveKey:@"anything"], @"anything");
}

#pragma mark - valueForCaseInsensitiveKey:

- (void)testValueForCaseInsensitiveKeyMatchesRegardlessOfCase {
    NSDictionary *dictionary = @{@"KeY1": @"value1", @"key2": @2};
    XCTAssertEqualObjects([dictionary valueForCaseInsensitiveKey:@"kEy1"], @"value1");
    XCTAssertEqualObjects([dictionary valueForCaseInsensitiveKey:@"KEY2"], @2);
}

- (void)testValueForCaseInsensitiveKeyReturnsNilWhenAbsent {
    NSDictionary *dictionary = @{@"Key1": @"value1"};
    XCTAssertNil([dictionary valueForCaseInsensitiveKey:@"This key does not exist"]);
}

#pragma mark - transformValuesToString

- (void)testTransformKeepsStringsUnchanged {
    NSDictionary *result = [@{@"key": @"value"} transformValuesToString];
    XCTAssertEqualObjects(result[@"key"], @"value");
}

- (void)testTransformEncodesBooleanNumbersAsTrueAndFalse {
    NSDictionary *result = [@{@"yes": @YES, @"no": @NO} transformValuesToString];
    XCTAssertEqualObjects(result[@"yes"], @"true");
    XCTAssertEqualObjects(result[@"no"], @"false");
}

- (void)testTransformEncodesNonBooleanNumbersWithStringValue {
    NSDictionary *result = [@{@"one": @1, @"zero": @0, @"double": @3.5, @"negative": @(-7)} transformValuesToString];
    XCTAssertEqualObjects(result[@"one"], @"1");
    XCTAssertEqualObjects(result[@"zero"], @"0");
    XCTAssertEqualObjects(result[@"double"], @"3.5");
    XCTAssertEqualObjects(result[@"negative"], @"-7");
}

- (void)testTransformEncodesDatesAsRFC3339 {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1600000000];
    NSDictionary *result = [@{@"date": date} transformValuesToString];
    XCTAssertEqualObjects(result[@"date"], [MPDateFormatter stringFromDateRFC3339:date]);
}

- (void)testTransformDecodesNonEmptyDataAsUTF8 {
    NSData *data = [@"payload" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *result = [@{@"data": data} transformValuesToString];
    XCTAssertEqualObjects(result[@"data"], @"payload");
}

// Non-empty data passes the length guard but still yields nil when it is not
// valid UTF-8, which drops the key without reaching the unsupported branch.
- (void)testTransformDropsDataThatIsNotValidUTF8 {
    const unsigned char invalidBytes[] = {0xC3, 0x28};
    NSData *invalid = [NSData dataWithBytes:invalidBytes length:sizeof(invalidBytes)];
    NSDictionary *result = [@{@"invalid": invalid, @"keep": @"value"} transformValuesToString];
    XCTAssertNil(result[@"invalid"]);
    XCTAssertEqualObjects(result[@"keep"], @"value");
}

- (void)testTransformEncodesCollectionsWithDescription {
    NSDictionary *inner = @{@"a": @1};
    NSArray *array = @[@"x", @"y"];
    NSDictionary *result = [@{@"dict": inner, @"array": array} transformValuesToString];
    XCTAssertEqualObjects(result[@"dict"], [inner description]);
    XCTAssertEqualObjects(result[@"array"], [array description]);
}

- (void)testTransformEncodesMutableCollectionsWithDescription {
    NSMutableDictionary *inner = [@{@"a": @1} mutableCopy];
    NSMutableArray *array = [@[@"x"] mutableCopy];
    NSDictionary *result = [@{@"dict": inner, @"array": array} transformValuesToString];
    XCTAssertEqualObjects(result[@"dict"], [inner description]);
    XCTAssertEqualObjects(result[@"array"], [array description]);
}

- (void)testTransformLeavesNullAsNSNull {
    NSDictionary *result = [@{@"null": [NSNull null]} transformValuesToString];
    XCTAssertEqualObjects(result[@"null"], [NSNull null]);
}

- (void)testTransformOfEmptyDictionaryIsEmpty {
    XCTAssertEqualObjects([@{} transformValuesToString], @{});
}

- (void)testTransformGoldenRoundTrip {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1600000000];
    NSDictionary *inner = @{@"a": @1};
    NSArray *array = @[@"x", @"y"];

    NSDictionary *original = @{
        @"string": @"text",
        @"boolTrue": @YES,
        @"boolFalse": @NO,
        @"int": @42,
        @"zero": @0,
        @"double": @3.5,
        @"date": date,
        @"data": [@"payload" dataUsingEncoding:NSUTF8StringEncoding],
        @"dict": inner,
        @"array": array,
        @"null": [NSNull null]
    };

    NSDictionary *expected = @{
        @"string": @"text",
        @"boolTrue": @"true",
        @"boolFalse": @"false",
        @"int": @"42",
        @"zero": @"0",
        @"double": @"3.5",
        @"date": [MPDateFormatter stringFromDateRFC3339:date],
        @"data": @"payload",
        @"dict": [inner description],
        @"array": [array description],
        @"null": [NSNull null]
    };

    XCTAssertEqualObjects([original transformValuesToString], expected);
}

// Zero-length NSData fails the `length > 0` guard and falls through to the
// unsupported-value branch, so the key is dropped.
- (void)testTransformOfEmptyDataIsUnsupported {
    NSDictionary *original = @{@"empty": [NSData data], @"keep": @"value"};
    NSDictionary *result = nil;
    XCTAssertNoThrow(result = [original transformValuesToString]);
    XCTAssertNil(result[@"empty"]);
    XCTAssertEqualObjects(result[@"keep"], @"value");
}

- (void)testTransformOfUnsupportedValueType {
    NSDictionary *original = @{@"unsupported": [[NSObject alloc] init], @"keep": @"value"};
    NSDictionary *result = nil;
    XCTAssertNoThrow(result = [original transformValuesToString]);
    XCTAssertNil(result[@"unsupported"]);
    XCTAssertEqualObjects(result[@"keep"], @"value");
}

@end

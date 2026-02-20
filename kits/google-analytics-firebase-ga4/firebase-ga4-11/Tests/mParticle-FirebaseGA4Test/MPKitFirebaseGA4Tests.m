#import <XCTest/XCTest.h>
#import "MPKitFirebaseGA4.h"
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
#import <mParticle_Apple_SDK/mParticle.h>
#else
#import "mParticle.h"
#endif

@interface MPKitFirebaseGA4 ()
- (NSString *)standardizeNameOrKey:(NSString *)nameOrKey forEvent:(BOOL)forEvent;
- (NSString *)standardizeValue:(id)value forEvent:(BOOL)forEvent;
- (void)limitDictionary:(NSMutableDictionary *)dictionary maxCount:(int)maxCount;
@end

@interface MPKitFirebaseGA4Tests : XCTestCase
@property (nonatomic, strong) MPKitFirebaseGA4 *kit;
@end

@implementation MPKitFirebaseGA4Tests

- (void)setUp {
    [super setUp];
    self.kit = [[MPKitFirebaseGA4 alloc] init];
}

- (void)tearDown {
    self.kit = nil;
    [super tearDown];
}

- (void)testKitCode {
    XCTAssertEqualObjects([MPKitFirebaseGA4 kitCode], @(MPKitInstanceGoogleAnalyticsFirebaseGA4));
}

- (void)testStandardizeEventNameTruncatesAt40 {
    NSString *longName = @"ThisIsAVeryLongEventNameThatExceedsFortyCharactersLimit";
    NSString *result = [self.kit standardizeNameOrKey:longName forEvent:YES];
    XCTAssertLessThanOrEqual(result.length, 40);
}

- (void)testStandardizeEventNameRemovesFirebasePrefix {
    NSString *name = @"firebase_my_event";
    NSString *result = [self.kit standardizeNameOrKey:name forEvent:YES];
    XCTAssertFalse([result hasPrefix:@"firebase_"]);
}

- (void)testStandardizeEventNameRemovesGooglePrefix {
    NSString *name = @"google_my_event";
    NSString *result = [self.kit standardizeNameOrKey:name forEvent:YES];
    XCTAssertFalse([result hasPrefix:@"google_"]);
}

- (void)testStandardizeEventNameRemovesGaPrefix {
    NSString *name = @"ga_my_event";
    NSString *result = [self.kit standardizeNameOrKey:name forEvent:YES];
    XCTAssertFalse([result hasPrefix:@"ga_"]);
}

- (void)testStandardizeEventNameHandlesEmptyString {
    NSString *result = [self.kit standardizeNameOrKey:@"" forEvent:YES];
    XCTAssertEqualObjects(result, @"invalid_ga4_key");
}

- (void)testStandardizeEventNameReplacesInvalidChars {
    NSString *name = @"my-event-name";
    NSString *result = [self.kit standardizeNameOrKey:name forEvent:YES];
    XCTAssertFalse([result containsString:@"-"]);
}

- (void)testStandardizeValueTruncatesEventAttrAt500 {
    NSMutableString *longValue = [NSMutableString string];
    for (int i = 0; i < 600; i++) [longValue appendString:@"a"];
    NSString *result = [self.kit standardizeValue:longValue forEvent:YES];
    XCTAssertLessThanOrEqual(result.length, 500);
}

- (void)testStandardizeValueTruncatesIdentityAttrAt36 {
    NSMutableString *longValue = [NSMutableString string];
    for (int i = 0; i < 100; i++) [longValue appendString:@"a"];
    NSString *result = [self.kit standardizeValue:longValue forEvent:NO];
    XCTAssertLessThanOrEqual(result.length, 36);
}

- (void)testLimitDictionaryReducesToMaxCount {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (int i = 0; i < 10; i++) {
        dict[[NSString stringWithFormat:@"key%d", i]] = @"value";
    }
    [self.kit limitDictionary:dict maxCount:5];
    XCTAssertEqual(dict.count, 5);
}

- (void)testCustomNameStandardizationIsApplied {
    [MPKitFirebaseGA4 setCustomNameStandardization:^NSString * _Nonnull(NSString * _Nonnull name) {
        return @"custom_name";
    }];
    NSString *result = [self.kit standardizeNameOrKey:@"original_name" forEvent:YES];
    XCTAssertEqualObjects(result, @"custom_name");
    [MPKitFirebaseGA4 setCustomNameStandardization:nil];
}

- (void)testConvertToKeyValuePairs {
    NSArray *mappings = @[
        @{@"value": @"ad_storage", @"map": @"Advertising"},
        @{@"value": @"analytics_storage", @"map": @"Analytics"}
    ];
    NSDictionary *result = [self.kit convertToKeyValuePairs:mappings];
    XCTAssertEqualObjects(result[@"ad_storage"], @"advertising");
    XCTAssertEqualObjects(result[@"analytics_storage"], @"analytics");
}

@end

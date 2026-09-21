#import <XCTest/XCTest.h>
#import "MPKitOneTrust.h"

// start wraps its body in a process-wide dispatch_once that testStarted below already consumes, so
// the configuration parsing is exercised directly rather than through a second kit launch.
@interface MPKitOneTrust (Testing)
- (NSDictionary *)parseConsentMapping:(NSString *)rawConsentMapping;
- (NSString * _Nullable)configurationStringForKey:(NSString *)key;
- (void)persistConfigurationKey:(NSString *)key asDefaultsKey:(NSString *)defaultsKey;
@end

@interface mParticle_OneTrustTests : XCTestCase

@end

@implementation mParticle_OneTrustTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testModuleID {
    XCTAssertEqualObjects([MPKitOneTrust kitCode], @134);
}

- (void)testStarted {
    MPKitOneTrust *oneTrustKit = [[MPKitOneTrust alloc] init];
    [oneTrustKit didFinishLaunchingWithConfiguration:@{@"mobileConsentGroups":@"12345"}];
    XCTAssertTrue(oneTrustKit.started);
}

#pragma mark - Malformed consent mapping

// The mapping is server-supplied JSON, so only its root array is guaranteed. Elements and their
// value/map fields may be any JSON type, and none of them may raise.

- (void)testParseConsentMappingIgnoresNonDictionaryElements {
    MPKitOneTrust *kit = [[MPKitOneTrust alloc] init];

    for (NSString *mapping in @[@"[\"a\"]", @"[1]", @"[[]]", @"[null]", @"[{}]"]) {
        NSDictionary *result = nil;
        XCTAssertNoThrow(result = [kit parseConsentMapping:mapping], @"raised for %@", mapping);
        XCTAssertEqual(result.count, 0, @"expected no entries for %@", mapping);
    }
}

- (void)testParseConsentMappingIgnoresNonStringValueAndMap {
    MPKitOneTrust *kit = [[MPKitOneTrust alloc] init];

    NSArray<NSString *> *mappings = @[
        @"[{\"value\":\"C0001\",\"map\":1}]",
        @"[{\"value\":\"C0001\",\"map\":null}]",
        @"[{\"value\":1,\"map\":\"marketing\"}]",
        @"[{\"value\":{},\"map\":\"marketing\"}]",
        @"[{\"value\":\"C0001\",\"map\":[]}]"
    ];

    for (NSString *mapping in mappings) {
        NSDictionary *result = nil;
        XCTAssertNoThrow(result = [kit parseConsentMapping:mapping], @"raised for %@", mapping);
        XCTAssertEqual(result.count, 0, @"expected no entries for %@", mapping);
    }
}

- (void)testParseConsentMappingSkipsMalformedEntriesAndKeepsValidOnes {
    MPKitOneTrust *kit = [[MPKitOneTrust alloc] init];
    NSString *mapping = @"[1, {\"value\":\"C0002\",\"map\":\"marketing\"}, null]";

    NSDictionary *result = [kit parseConsentMapping:mapping];

    XCTAssertEqual(result.count, 1);
    XCTAssertEqualObjects(result[@"C0002"][@"purpose"], @"marketing");
    XCTAssertEqualObjects(result[@"C0002"][@"regulation"], @"gdpr");
}

- (void)testParseConsentMappingStillRecognizesCCPAPurpose {
    MPKitOneTrust *kit = [[MPKitOneTrust alloc] init];
    NSString *mapping = @"[{\"value\":\"C0004\",\"map\":\"data_sale_opt_out\"}]";

    NSDictionary *result = [kit parseConsentMapping:mapping];

    XCTAssertEqualObjects(result[@"C0004"][@"regulation"], @"ccpa");
}

- (void)testParseConsentMappingIgnoresNonArrayRoot {
    MPKitOneTrust *kit = [[MPKitOneTrust alloc] init];

    NSDictionary *result = [kit parseConsentMapping:@"{\"value\":\"C0001\"}"];

    XCTAssertEqual(result.count, 0);
}

#pragma mark - Malformed configuration values

- (void)testConfigurationStringForKeyRejectsNonStringValues {
    MPKitOneTrust *kit = [[MPKitOneTrust alloc] init];
    kit.configuration = @{
        @"number": @42,
        @"container": @[[NSNull null]],
        @"dictionary": @{@"a": @"b"},
        @"string": @"[]"
    };

    XCTAssertNil([kit configurationStringForKey:@"number"]);
    XCTAssertNil([kit configurationStringForKey:@"container"]);
    XCTAssertNil([kit configurationStringForKey:@"dictionary"]);
    XCTAssertNil([kit configurationStringForKey:@"missing"]);
    XCTAssertEqualObjects([kit configurationStringForKey:@"string"], @"[]");
}

// NSUserDefaults only accepts property list objects, and an array holding a null is not one, so
// writing the raw configuration value used to raise before the kit could finish launching.
- (void)testPersistConfigurationKeyDoesNotWriteNonPropertyListValues {
    MPKitOneTrust *kit = [[MPKitOneTrust alloc] init];
    NSString *defaultsKey = @"OT_mP_Mapping_Test";
    [[NSUserDefaults standardUserDefaults] setObject:@"stale" forKey:defaultsKey];

    kit.configuration = @{@"mobileConsentGroups": @[[NSNull null]]};

    XCTAssertNoThrow([kit persistConfigurationKey:@"mobileConsentGroups" asDefaultsKey:defaultsKey]);
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey]);

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:defaultsKey];
}

- (void)testPersistConfigurationKeyWritesStringValues {
    MPKitOneTrust *kit = [[MPKitOneTrust alloc] init];
    NSString *defaultsKey = @"OT_mP_Mapping_Test";
    kit.configuration = @{@"mobileConsentGroups": @"[{\"value\":\"C0001\",\"map\":\"marketing\"}]"};

    [kit persistConfigurationKey:@"mobileConsentGroups" asDefaultsKey:defaultsKey];

    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] stringForKey:defaultsKey],
                          @"[{\"value\":\"C0001\",\"map\":\"marketing\"}]");

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:defaultsKey];
}

@end

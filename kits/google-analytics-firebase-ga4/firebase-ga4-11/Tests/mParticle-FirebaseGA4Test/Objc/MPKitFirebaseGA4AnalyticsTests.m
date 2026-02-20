#import <XCTest/XCTest.h>
#import "MPKitFirebaseGA4Analytics.h"
#import <FirebaseCore/FirebaseCore.h>
#import <FirebaseAnalytics/FirebaseAnalytics.h>

@interface FIRApp()
+ (void)resetApps;
@end

@interface MPKitFirebaseGA4Analytics()
- (NSString *)standardizeNameOrKey:(NSString *)nameOrKey forEvent:(BOOL)forEvent;
- (NSString *)standardizeValue:(id)value forEvent:(BOOL)forEvent;
- (NSString *)getEventNameForCommerceEvent:(MPCommerceEvent *)commerceEvent parameters:(NSDictionary *)parameters;
- (NSDictionary *)getParameterForCommerceEvent:(MPCommerceEvent *)commerceEvent;
- (NSMutableDictionary *)getParametersForScreen:(MPEvent *)screenEvent;
- (NSMutableArray *)getParametersForProducts:(id)products;
- (void)limitDictionary:(NSMutableDictionary *)dictionary maxCount:(int)maxCount;
@end

static BOOL sFirebaseConfigured = NO;

@interface MPKitFirebaseGA4AnalyticsTests : XCTestCase
@end

@implementation MPKitFirebaseGA4AnalyticsTests

+ (void)setUp {
    [super setUp];
    if (sFirebaseConfigured) return;

    NSBundle *testBundle = [NSBundle bundleForClass:self];
    NSString *filePath = nil;

    NSURL *resourceBundleURL = [testBundle URLForResource:@"mParticle-FirebaseGA4_mParticle-FirebaseGA4-Objc-Tests"
                                            withExtension:@"bundle"];
    if (resourceBundleURL) {
        NSBundle *resourceBundle = [NSBundle bundleWithURL:resourceBundleURL];
        filePath = [resourceBundle pathForResource:@"GoogleService-Info" ofType:@"plist"];
    }
    if (!filePath) {
        filePath = [testBundle pathForResource:@"GoogleService-Info" ofType:@"plist"];
    }
    if (filePath) {
        FIROptions *options = [[FIROptions alloc] initWithContentsOfFile:filePath];
        if (options) {
            @try {
                [FIRApp configureWithOptions:options];
                sFirebaseConfigured = YES;
            } @catch (NSException *exception) {
                NSLog(@"Firebase configuration failed: %@", exception);
            }
        }
    }
}

- (void)tearDown {
    [MPKitFirebaseGA4Analytics setCustomNameStandardization:nil];
    [super tearDown];
}

- (MPKitFirebaseGA4Analytics *)configuredKit {
    MPKitFirebaseGA4Analytics *kit = [[MPKitFirebaseGA4Analytics alloc] init];
    if (sFirebaseConfigured) {
        [kit didFinishLaunchingWithConfiguration:@{}];
    }
    return kit;
}

#pragma mark - Sanitization Tests (no Firebase required)

- (void)testSanitization {
    MPKitFirebaseGA4Analytics *exampleKit = [[MPKitFirebaseGA4Analytics alloc] init];

    NSArray *badPrefixes = @[@"firebase_event_name",
                             @"google_event_name",
                             @"ga_event_name"];
    for (NSString *badPrefix in badPrefixes) {
        XCTAssertEqualObjects([exampleKit standardizeNameOrKey:badPrefix forEvent:YES], @"event_name");
    }

    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event name" forEvent:YES], @"event_name");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event_name " forEvent:YES], @"event_name_");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event  name " forEvent:YES], @"event__name_");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event - name " forEvent:YES], @"event___name_");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event! - ?name " forEvent:YES], @"event_____name_");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event name" forEvent:NO], @"event name");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event_name " forEvent:NO], @"event_name ");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event  name " forEvent:NO], @"event  name ");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event - name " forEvent:NO], @"event - name ");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event! - ?name " forEvent:NO], @"event! - ?name ");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event! - ?name  " forEvent:NO], @"event! - ?name  ");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"!@#$%^&*()_+=[]{}|'\"?>" forEvent:NO], @"!@#$%^&*()_+=[]{}|'\"?>");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@" event_name" forEvent:NO], @" event_name");

    NSArray *badStarts = @[@"!@#$%^&*()_+=[]{}|'\"?><:;event_name",
                           @"_event_name",
                           @" event_name",
                           @"_event_name"];

    for (NSString *badStart in badStarts) {
        XCTAssertEqualObjects([exampleKit standardizeNameOrKey:badStart forEvent:YES], @"event_name");
    }

    NSString *tooLong = @"abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890";
    XCTAssertEqual(40, [exampleKit standardizeNameOrKey:tooLong forEvent:YES].length);
    XCTAssertEqual(24, [exampleKit standardizeNameOrKey:tooLong forEvent:NO].length);
    XCTAssertEqual(500, [exampleKit standardizeValue:tooLong forEvent:YES].length);
    XCTAssertEqual(36, [exampleKit standardizeValue:tooLong forEvent:NO].length);

    NSArray *emptyStrings = @[@"!@#$%^&*()_+=[]{}|'\"?><:;",
                              @"_1234567890",
                              @" ",
                              @""];
    for (NSString *emptyString in emptyStrings) {
        XCTAssertEqualObjects([exampleKit standardizeNameOrKey:emptyString forEvent:YES], @"invalid_ga4_key");
    }
}

- (void)testSanitizationCustom {
    MPKitFirebaseGA4Analytics *exampleKit = [[MPKitFirebaseGA4Analytics alloc] init];

    NSArray *customTest = @[@"firebase_event_name",
                            @"google_event_name",
                            @"ga_event_name"];

    [MPKitFirebaseGA4Analytics setCustomNameStandardization:^(NSString* name) {
        return @"test";
    }];
    for (NSString *tests in customTest) {
        XCTAssertEqualObjects([exampleKit standardizeNameOrKey:tests forEvent:YES], @"test");
    }

    for (NSString *tests in customTest) {
        XCTAssertEqualObjects([exampleKit standardizeNameOrKey:tests forEvent:NO], @"test");
    }
}

- (void)testLimitDictionary {
    MPKitFirebaseGA4Analytics *kit = [[MPKitFirebaseGA4Analytics alloc] init];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (int i = 0; i < 10; i++) {
        dict[[NSString stringWithFormat:@"key%d", i]] = @"value";
    }
    [kit limitDictionary:dict maxCount:5];
    XCTAssertEqual(dict.count, 5);
}

- (void)testKitCode {
    XCTAssertEqualObjects([MPKitFirebaseGA4Analytics kitCode], @(MPKitInstanceGoogleAnalyticsFirebaseGA4));
}

#pragma mark - Firebase-dependent Tests

- (void)testStarted {
    if (!sFirebaseConfigured) { return; }
    MPKitFirebaseGA4Analytics *exampleKit = [self configuredKit];
    XCTAssertTrue(exampleKit.started);
}

- (void)testLogCommerceEvent {
    if (!sFirebaseConfigured) { return; }
    MPKitFirebaseGA4Analytics *exampleKit = [self configuredKit];

    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionCheckoutOptions];
    MPKitExecStatus *execStatus = [exampleKit logBaseEvent:event];
    XCTAssertTrue(execStatus.success);
}

- (void)testLogCommerceEventPurchase {
    if (!sFirebaseConfigured) { return; }
    MPKitFirebaseGA4Analytics *exampleKit = [self configuredKit];

    MPProduct *product = [[MPProduct alloc] initWithName:@"Tardis" sku:@"9who" quantity:@1 price:@42.0];
    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    MPKitExecStatus *execStatus = [exampleKit logBaseEvent:event];

    XCTAssertTrue(execStatus.success);
}

- (void)testLogCommerceEventImpression {
    if (!sFirebaseConfigured) { return; }
    MPKitFirebaseGA4Analytics *exampleKit = [self configuredKit];

    MPProduct *product = [[MPProduct alloc] initWithName:@"Tardis" sku:@"9who" quantity:@1 price:@42.0];
    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithImpressionName:@"suggested products list" product:product];
    MPKitExecStatus *execStatus = [exampleKit logBaseEvent:event];

    XCTAssertTrue(execStatus.success);
}

- (void)testLogCommerceEventPromotion {
    if (!sFirebaseConfigured) { return; }
    MPKitFirebaseGA4Analytics *exampleKit = [self configuredKit];

    MPPromotion *promotion = [[MPPromotion alloc] init];
    promotion.promotionId = @"my_promo_1";
    promotion.creative = @"sale_banner_1";
    promotion.name = @"App-wide 50% off sale";
    promotion.position = @"dashboard_bottom";

    MPPromotionContainer *container = [[MPPromotionContainer alloc] initWithAction:MPPromotionActionView promotion:promotion];
    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithPromotionContainer:container];
    MPKitExecStatus *execStatus = [exampleKit logBaseEvent:event];

    XCTAssertTrue(execStatus.success);
}

- (void)testLogEvent {
    if (!sFirebaseConfigured) { return; }
    MPKitFirebaseGA4Analytics *exampleKit = [self configuredKit];

    MPEvent *event = [[MPEvent alloc] initWithName:@"example" type:MPEventTypeOther];
    MPKitExecStatus *execStatus = [exampleKit logBaseEvent:event];

    XCTAssertTrue(execStatus.success);
}

- (void)testLogEventWithNilEvent {
    if (!sFirebaseConfigured) { return; }
    MPKitFirebaseGA4Analytics *exampleKit = [self configuredKit];

    MPEvent *event = nil;
    MPKitExecStatus *execStatus = [exampleKit logBaseEvent:event];

    XCTAssertFalse(execStatus.success);
}

- (void)testSanitizationMax {
    if (!sFirebaseConfigured) { return; }
    MPKitFirebaseGA4Analytics *exampleKit = [self configuredKit];

    NSDictionary *testAttributes = @{ @"test1": @"parameter", @"test2": @"parameter",
                                      @"test3": @"parameter", @"test4": @"parameter",
                                      @"test5": @"parameter", @"test6": @"parameter",
                                      @"test7": @"parameter", @"test8": @"parameter",
                                      @"test9": @"parameter", @"test10": @"parameter",
                                      @"test11": @"parameter", @"test12": @"parameter",
                                      @"test13": @"parameter", @"test14": @"parameter",
                                      @"test15": @"parameter", @"test16": @"parameter",
                                      @"test17": @"parameter", @"test18": @"parameter",
                                      @"test19": @"parameter", @"test20": @"parameter",
                                      @"test21": @"parameter", @"test22": @"parameter",
                                      @"test23": @"parameter", @"test24": @"parameter" };

    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionCheckoutOptions];
    event.customAttributes = testAttributes;

    NSDictionary *parameters = [exampleKit getParameterForCommerceEvent:event];
    XCTAssertEqual([parameters count], 25);

    NSMutableDictionary *testExcessiveAttributes = [[NSMutableDictionary alloc] initWithCapacity:125];
    for (int i = 0; i < 125; i++) {
        NSString *key = [NSString stringWithFormat:@"test%03d", i];
        testExcessiveAttributes[key] = @"parameter";
    }
    event.customAttributes = testExcessiveAttributes;

    parameters = [exampleKit getParameterForCommerceEvent:event];
    XCTAssertEqual([parameters count], 100);

    MPKitExecStatus *execStatus = [exampleKit logBaseEvent:event];
    XCTAssertTrue(execStatus.success);
}

- (void)testProductParameters {
    if (!sFirebaseConfigured) { return; }
    MPKitFirebaseGA4Analytics *exampleKit = [self configuredKit];

    MPProduct *product = [[MPProduct alloc] initWithName:@"expensivePotato" sku:@"SKU123" quantity:@1 price:@40.0];
    NSMutableDictionary *testProductCustomAttributes = [[@{@"productCustomAttribute": @"potato", @"store": @"Target"} mutableCopy] mutableCopy];
    product.brand = @"LV";
    product.category = @"vegetable";
    product.position = 4;
    product.userDefinedAttributes = testProductCustomAttributes;

    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithImpressionName:@"suggested products list" product:product];
    NSSet *impressionProducts = event.impressions[@"suggested products list"];

    NSArray *itemsArray = [exampleKit getParametersForProducts:impressionProducts];
    id item = itemsArray[0];

    XCTAssertEqual([item count], 9);
}

- (void)testProductPositionEqualZero {
    if (!sFirebaseConfigured) { return; }
    MPKitFirebaseGA4Analytics *exampleKit = [self configuredKit];

    MPProduct *product = [[MPProduct alloc] initWithName:@"expensivePotato" sku:@"SKU123" quantity:@1 price:@40.0];
    NSMutableDictionary *testProductCustomAttributes = [[@{@"productCustomAttribute": @"potato", @"store": @"Target"} mutableCopy] mutableCopy];
    product.brand = @"LV";
    product.category = @"vegetable";
    product.position = 0;
    product.userDefinedAttributes = testProductCustomAttributes;

    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithImpressionName:@"suggested products list" product:product];
    NSSet *impressionProducts = event.impressions[@"suggested products list"];

    NSArray *itemsArray = [exampleKit getParametersForProducts:impressionProducts];
    id item = itemsArray[0];

    XCTAssertEqual([item count], 9);
}

- (void)testCommerceEventCheckoutOptions {
    if (!sFirebaseConfigured) { return; }
    MPKitFirebaseGA4Analytics *exampleKit = [self configuredKit];

    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionCheckoutOptions];
    [event addCustomFlag:kFIREventAddShippingInfo withKey:kMPFIRGA4CommerceEventType];
    NSDictionary *parameters = [exampleKit getParameterForCommerceEvent:event];
    NSString *eventName = [exampleKit getEventNameForCommerceEvent:event parameters:parameters];
    XCTAssertEqualObjects(kFIREventAddShippingInfo, eventName);

    event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionCheckoutOptions];
    [event addCustomFlag:kFIREventAddPaymentInfo withKey:kMPFIRGA4CommerceEventType];
    eventName = [exampleKit getEventNameForCommerceEvent:event parameters:parameters];
    XCTAssertEqualObjects(kFIREventAddPaymentInfo, eventName);

    event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionCheckoutOptions];
    [event addCustomFlags:@[kFIREventAddShippingInfo, kFIREventAddPaymentInfo] withKey:kMPFIRGA4CommerceEventType];
    eventName = [exampleKit getEventNameForCommerceEvent:event parameters:parameters];
    XCTAssertEqualObjects(kFIREventAddShippingInfo, eventName);
}

- (void)testScreenNameAttributes {
    if (!sFirebaseConfigured) { return; }
    MPKitFirebaseGA4Analytics *exampleKit = [self configuredKit];

    MPEvent *event = [[MPEvent alloc] initWithName:@"testScreenName" type:MPEventTypeOther];
    event.customAttributes = @{@"testScreenAttribute":@"value"};
    MPKitExecStatus *execStatus = [exampleKit logScreen:event];

    XCTAssertTrue(execStatus.success);

    NSMutableDictionary *screenParameters = [exampleKit getParametersForScreen:event];
    XCTAssertEqual(screenParameters.count, 2);

    NSString *standardizedScreenName = [exampleKit standardizeNameOrKey:event.name forEvent:YES];
    NSString *screenNameParameter = screenParameters[kFIRParameterScreenName];

    XCTAssertNotNil(screenNameParameter);
    XCTAssertEqualObjects(screenNameParameter, standardizedScreenName);
}

@end

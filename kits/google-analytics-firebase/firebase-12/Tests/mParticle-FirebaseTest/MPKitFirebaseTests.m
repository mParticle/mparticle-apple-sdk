#import "MPKitFirebase.h"
#import <XCTest/XCTest.h>
#import <FirebaseCore/FirebaseCore.h>
#import <FirebaseAnalytics/FirebaseAnalytics.h>

@interface FIRApp()
+ (void)resetApps;
@end

@interface MPKitFirebase()
- (NSString *)standardizeNameOrKey:(NSString *)nameOrKey forEvent:(BOOL)forEvent;
- (NSString *)getEventNameForCommerceEvent:(MPCommerceEvent *)commerceEvent parameters:(NSDictionary<NSString *, id> *)parameters;
- (NSDictionary<NSString *, id> *)getParameterForCommerceEvent:(MPCommerceEvent *)commerceEvent;
- (NSMutableDictionary<NSString *, id> *)getParametersForScreen:(MPEvent *)screenEvent;
@end

@interface MPKitFirebaseTests : XCTestCase
@end

@implementation MPKitFirebaseTests

- (void)setUp {
    [super setUp];

    // Values from GoogleService-Info.plist (FIROptions does not support IS_*, PLIST_VERSION)
    NSString *googleAppID = @"1:123456789012:ios:abcdef1234567890";
    NSString *gcmSenderID = @"123456789012";
    NSString *apiKey = @"AIzaSyTestKeyForUnitTesting123456789012";
    NSString *projectID = @"mparticle-test-project";
    NSString *storageBucket = @"mparticle-test-project.appspot.com";
    NSString *bundleID = @"com.mparticle.mParticle-FirebaseGA4-Tests";

    FIROptions *options = [[FIROptions alloc] initWithGoogleAppID:googleAppID GCMSenderID:gcmSenderID];
    options.APIKey = apiKey;
    options.projectID = projectID;
    options.storageBucket = storageBucket;
    options.bundleID = bundleID;
    [FIRApp configureWithOptions:options];
}

- (void)tearDown {
    [FIRApp resetApps];
}

- (void)testKitCode {
    XCTAssertEqualObjects([MPKitFirebase kitCode], @243);
}

- (void)testStarted {
    MPKitFirebase *exampleKit = [[MPKitFirebase alloc] init];
    [exampleKit didFinishLaunchingWithConfiguration:@{}];

    XCTAssertTrue(exampleKit.started);
}

- (void)testLogCommerceEvent {
    MPKitFirebase *exampleKit = [[MPKitFirebase alloc] init];
    [exampleKit didFinishLaunchingWithConfiguration:@{}];

    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionCheckoutOptions];
    MPKitExecStatus *execStatus = [exampleKit logBaseEvent:event];
    XCTAssertTrue(execStatus.success);
}

- (void)testLogCommerceEventPurchase {
    MPKitFirebase *exampleKit = [[MPKitFirebase alloc] init];
    [exampleKit didFinishLaunchingWithConfiguration:@{}];

    MPProduct *product = [[MPProduct alloc] initWithName:@"Tardis" sku:@"9who" quantity:@1 price:@42.0];
    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    MPKitExecStatus *execStatus = [exampleKit logBaseEvent:event];

    XCTAssertTrue(execStatus.success);
}

- (void)testLogCommerceEventImpression {
    MPKitFirebase *exampleKit = [[MPKitFirebase alloc] init];
    [exampleKit didFinishLaunchingWithConfiguration:@{}];

    MPProduct *product = [[MPProduct alloc] initWithName:@"Tardis" sku:@"9who" quantity:@1 price:@42.0];
    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithImpressionName:@"suggested products list" product:product];
    MPKitExecStatus *execStatus = [exampleKit logBaseEvent:event];

    XCTAssertTrue(execStatus.success);
}

- (void)testLogCommerceEventPromotion {
    MPKitFirebase *exampleKit = [[MPKitFirebase alloc] init];
    [exampleKit didFinishLaunchingWithConfiguration:@{}];

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
    MPKitFirebase *exampleKit = [[MPKitFirebase alloc] init];
    [exampleKit didFinishLaunchingWithConfiguration:@{}];

    MPEvent *event = [[MPEvent alloc] initWithName:@"example" type:MPEventTypeOther];
    MPKitExecStatus *execStatus = [exampleKit logBaseEvent:event];

    XCTAssertTrue(execStatus.success);
}

- (void)testLogEventWithNilEvent {
    MPKitFirebase *exampleKit = [[MPKitFirebase alloc] init];
    [exampleKit didFinishLaunchingWithConfiguration:@{}];

    MPEvent *event = nil;
    MPKitExecStatus *execStatus = [exampleKit logBaseEvent:event];

    XCTAssertFalse(execStatus.success);
}

- (void)testSanitization {
    MPKitFirebase *exampleKit = [[MPKitFirebase alloc] init];

    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event name" forEvent:YES], @"event_name");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event_name " forEvent:YES], @"event_name_");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event  name " forEvent:YES], @"event_name_");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event - name " forEvent:YES], @"event_name_");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event name" forEvent:NO], @"event_name");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event_name " forEvent:NO], @"event_name_");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event  name " forEvent:NO], @"event_name_");
    XCTAssertEqualObjects([exampleKit standardizeNameOrKey:@"event - name " forEvent:NO], @"event_name_");
}

- (void)testCommerceEventCheckoutOptions {
    MPKitFirebase *exampleKit = [[MPKitFirebase alloc] init];
    [exampleKit didFinishLaunchingWithConfiguration:@{}];

    // Test fallback when not using
    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionCheckoutOptions];
    NSDictionary<NSString *, id> *parameters = [exampleKit getParameterForCommerceEvent:event];
    NSString *eventName = [exampleKit getEventNameForCommerceEvent:event parameters:parameters];
    XCTAssertEqualObjects(kFIREventSelectItem, eventName);

    // Test kFIREventAddShippingInfo
    event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionCheckoutOptions];
    [event addCustomFlag:kFIREventAddShippingInfo withKey:kMPFIRCommerceEventType];
    eventName = [exampleKit getEventNameForCommerceEvent:event parameters:parameters];
    XCTAssertEqualObjects(kFIREventAddShippingInfo, eventName);

    // Test kFIREventAddPaymentInfo
    event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionCheckoutOptions];
    [event addCustomFlag:kFIREventAddPaymentInfo withKey:kMPFIRCommerceEventType];
    eventName = [exampleKit getEventNameForCommerceEvent:event parameters:parameters];
    XCTAssertEqualObjects(kFIREventAddPaymentInfo, eventName);

    // Test both (defaults to kFIREventAddShippingInfo)
    event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionCheckoutOptions];
    [event addCustomFlags:@[kFIREventAddShippingInfo, kFIREventAddPaymentInfo] withKey:kMPFIRCommerceEventType];
    eventName = [exampleKit getEventNameForCommerceEvent:event parameters:parameters];
    XCTAssertEqualObjects(kFIREventAddShippingInfo, eventName);
}

- (void)testScreenNameAttributes {
    MPKitFirebase *exampleKit = [[MPKitFirebase alloc] init];
    [exampleKit didFinishLaunchingWithConfiguration:@{}];

    MPEvent *event = [[MPEvent alloc] initWithName:@"testScreenName" type:MPEventTypeOther];
    event.customAttributes = @{@"testScreenAttribute":@"value"};
    MPKitExecStatus *execStatus = [exampleKit logScreen:event];

    XCTAssertTrue(execStatus.success);

    NSMutableDictionary<NSString *, id> *screenParameters = [exampleKit getParametersForScreen:event];

    // Even though we only pass one custom attribute, the parameters should include the standardized screen name, so the total expected count is two
    XCTAssertEqual(screenParameters.count, 2);

    NSString *standardizedScreenName = [exampleKit standardizeNameOrKey:event.name forEvent:YES];
    NSString *screenNameParameter = screenParameters[kFIRParameterScreenName];

    // Test screen name parameter is not Nil and exists in the screen parameters dictionary
    XCTAssertNotNil(screenNameParameter);
    // Test screen name parameter value is correct
    XCTAssertEqualObjects(screenNameParameter, standardizedScreenName);
}

@end

#import <XCTest/XCTest.h>
@import RoktContracts;

/// Tests to verify RoktContracts event types are accessible from Objective-C
/// via the mParticle SDK's dependency on RoktContracts.
@interface RoktEventContractsObjCTests : XCTestCase
@end

@implementation RoktEventContractsObjCTests

#pragma mark - RoktInitComplete Tests

- (void)testInitCompleteWithSuccessTrue {
    RoktInitComplete *event = [[RoktInitComplete alloc] initWithSuccess:YES];
    XCTAssertNotNil(event);
    XCTAssertTrue(event.success);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

- (void)testInitCompleteWithSuccessFalse {
    RoktInitComplete *event = [[RoktInitComplete alloc] initWithSuccess:NO];
    XCTAssertNotNil(event);
    XCTAssertFalse(event.success);
}

#pragma mark - Loading Indicator Tests

- (void)testShowLoadingIndicator {
    RoktShowLoadingIndicator *event = [[RoktShowLoadingIndicator alloc] init];
    XCTAssertNotNil(event);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

- (void)testHideLoadingIndicator {
    RoktHideLoadingIndicator *event = [[RoktHideLoadingIndicator alloc] init];
    XCTAssertNotNil(event);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - Placement Lifecycle Tests

- (void)testPlacementReady {
    RoktPlacementReady *event = [[RoktPlacementReady alloc] initWithIdentifier:@"test-placement"];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, @"test-placement");
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

- (void)testPlacementInteractive {
    RoktPlacementInteractive *event = [[RoktPlacementInteractive alloc] initWithIdentifier:@"test-placement"];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, @"test-placement");
}

- (void)testPlacementClosed {
    RoktPlacementClosed *event = [[RoktPlacementClosed alloc] initWithIdentifier:@"test-placement"];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, @"test-placement");
}

- (void)testPlacementCompleted {
    RoktPlacementCompleted *event = [[RoktPlacementCompleted alloc] initWithIdentifier:@"test-placement"];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, @"test-placement");
}

- (void)testPlacementFailure {
    RoktPlacementFailure *event = [[RoktPlacementFailure alloc] initWithIdentifier:nil];
    XCTAssertNotNil(event);
    XCTAssertNil(event.identifier);
}

#pragma mark - Engagement Tests

- (void)testOfferEngagement {
    RoktOfferEngagement *event = [[RoktOfferEngagement alloc] initWithIdentifier:@"test"];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, @"test");
}

- (void)testPositiveEngagement {
    RoktPositiveEngagement *event = [[RoktPositiveEngagement alloc] initWithIdentifier:@"test"];
    XCTAssertNotNil(event);
}

- (void)testFirstPositiveEngagement {
    RoktFirstPositiveEngagement *event = [[RoktFirstPositiveEngagement alloc] initWithIdentifier:@"test" setFulfillmentAttributes:nil];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, @"test");
}

- (void)testOpenUrl {
    RoktOpenUrl *event = [[RoktOpenUrl alloc] initWithIdentifier:@"test" url:@"https://example.com"];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.url, @"https://example.com");
}

#pragma mark - Embedded Size Changed Tests

- (void)testEmbeddedSizeChanged {
    RoktEmbeddedSizeChanged *event = [[RoktEmbeddedSizeChanged alloc] initWithIdentifier:@"embed" updatedHeight:250.5];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, @"embed");
    XCTAssertEqualWithAccuracy(event.updatedHeight, 250.5, 0.001);
}

#pragma mark - Shoppable Ads Events Tests

- (void)testCartItemInstantPurchase {
    RoktCartItemInstantPurchase *event = [[RoktCartItemInstantPurchase alloc]
        initWithIdentifier:@"placement1"
                      name:@"Test Item"
                cartItemId:@"v1:abc:canal"
             catalogItemId:@"cat-123"
                  currency:@"USD"
               description:@"A test item"
           linkedProductId:nil
              providerData:@"{}"
                  quantity:[[NSDecimalNumber alloc] initWithInt:1]
                totalPrice:[[NSDecimalNumber alloc] initWithDouble:49.99]
                 unitPrice:[[NSDecimalNumber alloc] initWithDouble:49.99]];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.cartItemId, @"v1:abc:canal");
    XCTAssertEqualObjects(event.catalogItemId, @"cat-123");
    XCTAssertEqualObjects(event.currency, @"USD");
}

- (void)testCartItemInstantPurchaseInitiated {
    RoktCartItemInstantPurchaseInitiated *event = [[RoktCartItemInstantPurchaseInitiated alloc]
        initWithIdentifier:@"placement1"
             catalogItemId:@"cat-123"
                cartItemId:@"v1:abc:canal"];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.catalogItemId, @"cat-123");
}

- (void)testCartItemInstantPurchaseFailure {
    RoktCartItemInstantPurchaseFailure *event = [[RoktCartItemInstantPurchaseFailure alloc]
        initWithIdentifier:@"placement1"
             catalogItemId:@"cat-123"
                cartItemId:@"v1:abc:canal"
                     error:@"Payment declined"];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.error, @"Payment declined");
}

- (void)testCartItemDevicePay {
    RoktCartItemDevicePay *event = [[RoktCartItemDevicePay alloc]
        initWithIdentifier:@"placement1"
             catalogItemId:@"cat-123"
                cartItemId:@"v1:abc:canal"
           paymentProvider:@"stripe"];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.paymentProvider, @"stripe");
}

#pragma mark - Config Tests

- (void)testRoktConfigBuilder {
    RoktConfig *config = [[[[RoktConfigBuilder alloc] init] colorMode:RoktColorModeDark] build];
    XCTAssertNotNil(config);
    XCTAssertEqual(config.colorMode, RoktColorModeDark);
}

- (void)testRoktConfigBuilderWithCache {
    RoktCacheConfig *cacheConfig = [[RoktCacheConfig alloc] initWithCacheDuration:3600 cacheAttributes:@{@"key": @"value"}];
    RoktConfig *config = [[[[[RoktConfigBuilder alloc] init] colorMode:RoktColorModeLight] cacheConfig:cacheConfig] build];
    XCTAssertNotNil(config);
    XCTAssertEqual(config.colorMode, RoktColorModeLight);
    XCTAssertTrue([config.cacheConfig isCacheEnabled]);
}

#pragma mark - Embedded View Tests

- (void)testRoktEmbeddedView {
    RoktEmbeddedView *view = [[RoktEmbeddedView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
    XCTAssertNotNil(view);
    XCTAssertTrue([view isKindOfClass:[UIView class]]);
}

#pragma mark - Placement Options Tests

- (void)testRoktPlacementOptions {
    RoktPlacementOptions *options = [[RoktPlacementOptions alloc] initWithTimestamp:1234567890];
    XCTAssertEqual(options.jointSdkSelectPlacements, 1234567890);
}

@end

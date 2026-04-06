#import <XCTest/XCTest.h>
@import RoktContracts;

@interface MPRoktEventTests : XCTestCase
@end

@implementation MPRoktEventTests

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

#pragma mark - RoktShowLoadingIndicator Tests

- (void)testShowLoadingIndicator {
    RoktShowLoadingIndicator *event = [[RoktShowLoadingIndicator alloc] init];
    XCTAssertNotNil(event);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - RoktHideLoadingIndicator Tests

- (void)testHideLoadingIndicator {
    RoktHideLoadingIndicator *event = [[RoktHideLoadingIndicator alloc] init];
    XCTAssertNotNil(event);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - RoktPlacementInteractive Tests

- (void)testPlacementInteractiveWithPlacementId {
    NSString *identifier = @"test-placement-123";
    RoktPlacementInteractive *event = [[RoktPlacementInteractive alloc] initWithIdentifier:identifier];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, identifier);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

- (void)testPlacementInteractiveWithNilPlacementId {
    RoktPlacementInteractive *event = [[RoktPlacementInteractive alloc] initWithIdentifier:nil];
    XCTAssertNotNil(event);
    XCTAssertNil(event.identifier);
}

#pragma mark - RoktPlacementReady Tests

- (void)testPlacementReadyWithPlacementId {
    NSString *identifier = @"ready-placement-456";
    RoktPlacementReady *event = [[RoktPlacementReady alloc] initWithIdentifier:identifier];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, identifier);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

- (void)testPlacementReadyWithNilPlacementId {
    RoktPlacementReady *event = [[RoktPlacementReady alloc] initWithIdentifier:nil];
    XCTAssertNotNil(event);
    XCTAssertNil(event.identifier);
}

#pragma mark - RoktOfferEngagement Tests

- (void)testOfferEngagementWithPlacementId {
    NSString *identifier = @"offer-placement-789";
    RoktOfferEngagement *event = [[RoktOfferEngagement alloc] initWithIdentifier:identifier];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, identifier);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - RoktOpenUrl Tests

- (void)testOpenUrlWithPlacementIdAndUrl {
    NSString *identifier = @"url-placement";
    NSString *url = @"https://example.com/offer";
    RoktOpenUrl *event = [[RoktOpenUrl alloc] initWithIdentifier:identifier url:url];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, identifier);
    XCTAssertEqualObjects(event.url, url);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

- (void)testOpenUrlWithNilPlacementId {
    NSString *url = @"https://example.com/offer";
    RoktOpenUrl *event = [[RoktOpenUrl alloc] initWithIdentifier:nil url:url];
    XCTAssertNotNil(event);
    XCTAssertNil(event.identifier);
    XCTAssertEqualObjects(event.url, url);
}

#pragma mark - RoktPositiveEngagement Tests

- (void)testPositiveEngagementWithPlacementId {
    NSString *identifier = @"positive-placement";
    RoktPositiveEngagement *event = [[RoktPositiveEngagement alloc] initWithIdentifier:identifier];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, identifier);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - RoktPlacementClosed Tests

- (void)testPlacementClosedWithPlacementId {
    NSString *identifier = @"closed-placement";
    RoktPlacementClosed *event = [[RoktPlacementClosed alloc] initWithIdentifier:identifier];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, identifier);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - RoktPlacementCompleted Tests

- (void)testPlacementCompletedWithPlacementId {
    NSString *identifier = @"completed-placement";
    RoktPlacementCompleted *event = [[RoktPlacementCompleted alloc] initWithIdentifier:identifier];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, identifier);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - RoktPlacementFailure Tests

- (void)testPlacementFailureWithPlacementId {
    NSString *identifier = @"failed-placement";
    RoktPlacementFailure *event = [[RoktPlacementFailure alloc] initWithIdentifier:identifier];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, identifier);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - RoktFirstPositiveEngagement Tests

- (void)testFirstPositiveEngagementWithPlacementId {
    NSString *identifier = @"first-positive-placement";
    RoktFirstPositiveEngagement *event = [[RoktFirstPositiveEngagement alloc] initWithIdentifier:identifier
                                                                          setFulfillmentAttributes:nil];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, identifier);
    XCTAssertNil(event.setFulfillmentAttributes);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

- (void)testFirstPositiveEngagementFulfillmentCallbackReceivesAttributes {
    NSString *identifier = @"first-positive-placement";
    __block NSDictionary<NSString *, NSString *> *receivedAttributes = nil;

    RoktFirstPositiveEngagement *event = [[RoktFirstPositiveEngagement alloc] initWithIdentifier:identifier
                                                                          setFulfillmentAttributes:^(NSDictionary<NSString *, NSString *> * _Nonnull attributes) {
        receivedAttributes = attributes;
    }];

    XCTAssertEqualObjects(event.identifier, identifier);
    XCTAssertNotNil(event.setFulfillmentAttributes);

    NSDictionary<NSString *, NSString *> *expected = @{@"key": @"value", @"other": @"42"};
    event.setFulfillmentAttributes(expected);

    XCTAssertEqualObjects(receivedAttributes, expected);
}

- (void)testFirstPositiveEngagementFulfillmentCallbackCanBeInvokedMultipleTimes {
    __block NSUInteger invocationCount = 0;

    RoktFirstPositiveEngagement *event = [[RoktFirstPositiveEngagement alloc] initWithIdentifier:@"p1"
                                                                          setFulfillmentAttributes:^(NSDictionary<NSString *, NSString *> * _Nonnull attributes) {
        invocationCount++;
        XCTAssertEqualObjects(attributes[@"k"], @"v");
    }];

    event.setFulfillmentAttributes(@{@"k": @"v"});
    event.setFulfillmentAttributes(@{@"k": @"v"});

    XCTAssertEqual(invocationCount, 2U);
}

#pragma mark - RoktCartItemInstantPurchase Tests

- (void)testCartItemInstantPurchaseWithAllParameters {
    NSString *identifier = @"cart-placement";
    NSString *name = @"Test Product";
    NSString *cartItemId = @"cart-123";
    NSString *catalogItemId = @"catalog-456";
    NSString *currency = @"USD";
    NSString *description = @"A test product description";
    NSString *linkedProductId = @"linked-789";
    NSString *providerData = @"provider-data";
    NSDecimalNumber *quantity = [NSDecimalNumber decimalNumberWithString:@"2"];
    NSDecimalNumber *totalPrice = [NSDecimalNumber decimalNumberWithString:@"19.99"];
    NSDecimalNumber *unitPrice = [NSDecimalNumber decimalNumberWithString:@"9.995"];
    
    RoktCartItemInstantPurchase *event = [[RoktCartItemInstantPurchase alloc]
                                            initWithIdentifier:identifier
                                            name:name
                                            cartItemId:cartItemId
                                            catalogItemId:catalogItemId
                                            currency:currency
                                            description:description
                                            linkedProductId:linkedProductId
                                            providerData:providerData
                                            quantity:quantity
                                            totalPrice:totalPrice
                                            unitPrice:unitPrice];
    
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, identifier);
    XCTAssertEqualObjects(event.name, name);
    XCTAssertEqualObjects(event.cartItemId, cartItemId);
    XCTAssertEqualObjects(event.catalogItemId, catalogItemId);
    XCTAssertEqualObjects(event.currency, currency);
    XCTAssertEqualObjects(event.description, description);
    XCTAssertEqualObjects(event.linkedProductId, linkedProductId);
    XCTAssertEqualObjects(event.providerData, providerData);
    XCTAssertEqualObjects(event.quantity, quantity);
    XCTAssertEqualObjects(event.totalPrice, totalPrice);
    XCTAssertEqualObjects(event.unitPrice, unitPrice);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

- (void)testCartItemInstantPurchaseWithNilOptionalParameters {
    NSString *identifier = @"cart-placement";
    NSString *cartItemId = @"cart-123";
    NSString *catalogItemId = @"catalog-456";
    NSString *currency = @"USD";
    NSString *description = @"A test product";
    NSString *providerData = @"provider-data";
    
    RoktCartItemInstantPurchase *event = [[RoktCartItemInstantPurchase alloc]
                                            initWithIdentifier:identifier
                                            name:nil
                                            cartItemId:cartItemId
                                            catalogItemId:catalogItemId
                                            currency:currency
                                            description:description
                                            linkedProductId:nil
                                            providerData:providerData
                                            quantity:nil
                                            totalPrice:nil
                                            unitPrice:nil];
    
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, identifier);
    XCTAssertNil(event.name);
    XCTAssertEqualObjects(event.cartItemId, cartItemId);
    XCTAssertEqualObjects(event.catalogItemId, catalogItemId);
    XCTAssertEqualObjects(event.currency, currency);
    XCTAssertEqualObjects(event.description, description);
    XCTAssertNil(event.linkedProductId);
    XCTAssertEqualObjects(event.providerData, providerData);
    XCTAssertNil(event.quantity);
    XCTAssertNil(event.totalPrice);
    XCTAssertNil(event.unitPrice);
}

- (void)testCartItemInstantPurchaseDescriptionOverride {
    NSString *customDescription = @"Custom description text";
    
    RoktCartItemInstantPurchase *event = [[RoktCartItemInstantPurchase alloc]
                                            initWithIdentifier:@"placement"
                                            name:nil
                                            cartItemId:@"cart"
                                            catalogItemId:@"catalog"
                                            currency:@"USD"
                                            description:customDescription
                                            linkedProductId:nil
                                            providerData:@"data"
                                            quantity:nil
                                            totalPrice:nil
                                            unitPrice:nil];
    
    // Verify the description property returns the custom description
    XCTAssertEqualObjects(event.description, customDescription);
}

#pragma mark - RoktEmbeddedSizeChanged Tests

- (void)testEmbeddedSizeChangedWithIdentifierAndHeight {
    NSString *identifier = @"Location1";
    CGFloat height = 250.5;
    RoktEmbeddedSizeChanged *event = [[RoktEmbeddedSizeChanged alloc] initWithIdentifier:identifier updatedHeight:height];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, identifier);
    XCTAssertEqual(event.updatedHeight, height);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

- (void)testEmbeddedSizeChangedZeroHeight {
    RoktEmbeddedSizeChanged *event = [[RoktEmbeddedSizeChanged alloc] initWithIdentifier:@"embed" updatedHeight:0];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.identifier, @"embed");
    XCTAssertEqual(event.updatedHeight, (CGFloat)0);
}

#pragma mark - Inheritance Tests

- (void)testAllEventTypesInheritFromRoktEvent {
    // Test that all event types inherit from RoktEvent (RoktContracts)
    XCTAssertTrue([[[RoktInitComplete alloc] initWithSuccess:YES] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktShowLoadingIndicator alloc] init] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktHideLoadingIndicator alloc] init] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktPlacementInteractive alloc] initWithIdentifier:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktPlacementReady alloc] initWithIdentifier:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktOfferEngagement alloc] initWithIdentifier:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktOpenUrl alloc] initWithIdentifier:@"test" url:@"url"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktPositiveEngagement alloc] initWithIdentifier:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktPlacementClosed alloc] initWithIdentifier:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktPlacementCompleted alloc] initWithIdentifier:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktPlacementFailure alloc] initWithIdentifier:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktFirstPositiveEngagement alloc] initWithIdentifier:@"test" setFulfillmentAttributes:nil] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktEmbeddedSizeChanged alloc] initWithIdentifier:@"Location1" updatedHeight:320] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktCartItemInstantPurchase alloc] initWithIdentifier:@"p" name:nil cartItemId:@"c" catalogItemId:@"cat" currency:@"USD" description:@"d" linkedProductId:nil providerData:@"prov" quantity:nil totalPrice:nil unitPrice:nil] isKindOfClass:[RoktEvent class]]);
}

@end

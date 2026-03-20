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
    NSString *placementId = @"test-placement-123";
    RoktPlacementInteractive *event = [[RoktPlacementInteractive alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

- (void)testPlacementInteractiveWithNilPlacementId {
    RoktPlacementInteractive *event = [[RoktPlacementInteractive alloc] initWithPlacementId:nil];
    XCTAssertNotNil(event);
    XCTAssertNil(event.placementId);
}

#pragma mark - RoktPlacementReady Tests

- (void)testPlacementReadyWithPlacementId {
    NSString *placementId = @"ready-placement-456";
    RoktPlacementReady *event = [[RoktPlacementReady alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

- (void)testPlacementReadyWithNilPlacementId {
    RoktPlacementReady *event = [[RoktPlacementReady alloc] initWithPlacementId:nil];
    XCTAssertNotNil(event);
    XCTAssertNil(event.placementId);
}

#pragma mark - RoktOfferEngagement Tests

- (void)testOfferEngagementWithPlacementId {
    NSString *placementId = @"offer-placement-789";
    RoktOfferEngagement *event = [[RoktOfferEngagement alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - RoktOpenUrl Tests

- (void)testOpenUrlWithPlacementIdAndUrl {
    NSString *placementId = @"url-placement";
    NSString *url = @"https://example.com/offer";
    RoktOpenUrl *event = [[RoktOpenUrl alloc] initWithPlacementId:placementId url:url];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertEqualObjects(event.url, url);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

- (void)testOpenUrlWithNilPlacementId {
    NSString *url = @"https://example.com/offer";
    RoktOpenUrl *event = [[RoktOpenUrl alloc] initWithPlacementId:nil url:url];
    XCTAssertNotNil(event);
    XCTAssertNil(event.placementId);
    XCTAssertEqualObjects(event.url, url);
}

#pragma mark - RoktPositiveEngagement Tests

- (void)testPositiveEngagementWithPlacementId {
    NSString *placementId = @"positive-placement";
    RoktPositiveEngagement *event = [[RoktPositiveEngagement alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - RoktPlacementClosed Tests

- (void)testPlacementClosedWithPlacementId {
    NSString *placementId = @"closed-placement";
    RoktPlacementClosed *event = [[RoktPlacementClosed alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - RoktPlacementCompleted Tests

- (void)testPlacementCompletedWithPlacementId {
    NSString *placementId = @"completed-placement";
    RoktPlacementCompleted *event = [[RoktPlacementCompleted alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - RoktPlacementFailure Tests

- (void)testPlacementFailureWithPlacementId {
    NSString *placementId = @"failed-placement";
    RoktPlacementFailure *event = [[RoktPlacementFailure alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - RoktFirstPositiveEngagement Tests

- (void)testFirstPositiveEngagementWithPlacementId {
    NSString *placementId = @"first-positive-placement";
    RoktFirstPositiveEngagement *event = [[RoktFirstPositiveEngagement alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[RoktEvent class]]);
}

#pragma mark - RoktCartItemInstantPurchase Tests

- (void)testCartItemInstantPurchaseWithAllParameters {
    NSString *placementId = @"cart-placement";
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
                                            initWithPlacementId:placementId
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
    XCTAssertEqualObjects(event.placementId, placementId);
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
    NSString *placementId = @"cart-placement";
    NSString *cartItemId = @"cart-123";
    NSString *catalogItemId = @"catalog-456";
    NSString *currency = @"USD";
    NSString *description = @"A test product";
    NSString *providerData = @"provider-data";
    
    RoktCartItemInstantPurchase *event = [[RoktCartItemInstantPurchase alloc]
                                            initWithPlacementId:placementId
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
    XCTAssertEqualObjects(event.placementId, placementId);
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
                                            initWithPlacementId:@"placement"
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

#pragma mark - Inheritance Tests

- (void)testAllEventTypesInheritFromRoktEvent {
    // Test that all event types inherit from RoktEvent (RoktContracts)
    XCTAssertTrue([[[RoktInitComplete alloc] initWithSuccess:YES] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktShowLoadingIndicator alloc] init] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktHideLoadingIndicator alloc] init] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktPlacementInteractive alloc] initWithPlacementId:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktPlacementReady alloc] initWithPlacementId:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktOfferEngagement alloc] initWithPlacementId:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktOpenUrl alloc] initWithPlacementId:@"test" url:@"url"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktPositiveEngagement alloc] initWithPlacementId:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktPlacementClosed alloc] initWithPlacementId:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktPlacementCompleted alloc] initWithPlacementId:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktPlacementFailure alloc] initWithPlacementId:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktFirstPositiveEngagement alloc] initWithPlacementId:@"test"] isKindOfClass:[RoktEvent class]]);
    XCTAssertTrue([[[RoktCartItemInstantPurchase alloc] initWithPlacementId:@"p" name:nil cartItemId:@"c" catalogItemId:@"cat" currency:@"USD" description:@"d" linkedProductId:nil providerData:@"prov" quantity:nil totalPrice:nil unitPrice:nil] isKindOfClass:[RoktEvent class]]);
}

@end

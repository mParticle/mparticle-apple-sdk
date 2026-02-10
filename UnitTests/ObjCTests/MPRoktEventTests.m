#import <XCTest/XCTest.h>
#import "MPRoktEvent.h"

@interface MPRoktEventTests : XCTestCase
@end

@implementation MPRoktEventTests

#pragma mark - MPRoktInitComplete Tests

- (void)testInitCompleteWithSuccessTrue {
    MPRoktInitComplete *event = [[MPRoktInitComplete alloc] initWithSuccess:YES];
    XCTAssertNotNil(event);
    XCTAssertTrue(event.success);
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

- (void)testInitCompleteWithSuccessFalse {
    MPRoktInitComplete *event = [[MPRoktInitComplete alloc] initWithSuccess:NO];
    XCTAssertNotNil(event);
    XCTAssertFalse(event.success);
}

#pragma mark - MPRoktShowLoadingIndicator Tests

- (void)testShowLoadingIndicator {
    MPRoktShowLoadingIndicator *event = [[MPRoktShowLoadingIndicator alloc] init];
    XCTAssertNotNil(event);
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

#pragma mark - MPRoktHideLoadingIndicator Tests

- (void)testHideLoadingIndicator {
    MPRoktHideLoadingIndicator *event = [[MPRoktHideLoadingIndicator alloc] init];
    XCTAssertNotNil(event);
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

#pragma mark - MPRoktPlacementInteractive Tests

- (void)testPlacementInteractiveWithPlacementId {
    NSString *placementId = @"test-placement-123";
    MPRoktPlacementInteractive *event = [[MPRoktPlacementInteractive alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

- (void)testPlacementInteractiveWithNilPlacementId {
    MPRoktPlacementInteractive *event = [[MPRoktPlacementInteractive alloc] initWithPlacementId:nil];
    XCTAssertNotNil(event);
    XCTAssertNil(event.placementId);
}

#pragma mark - MPRoktPlacementReady Tests

- (void)testPlacementReadyWithPlacementId {
    NSString *placementId = @"ready-placement-456";
    MPRoktPlacementReady *event = [[MPRoktPlacementReady alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

- (void)testPlacementReadyWithNilPlacementId {
    MPRoktPlacementReady *event = [[MPRoktPlacementReady alloc] initWithPlacementId:nil];
    XCTAssertNotNil(event);
    XCTAssertNil(event.placementId);
}

#pragma mark - MPRoktOfferEngagement Tests

- (void)testOfferEngagementWithPlacementId {
    NSString *placementId = @"offer-placement-789";
    MPRoktOfferEngagement *event = [[MPRoktOfferEngagement alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

#pragma mark - MPRoktOpenUrl Tests

- (void)testOpenUrlWithPlacementIdAndUrl {
    NSString *placementId = @"url-placement";
    NSString *url = @"https://example.com/offer";
    MPRoktOpenUrl *event = [[MPRoktOpenUrl alloc] initWithPlacementId:placementId url:url];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertEqualObjects(event.url, url);
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

- (void)testOpenUrlWithNilPlacementId {
    NSString *url = @"https://example.com/offer";
    MPRoktOpenUrl *event = [[MPRoktOpenUrl alloc] initWithPlacementId:nil url:url];
    XCTAssertNotNil(event);
    XCTAssertNil(event.placementId);
    XCTAssertEqualObjects(event.url, url);
}

#pragma mark - MPRoktPositiveEngagement Tests

- (void)testPositiveEngagementWithPlacementId {
    NSString *placementId = @"positive-placement";
    MPRoktPositiveEngagement *event = [[MPRoktPositiveEngagement alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

#pragma mark - MPRoktPlacementClosed Tests

- (void)testPlacementClosedWithPlacementId {
    NSString *placementId = @"closed-placement";
    MPRoktPlacementClosed *event = [[MPRoktPlacementClosed alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

#pragma mark - MPRoktPlacementCompleted Tests

- (void)testPlacementCompletedWithPlacementId {
    NSString *placementId = @"completed-placement";
    MPRoktPlacementCompleted *event = [[MPRoktPlacementCompleted alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

#pragma mark - MPRoktPlacementFailure Tests

- (void)testPlacementFailureWithPlacementId {
    NSString *placementId = @"failed-placement";
    MPRoktPlacementFailure *event = [[MPRoktPlacementFailure alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

#pragma mark - MPRoktFirstPositiveEngagement Tests

- (void)testFirstPositiveEngagementWithPlacementId {
    NSString *placementId = @"first-positive-placement";
    MPRoktFirstPositiveEngagement *event = [[MPRoktFirstPositiveEngagement alloc] initWithPlacementId:placementId];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

#pragma mark - MPRoktCartItemInstantPurchase Tests

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
    
    MPRoktCartItemInstantPurchase *event = [[MPRoktCartItemInstantPurchase alloc]
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
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

- (void)testCartItemInstantPurchaseWithNilOptionalParameters {
    NSString *placementId = @"cart-placement";
    NSString *cartItemId = @"cart-123";
    NSString *catalogItemId = @"catalog-456";
    NSString *currency = @"USD";
    NSString *description = @"A test product";
    NSString *providerData = @"provider-data";
    
    MPRoktCartItemInstantPurchase *event = [[MPRoktCartItemInstantPurchase alloc]
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
    
    MPRoktCartItemInstantPurchase *event = [[MPRoktCartItemInstantPurchase alloc]
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

#pragma mark - MPRoktEmbeddedSizeChanged Tests

- (void)testEmbeddedSizeChangedWithPlacementIdAndHeight {
    NSString *placementId = @"embed-placement-123";
    CGFloat updatedHeight = 250.5;
    MPRoktEmbeddedSizeChanged *event = [[MPRoktEmbeddedSizeChanged alloc] initWithPlacementId:placementId updatedHeight:updatedHeight];
    XCTAssertNotNil(event);
    XCTAssertEqualObjects(event.placementId, placementId);
    XCTAssertEqualWithAccuracy(event.updatedHeight, updatedHeight, 0.001);
    XCTAssertTrue([event isKindOfClass:[MPRoktEvent class]]);
}

- (void)testEmbeddedSizeChangedWithZeroHeight {
    MPRoktEmbeddedSizeChanged *event = [[MPRoktEmbeddedSizeChanged alloc] initWithPlacementId:@"placement" updatedHeight:0];
    XCTAssertNotNil(event);
    XCTAssertEqualWithAccuracy(event.updatedHeight, 0, 0.001);
}

#pragma mark - Inheritance Tests

- (void)testAllEventTypesInheritFromMPRoktEvent {
    // Test that all event types inherit from MPRoktEvent
    XCTAssertTrue([[[MPRoktInitComplete alloc] initWithSuccess:YES] isKindOfClass:[MPRoktEvent class]]);
    XCTAssertTrue([[[MPRoktShowLoadingIndicator alloc] init] isKindOfClass:[MPRoktEvent class]]);
    XCTAssertTrue([[[MPRoktHideLoadingIndicator alloc] init] isKindOfClass:[MPRoktEvent class]]);
    XCTAssertTrue([[[MPRoktPlacementInteractive alloc] initWithPlacementId:@"test"] isKindOfClass:[MPRoktEvent class]]);
    XCTAssertTrue([[[MPRoktPlacementReady alloc] initWithPlacementId:@"test"] isKindOfClass:[MPRoktEvent class]]);
    XCTAssertTrue([[[MPRoktOfferEngagement alloc] initWithPlacementId:@"test"] isKindOfClass:[MPRoktEvent class]]);
    XCTAssertTrue([[[MPRoktOpenUrl alloc] initWithPlacementId:@"test" url:@"url"] isKindOfClass:[MPRoktEvent class]]);
    XCTAssertTrue([[[MPRoktPositiveEngagement alloc] initWithPlacementId:@"test"] isKindOfClass:[MPRoktEvent class]]);
    XCTAssertTrue([[[MPRoktPlacementClosed alloc] initWithPlacementId:@"test"] isKindOfClass:[MPRoktEvent class]]);
    XCTAssertTrue([[[MPRoktPlacementCompleted alloc] initWithPlacementId:@"test"] isKindOfClass:[MPRoktEvent class]]);
    XCTAssertTrue([[[MPRoktPlacementFailure alloc] initWithPlacementId:@"test"] isKindOfClass:[MPRoktEvent class]]);
    XCTAssertTrue([[[MPRoktFirstPositiveEngagement alloc] initWithPlacementId:@"test"] isKindOfClass:[MPRoktEvent class]]);
    XCTAssertTrue([[[MPRoktCartItemInstantPurchase alloc] initWithPlacementId:@"p" name:nil cartItemId:@"c" catalogItemId:@"cat" currency:@"USD" description:@"d" linkedProductId:nil providerData:@"prov" quantity:nil totalPrice:nil unitPrice:nil] isKindOfClass:[MPRoktEvent class]]);
    XCTAssertTrue([[[MPRoktEmbeddedSizeChanged alloc] initWithPlacementId:@"p" updatedHeight:100] isKindOfClass:[MPRoktEvent class]]);
}

@end

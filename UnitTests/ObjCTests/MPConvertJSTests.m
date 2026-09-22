#import <XCTest/XCTest.h>
#import "MPConvertJS.h"
#import "mParticle.h"
#import "MPBaseTestCase.h"
#import "MPPromotion.h"
#import "MPPromotion+Dictionary.h"
#import "MPTransactionAttributes+Dictionary.h"

@interface MPConvertJSTests : MPBaseTestCase

@end

@implementation MPConvertJSTests

- (void)testConvertTransaction {
    NSDictionary *json = @{
                           @"Affiliation":@"Test affiliation",
                           @"CouponCode":@"Test coupon code",
                           @"ShippingAmount":@20.00,
                           @"TaxAmount":@30.00,
                           @"TotalAmount":@450.00,
                           @"TransactionId":@"Test transaction id"
                           };
    
    MPTransactionAttributes *transactionAttributes = nil;
    transactionAttributes = [MPConvertJS_PRIVATE transactionAttributes:json];
    XCTAssertNotNil(transactionAttributes);
    XCTAssertEqualObjects(transactionAttributes.affiliation, @"Test affiliation");
    XCTAssertEqualObjects(transactionAttributes.couponCode, @"Test coupon code");
    XCTAssertEqualObjects(transactionAttributes.shipping, @20.00);
    XCTAssertEqualObjects(transactionAttributes.tax, @30.00);
    XCTAssertEqualObjects(transactionAttributes.revenue, @450.00);
    XCTAssertEqualObjects(transactionAttributes.transactionId, @"Test transaction id");
}

- (void)testConvertTransactionWithNoValidFieldsLeavesAttributesNil {
    // Every field either absent or a non-string/non-number, so nothing should
    // ever touch MPTransactionAttributes's lazy attributes dictionary.
    NSDictionary *json = @{
                           @"ShippingAmount":[NSNull null],
                           @"TaxAmount":[NSNull null]
                           };

    MPTransactionAttributes *transactionAttributes = [MPConvertJS_PRIVATE transactionAttributes:json];
    XCTAssertNotNil(transactionAttributes);
    XCTAssertNil([transactionAttributes dictionaryRepresentation],
                 @"A transaction with no valid fields must serialize to nil, not an empty dictionary.");
}

- (void)testConvertPromotionWithNoValidFieldsLeavesAttributesNil {
    // Regression test for the case Brandon's review on #929 flagged: an
    // unconditional setter call still allocates MPPromotion's lazy attributes
    // dictionary even when the value being assigned is nil, turning "no valid
    // fields" into an empty (non-nil) dictionaryRepresentation that
    // MPPromotionContainer no longer skips.
    NSDictionary *json = @{
                           @"Creative":[NSNull null],
                           @"Name":[NSNull null]
                           };

    MPPromotion *promotion = [MPConvertJS_PRIVATE promotion:json];
    XCTAssertNotNil(promotion);
    XCTAssertNil([promotion dictionaryRepresentation],
                 @"A promotion with no valid fields must serialize to nil, not an empty dictionary — "
                 @"otherwise MPPromotionContainer stops skipping it and ships an empty promotion.");
}

- (void)testConvertMPCommerceEventProductAction {
    NSDictionary *customFlags = @{
        @"customFlag1": @"flag1value",
        @"customFlag2": @"flag2Value"
    };
    NSDictionary *customFlagsFinal = @{
        @"customFlag1": @[@"flag1value"],
        @"customFlag2": @[@"flag2Value"]
    };
    NSDictionary *json = @{
        @"CheckoutOptions":@"Test checkout option",
        @"productActionListName":@"Test action list name",
        @"productActionListSource":@"Test action list source",
        @"CurrencyCode":@"Test currency code",
        @"CustomFlags":customFlags,
        @"ProductAction":@{
                @"ProductActionType":@(MPJSCommerceEventActionAddToCart),
                @"Affiliation":@"Test affiliation",
                @"CouponCode":@"Test coupon code",
                @"ShippingAmount":@20.00,
                @"TaxAmount":@30.00,
                @"TotalAmount":@450.00,
                @"TransactionId":@"Test transaction id",
                @"ProductList": @[]
        },
        @"CheckoutStep": @2
    };
    
    MPCommerceEvent *commerceEvent = nil;
    commerceEvent = [MPConvertJS_PRIVATE commerceEvent:json];
    XCTAssertNotNil(commerceEvent);
    XCTAssertEqual(commerceEvent.action, MPCommerceEventActionAddToCart);
    XCTAssertEqualObjects(commerceEvent.checkoutOptions, @"Test checkout option");
    XCTAssertEqualObjects(commerceEvent.productListName, @"Test action list name");
    XCTAssertEqualObjects(commerceEvent.productListSource, @"Test action list source");
    XCTAssertEqualObjects(commerceEvent.currency, @"Test currency code");
    XCTAssertEqualObjects(commerceEvent.customFlags, customFlagsFinal);
    XCTAssertEqual(commerceEvent.checkoutStep, 2);

    XCTAssertNotNil(commerceEvent.transactionAttributes);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.affiliation, @"Test affiliation");
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.couponCode, @"Test coupon code");
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.shipping, @20.00);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.tax, @30.00);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.revenue, @450.00);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.transactionId, @"Test transaction id");
}

- (void)testConvertMPCommerceEventProductActionWithArrayCustomFlags {
    NSDictionary *customFlags = @{
        @"customFlag1": @[@"flag1value", @"flagAValue"],
        @"customFlag2": @[@"flag2Value", @"flagBValue"]
    };
    NSDictionary *json = @{
        @"CheckoutOptions":@"Test checkout option",
        @"productActionListName":@"Test action list name",
        @"productActionListSource":@"Test action list source",
        @"CurrencyCode":@"Test currency code",
        @"CustomFlags":customFlags,
        @"ProductAction":@{
                @"ProductActionType":@(MPJSCommerceEventActionAddToCart),
                @"Affiliation":@"Test affiliation",
                @"CouponCode":@"Test coupon code",
                @"ShippingAmount":@20.00,
                @"TaxAmount":@30.00,
                @"TotalAmount":@450.00,
                @"TransactionId":@"Test transaction id",
                @"ProductList": @[]
        },
        @"CheckoutStep": @2
    };
    
    MPCommerceEvent *commerceEvent = nil;
    commerceEvent = [MPConvertJS_PRIVATE commerceEvent:json];
    XCTAssertNotNil(commerceEvent);
    XCTAssertEqual(commerceEvent.action, MPCommerceEventActionAddToCart);
    XCTAssertEqualObjects(commerceEvent.checkoutOptions, @"Test checkout option");
    XCTAssertEqualObjects(commerceEvent.productListName, @"Test action list name");
    XCTAssertEqualObjects(commerceEvent.productListSource, @"Test action list source");
    XCTAssertEqualObjects(commerceEvent.currency, @"Test currency code");
    XCTAssertEqualObjects(commerceEvent.customFlags, customFlags);
    XCTAssertEqual(commerceEvent.checkoutStep, 2);

    XCTAssertNotNil(commerceEvent.transactionAttributes);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.affiliation, @"Test affiliation");
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.couponCode, @"Test coupon code");
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.shipping, @20.00);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.tax, @30.00);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.revenue, @450.00);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.transactionId, @"Test transaction id");
}

- (void)testConvertMPCommerceEventProductActionPurchase {
    NSDictionary *json = @{
        @"CheckoutOptions":@"Test checkout option",
        @"productActionListName":@"Test action list name",
        @"productActionListSource":@"Test action list source",
        @"CurrencyCode":@"Test currency code",
        @"ProductAction":@{
                @"ProductActionType":@(MPJSCommerceEventActionPurchase),
                @"Affiliation":@"Test affiliation",
                @"CouponCode":@"Test coupon code",
                @"ShippingAmount":@20.00,
                @"TaxAmount":@30.00,
                @"TotalAmount":@450.00,
                @"TransactionId":@"Test transaction id",
                @"ProductList": @[]
        },
        @"CheckoutStep": @2
    };
    
    MPCommerceEvent *commerceEvent = nil;
    commerceEvent = [MPConvertJS_PRIVATE commerceEvent:json];
    XCTAssertNotNil(commerceEvent);
    XCTAssertEqual(commerceEvent.action, MPCommerceEventActionPurchase);
    XCTAssertEqualObjects(commerceEvent.checkoutOptions, @"Test checkout option");
    XCTAssertEqualObjects(commerceEvent.productListName, @"Test action list name");
    XCTAssertEqualObjects(commerceEvent.productListSource, @"Test action list source");
    XCTAssertEqualObjects(commerceEvent.currency, @"Test currency code");
    XCTAssertEqual(commerceEvent.checkoutStep, 2);

    XCTAssertNotNil(commerceEvent.transactionAttributes);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.affiliation, @"Test affiliation");
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.couponCode, @"Test coupon code");
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.shipping, @20.00);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.tax, @30.00);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.revenue, @450.00);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.transactionId, @"Test transaction id");
}

- (void)testConvertMPCommerceEventProductActionWithNilProducts {
    NSDictionary *json = @{
        @"CheckoutOptions":@"Test checkout option",
        @"productActionListName":@"Test action list name",
        @"productActionListSource":@"Test action list source",
        @"CurrencyCode":@"Test currency code",
        @"ProductAction":@{
                @"ProductActionType":@0,
                @"Affiliation":@"Test affiliation",
                @"CouponCode":@"Test coupon code",
                @"ShippingAmount":@20.00,
                @"TaxAmount":@30.00,
                @"TotalAmount":@450.00,
                @"TransactionId":@"Test transaction id",
                @"ProductList": [NSNull null]
        },
        @"CheckoutStep": @2
    };
    
    MPCommerceEvent *commerceEvent = nil;
    commerceEvent = [MPConvertJS_PRIVATE commerceEvent:json];
    XCTAssertNotNil(commerceEvent);
    XCTAssertEqual(commerceEvent.action, MPCommerceEventActionAddToCart);
    XCTAssertEqualObjects(commerceEvent.checkoutOptions, @"Test checkout option");
    XCTAssertEqualObjects(commerceEvent.productListName, @"Test action list name");
    XCTAssertEqualObjects(commerceEvent.productListSource, @"Test action list source");
    XCTAssertEqualObjects(commerceEvent.currency, @"Test currency code");
    XCTAssertEqual(commerceEvent.checkoutStep, 2);

    XCTAssertNotNil(commerceEvent.transactionAttributes);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.affiliation, @"Test affiliation");
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.couponCode, @"Test coupon code");
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.shipping, @20.00);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.tax, @30.00);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.revenue, @450.00);
    XCTAssertEqualObjects(commerceEvent.transactionAttributes.transactionId, @"Test transaction id");
}

- (void)testConvertMPCommerceEventImpressionAction {
    NSDictionary *json = @{
        @"CheckoutOptions":@"Test checkout option",
        @"productActionListName":@"Test action list name",
        @"productActionListSource":@"Test action list source",
        @"CurrencyCode":@"Test currency code",
        @"ProductImpressions":@[
                @{
                        @"ProductList": @[
                        @{
                            @"Name": @"test name",
                            @"Brand": @"testing brand",
                            @"Price": @0,
                            @"Sku": @"sku test",
                            @"Quantity": @0
                        }
                        ],
                        @"ProductImpressionList": @"Impression List Test"
                }
        ],
        @"CheckoutStep": @2
    };
    
    MPCommerceEvent *commerceEvent = nil;
    commerceEvent = [MPConvertJS_PRIVATE commerceEvent:json];
    XCTAssertNotNil(commerceEvent);
    XCTAssertEqual(commerceEvent.type, MPEventTypeImpression);
    XCTAssertEqualObjects(commerceEvent.checkoutOptions, @"Test checkout option");
    XCTAssertEqualObjects(commerceEvent.productListName, @"Test action list name");
    XCTAssertEqualObjects(commerceEvent.productListSource, @"Test action list source");
    XCTAssertEqualObjects(commerceEvent.currency, @"Test currency code");
    XCTAssertEqual(commerceEvent.checkoutStep, 2);
    XCTAssertEqual(commerceEvent.impressions.count, 1);
    XCTAssertEqualObjects(commerceEvent.impressions[@"Impression List Test"].anyObject.name, @"test name");
    XCTAssertEqualObjects(commerceEvent.impressions[@"Impression List Test"].anyObject.quantity, @0);
}

- (void)testConvertMPCommerceEventImpressionActionWithNil {
    NSDictionary *json = @{
        @"CheckoutOptions":@"Test checkout option",
        @"productActionListName":@"Test action list name",
        @"productActionListSource":@"Test action list source",
        @"CurrencyCode":@"Test currency code",
        @"ProductImpressions": [NSNull null],
        @"CheckoutStep": @2
    };
    
    MPCommerceEvent *commerceEvent = nil;
    commerceEvent = [MPConvertJS_PRIVATE commerceEvent:json];
    XCTAssertNotNil(commerceEvent);
    XCTAssertEqual(commerceEvent.type, MPEventTypeImpression);
    XCTAssertEqualObjects(commerceEvent.checkoutOptions, @"Test checkout option");
    XCTAssertEqualObjects(commerceEvent.productListName, @"Test action list name");
    XCTAssertEqualObjects(commerceEvent.productListSource, @"Test action list source");
    XCTAssertEqualObjects(commerceEvent.currency, @"Test currency code");
    XCTAssertEqual(commerceEvent.checkoutStep, 2);
    XCTAssertEqual(commerceEvent.impressions.count, 0);
}

- (void)testConvertMPCommerceEventImpressionActionPriceString {
    NSDictionary *json = @{
        @"CheckoutOptions":@"Test checkout option",
        @"productActionListName":@"Test action list name",
        @"productActionListSource":@"Test action list source",
        @"CurrencyCode":@"Test currency code",
        @"ProductImpressions":@[
                @{
                        @"ProductList": @[
                        @{
                            @"Name": @"test name",
                            @"Brand": @"testing brand",
                            @"Price": @"0",
                            @"Sku": @"sku test",
                            @"Quantity": @0
                        }
                        ],
                        @"ProductImpressionList": @"Impression List Test"
                }
        ],
        @"CheckoutStep": @2
    };
    
    MPCommerceEvent *commerceEvent = nil;
    commerceEvent = [MPConvertJS_PRIVATE commerceEvent:json];
    XCTAssertNotNil(commerceEvent);
    XCTAssertEqual(commerceEvent.type, MPEventTypeImpression);
    XCTAssertEqualObjects(commerceEvent.checkoutOptions, @"Test checkout option");
    XCTAssertEqualObjects(commerceEvent.productListName, @"Test action list name");
    XCTAssertEqualObjects(commerceEvent.productListSource, @"Test action list source");
    XCTAssertEqualObjects(commerceEvent.currency, @"Test currency code");
    XCTAssertEqual(commerceEvent.checkoutStep, 2);
    XCTAssertEqual(commerceEvent.impressions.count, 1);
    XCTAssertEqualObjects(commerceEvent.impressions[@"Impression List Test"].anyObject.name, @"test name");
    XCTAssertEqualObjects(commerceEvent.impressions[@"Impression List Test"].anyObject.price, @0);
}

@end

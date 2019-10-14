#import <XCTest/XCTest.h>
#import "MPConvertJS.h"
#import "mParticle.h"
#import "MPBaseTestCase.h"

@interface MPConvertJSTests : MPBaseTestCase

@end

@implementation MPConvertJSTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

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
    transactionAttributes = [MPConvertJS MPTransactionAttributes:json];
    XCTAssertNotNil(transactionAttributes);
    XCTAssertEqualObjects(transactionAttributes.affiliation, @"Test affiliation");
    XCTAssertEqualObjects(transactionAttributes.couponCode, @"Test coupon code");
    XCTAssertEqualObjects(transactionAttributes.shipping, @20.00);
    XCTAssertEqualObjects(transactionAttributes.tax, @30.00);
    XCTAssertEqualObjects(transactionAttributes.revenue, @450.00);
    XCTAssertEqualObjects(transactionAttributes.transactionId, @"Test transaction id");
}

- (void)testConvertMPCommerceEventProductAction {
    NSDictionary *json = @{
        @"CheckoutOptions":@"Test checkout option",
        @"productActionListName":@"Test action list name",
        @"productActionListSource":@"Test action list source",
        @"CurrencyCode":@"Test currency code",
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
    commerceEvent = [MPConvertJS MPCommerceEvent:json];
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
    commerceEvent = [MPConvertJS MPCommerceEvent:json];
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
    commerceEvent = [MPConvertJS MPCommerceEvent:json];
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
    commerceEvent = [MPConvertJS MPCommerceEvent:json];
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
    commerceEvent = [MPConvertJS MPCommerceEvent:json];
    XCTAssertNotNil(commerceEvent);
    XCTAssertEqual(commerceEvent.type, MPEventTypeImpression);
    XCTAssertEqualObjects(commerceEvent.checkoutOptions, @"Test checkout option");
    XCTAssertEqualObjects(commerceEvent.productListName, @"Test action list name");
    XCTAssertEqualObjects(commerceEvent.productListSource, @"Test action list source");
    XCTAssertEqualObjects(commerceEvent.currency, @"Test currency code");
    XCTAssertEqual(commerceEvent.checkoutStep, 2);
    XCTAssertEqual(commerceEvent.impressions.count, 0);
}

@end

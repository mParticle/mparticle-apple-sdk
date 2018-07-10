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

@end

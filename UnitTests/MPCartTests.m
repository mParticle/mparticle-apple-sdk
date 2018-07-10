#import <XCTest/XCTest.h>
#import "MPCart.h"
#import "MPCart+Tests.h"
#import "MPProduct.h"
#import "MPBaseTestCase.h"

@interface MPCartTests : MPBaseTestCase

@end

@interface MPCart ()

- (nonnull instancetype)initWithUserId:(NSNumber *_Nonnull)userId;

@end

@implementation MPCartTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testAddProduct {
    MPCart *cart = [[MPCart alloc] initWithUserId:@123];
    XCTAssertEqual(cart.products.count, 0, @"There should have been no products in the cart.");
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    [cart addProducts:@[product] logEvent:NO updateProductList:YES];
    XCTAssertEqual(cart.products.count, 1, @"There should have been 1 product in the cart.");
    
    [cart clear];
    XCTAssertEqual(cart.products.count, 0, @"There should have been no products in the cart.");
}

- (void)testRemoveProduct {
    MPCart *cart = [[MPCart alloc] initWithUserId:@123];
    XCTAssertEqual(cart.products.count, 0, @"There should have been no products in the cart.");
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    [cart addProducts:@[product] logEvent:NO updateProductList:YES];
    XCTAssertEqual(cart.products.count, 1, @"There should have been 1 product in the cart.");
    
    [cart removeProducts:@[product] logEvent:NO updateProductList:YES];
    XCTAssertEqual(cart.products.count, 0, @"There should have been no products in the cart.");
    
    [cart clear];
}

- (void)testLoadingPersistedCart {
    MPCart *cart = [[MPCart alloc] initWithUserId:@123];
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    [cart addProducts:@[product] logEvent:NO updateProductList:YES];
    
    MPCart *persistedCart = [cart retrieveCart];
    XCTAssertEqualObjects(cart.products, persistedCart.products, @"Cart products should have been a match.");
    
    [cart clear];
    XCTAssertEqual(cart.products.count, 0, @"There should have been no products in the cart.");
}

@end

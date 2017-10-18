//
//  MPCartTests.m
//
//  Copyright 2015 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <XCTest/XCTest.h>
#import "MPCart.h"
#import "MPCart+Tests.h"
#import "MPProduct.h"

@interface MPCartTests : XCTestCase

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

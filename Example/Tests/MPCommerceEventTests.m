//
//  MPCommerceEventTests.m
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
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "MPPromotion.h"
#import "MPPromotion+Dictionary.h"
#import "MPTransactionAttributes.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"

@interface MPCommerceEventTests : XCTestCase

@end

@implementation MPCommerceEventTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testProduct {
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean"
                                                     sku:@"OutATime"
                                                quantity:@1
                                                   price:@4.32];
    
    XCTAssertNotNil(product, @"Product should not have been nil.");
    
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    
    product[@"key1"] = @"val1";
    product[@"key_number"] = @1;
    product[@"key_bool"] = @YES;
    
    NSDictionary *productDictionary = [product dictionaryRepresentation];
    XCTAssertNotNil(productDictionary, @"Product dictionary representation should not have been nil.");
    XCTAssertEqual(productDictionary.count, 13, @"Incorrect number of attributes.");
    
    __block NSArray *keys = @[@"br", @"ca", @"cc", @"nm", @"ps", @"qt",
                              @"id", @"pr", @"va", @"key1", @"key_bool", @"key_number"];
    
    __block NSArray *values = @[@"DLC", @"Time Machine", @"88mph", @"DeLorean", @"1", @"1",
                                @"OutATime", @"4.32", @"It depends", @"val1", @"Y", @"1"];
    
    [keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        XCTAssertNotNil(productDictionary[key], @"There should have been a key/value pair.");
        XCTAssertEqualObjects(productDictionary[key], values[idx], @"Value for key (%@) is not correct.", key);
    }];
    
    NSDictionary *expandedProductDictionary = [product beautifiedDictionaryRepresentation];
    XCTAssertNotNil(expandedProductDictionary, @"Product dictionary representation should not have been nil.");
    XCTAssertEqual(expandedProductDictionary.count, 13, @"Incorrect number of attributes.");
    
    keys = @[@"Brand", @"Category", @"Coupon Code", @"Name", @"Position", @"Quantity",
             @"Id", @"Item Price", @"Variant", @"key1", @"key_bool", @"key_number"];
    
    [keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        XCTAssertNotNil(expandedProductDictionary[key], @"There should have been a key/value pair.");
        XCTAssertEqualObjects(expandedProductDictionary[key], values[idx], @"Value for key (%@) is not correct.", key);
    }];
}

- (void)testPromotion {
    MPPromotion *promotion = [[MPPromotion alloc] init];
    XCTAssertNotNil(promotion, @"Promotion should not have been nil.");
    
    promotion.creative = @"ACME";
    promotion.name = @"Bird Seed";
    promotion.position = @"bottom";
    promotion.promotionId = @"catch_a_roadrunner";
    
    NSDictionary *promotionDictionary = [promotion dictionaryRepresentation];
    XCTAssertEqual(promotionDictionary.count, 4, @"Incorrect number of attributes");
    
    MPPromotionContainer *promotionContainer = [[MPPromotionContainer alloc] initWithAction:MPPromotionActionView promotion:promotion];
    XCTAssertNotNil(promotionContainer, @"Promotion container should not have been nil.");
    
    XCTAssertEqual(promotionContainer.action, MPPromotionActionView, @"Incorrect promotion action.");
    XCTAssertEqual(promotionContainer.promotions.count, 1, @"Incorrect number of entries.");
    
    NSDictionary *promotionContainerDictionary = [promotionContainer dictionaryRepresentation];
    XCTAssertNotNil(promotionContainerDictionary, @"Product container dictionary representation should not have been nil.");
    XCTAssertEqualObjects(promotionContainerDictionary[@"an"], @"view", @"Incorrect promotion action.");
    XCTAssertTrue([promotionContainerDictionary[@"pl"] isKindOfClass:[NSArray class]], @"Incorrect value type.");
    promotionDictionary = [promotionContainerDictionary[@"pl"] firstObject];
    XCTAssertEqualObjects(promotionDictionary[@"cr"], @"ACME", @"Incorrect value.");
    XCTAssertEqualObjects(promotionDictionary[@"id"], @"catch_a_roadrunner", @"Incorrect value.");
    XCTAssertEqualObjects(promotionDictionary[@"nm"], @"Bird Seed", @"Incorrect value.");
    XCTAssertEqualObjects(promotionDictionary[@"ps"], @"bottom", @"Incorrect value.");
    
    promotion = [[MPPromotion alloc] init];
    promotion.creative = @"Socks, Inc.";
    promotion.name = @"Socks";
    promotion.position = @"top";
    promotion.promotionId = @"wear_matching_socks";
    
    [promotionContainer addPromotion:promotion];
    XCTAssertEqual(promotionContainer.promotions.count, 2, @"Incorrect number of entries.");
}

- (void)testTransactionAttributes {
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    XCTAssertNotNil(transactionAttributes, @"Transaction attributes should not have been nil.");
    
    transactionAttributes.affiliation = @"ELB, Inc.";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @5.79;
    transactionAttributes.transactionId = @"noroads_2015";
    
    NSDictionary *transactionattributesDictionary = [transactionAttributes dictionaryRepresentation];
    XCTAssertNotNil(transactionattributesDictionary, @"Transaction attributes dictionary representation should not have been nil.");
    XCTAssertEqual(transactionattributesDictionary.count, 5, @"Incorrect number of entries.");
    
    __block NSArray *keys = @[@"ti", @"ts", @"ta", @"tr", @"tt"];
    
    __block NSArray *values = @[@"noroads_2015", @"1.23", @"ELB, Inc.", @"5.79", @"4.56"];
    
    [keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        XCTAssertNotNil(transactionattributesDictionary[key], @"There should have been a key/value pair.");
        XCTAssertEqualObjects(transactionattributesDictionary[key], values[idx], @"Value for key (%@) is not correct.", key);
    }];
}

- (void)testCommerceEventProduct {
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    product[@"key1"] = @"val1";
    product[@"key_number"] = @1;
    product[@"key_bool"] = @YES;
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertEqual(commerceEvent.products.count, 1, @"Incorrect product count.");
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent[@"key_string"] = @"val_string";
    commerceEvent[@"key_number"] = @3.14;
    
    product = [[MPProduct alloc] initWithName:@"Tardis" sku:@"trds" quantity:@1 price:@7.89];
    product.brand = @"Gallifrey Tardis";
    product.category = @"Time Machine";
    product.position = 2;
    product.variant = @"Police Box";
    
    [commerceEvent addProduct:product];
    XCTAssertEqual(commerceEvent.products.count, 2, @"Incorrect product count.");
    
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Doctor";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @18;
    transactionAttributes.transactionId = @"42";
    commerceEvent.transactionAttributes = transactionAttributes;
    XCTAssertNotNil(commerceEvent.transactionAttributes, @"Transaction attributes should not have been nil.");
    
    NSDictionary *commerceEventDictionary = [commerceEvent dictionaryRepresentation];
    XCTAssertNotNil(commerceEventDictionary, @"Commerce event dictionary representation should not have been nil.");
    XCTAssertEqual(commerceEventDictionary.count, 2, @"Incorrect number of entries.");
    XCTAssertNotNil(commerceEventDictionary[@"attrs"], @"There should have been a key/value pair.");
    XCTAssertNotNil(commerceEventDictionary[@"pd"], @"There should have been a key/value pair.");
}

- (void)testCommerceEventPromotion {
    MPPromotion *promotion = [[MPPromotion alloc] init];
    promotion.creative = @"ACME";
    promotion.name = @"Bird Seed";
    promotion.position = @"bottom";
    promotion.promotionId = @"catch_a_roadrunner";
    
    MPPromotionContainer *promotionContainer = [[MPPromotionContainer alloc] initWithAction:MPPromotionActionView promotion:promotion];
    
    promotion = [[MPPromotion alloc] init];
    promotion.creative = @"Socks, Inc.";
    promotion.name = @"Socks";
    promotion.position = @"top";
    promotion.promotionId = @"wear_matching_socks";
    
    [promotionContainer addPromotion:promotion];
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithPromotionContainer:promotionContainer];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    
    NSDictionary *commerceEventDictionary = [commerceEvent dictionaryRepresentation];
    XCTAssertNotNil(commerceEventDictionary, @"Commerce event dictionary representation should not have been nil.");
    XCTAssertEqual(commerceEventDictionary.count, 1, @"Incorrect number of entries.");
    
    NSDictionary *promotionDictionary = commerceEventDictionary[@"pm"];
    XCTAssertNotNil(promotionDictionary[@"an"], @"There should have been a key/value pair.");
    XCTAssertNotNil(promotionDictionary[@"pl"], @"There should have been a key/value pair.");
    XCTAssertEqual([promotionDictionary[@"pl"] count], 2, @"Incorrect number of entries.");
}

- (void)testCommerceEventImpression {
    MPProduct *product = [[MPProduct alloc] initWithName:@"Flux Capacitor" sku:@"flxcpt" quantity:@1 price:@3.21];
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithImpressionName:@"Time accessories" product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertNotNil(commerceEvent.impressions, @"Impressions should not have been nil.");
    
    NSDictionary *commerceEventDictionary = [commerceEvent dictionaryRepresentation];
    XCTAssertNotNil(commerceEventDictionary, @"Commerce event dictionary representation should not have been nil.");
    XCTAssertEqual(commerceEventDictionary.count, 1, @"Incorrect number of entries.");
    XCTAssertNotNil(commerceEventDictionary[@"pi"], @"There should have been a key/value pair.");
}

- (void)testExpandedCommerceEventProductRepresentation {
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    product[@"key1"] = @"val1";
    product[@"key_number"] = @1;
    product[@"key_bool"] = @YES;
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent[@"key_string"] = @"val_string";
    commerceEvent[@"key_number"] = @3.14;
    
    product = [[MPProduct alloc] initWithName:@"Tardis" sku:@"trds" quantity:@1 price:@7.89];
    product.brand = @"Gallifrey Tardis";
    product.category = @"Time Machine";
    product.position = 2;
    product.variant = @"Police Box";
    
    [commerceEvent addProduct:product];
    
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Doctor";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @18;
    transactionAttributes.transactionId = @"42";
    commerceEvent.transactionAttributes = transactionAttributes;
    XCTAssertNotNil(commerceEvent.transactionAttributes, @"Transaction attributes should not have been nil.");
    
    NSArray *expandedInstructions = [commerceEvent expandedInstructions];
    XCTAssertNotNil(expandedInstructions, @"Expanded commerce instructions should not have been nil.");
}

- (void)testExpandedCommerceEventPromotionRepresentation {
    MPPromotion *promotion = [[MPPromotion alloc] init];
    promotion.creative = @"ACME";
    promotion.name = @"Bird Seed";
    promotion.position = @"bottom";
    promotion.promotionId = @"catch_a_roadrunner";
    
    MPPromotionContainer *promotionContainer = [[MPPromotionContainer alloc] initWithAction:MPPromotionActionView promotion:promotion];
    
    promotion = [[MPPromotion alloc] init];
    promotion.creative = @"Socks, Inc.";
    promotion.name = @"Socks";
    promotion.position = @"top";
    promotion.promotionId = @"wear_matching_socks";
    
    [promotionContainer addPromotion:promotion];
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithPromotionContainer:promotionContainer];
    
    NSArray *expandedInstructions = [commerceEvent expandedInstructions];
    XCTAssertNotNil(expandedInstructions, @"Expanded commerce instructions should not have been nil.");
}

@end

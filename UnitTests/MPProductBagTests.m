//
//  MPProductBagTests.m
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
#import "MPBags.h"
#import "MPBags+Internal.h"
#import "MPProductBag.h"
#import "MPProduct.h"

@interface MPProductBagTests : XCTestCase

@end

@implementation MPProductBagTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testProductBagInstance {
    MPProductBag *productBag = [[MPProductBag alloc] initWithName:@"bag1"];
    XCTAssertNotNil(productBag, @"Instance should not have been nil.");
    XCTAssertEqual(productBag.products.count, 0, @"Incorrect count.");
    
    NSString *nilName = nil;
    productBag = [[MPProductBag alloc] initWithName:nilName];
    XCTAssertNil(productBag, @"Instance should have been nil.");
    
    productBag = [[MPProductBag alloc] initWithName:(NSString *)[NSNull null]];
    XCTAssertNil(productBag, @"Instance should have been nil.");
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"prod1" sku:@"sku1" quantity:@1 price:@0];
    XCTAssertNotNil(product, @"Instance should not have been nil.");
    
    productBag = [[MPProductBag alloc] initWithName:@"bag1" product:product];
    XCTAssertNotNil(productBag, @"Instance should not have been nil.");
    XCTAssertEqual(productBag.products.count, 1, @"Incorrect count.");
    
    productBag.name = @"A new bag";
    XCTAssertEqualObjects(productBag.name, @"A new bag", @"Should have been equal.");
}

- (void)testProductBagEquality {
    MPProductBag *productBag1 = [[MPProductBag alloc] initWithName:@"bag1"];
    MPProductBag *productBag2 = [[MPProductBag alloc] initWithName:@"bag1"];
    
    XCTAssertEqualObjects(productBag1, productBag2, @"Instances should have been equal.");
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"prod1" sku:@"sku1" quantity:@1 price:@0];
    [productBag2.products addObject:product];
    XCTAssertNotEqualObjects(productBag1, productBag2, @"Instances should have been different.");
    XCTAssertNotEqualObjects(productBag1, [NSNull null], @"Should have been different.");
}

- (void)testProductBagDictionaryRepresentation {
    MPProduct *product = [[MPProduct alloc] initWithName:@"prod1" sku:@"sku1" quantity:@1 price:@0];
    MPProductBag *productBag = [[MPProductBag alloc] initWithName:@"bag1" product:product];
    NSDictionary *dictionaryRepresentation = [productBag dictionaryRepresentation];
    XCTAssertNotNil(dictionaryRepresentation, @"Should not have been nil.");
    XCTAssertTrue([dictionaryRepresentation isKindOfClass:[NSDictionary class]], @"Wrong class type.");
    
    NSString *bagKey = [[dictionaryRepresentation allKeys] firstObject];
    XCTAssertNotNil(bagKey, @"Should not have been nil.");
    XCTAssertTrue([bagKey isKindOfClass:[NSString class]], @"Wrong class type.");
    
    NSDictionary *keyDictionary = dictionaryRepresentation[bagKey];
    XCTAssertNotNil(keyDictionary, @"Should not have been nil.");
    XCTAssertTrue([keyDictionary isKindOfClass:[NSDictionary class]], @"Wrong class type.");
    
    NSString *productsKey = [[keyDictionary allKeys] firstObject];
    XCTAssertNotNil(productsKey, @"Should not have been nil.");
    XCTAssertTrue([productsKey isKindOfClass:[NSString class]], @"Wrong class type.");
    
    NSArray *products = keyDictionary[productsKey];
    XCTAssertNotNil(products, @"Should not have been nil.");
    XCTAssertTrue([products isKindOfClass:[NSArray class]], @"Wrong class type.");
    
    NSDictionary *productDictionary = [products firstObject];
    XCTAssertNotNil(productDictionary, @"Should not have been nil.");
    XCTAssertTrue([productDictionary isKindOfClass:[NSDictionary class]], @"Wrong class type.");
}

- (void)testBagsOperations {
    MPBags *bags = [[MPBags alloc] init];
    XCTAssertNotNil(bags, @"Should not have been nil.");
    XCTAssertEqual(bags.productBags.count, 0, @"Incorrect count.");
    
    MPProduct *product1 = [[MPProduct alloc] initWithName:@"prod1" sku:@"sku1" quantity:@1 price:@0];
    [bags addProduct:product1 toBag:@"bag1"];
    XCTAssertEqual(bags.productBags.count, 1, @"Incorrect count.");
    
    MPProduct *nilProduct = nil;
    NSString *nilBag = nil;
    
    [bags addProduct:nilProduct toBag:@"bag2"];
    [bags addProduct:(MPProduct *)[NSNull null] toBag:@"bag2"];
    [bags addProduct:product1 toBag:nilBag];
    [bags addProduct:product1 toBag:(NSString *)[NSNull null]];
    [bags addProduct:nilProduct toBag:nilBag];
    [bags addProduct:(MPProduct *)[NSNull null] toBag:(NSString *)[NSNull null]];
    XCTAssertEqual([bags productBags].count, 1, @"Incorrect count.");
    
    MPProduct *product2 = [[MPProduct alloc] initWithName:@"prod2" sku:@"sku2" quantity:@1 price:@0];
    [bags addProduct:product2 toBag:@"bag1"];
    NSArray *products = bags.productBags[@"bag1"];
    XCTAssertNotNil(products, @"Should not have been nil.");
    XCTAssertEqual(products.count, 2, @"Incorrect count.");
    
    [bags removeProduct:product1 fromBag:@"bag1"];
    products = bags.productBags[@"bag1"];
    XCTAssertNotNil(products, @"Should not have been nil.");
    XCTAssertEqual(products.count, 1, @"Incorrect count.");
    
    [bags removeProduct:nilProduct fromBag:@"bag1"];
    [bags removeProduct:(MPProduct *)[NSNull null] fromBag:@"bag1"];
    [bags removeProduct:product2 fromBag:nilBag];
    [bags removeProduct:product2 fromBag:(NSString *)[NSNull null]];
    [bags removeProduct:nilProduct fromBag:nilBag];
    [bags removeProduct:(MPProduct *)[NSNull null] fromBag:(NSString *)[NSNull null]];
    products = bags.productBags[@"bag1"];
    XCTAssertNotNil(products, @"Should not have been nil.");
    XCTAssertEqual(products.count, 1, @"Incorrect count.");

    MPProduct *product3 = [[MPProduct alloc] initWithName:@"prod3" sku:@"sku3" quantity:@1 price:@0];
    [bags addProduct:product3 toBag:@"bag2"];

    [bags removeProduct:product3 fromBag:@"bag4"];
    [bags removeProduct:product3 fromBag:@"bag1"];
    products = bags.productBags[@"bag1"];
    XCTAssertEqual(products.count, 1, @"Incorrect count.");

    XCTAssertEqual([bags productBags].count, 2, @"Should have been equal.");
    [bags removeProductBag:(NSString *)[NSNull null]];
    [bags removeProductBag:@"bag3"];
    [bags removeProductBag:@"bag2"];
    XCTAssertEqual([bags productBags].count, 1, @"Should have been equal.");
    [bags removeAllProductBags];
    XCTAssertEqual([bags productBags].count, 0, @"Incorrect count.");
}

- (void)testBagsDictionaryRepresentation {
    MPBags *bags = [[MPBags alloc] init];
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"prod1" sku:@"sku1" quantity:@1 price:@0];
    [bags addProduct:product toBag:@"bag1"];
    
    product = [[MPProduct alloc] initWithName:@"prod2" sku:@"sku2" quantity:@1 price:@0];
    [bags addProduct:product toBag:@"bag1"];
    
    product = [[MPProduct alloc] initWithName:@"prod3" sku:@"sku3" quantity:@1 price:@0];
    [bags addProduct:product toBag:@"bag2"];
    
    NSDictionary *bagsDictionaryRepresentation = [bags dictionaryRepresentation];
    XCTAssertNotNil(bagsDictionaryRepresentation, @"Should not have been nil.");
    NSArray *bagsKeys = [bagsDictionaryRepresentation allKeys];
    NSArray *testKeys = @[@"bag2", @"bag1"];
    XCTAssertEqualObjects(bagsKeys, testKeys, @"Objects are not equal.");
    
    [bags removeAllProductBags];
    XCTAssertEqual(bags.productBags.count, 0, @"Incorrect count.");
}

@end

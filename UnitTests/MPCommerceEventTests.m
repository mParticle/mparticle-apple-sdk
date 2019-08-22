#import <XCTest/XCTest.h>
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "MPPromotion.h"
#import "MPPromotion+Dictionary.h"
#import "MPTransactionAttributes.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPBaseTestCase.h"
#import "MParticle.h"

@interface MPCommerceEventTests : MPBaseTestCase

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
    product[@"key_number"] = @"1";
    product[@"key_bool"] = @"Y";
    
    NSDictionary *productDictionary = [product dictionaryRepresentation];
    XCTAssertNotNil(productDictionary, @"Product dictionary representation should not have been nil.");
    XCTAssertEqual(productDictionary.count, 13, @"Incorrect number of attributes.");
    
    NSString *description = [product description];
    XCTAssertNotNil(description, @"Should not have been nil.");
    
    __block NSArray *keys = @[@"br", @"ca", @"cc", @"nm", @"ps", @"qt",
                              @"id", @"pr", @"va", @"key1", @"key_bool", @"key_number"];
    
    __block NSArray *values = @[@"DLC", @"Time Machine", @"88mph", @"DeLorean", @"1", @"1",
                                @"OutATime", @"4.32", @"It depends", @"val1", @"Y", @"1"];
    
    [keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        XCTAssertNotNil(productDictionary[key], @"There should have been a key/value pair.");
        XCTAssertEqualObjects(productDictionary[key], values[idx], @"Value for key (%@) is not correct.", key);
    }];
    
    NSDictionary *expectedCommerceDictionary = @{@"attrs":@{@"key1":@"val1",
                                                            @"key_bool":@"Y",
                                                            @"key_number":@"1"
                                                            },
                                                 @"br":@"DLC",
                                                 @"ca":@"Time Machine",
                                                 @"cc":@"88mph",
                                                 @"id":@"OutATime",
                                                 @"nm":@"DeLorean",
                                                 @"pr":@"4.32",
                                                 @"ps":@"1",
                                                 @"qt":@"1",
                                                 @"tpa":@"4.32",
                                                 @"va":@"It depends"
                                                 };
    productDictionary = [product commerceDictionaryRepresentation];
    XCTAssertNotNil(productDictionary, @"Should not have been nil.");
    XCTAssertEqualObjects(productDictionary, expectedCommerceDictionary, @"Should have been equal.");
    
    XCTAssertEqualObjects(product[@"key1"], @"val1", @"Should have been equal");
    XCTAssertEqualObjects(product[@"ca"], @"Time Machine", @"Should have been equal");
    
    NSArray *allKeys = [product allKeys];
    NSArray *expectedKeys = @[@"ca", @"ps", @"qt", @"id", @"tpa", @"va", @"pr", @"br", @"cc", @"nm", @"key1", @"key_number", @"key_bool"];
    XCTAssertEqualObjects(allKeys, expectedKeys, @"Should have been equal");
    
    NSUInteger count = [product count];
    XCTAssertEqual(count, 13, @"Should have been equal");
    
    NSDictionary *expandedProductDictionary = [product beautifiedDictionaryRepresentation];
    XCTAssertNotNil(expandedProductDictionary, @"Product dictionary representation should not have been nil.");
    XCTAssertEqual(expandedProductDictionary.count, 13, @"Incorrect number of attributes.");
    
    keys = @[@"Brand", @"Category", @"Coupon Code", @"Name", @"Position", @"Quantity",
             @"Id", @"Item Price", @"Variant", @"key1", @"key_bool", @"key_number"];
    
    [keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        XCTAssertNotNil(expandedProductDictionary[key], @"There should have been a key/value pair.");
        XCTAssertEqualObjects(expandedProductDictionary[key], values[idx], @"Value for key (%@) is not correct.", key);
    }];
    
    MPProduct *productCopy = [product copy];
    XCTAssertNotNil(productCopy, @"Should not have been nil.");
    XCTAssertEqualObjects(product, productCopy, @"Should have been equal.");
    productCopy.variant = @"Dependends on what?";
    XCTAssertNotEqualObjects(product, productCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(product, (MPProduct *)[NSNull null], @"Should not have been equal.");
    XCTAssertNotEqualObjects(product, (MPProduct *)@"This is not a product", @"Should not have been equal.");
    
    NSData *productData = [NSKeyedArchiver archivedDataWithRootObject:product];
    XCTAssertNotNil(productData, @"Should not have been nil.");
    MPProduct *deserializedProduct = [NSKeyedUnarchiver unarchiveObjectWithData:productData];
    XCTAssertNotNil(deserializedProduct, @"Should not have been nil.");
    XCTAssertEqualObjects(product, deserializedProduct, @"Should have been equal.");
    
    productDictionary = [product beautifiedDictionaryRepresentation];
    XCTAssertNotNil(productDictionary[@"Variant"], @"Should not have been nil.");
    MPProduct *hashMatchinProduct = [product copyMatchingHashedProperties:@{@"236785797":@0}];
    productDictionary = [hashMatchinProduct beautifiedDictionaryRepresentation];
    XCTAssertNil(productDictionary[@"Variant"], @"Should have been nil.");
}

- (void)testPromotion {
    MPPromotion *promotion = [[MPPromotion alloc] init];
    XCTAssertNotNil(promotion, @"Promotion should not have been nil.");

    XCTAssertNotEqualObjects(promotion, (MPPromotion *)[NSNull null], @"Should not have been equal.");
    
    MPPromotion *promotion2 = [[MPPromotion alloc] init];
    XCTAssertEqualObjects(promotion, promotion2, @"Should have been equal.");

    promotion.creative = @"ACME";
    XCTAssertNotEqualObjects(promotion, promotion2, @"Should not have been equal.");
    
    promotion.name = @"Bird Seed";
    promotion.position = @"bottom";
    promotion.promotionId = @"catch_a_roadrunner";
    
    NSDictionary *promotionDictionary = [promotion dictionaryRepresentation];
    XCTAssertEqual(promotionDictionary.count, 4, @"Incorrect number of attributes");
    
    promotionDictionary = [promotion beautifiedDictionaryRepresentation];
    XCTAssertEqual(promotionDictionary.count, 4, @"Incorrect number of attributes");
    
    NSString *description = [promotion description];
    XCTAssertNotNil(description, @"Should not have been nil.");
    
    MPPromotion *promotionCopy  = [promotion copy];
    XCTAssertEqualObjects(promotion, promotionCopy, @"Should have been equal.");
    promotionCopy.position = @"top";
    XCTAssertNotEqualObjects(promotion, promotionCopy, @"Should not have been equal.");
    
    NSData *promotionData = [NSKeyedArchiver archivedDataWithRootObject:promotion];
    XCTAssertNotNil(promotionData, @"Should not have been nil.");
    MPPromotion *deserializedPromotion = [NSKeyedUnarchiver unarchiveObjectWithData:promotionData];
    XCTAssertNotNil(deserializedPromotion, @"Should not have been nil.");
    XCTAssertEqualObjects(promotion, deserializedPromotion, @"Should have been equal.");
    
    MPPromotion *hashMatchinPromotion = [promotion copyMatchingHashedProperties:@{@"747804969":@0}];
    promotionDictionary = [hashMatchinPromotion beautifiedDictionaryRepresentation];
    XCTAssertEqual(promotionDictionary.count, 3, @"Incorrect number of attributes");
    
    MPPromotionContainer *promotionContainer = [[MPPromotionContainer alloc] initWithAction:MPPromotionActionView promotion:promotion];
    XCTAssertNotNil(promotionContainer, @"Promotion container should not have been nil.");
    XCTAssertEqual(promotionContainer.action, MPPromotionActionView, @"Incorrect promotion action.");
    XCTAssertEqual(promotionContainer.promotions.count, 1, @"Incorrect number of entries.");
    
    MPPromotionContainer *promotionContainerCopy = [promotionContainer copy];
    XCTAssertNotNil(promotionContainerCopy, @"Should not have been nil.");
    XCTAssertEqualObjects(promotionContainer, promotionContainerCopy, @"Should have been equal.");
    [promotionContainerCopy addPromotion:promotionCopy];
    XCTAssertNotEqualObjects(promotionContainer, promotionContainerCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(promotionContainer, (MPPromotionContainer *)[NSNull null], @"Should not have been equal.");
    id invalidPromotionContainer = @"This clearly is not a promotion container.";
    XCTAssertNotEqualObjects(promotionContainer, invalidPromotionContainer, @"Should not have been equal.");
    
    NSData *promotionContainerData = [NSKeyedArchiver archivedDataWithRootObject:promotionContainer];
    XCTAssertNotNil(promotionContainerData, @"Should not have been nil.");
    MPPromotionContainer *deserializedPromotionContainer = [NSKeyedUnarchiver unarchiveObjectWithData:promotionContainerData];
    XCTAssertNotNil(deserializedPromotionContainer, @"Should not have been nil.");
    XCTAssertEqualObjects(promotionContainer, deserializedPromotionContainer, @"Should have been equal.");
    [deserializedPromotionContainer addPromotion:promotionCopy];
    XCTAssertNotEqualObjects(promotionContainer, deserializedPromotionContainer, @"Should not have been equal.");
    
    NSDictionary *promotionContainerDictionary = [promotionContainer dictionaryRepresentation];
    XCTAssertNotNil(promotionContainerDictionary, @"Product container dictionary representation should not have been nil.");
    XCTAssertEqualObjects(promotionContainerDictionary[@"an"], @"view", @"Incorrect promotion action.");
    XCTAssertTrue([promotionContainerDictionary[@"pl"] isKindOfClass:[NSArray class]], @"Incorrect value type.");
    promotionDictionary = [promotionContainerDictionary[@"pl"] firstObject];
    XCTAssertEqualObjects(promotionDictionary[@"cr"], @"ACME", @"Incorrect value.");
    XCTAssertEqualObjects(promotionDictionary[@"id"], @"catch_a_roadrunner", @"Incorrect value.");
    XCTAssertEqualObjects(promotionDictionary[@"nm"], @"Bird Seed", @"Incorrect value.");
    XCTAssertEqualObjects(promotionDictionary[@"ps"], @"bottom", @"Incorrect value.");
    
    promotionContainerDictionary = [promotionContainer beautifiedDictionaryRepresentation];
    XCTAssertNotNil(promotionContainerDictionary, @"Should not have been nil.");
    
    promotion = [[MPPromotion alloc] init];
    promotion.creative = @"Socks, Inc.";
    promotion.name = @"Socks";
    promotion.position = @"top";
    promotion.promotionId = @"wear_matching_socks";
    
    [promotionContainer addPromotion:promotion];
    XCTAssertEqual(promotionContainer.promotions.count, 2, @"Incorrect number of entries.");
    
    MPPromotionContainer *hashMatchingPromotionContainer = [promotionContainer copyMatchingHashedProperties:@{@"747804969":@0}];
    promotionContainerDictionary = [hashMatchingPromotionContainer beautifiedDictionaryRepresentation];
    XCTAssertNotNil(promotionContainerDictionary, @"Should not have been nil.");
    
    NSDictionary *expectedDictionary = @{@"an":@"view",
                                         @"pl":@[@{@"Creative":@"ACME",
                                                   @"Id":@"catch_a_roadrunner",
                                                   @"Name":@"Bird Seed"
                                                   },
                                                 @{@"Creative":@"Socks, Inc.",
                                                   @"Id":@"wear_matching_socks",
                                                   @"Name":@"Socks"
                                                   }
                                                 ]
                                         };
    XCTAssertEqualObjects(promotionContainerDictionary, expectedDictionary, @"Should have been equal.");
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
    
    transactionattributesDictionary = [transactionAttributes beautifiedDictionaryRepresentation];
    XCTAssertNotNil(transactionattributesDictionary, @"Should not have been nil.");
    
    NSString *description = [transactionAttributes description];
    XCTAssertNotNil(description, @"Should not have been nil.");
    
    MPTransactionAttributes *transactionAttributesCopy = [transactionAttributes copy];
    XCTAssertNotNil(transactionAttributesCopy, @"Should not have been nil.");
    XCTAssertEqualObjects(transactionAttributes, transactionAttributesCopy, @"Should have been equal.");
    transactionAttributesCopy.affiliation = nil;
    XCTAssertNotEqualObjects(transactionAttributes, transactionAttributesCopy, @"Should not have been equal.");
    XCTAssertNotEqualObjects(transactionAttributes, [NSNull null], @"Should not have been equal.");
    
    NSData *transactionAttributesData = [NSKeyedArchiver archivedDataWithRootObject:transactionAttributes];
    XCTAssertNotNil(transactionAttributesData, @"Should not have been nil.");
    MPTransactionAttributes *deserializedTransactionAttributes = [NSKeyedUnarchiver unarchiveObjectWithData:transactionAttributesData];
    XCTAssertNotNil(deserializedTransactionAttributes, @"Should not have been nil.");
    XCTAssertEqualObjects(transactionAttributes, deserializedTransactionAttributes, @"Should have been equal.");
}

- (void)testCommerceEventProduct {
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    product[@"key1"] = @"val1";
    product[@"key_number"] = @"1";
    product[@"key_bool"] = @"YES";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertEqual(commerceEvent.products.count, 1, @"Incorrect product count.");
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent.customAttributes = @{@"key_string": @"val_string", @"key_number":@"3.14"};
    commerceEvent.currency = @"bitcoins";
    commerceEvent.nonInteractive = YES;
    commerceEvent.screenName = @"time machine screen";
    
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
    XCTAssertEqual(commerceEventDictionary.count, 5, @"Incorrect number of entries.");
    XCTAssertNotNil(commerceEventDictionary[@"attrs"], @"There should have been a key/value pair.");
    XCTAssertNotNil(commerceEventDictionary[@"pd"], @"There should have been a key/value pair.");
    XCTAssertEqualObjects(commerceEventDictionary[@"cu"], @"bitcoins", @"Currency should have been present.");
    XCTAssertEqualObjects(commerceEventDictionary[@"sn"], @"time machine screen", @"Screen name should have been present.");
    XCTAssertEqualObjects(commerceEventDictionary[@"ni"], @YES, @"Non-interactive should have been present.");
}

- (void)testCommerceEventProductDeprecated {
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    product[@"key1"] = @"val1";
    product[@"key_number"] = @"1";
    product[@"key_bool"] = @"YES";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertEqual(commerceEvent.products.count, 1, @"Incorrect product count.");
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent[@"key_string"] = @"val_string";
    commerceEvent[@"key_number"] = @"3.14";
    commerceEvent.currency = @"bitcoins";
    commerceEvent.nonInteractive = YES;
    commerceEvent.screenName = @"time machine screen";
#pragma clang diagnostic pop
    
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
    XCTAssertEqual(commerceEventDictionary.count, 5, @"Incorrect number of entries.");
    XCTAssertNotNil(commerceEventDictionary[@"attrs"], @"There should have been a key/value pair.");
    XCTAssertNotNil(commerceEventDictionary[@"pd"], @"There should have been a key/value pair.");
    XCTAssertEqualObjects(commerceEventDictionary[@"cu"], @"bitcoins", @"Currency should have been present.");
    XCTAssertEqualObjects(commerceEventDictionary[@"sn"], @"time machine screen", @"Screen name should have been present.");
    XCTAssertEqualObjects(commerceEventDictionary[@"ni"], @YES, @"Non-interactive should have been present.");
}

- (void)testCustomAttributes {
    MPProduct *product = [[MPProduct alloc] initWithName:@"prod1" sku:@"sku1" quantity:@1 price:@0];
    XCTAssertNotNil(product, @"Instance should not have been nil.");
    
    product[@"TestCustomAttribute"] = @"4";
    XCTAssertEqual(product[@"TestCustomAttribute"], @"4");
    
    int x = 0;
    
    @try {
        product[@"TestCustomAttribute2"] = @(4);
    }
    
    @catch ( NSException *e) {
        x++;
    }
    
    @finally {
        XCTAssertEqual(x, 1, @"Exception should be called anytime a non NSObject is added to this dictionary");
    }
    
    @try {
        product[@"TestCustomAttribute2"] = [UIColor blueColor];
    }
    
    @catch ( NSException *e) {
        x++;
    }
    
    @finally {
        XCTAssertEqual(x, 2, @"Exception should be called anytime a non NSObject is added to this dictionary");
    }
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertEqual(commerceEvent.products.count, 1, @"Incorrect product count.");
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent.customAttributes = @{@"key_string": @"val_string"};
    commerceEvent.currency = @"bitcoins";
    commerceEvent.nonInteractive = YES;
    commerceEvent.screenName = @"time machine screen";
    
    @try {
        commerceEvent.customAttributes = @{@"key_string": @"val_string", @"key_number": @"3.14"};
    }
    
    @catch ( NSException *e) {
        x++;
    }
    
    @finally {
        XCTAssertEqual(x, 2, @"Exception should not be called anytime a non NSObject is added to this dictionary");
    }
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
    product[@"key_number"] = @"1";
    product[@"key_bool"] = @"Y";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent.customAttributes = @{@"key_string": @"val_string", @"key_number": @"3.14"};
    
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

- (void)testBeautifiedAttributesContainTransactionAttributes {
    MPCommerceEvent *purchaseEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:nil];
    
    MPTransactionAttributes *attributes = [[MPTransactionAttributes alloc] init];
    attributes.transactionId = @"<transaction id>";
    attributes.revenue = @1;
    attributes.tax = @0.5;
    attributes.shipping = @2;
    attributes.couponCode = @"<coupon code>";
    
    purchaseEvent.transactionAttributes = attributes;
    purchaseEvent.currency = @"<currency>";
    
    NSDictionary *beautifiedAttributes = [purchaseEvent beautifiedAttributes];
    XCTAssertEqualObjects(beautifiedAttributes[@"Currency Code"], @"<currency>");
    XCTAssertEqualObjects(beautifiedAttributes[@"Coupon Code"], @"<coupon code>");
    XCTAssertEqualObjects(beautifiedAttributes[@"Shipping Amount"], @"2");
    XCTAssertEqualObjects(beautifiedAttributes[@"Tax Amount"], @"0.5");
    XCTAssertEqualObjects(beautifiedAttributes[@"Total Amount"], @"1");
    XCTAssertEqualObjects(beautifiedAttributes[@"Transaction Id"], @"<transaction id>");
}

- (void)testBeautifiedAttributesReflectTransactionAttributeChanges {
    MPCommerceEvent *purchaseEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:nil];
    
    MPTransactionAttributes *attributes = [[MPTransactionAttributes alloc] init];
    attributes.revenue = @1;
    
    purchaseEvent.transactionAttributes = attributes;
    
    attributes.revenue = @2;
    
    NSDictionary *beautifiedAttributes = [purchaseEvent beautifiedAttributes];
    XCTAssertEqualObjects(beautifiedAttributes[@"Total Amount"], @"2");
}

- (void)testPromotionEncoding {
    MPPromotion *promotion = [[MPPromotion alloc] init];
    promotion.creative = @"ACME";
    promotion.name = @"Bird Seed";
    promotion.position = @"bottom";
    promotion.promotionId = @"catch_a_roadrunner";
    
    MPPromotion *persistedPromotion = [self attemptSecureEncodingwithClass:[MPPromotion class] Object:promotion];
    XCTAssertEqualObjects(promotion, persistedPromotion, @"Promotion should have been a match.");
}

- (void)testTransactionAttributesEncoding {
    MPTransactionAttributes *attributes = [[MPTransactionAttributes alloc] init];
    attributes.transactionId = @"<transaction id>";
    attributes.revenue = @1;
    attributes.tax = @0.5;
    attributes.shipping = @2;
    attributes.couponCode = @"<coupon code>";
    
    MPTransactionAttributes *persisteAttributes = [self attemptSecureEncodingwithClass:[MPTransactionAttributes class] Object:attributes];
    XCTAssertEqualObjects(attributes, persisteAttributes, @"Attributes should have been a match.");
}

- (void)testCommerceEventEncoding {
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    product[@"key1"] = @"val1";
    product[@"key_number"] = @"1";
    product[@"key_bool"] = @"YES";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    
    MPCommerceEvent *persistedCommerceEvent = [self attemptSecureEncodingwithClass:[MPCommerceEvent class] Object:commerceEvent];
    XCTAssertEqualObjects([commerceEvent dictionaryRepresentation], [persistedCommerceEvent dictionaryRepresentation], @"Commerce Event should have been a match.");
}

- (void)testDocsUse {
    // Get the cart
    MParticleUser *currentUser = [[[MParticle sharedInstance] identity] currentUser];
    MPCart *cart = currentUser.cart;
    
    // Add products to the cart
    MPProduct *doubleRoom = [[MPProduct alloc] initWithName:@"Double Room - Econ Rate"
                                                        sku:@"econ-1"
                                                   quantity:@4
                                                      price:@100.00];
    [cart addProduct:doubleRoom]; // Generates an Add to Cart event
    
    MPProduct *spaPackage = [[MPProduct alloc] initWithName:@"Spa Package"
                                                        sku:@"Spa/Hya"
                                                   quantity:@1
                                                      price:@170.00];
    [cart addProduct:spaPackage]; // Generates an Add to Cart event
    
    // Remove products from the cart
    [cart removeProduct:spaPackage]; // Generates a Remove from Cart event
    
    // Summarize the transaction
    MPTransactionAttributes *attributes = [[MPTransactionAttributes alloc] init];
    attributes.transactionId = @"foo-transaction-id";
    attributes.revenue = @430.00;
    attributes.tax = @30.00;
    
    cart = currentUser.cart;
    XCTAssertEqual(cart.products.count, 1, @"Cart should have 1 product.");

    // Log a purchase with all items currently in the cart
    MPCommerce *commerce = [[MParticle sharedInstance] commerce];
    [commerce purchaseWithTransactionAttributes:attributes
                                      clearCart:YES];
    cart = currentUser.cart;
    XCTAssertEqual(cart.products.count, 0, @"Cart should be empty.");
}

@end

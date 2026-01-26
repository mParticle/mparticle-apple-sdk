@import mParticle_Apple_SDK_NoLocation;

#import <XCTest/XCTest.h>
#import "MPBaseTestCase.h"
#import "MPIConstants.h"
@import mParticle_Apple_SDK_Swift;

@interface HasherTests : MPBaseTestCase

@end

@implementation HasherTests

MPIHasher* hasher;

- (void)setUp {
    [super setUp];
    MParticle* mparticle = MParticle.sharedInstance;
    MPLog* logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
    logger.customLogger = mparticle.customLogger;
    hasher = [[MPIHasher alloc] initWithLogger:logger];
}

- (void)testHashingString {
    NSString *referenceString = @"The Quick Brown Fox Jumps Over the Lazy Dog.";
    NSString *hashedString = [hasher hashString:referenceString];
    XCTAssertEqualObjects(hashedString, @"-142870245", @"Hasher is not hashing strings properly.");
    
    referenceString = @"";
    hashedString = [hasher hashString:referenceString];
    XCTAssertEqualObjects(hashedString, @"", @"Hashing an empty string.");
}

- (void)testHashingPerformance {
    [self measureBlock:^{
        NSString *referenceString = @"The Quick Brown Fox Jumps Over the Lazy Dog.";
        (void)[hasher hashString:referenceString];
    }];
}

- (NSArray<NSString*> *)hashedEventTypes:(NSArray<NSNumber*> *)eventTypes {
    NSMutableArray *hashedTypes = [NSMutableArray arrayWithCapacity:eventTypes.count];
    if (eventTypes.count == 0) {
        return hashedTypes;
    }
    
    for (NSNumber *eventType in eventTypes) {
        NSString *hashedEventType = [hasher hashString:eventType.stringValue];
        [hashedTypes addObject:hashedEventType];
    }
    return hashedTypes;
}

- (NSArray<NSString*> *)hashedAllEventTypes {
    NSMutableArray *eventTypes = [NSMutableArray arrayWithCapacity:22];
    for (int i = 0; i < 22; i++) {
        [eventTypes addObject:@(i)];
    }
    
    NSArray *hashes = [self hashedEventTypes:eventTypes];
    return hashes;
}

- (void)testHashAllEventTypes {
    NSString *hashedEventType;
    
    NSArray *hashedEventTypes = [self hashedAllEventTypes];
    
    hashedEventType = hashedEventTypes[MPEventTypeNavigation];
    XCTAssertEqualObjects(hashedEventType, @"49", @"Hashed event type navigation is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeLocation];
    XCTAssertEqualObjects(hashedEventType, @"50", @"Hashed event type location is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeSearch];
    XCTAssertEqualObjects(hashedEventType, @"51", @"Hashed event type search is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeTransaction];
    XCTAssertEqualObjects(hashedEventType, @"52", @"Hashed event type transaction is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeUserContent];
    XCTAssertEqualObjects(hashedEventType, @"53", @"Hashed event type user content is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeUserPreference];
    XCTAssertEqualObjects(hashedEventType, @"54", @"Hashed event type user preference is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeSocial];
    XCTAssertEqualObjects(hashedEventType, @"55", @"Hashed event type social is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeOther];
    XCTAssertEqualObjects(hashedEventType, @"56", @"Hashed event type other is incorrect.");
}

- (void)testHashSomeEventTypes {
    NSArray *eventTypes = [NSArray array];
    NSArray *hashedEventTypes = [self hashedEventTypes:eventTypes];
    XCTAssertTrue(hashedEventTypes.count == 0, @"Should have been empty.");
    
    eventTypes = @[@(MPEventTypeNavigation), @(MPEventTypeTransaction), @(MPEventTypeOther)];
    hashedEventTypes = [self hashedEventTypes:eventTypes];
    
    XCTAssertTrue([hashedEventTypes containsObject:@"49"], @"Not hashing event type navigation.");
    XCTAssertTrue([hashedEventTypes containsObject:@"52"], @"Not hashing event type transaction.");
    XCTAssertTrue([hashedEventTypes containsObject:@"56"], @"Not hashing event type other.");
}

- (void)testRampHash {
    NSString *rampString = @"E1492888-3B7C-4FB2-98A5-6C483BF9EBEB";
    NSData *rampData = [rampString dataUsingEncoding:NSUTF8StringEncoding];
    int64_t rampHash = [hasher hashFNV1a:rampData];
    
    XCTAssertEqual(rampHash, -1177587625323713153, @"Ramp hash is being calculated incorrectly.");
}

- (void)testNegativeSessionIDHash {
    NSString *sessionUUID = @"76F1ABB9-7A9A-4D4E-AB4D-56C8FF79CAD1";
    int64_t sessionID = [hasher hashStringUTF16:sessionUUID].integerValue;
    
    XCTAssertEqual(sessionID, -6881666186511944082, @"Negative Session ID hash is being calculated incorrectly.");
}

- (void)testPositiveSessionIDHash {
    NSString *sessionUUID = @"222F6BEA-F6A8-4DFC-A950-744EFD6FEC3D";
    int64_t sessionID = [hasher hashStringUTF16:sessionUUID].integerValue;
    
    XCTAssertEqual(sessionID, 7868951891731938297, @"Positive Session ID hash is being calculated incorrectly.");
}

- (void)testOverflowSessionIDHash {
    NSString *sessionUUID = @"B469F3A1-79B6-4E83-823A-53CFC41C3880";
    int64_t sessionID = [hasher hashStringUTF16:sessionUUID].integerValue;
    
    XCTAssertEqual(sessionID, -5269132687922921892, @"Overflow Session ID hash is being calculated incorrectly.");
}

- (void)testEventTypeHash {
    NSString *hashString = @"49";
    MPEventType eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeNavigation, @"Should have been equal.");
    
    hashString = @"50";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeLocation, @"Should have been equal.");
    
    hashString = @"51";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSearch, @"Should have been equal.");
    
    hashString = @"52";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeTransaction, @"Should have been equal.");
    
    hashString = @"53";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeUserContent, @"Should have been equal.");
    
    hashString = @"54";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeUserPreference, @"Should have been equal.");
    
    hashString = @"55";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSocial, @"Should have been equal.");
    
    hashString = @"56";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeOther, @"Should have been equal.");
    
    hashString = @"1567";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeAddToCart, @"Should have been equal.");
    
    hashString = @"1568";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeRemoveFromCart, @"Should have been equal.");
    
    hashString = @"1569";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeCheckout, @"Should have been equal.");
    
    hashString = @"1570";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeCheckoutOption, @"Should have been equal.");
    
    hashString = @"1571";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeClick, @"Should have been equal.");
    
    hashString = @"1572";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeViewDetail, @"Should have been equal.");
    
    hashString = @"1573";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypePurchase, @"Should have been equal.");
    
    hashString = @"1574";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeRefund, @"Should have been equal.");
    
    hashString = @"1575";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypePromotionView, @"Should have been equal.");
    
    hashString = @"1576";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypePromotionClick, @"Should have been equal.");
    
    hashString = @"1598";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeAddToWishlist, @"Should have been equal.");
    
    hashString = @"1599";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeRemoveFromWishlist, @"Should have been equal.");
    
    hashString = @"1600";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeImpression, @"Should have been equal.");
    
    hashString = @"Invalid hash";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeOther, @"Should have been equal.");
}

- (void)testHashEventType {
    NSString *hashTestString = [hasher hashEventType:MPEventTypeNavigation];

    XCTAssertEqualObjects(hashTestString, @"49", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeLocation];
    XCTAssertEqualObjects(hashTestString, @"50", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSearch];
    XCTAssertEqualObjects(hashTestString, @"51", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeTransaction];
    XCTAssertEqualObjects(hashTestString, @"52", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeUserContent];
    XCTAssertEqualObjects(hashTestString, @"53", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeUserPreference];
    XCTAssertEqualObjects(hashTestString, @"54", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSocial];
    XCTAssertEqualObjects(hashTestString, @"55", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeOther];
    XCTAssertEqualObjects(hashTestString, @"56", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeMedia];
    XCTAssertEqualObjects(hashTestString, @"57", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeAddToCart];
    XCTAssertEqualObjects(hashTestString, @"1567", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeRemoveFromCart];
    XCTAssertEqualObjects(hashTestString, @"1568", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeCheckout];
    XCTAssertEqualObjects(hashTestString, @"1569", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeCheckoutOption];
    XCTAssertEqualObjects(hashTestString, @"1570", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeClick];
    XCTAssertEqualObjects(hashTestString, @"1571", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeViewDetail];
    XCTAssertEqualObjects(hashTestString, @"1572", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypePurchase];
    XCTAssertEqualObjects(hashTestString, @"1573", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeRefund];
    XCTAssertEqualObjects(hashTestString, @"1574", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypePromotionView];
    XCTAssertEqualObjects(hashTestString, @"1575", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypePromotionClick];
    XCTAssertEqualObjects(hashTestString, @"1576", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeAddToWishlist];
    XCTAssertEqualObjects(hashTestString, @"1598", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeRemoveFromWishlist];
    XCTAssertEqualObjects(hashTestString, @"1599", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeImpression];
    XCTAssertEqualObjects(hashTestString, @"1600", @"Should have been equal.");
}

- (void)testHashEventName {
    NSString *hashTestString = [hasher hashEventType:MPEventTypeNavigation eventName:@"test" isLogScreen:false];
    XCTAssertEqualObjects(hashTestString, @"48809027", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeNavigation eventName:@"test" isLogScreen:true];
    XCTAssertEqualObjects(hashTestString, @"47885506", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeLocation eventName:@"test" isLogScreen:false];
    XCTAssertEqualObjects(hashTestString, @"49732548", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeLocation eventName:@"test" isLogScreen:true];
    XCTAssertEqualObjects(hashTestString, @"47885506", @"Should have been equal.");
}

- (void)testHashEventAttributeKey {
    NSString *hashTestString = [hasher hashEventAttributeKey:MPEventTypeNavigation eventName:@"test" customAttributeName:@"testAtt" isLogScreen:false];
    XCTAssertEqualObjects(hashTestString, @"-1449619668", @"Should have been equal.");
    
    hashTestString = [hasher hashEventAttributeKey:MPEventTypeNavigation eventName:@"test" customAttributeName:@"testAtt" isLogScreen:true];
    XCTAssertEqualObjects(hashTestString, @"-1578702387", @"Should have been equal.");
    
    hashTestString = [hasher hashEventAttributeKey:MPEventTypeLocation eventName:@"test" customAttributeName:@"testAtt" isLogScreen:false];
    XCTAssertEqualObjects(hashTestString, @"-1320536949", @"Should have been equal.");
    
    hashTestString = [hasher hashEventAttributeKey:MPEventTypeLocation eventName:@"test" customAttributeName:@"testAtt" isLogScreen:true];
    XCTAssertEqualObjects(hashTestString, @"-1578702387", @"Should have been equal.");
}

- (void)testHashUserAttributeKeyAndValue {
    NSString *hashTestString = [hasher hashUserAttributeKey:@"key1"];
    XCTAssertEqualObjects(hashTestString, @"3288498", @"Should have been equal.");
    
    hashTestString = [hasher hashUserAttributeKey:@"key2"];
    XCTAssertEqualObjects(hashTestString, @"3288499", @"Should have been equal.");
    
    hashTestString = [hasher hashUserAttributeValue:@"value1"];
    XCTAssertEqualObjects(hashTestString, @"-823812896", @"Should have been equal.");
    
    hashTestString = [hasher hashUserAttributeValue:@"value2"];
    XCTAssertEqualObjects(hashTestString, @"-823812895", @"Should have been equal.");
}

- (void)testHashUserIdentity {
    NSString *hashTestString = [hasher hashUserIdentity:MPUserIdentityOther];
    XCTAssertEqualObjects(hashTestString, @"0", @"Should have been equal.");
    
    hashTestString = [hasher hashUserIdentity:MPUserIdentityCustomerId];
    XCTAssertEqualObjects(hashTestString, @"1", @"Should have been equal.");
}

- (void)testHashConsentPurpose {
    NSString *hashTestString = [hasher hashConsentPurpose:kMPConsentCCPARegulationType purpose:kMPConsentCCPAPurposeName];
    XCTAssertEqualObjects(hashTestString, @"-575335347", @"Should have been equal.");
    
    hashTestString = [hasher hashConsentPurpose:kMPConsentGDPRRegulationType purpose:@""];
    XCTAssertEqualObjects(hashTestString, @"49", @"Should have been equal.");
    
    hashTestString = [hasher hashConsentPurpose:kMPConsentGDPRRegulationType purpose:@"purpose1"];
    XCTAssertEqualObjects(hashTestString, @"-910367228", @"Should have been equal.");
}

- (void)testHashCommerceEventAttribute {
    NSString *hashTestString = [hasher hashCommerceEventAttribute:MPEventTypePurchase key:@"price"];
    XCTAssertEqualObjects(hashTestString, @"-2104051132", @"Should have been equal.");
    
    hashTestString = [hasher hashCommerceEventAttribute:MPEventTypeRefund key:@"price"];
    XCTAssertEqualObjects(hashTestString, @"-2075421981", @"Should have been equal.");
}

- (void)testHashTriggerEvent {
    NSString *hashedEvent = [hasher hashTriggerEventName:@"Loaded screen" eventType:@"Navigation"];
    XCTAssertEqualObjects(hashedEvent, @"431828539", @"Should have been equal.");
}

- (void)testHashDifferences {
    // Creates a product object
    MPProduct *product = [[MPProduct alloc] initWithName:@"Awesome Book" sku:@"1234567890" quantity:@1 price:@9.99];
    product.brand = @"A Publisher";
    product.category = @"Fiction";
    product.couponCode = @"XYZ123";
    product.position = 1;
    product[@"custom key"] = @"custom value"; // A product may contain custom key/value pairs
    
    // Creates a commerce event object
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    NSString *key = @"an_extra_key";
    commerceEvent.customAttributes = @{key: @"an_extra_value"}; // A commerce event may contain custom key/value pairs
    
    NSString *attributeTohash = [[@(commerceEvent.type) stringValue] stringByAppendingString:key];
    int hashValueOldInt = [[hasher hashString:attributeTohash] intValue];
    
    NSString *hashValueNewString = [hasher hashCommerceEventAttribute:commerceEvent.type key:key];
    XCTAssertEqual(hashValueOldInt, [hashValueNewString intValue], @"Should have been equal.");

}

@end

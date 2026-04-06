#import <XCTest/XCTest.h>
@import mParticle_Apple_SDK_Swift;

@interface HasherTests : XCTestCase

@end

@implementation HasherTests

MPIHasher* hasher;

- (void)setUp {
    [super setUp];
    MPLog* logger = [[MPLog alloc] initWithLogLevel:MPILogLevelSwiftDebug];
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
    
    hashedEventType = hashedEventTypes[MPEventTypeSwiftNavigation];
    XCTAssertEqualObjects(hashedEventType, @"49", @"Hashed event type navigation is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeSwiftLocation];
    XCTAssertEqualObjects(hashedEventType, @"50", @"Hashed event type location is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeSwiftSearch];
    XCTAssertEqualObjects(hashedEventType, @"51", @"Hashed event type search is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeSwiftTransaction];
    XCTAssertEqualObjects(hashedEventType, @"52", @"Hashed event type transaction is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeSwiftUserContent];
    XCTAssertEqualObjects(hashedEventType, @"53", @"Hashed event type user content is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeSwiftUserPreference];
    XCTAssertEqualObjects(hashedEventType, @"54", @"Hashed event type user preference is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeSwiftSocial];
    XCTAssertEqualObjects(hashedEventType, @"55", @"Hashed event type social is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeSwiftOther];
    XCTAssertEqualObjects(hashedEventType, @"56", @"Hashed event type other is incorrect.");
}

- (void)testHashSomeEventTypes {
    NSArray *eventTypes = [NSArray array];
    NSArray *hashedEventTypes = [self hashedEventTypes:eventTypes];
    XCTAssertTrue(hashedEventTypes.count == 0, @"Should have been empty.");
    
    eventTypes = @[@(MPEventTypeSwiftNavigation), @(MPEventTypeSwiftTransaction), @(MPEventTypeSwiftOther)];
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
    MPEventTypeSwift eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftNavigation, @"Should have been equal.");
    
    hashString = @"50";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftLocation, @"Should have been equal.");
    
    hashString = @"51";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftSearch, @"Should have been equal.");
    
    hashString = @"52";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftTransaction, @"Should have been equal.");
    
    hashString = @"53";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftUserContent, @"Should have been equal.");
    
    hashString = @"54";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftUserPreference, @"Should have been equal.");
    
    hashString = @"55";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftSocial, @"Should have been equal.");
    
    hashString = @"56";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftOther, @"Should have been equal.");
    
    hashString = @"1567";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftAddToCart, @"Should have been equal.");
    
    hashString = @"1568";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftRemoveFromCart, @"Should have been equal.");
    
    hashString = @"1569";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftCheckout, @"Should have been equal.");
    
    hashString = @"1570";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftCheckoutOption, @"Should have been equal.");
    
    hashString = @"1571";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftClick, @"Should have been equal.");
    
    hashString = @"1572";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftViewDetail, @"Should have been equal.");
    
    hashString = @"1573";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftPurchase, @"Should have been equal.");
    
    hashString = @"1574";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftRefund, @"Should have been equal.");
    
    hashString = @"1575";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftPromotionView, @"Should have been equal.");
    
    hashString = @"1576";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftPromotionClick, @"Should have been equal.");
    
    hashString = @"1598";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftAddToWishlist, @"Should have been equal.");
    
    hashString = @"1599";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftRemoveFromWishlist, @"Should have been equal.");
    
    hashString = @"1600";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftImpression, @"Should have been equal.");
    
    hashString = @"Invalid hash";
    eventType = [hasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSwiftOther, @"Should have been equal.");
}

- (void)testHashEventType {
    NSString *hashTestString = [hasher hashEventType:MPEventTypeSwiftNavigation];

    XCTAssertEqualObjects(hashTestString, @"49", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftLocation];
    XCTAssertEqualObjects(hashTestString, @"50", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftSearch];
    XCTAssertEqualObjects(hashTestString, @"51", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftTransaction];
    XCTAssertEqualObjects(hashTestString, @"52", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftUserContent];
    XCTAssertEqualObjects(hashTestString, @"53", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftUserPreference];
    XCTAssertEqualObjects(hashTestString, @"54", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftSocial];
    XCTAssertEqualObjects(hashTestString, @"55", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftOther];
    XCTAssertEqualObjects(hashTestString, @"56", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftMedia];
    XCTAssertEqualObjects(hashTestString, @"57", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftAddToCart];
    XCTAssertEqualObjects(hashTestString, @"1567", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftRemoveFromCart];
    XCTAssertEqualObjects(hashTestString, @"1568", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftCheckout];
    XCTAssertEqualObjects(hashTestString, @"1569", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftCheckoutOption];
    XCTAssertEqualObjects(hashTestString, @"1570", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftClick];
    XCTAssertEqualObjects(hashTestString, @"1571", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftViewDetail];
    XCTAssertEqualObjects(hashTestString, @"1572", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftPurchase];
    XCTAssertEqualObjects(hashTestString, @"1573", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftRefund];
    XCTAssertEqualObjects(hashTestString, @"1574", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftPromotionView];
    XCTAssertEqualObjects(hashTestString, @"1575", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftPromotionClick];
    XCTAssertEqualObjects(hashTestString, @"1576", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftAddToWishlist];
    XCTAssertEqualObjects(hashTestString, @"1598", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftRemoveFromWishlist];
    XCTAssertEqualObjects(hashTestString, @"1599", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftImpression];
    XCTAssertEqualObjects(hashTestString, @"1600", @"Should have been equal.");
}

- (void)testHashEventName {
    NSString *hashTestString = [hasher hashEventType:MPEventTypeSwiftNavigation eventName:@"test" isLogScreen:false];
    XCTAssertEqualObjects(hashTestString, @"48809027", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftNavigation eventName:@"test" isLogScreen:true];
    XCTAssertEqualObjects(hashTestString, @"47885506", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftLocation eventName:@"test" isLogScreen:false];
    XCTAssertEqualObjects(hashTestString, @"49732548", @"Should have been equal.");
    
    hashTestString = [hasher hashEventType:MPEventTypeSwiftLocation eventName:@"test" isLogScreen:true];
    XCTAssertEqualObjects(hashTestString, @"47885506", @"Should have been equal.");
}

- (void)testHashEventAttributeKey {
    NSString *hashTestString = [hasher hashEventAttributeKey:MPEventTypeSwiftNavigation eventName:@"test" customAttributeName:@"testAtt" isLogScreen:false];
    XCTAssertEqualObjects(hashTestString, @"-1449619668", @"Should have been equal.");
    
    hashTestString = [hasher hashEventAttributeKey:MPEventTypeSwiftNavigation eventName:@"test" customAttributeName:@"testAtt" isLogScreen:true];
    XCTAssertEqualObjects(hashTestString, @"-1578702387", @"Should have been equal.");
    
    hashTestString = [hasher hashEventAttributeKey:MPEventTypeSwiftLocation eventName:@"test" customAttributeName:@"testAtt" isLogScreen:false];
    XCTAssertEqualObjects(hashTestString, @"-1320536949", @"Should have been equal.");
    
    hashTestString = [hasher hashEventAttributeKey:MPEventTypeSwiftLocation eventName:@"test" customAttributeName:@"testAtt" isLogScreen:true];
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
    NSString *hashTestString = [hasher hashUserIdentity:MPUserIdentitySwiftOther];
    XCTAssertEqualObjects(hashTestString, @"0", @"Should have been equal.");
    
    hashTestString = [hasher hashUserIdentity:MPUserIdentitySwiftCustomerId];
    XCTAssertEqualObjects(hashTestString, @"1", @"Should have been equal.");
}

- (void)testHashConsentPurpose {
    NSString *hashTestString = [hasher hashConsentPurpose:ConsentFilteringSwift.kMPConsentCCPARegulationType purpose:ConsentFilteringSwift.kMPConsentCCPAPurposeName];
    XCTAssertEqualObjects(hashTestString, @"-575335347", @"Should have been equal.");
    
    hashTestString = [hasher hashConsentPurpose:ConsentFilteringSwift.kMPConsentGDPRRegulationType purpose:@""];
    XCTAssertEqualObjects(hashTestString, @"49", @"Should have been equal.");
    
    hashTestString = [hasher hashConsentPurpose:ConsentFilteringSwift.kMPConsentGDPRRegulationType purpose:@"purpose1"];
    XCTAssertEqualObjects(hashTestString, @"-910367228", @"Should have been equal.");
}

- (void)testHashCommerceEventAttribute {
    NSString *hashTestString = [hasher hashCommerceEventAttribute:MPEventTypeSwiftPurchase key:@"price"];
    XCTAssertEqualObjects(hashTestString, @"-2104051132", @"Should have been equal.");
    
    hashTestString = [hasher hashCommerceEventAttribute:MPEventTypeSwiftRefund key:@"price"];
    XCTAssertEqualObjects(hashTestString, @"-2075421981", @"Should have been equal.");
}

- (void)testHashTriggerEvent {
    NSString *hashedEvent = [hasher hashTriggerEventName:@"Loaded screen" eventType:@"Navigation"];
    XCTAssertEqualObjects(hashedEvent, @"431828539", @"Should have been equal.");
}

- (void)testHashDifferences {
    NSString *key = @"an_extra_key";
    NSInteger MPEventTypePurchase = 16;

    NSString *attr = [@(MPEventTypePurchase).stringValue stringByAppendingString:key];
    XCTAssertEqual([[hasher hashString:attr] intValue],
                   [[hasher hashCommerceEventAttribute:MPEventTypePurchase key:key] intValue]);
}

@end

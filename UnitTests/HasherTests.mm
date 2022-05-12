#import <XCTest/XCTest.h>
#import "MPHasher.h"
#import "MPEnums.h"
#import "MPEvent.h"
#import "MPBaseTestCase.h"
#import "MPIHasher.h"

@interface HasherTests : MPBaseTestCase

@end

@implementation HasherTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testHashingString {
    NSString *referenceString = @"The Quick Brown Fox Jumps Over the Lazy Dog.";
    NSString *hashedString = [NSString stringWithCString:mParticle::Hasher::hashString([[referenceString lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                                encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(hashedString, @"-142870245", @"Hasher is not hashing strings properly.");
    
    referenceString = @"";
    hashedString = [NSString stringWithCString:mParticle::Hasher::hashString([referenceString cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                      encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(hashedString, @"", @"Hashing an empty string.");
    
    int hash = mParticle::Hasher::hashFromString("");
    XCTAssertEqual(hash, 0, @"Should have been equal.");
    
    std::string hashedEvent = mParticle::Hasher::hashEvent("Loaded screen", "Navigation");
    XCTAssertEqual(hashedEvent, "431828539", @"Should have been equal.");
}

- (void)testHashingPerformance {
    [self measureBlock:^{
        NSString *referenceString = @"The Quick Brown Fox Jumps Over the Lazy Dog.";
        mParticle::Hasher::hashString([referenceString cStringUsingEncoding:NSUTF8StringEncoding]);
    }];
}

- (void)testHashAllEventTypes {
    NSString *hashedEventType;
    
    vector<string> hashedAllEventTypes = mParticle::Hasher::hashedAllEventTypes();
    NSMutableArray *mHashedEventTypes = [[NSMutableArray alloc] initWithCapacity:hashedAllEventTypes.size()];
    
    for_each(hashedAllEventTypes.begin(), hashedAllEventTypes.end(),
             [&mHashedEventTypes](string str) {
                 NSString *nsstr = [NSString stringWithUTF8String:str.c_str()];
                 [mHashedEventTypes addObject:nsstr];
             });
    
    NSArray *hashedEventTypes = (NSArray *)mHashedEventTypes;
    
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
    vector<int> eventTypes;
    vector<string> hashedAllEventTypes = mParticle::Hasher::hashedEventTypes(eventTypes);
    XCTAssertTrue(hashedAllEventTypes.empty(), @"Should have been empty.");

    eventTypes = {MPEventTypeNavigation, MPEventTypeTransaction, MPEventTypeOther};
    hashedAllEventTypes = mParticle::Hasher::hashedEventTypes(eventTypes);
    NSMutableArray *mHashedEventTypes = [[NSMutableArray alloc] initWithCapacity:hashedAllEventTypes.size()];
    
    for_each(hashedAllEventTypes.begin(), hashedAllEventTypes.end(),
             [&mHashedEventTypes](string str) {
                 NSString *nsstr = [NSString stringWithUTF8String:str.c_str()];
                 [mHashedEventTypes addObject:nsstr];
             });
    
    NSArray *hashedEventTypes = (NSArray *)mHashedEventTypes;
    
    XCTAssertTrue([hashedEventTypes containsObject:@"49"], @"Not hashing event type navigation.");
    XCTAssertTrue([hashedEventTypes containsObject:@"52"], @"Not hashing event type transaction.");
    XCTAssertTrue([hashedEventTypes containsObject:@"56"], @"Not hashing event type other.");
}

- (void)testRampHash {
    NSString *rampString = @"E1492888-3B7C-4FB2-98A5-6C483BF9EBEB";
    NSData *rampData = [rampString dataUsingEncoding:NSUTF8StringEncoding];
    int64_t rampHash = mParticle::Hasher::hashFNV1a((const char *)[rampData bytes], (int)[rampData length]);
    
    XCTAssertEqual(rampHash, -1177587625323713153, @"Ramp hash is being calculated incorrectly.");
}

- (void)testNegativeSessionIDHash {
    NSString *sessionUUID = @"76F1ABB9-7A9A-4D4E-AB4D-56C8FF79CAD1";
    int64_t sessionID = [MPIHasher hashStringUTF16:sessionUUID].integerValue;
    
    XCTAssertEqual(sessionID, -6881666186511944082, @"Negative Session ID hash is being calculated incorrectly.");
}

- (void)testPositiveSessionIDHash {
    NSString *sessionUUID = @"222F6BEA-F6A8-4DFC-A950-744EFD6FEC3D";
    int64_t sessionID = [MPIHasher hashStringUTF16:sessionUUID].integerValue;
    
    XCTAssertEqual(sessionID, 7868951891731938297, @"Positive Session ID hash is being calculated incorrectly.");
}

- (void)testOverflowSessionIDHash {
    NSString *sessionUUID = @"B469F3A1-79B6-4E83-823A-53CFC41C3880";
    int64_t sessionID = [MPIHasher hashStringUTF16:sessionUUID].integerValue;
    
    XCTAssertEqual(sessionID, -5269132687922921892, @"Overflow Session ID hash is being calculated incorrectly.");
}

- (void)testEventTypeHash {
    NSString *hashString = @"49";
    MPEventType eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeNavigation, @"Should have been equal.");
    
    hashString = @"50";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeLocation, @"Should have been equal.");
    
    hashString = @"51";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSearch, @"Should have been equal.");
    
    hashString = @"52";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeTransaction, @"Should have been equal.");
    
    hashString = @"53";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeUserContent, @"Should have been equal.");
    
    hashString = @"54";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeUserPreference, @"Should have been equal.");
    
    hashString = @"55";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeSocial, @"Should have been equal.");
    
    hashString = @"56";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeOther, @"Should have been equal.");
    
    hashString = @"1567";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeAddToCart, @"Should have been equal.");
    
    hashString = @"1568";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeRemoveFromCart, @"Should have been equal.");
    
    hashString = @"1569";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeCheckout, @"Should have been equal.");
    
    hashString = @"1570";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeCheckoutOption, @"Should have been equal.");
    
    hashString = @"1571";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeClick, @"Should have been equal.");
    
    hashString = @"1572";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeViewDetail, @"Should have been equal.");
    
    hashString = @"1573";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypePurchase, @"Should have been equal.");
    
    hashString = @"1574";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeRefund, @"Should have been equal.");
    
    hashString = @"1575";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypePromotionView, @"Should have been equal.");
    
    hashString = @"1576";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypePromotionClick, @"Should have been equal.");
    
    hashString = @"1598";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeAddToWishlist, @"Should have been equal.");
    
    hashString = @"1599";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeRemoveFromWishlist, @"Should have been equal.");
    
    hashString = @"1600";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeImpression, @"Should have been equal.");
    
    hashString = @"Invalid hash";
    eventType = [MPIHasher eventTypeForHash:hashString];
    XCTAssertEqual(eventType, MPEventTypeOther, @"Should have been equal.");
}

- (void)testHashEventType {
    NSString *hashTestString = [MPIHasher hashEventType:MPEventTypeNavigation];

    XCTAssertEqualObjects(hashTestString, @"49", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeLocation];
    XCTAssertEqualObjects(hashTestString, @"50", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeSearch];
    XCTAssertEqualObjects(hashTestString, @"51", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeTransaction];
    XCTAssertEqualObjects(hashTestString, @"52", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeUserContent];
    XCTAssertEqualObjects(hashTestString, @"53", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeUserPreference];
    XCTAssertEqualObjects(hashTestString, @"54", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeSocial];
    XCTAssertEqualObjects(hashTestString, @"55", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeOther];
    XCTAssertEqualObjects(hashTestString, @"56", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeMedia];
    XCTAssertEqualObjects(hashTestString, @"57", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeAddToCart];
    XCTAssertEqualObjects(hashTestString, @"1567", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeRemoveFromCart];
    XCTAssertEqualObjects(hashTestString, @"1568", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeCheckout];
    XCTAssertEqualObjects(hashTestString, @"1569", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeCheckoutOption];
    XCTAssertEqualObjects(hashTestString, @"1570", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeClick];
    XCTAssertEqualObjects(hashTestString, @"1571", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeViewDetail];
    XCTAssertEqualObjects(hashTestString, @"1572", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypePurchase];
    XCTAssertEqualObjects(hashTestString, @"1573", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeRefund];
    XCTAssertEqualObjects(hashTestString, @"1574", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypePromotionView];
    XCTAssertEqualObjects(hashTestString, @"1575", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypePromotionClick];
    XCTAssertEqualObjects(hashTestString, @"1576", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeAddToWishlist];
    XCTAssertEqualObjects(hashTestString, @"1598", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeRemoveFromWishlist];
    XCTAssertEqualObjects(hashTestString, @"1599", @"Should have been equal.");
    
    hashTestString = [MPIHasher hashEventType:MPEventTypeImpression];
    XCTAssertEqualObjects(hashTestString, @"1600", @"Should have been equal.");
}

@end

#import <XCTest/XCTest.h>
#import "MPHasher.h"
#import "MPEnums.h"
#import "MPEvent.h"
#import "EventTypeName.h"

@interface HasherTests : XCTestCase

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
    XCTAssertEqual(hashedEvent, "1247535675", @"Should have been equal.");
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
    uint64_t rampHash = mParticle::Hasher::hashFNV1a((const char *)[rampData bytes], (int)[rampData length]);
    
    XCTAssertEqual(rampHash, 8288906072899054792, @"Ramp hash is being calculated incorrectly.");
}

- (void)testEventTypeHash {
    NSString *hashString = @"49";
    MPEventType eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeNavigation, @"Should have been equal.");
    
    hashString = @"50";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeLocation, @"Should have been equal.");
    
    hashString = @"51";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeSearch, @"Should have been equal.");
    
    hashString = @"52";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeTransaction, @"Should have been equal.");
    
    hashString = @"53";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeUserContent, @"Should have been equal.");
    
    hashString = @"54";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeUserPreference, @"Should have been equal.");
    
    hashString = @"55";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeSocial, @"Should have been equal.");
    
    hashString = @"56";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeOther, @"Should have been equal.");
    
    hashString = @"1567";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeAddToCart, @"Should have been equal.");
    
    hashString = @"1568";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeRemoveFromCart, @"Should have been equal.");
    
    hashString = @"1569";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeCheckout, @"Should have been equal.");
    
    hashString = @"1570";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeCheckoutOption, @"Should have been equal.");
    
    hashString = @"1571";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeClick, @"Should have been equal.");
    
    hashString = @"1572";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeViewDetail, @"Should have been equal.");
    
    hashString = @"1573";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypePurchase, @"Should have been equal.");
    
    hashString = @"1574";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeRefund, @"Should have been equal.");
    
    hashString = @"1575";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypePromotionView, @"Should have been equal.");
    
    hashString = @"1576";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypePromotionClick, @"Should have been equal.");
    
    hashString = @"1598";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeAddToWishlist, @"Should have been equal.");
    
    hashString = @"1599";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeRemoveFromWishlist, @"Should have been equal.");
    
    hashString = @"1600";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeImpression, @"Should have been equal.");
    
    hashString = @"Invalid hash";
    eventType = (MPEventType)mParticle::EventTypeName::eventTypeForHash(string([hashString cStringUsingEncoding:NSUTF8StringEncoding]));
    XCTAssertEqual(eventType, MPEventTypeOther, @"Should have been equal.");
}

- (void)testHashEventType {
    std::string hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::Navigation);
    XCTAssertEqual(hashString, "49", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::Location);
    XCTAssertEqual(hashString, "50", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::Search);
    XCTAssertEqual(hashString, "51", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::Transaction);
    XCTAssertEqual(hashString, "52", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::Content);
    XCTAssertEqual(hashString, "53", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::Preference);
    XCTAssertEqual(hashString, "54", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::Social);
    XCTAssertEqual(hashString, "55", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::Other);
    XCTAssertEqual(hashString, "56", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::AddToCart);
    XCTAssertEqual(hashString, "1567", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::RemoveFromCart);
    XCTAssertEqual(hashString, "1568", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::Checkout);
    XCTAssertEqual(hashString, "1569", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::CheckoutOption);
    XCTAssertEqual(hashString, "1570", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::Click);
    XCTAssertEqual(hashString, "1571", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::ViewDetail);
    XCTAssertEqual(hashString, "1572", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::Purchase);
    XCTAssertEqual(hashString, "1573", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::Refund);
    XCTAssertEqual(hashString, "1574", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::PromotionView);
    XCTAssertEqual(hashString, "1575", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::PromotionClick);
    XCTAssertEqual(hashString, "1576", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::AddToWishlist);
    XCTAssertEqual(hashString, "1598", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::RemoveFromWishlist);
    XCTAssertEqual(hashString, "1599", @"Should have been equal.");
    
    hashString = mParticle::EventTypeName::hashForEventType(mParticle::EventType::Impression);
    XCTAssertEqual(hashString, "1600", @"Should have been equal.");
}

@end

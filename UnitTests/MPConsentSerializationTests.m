#import <XCTest/XCTest.h>
#import "MPConsentSerialization.h"
#import "MPConsentState.h"
#import "MPGDPRConsent.h"
#import "MPConsentKitFilter.h"
#import "MPBaseTestCase.h"

static NSTimeInterval epsilon = 0.05;

@interface MPConsentSerialization ()

+ (nullable NSDictionary *)dictionaryFromString:(NSString *)string;

@end

@interface MPConsentSerializationTests : MPBaseTestCase

@end

@implementation MPConsentSerializationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testServerDictionary {
    MPConsentState *consentState = nil;
    NSDictionary *dictionary = nil;
    
    dictionary = [MPConsentSerialization serverDictionaryFromConsentState:consentState];
    XCTAssertNotNil(dictionary);
    XCTAssertEqual(dictionary.count, 0);
    
    consentState = [[MPConsentState alloc] init];
    dictionary = [MPConsentSerialization serverDictionaryFromConsentState:consentState];
    XCTAssertNotNil(dictionary);
    XCTAssertEqual(dictionary.count, 0);
    
    NSDate *date = [NSDate date];
    
    MPGDPRConsent *gdprConsent = [[MPGDPRConsent alloc] init];
    gdprConsent.consented = YES;
    gdprConsent.document = @"foo-document-1";
    gdprConsent.timestamp = date;
    gdprConsent.location = @"foo-location-1";
    gdprConsent.hardwareId = @"foo-hardware-id-1";
    
    [consentState addGDPRConsentState:gdprConsent purpose:@"test purpose 1"];
    dictionary = [MPConsentSerialization serverDictionaryFromConsentState:consentState];
    XCTAssertNotNil(dictionary);
    XCTAssertEqual(dictionary.count, 1);
    
    NSDictionary *gdprDictionary = dictionary[@"gdpr"];
    XCTAssertNotNil(gdprDictionary);
    XCTAssertEqual(gdprDictionary.count, 1);
    
    NSDictionary *gdprStateDictionary = gdprDictionary[@"test purpose 1"];
    XCTAssertNotNil(gdprStateDictionary);
    XCTAssertEqual(gdprStateDictionary.count, 5);
    
    XCTAssertEqualObjects(gdprStateDictionary[@"c"], @YES);
    XCTAssertEqualObjects(gdprStateDictionary[@"d"], @"foo-document-1");
    XCTAssertEqualObjects(gdprStateDictionary[@"l"], @"foo-location-1");
    XCTAssertEqualObjects(gdprStateDictionary[@"h"], @"foo-hardware-id-1");
    XCTAssertNotNil(gdprStateDictionary[@"ts"]);
    double interval = ((NSNumber *)gdprStateDictionary[@"ts"]).doubleValue/1000;
    XCTAssertLessThan([NSDate dateWithTimeIntervalSince1970:interval].timeIntervalSinceNow, epsilon);
}

- (void)testToString {
    MPConsentState *consentState = nil;
    NSString *string = nil;
    NSDictionary *dictionary = nil;
    
    string = [MPConsentSerialization stringFromConsentState:consentState];
    XCTAssertNil(string);
    
    consentState = [[MPConsentState alloc] init];
    string = [MPConsentSerialization stringFromConsentState:consentState];
    XCTAssertNil(string);
    
    NSDate *date = [NSDate date];
    
    MPGDPRConsent *gdprConsent = [[MPGDPRConsent alloc] init];
    gdprConsent.consented = YES;
    gdprConsent.document = @"foo-document-1";
    gdprConsent.timestamp = date;
    gdprConsent.location = @"foo-location-1";
    gdprConsent.hardwareId = @"foo-hardware-id-1";
    
    [consentState addGDPRConsentState:gdprConsent purpose:@"test purpose 1"];
    string = [MPConsentSerialization stringFromConsentState:consentState];
    XCTAssertNotNil(string);
    
    dictionary = [MPConsentSerialization dictionaryFromString:string];
    XCTAssertNotNil(dictionary);
    XCTAssertEqual(dictionary.count, 1);
    
    NSDictionary *gdprDictionary = dictionary[@"gdpr"];
    XCTAssertNotNil(gdprDictionary);
    XCTAssertEqual(gdprDictionary.count, 1);
    
    NSDictionary *gdprStateDictionary = gdprDictionary[@"test purpose 1"];
    XCTAssertNotNil(gdprStateDictionary);
    XCTAssertEqual(gdprStateDictionary.count, 5);
    
    XCTAssertEqualObjects(gdprStateDictionary[@"consented"], @YES);
    XCTAssertEqualObjects(gdprStateDictionary[@"document"], @"foo-document-1");
    XCTAssertEqualObjects(gdprStateDictionary[@"location"], @"foo-location-1");
    XCTAssertEqualObjects(gdprStateDictionary[@"hardware_id"], @"foo-hardware-id-1");
    XCTAssertNotNil(gdprStateDictionary[@"timestamp"]);
    NSNumber *timestampNumber = gdprStateDictionary[@"timestamp"];
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:(timestampNumber.intValue/1000)];
    XCTAssertLessThan(timestamp.timeIntervalSinceNow, epsilon);
}

- (void)testFromString {
    NSString *string = @"{\"gdpr\":{\"test purpose 1\":{\"document\":\"foo-document-1\",\"consented\":true,\"timestamp\":1524176880.888195,\"hardware_id\":\"foo-hardware-id-1\",\"location\":\"foo-location-1\"}}}";
    MPConsentState *state = [MPConsentSerialization consentStateFromString:string];
    NSDictionary<NSString *, MPGDPRConsent *> *gdprStateDictionary = [state gdprConsentState];
    XCTAssertEqual(gdprStateDictionary.count, 1);
    MPGDPRConsent *gdprState = gdprStateDictionary[@"test purpose 1"];
    XCTAssertNotNil(gdprState);
    XCTAssertTrue(gdprState.consented);
    XCTAssertEqualObjects(gdprState.document, @"foo-document-1");
    XCTAssertEqualObjects(gdprState.timestamp, [NSDate dateWithTimeIntervalSince1970:(1524176880.888195/1000)]);
    XCTAssertEqualObjects(gdprState.location, @"foo-location-1");
    XCTAssertEqualObjects(gdprState.hardwareId, @"foo-hardware-id-1");
}

- (void)testFilterFromDictionary {
    NSDictionary *configDictionary = @{@"i":@YES, @"v":@[@{@"c":@YES,@"h":@48278946},@{@"c":@YES,@"h":@1556641}]};
    MPConsentKitFilter *filter = [MPConsentSerialization filterFromDictionary:configDictionary];
    XCTAssertTrue(filter.shouldIncludeOnMatch);
    NSArray<MPConsentKitFilterItem *> *filterItems = filter.filterItems;
    XCTAssertEqual(filterItems.count, 2);
    MPConsentKitFilterItem *firstItem = filterItems[0];
    MPConsentKitFilterItem *secondItem = filterItems[1];
    XCTAssertNotNil(firstItem);
    XCTAssertNotNil(secondItem);
    XCTAssertTrue(firstItem.consented);
    XCTAssertTrue(secondItem.consented);
    XCTAssertEqual(firstItem.javascriptHash, 48278946);
    XCTAssertEqual(secondItem.javascriptHash, 1556641);
}

@end

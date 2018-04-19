#import <XCTest/XCTest.h>
#import "MPConsentSerialization.h"
#import "MPConsentState.h"
#import "MPGDPRConsent.h"

static NSTimeInterval epsilon = 0.05;

@interface MPConsentSerializationTests : XCTestCase

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
    XCTAssertNil(dictionary);
    
    consentState = [[MPConsentState alloc] init];
    dictionary = [MPConsentSerialization serverDictionaryFromConsentState:consentState];
    XCTAssertNil(dictionary);
    
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
    XCTAssertEqualObjects(gdprDictionary[@"d"], @"foo-document-1");
    XCTAssertEqualObjects(gdprDictionary[@"l"], @"foo-location-1");
    XCTAssertEqualObjects(gdprDictionary[@"h"], @"foo-hardware-id-1");
    XCTAssertNotNil(gdprDictionary[@"ts"]);
    XCTAssertLessThan(((NSDate *)gdprDictionary[@"ts"]).timeIntervalSinceNow, epsilon);
}

- (void)testToString {
    
}

- (void)testFromString {
    
}

@end

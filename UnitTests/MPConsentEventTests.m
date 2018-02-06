#import <XCTest/XCTest.h>
#import "MPConsentEvent.h"

@interface MPConsentEventTests : XCTestCase

@end

@implementation MPConsentEventTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testConsentEventProperties {
    MPConsentEvent *consentEvent = [[MPConsentEvent alloc] init];
    XCTAssertNotNil(consentEvent);
    consentEvent.regulation = MPConsentRegulationGDPR;
    XCTAssertEqual(consentEvent.regulation, MPConsentRegulationGDPR);
    consentEvent.timestamp = [NSDate dateWithTimeIntervalSince1970:1517259053];
    XCTAssertEqualObjects(consentEvent.timestamp, [NSDate dateWithTimeIntervalSince1970:1517259053]);
    consentEvent.document = @"consolidated_consentv234";
    XCTAssertEqualObjects(consentEvent.document, @"consolidated_consentv234");
    consentEvent.consentLocation = @"https://example.com/splash";
    XCTAssertEqualObjects(consentEvent.consentLocation, @"https://example.com/splash");
    consentEvent.hardwareId = @"3686B3BE-172A-4798-8C08-D252AE49E5F6";
    XCTAssertEqualObjects(consentEvent.hardwareId, @"3686B3BE-172A-4798-8C08-D252AE49E5F6");
    consentEvent.category = MPConsentCategoryProcessing;
    XCTAssertEqual(consentEvent.category, MPConsentCategoryProcessing);
    consentEvent.purpose = @"marketing";
    XCTAssertEqualObjects(consentEvent.purpose, @"marketing");
    consentEvent.type = MPConsentEventTypeGranted;
    XCTAssertEqual(consentEvent.type, MPConsentEventTypeGranted);
    consentEvent.type = MPConsentEventTypeDenied;
    XCTAssertEqual(consentEvent.type, MPConsentEventTypeDenied);
    consentEvent.customAttributes = @{@"Test attribute":@"Test value"};
    XCTAssertEqualObjects(consentEvent.customAttributes, @{@"Test attribute":@"Test value"});
}

- (void)testConsentEventDictionaryRepresentation {
    MPConsentEvent *consentEvent = [[MPConsentEvent alloc] init];
    consentEvent.regulation = MPConsentRegulationGDPR;
    consentEvent.timestamp = [NSDate dateWithTimeIntervalSince1970:1517259053];
    consentEvent.document = @"consolidated_consentv234";
    consentEvent.consentLocation = @"https://example.com/splash";
    consentEvent.hardwareId = @"3686B3BE-172A-4798-8C08-D252AE49E5F6";
    consentEvent.category = MPConsentCategoryProcessing;
    consentEvent.purpose = @"marketing";
    consentEvent.type = MPConsentEventTypeGranted;
    consentEvent.customAttributes = @{@"Test attribute":@"Test value"};
    
    NSDictionary *dictionary = [consentEvent dictionaryRepresentation];
    
    XCTAssertEqualObjects(@"GDPR", dictionary[@"crg"]);
    XCTAssertEqualObjects(@(1517259053), dictionary[@"ct"]);
    XCTAssertEqualObjects(@"consolidated_consentv234", dictionary[@"cdo"]);
    XCTAssertEqualObjects(@"https://example.com/splash", dictionary[@"clc"]);
    XCTAssertEqualObjects(@"3686B3BE-172A-4798-8C08-D252AE49E5F6", dictionary[@"chid"]);
    XCTAssertEqualObjects(@"processing", dictionary[@"cca"]);
    XCTAssertEqualObjects(@"marketing", dictionary[@"cpu"]);
    XCTAssertEqualObjects(@YES, dictionary[@"cnd"]);
    XCTAssertEqualObjects(@"Test value", dictionary[@"attrs"][@"Test attribute"]);
    
    consentEvent.type = MPConsentEventTypeDenied;
    dictionary = [consentEvent dictionaryRepresentation];
    XCTAssertEqualObjects(@NO, dictionary[@"cnd"]);
}

@end

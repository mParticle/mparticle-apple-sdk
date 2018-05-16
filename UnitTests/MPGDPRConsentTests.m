#import <XCTest/XCTest.h>
#import "MPGDPRConsent.h"

static NSTimeInterval epsilon = 0.05;

@interface MPGDPRConsentTests : XCTestCase {
    MPGDPRConsent *_state;
}

@end

@implementation MPGDPRConsentTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _state = [[MPGDPRConsent alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInit {
    XCTAssertNotNil(_state);
}

- (void)testDefaultPropertyValues {
    XCTAssertFalse(_state.consented);
    XCTAssertNil(_state.document);
    
    XCTAssertNotNil(_state.timestamp);
    XCTAssertLessThan(-1*_state.timestamp.timeIntervalSinceNow, epsilon);
    
    XCTAssertNil(_state.location);
    XCTAssertNil(_state.hardwareId);
}

- (void)testPropertySetters {
    _state.consented = YES;
    _state.document = @"foo-document-1";
    
    NSDate *date = [NSDate date];
    _state.timestamp = date;
    
    _state.location = @"foo-location-1";
    _state.hardwareId = @"foo-hardware-id-1";
    
    XCTAssertTrue(_state.consented);
    XCTAssertEqualObjects(_state.document, @"foo-document-1");
    XCTAssertEqualObjects(_state.timestamp, date);
    XCTAssertEqualObjects(_state.location, @"foo-location-1");
    XCTAssertEqualObjects(_state.hardwareId, @"foo-hardware-id-1");
    
    _state.consented = NO;
    XCTAssertFalse(_state.consented);
}

@end


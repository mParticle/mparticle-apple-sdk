#import <XCTest/XCTest.h>
#import "MParticleSwift.h"
#import "MPBaseTestCase.h"

static NSTimeInterval epsilon = 0.05;

@interface MPCCPAConsentTests : MPBaseTestCase

@end

@implementation MPCCPAConsentTests

- (void)testInit {
    MPCCPAConsent *state = [[MPCCPAConsent alloc] init];
    XCTAssertNotNil(state);
}

- (void)testDefaultPropertyValues {
    MPCCPAConsent *state = [[MPCCPAConsent alloc] init];
    
    XCTAssertFalse(state.consented);
    XCTAssertNil(state.document);
    
    XCTAssertNotNil(state.timestamp);
    XCTAssertLessThan(-1*state.timestamp.timeIntervalSinceNow, epsilon);
    
    XCTAssertNil(state.location);
    XCTAssertNil(state.hardwareId);
}

- (void)testPropertySetters {
    MPCCPAConsent *state = [[MPCCPAConsent alloc] init];
    
    state.consented = YES;
    state.document = @"foo-document-1";
    
    NSDate *date = [NSDate date];
    state.timestamp = date;
    
    state.location = @"foo-location-1";
    state.hardwareId = @"foo-hardware-id-1";
    
    XCTAssertTrue(state.consented);
    XCTAssertEqualObjects(state.document, @"foo-document-1");
    XCTAssertEqualObjects(state.timestamp, date);
    XCTAssertEqualObjects(state.location, @"foo-location-1");
    XCTAssertEqualObjects(state.hardwareId, @"foo-hardware-id-1");
    
    state.consented = NO;
    XCTAssertFalse(state.consented);
}

@end


#import <XCTest/XCTest.h>
#import "MPConsentState.h"
#import "MPBaseTestCase.h"
#import "MParticleSwift.h"

@interface MPConsentStateTests : MPBaseTestCase {
    MPConsentState *_globalState;
    MPGDPRConsent *_state;
    MPCCPAConsent *_ccpaState;
}

@end

@implementation MPConsentStateTests

- (void)setUp {
    [super setUp];
    _globalState = [[MPConsentState alloc] init];
    _state = [[MPGDPRConsent alloc] init];
    _ccpaState = [[MPCCPAConsent alloc] init];
}


- (void)testInit {
    XCTAssertNotNil(_globalState);
    XCTAssertNotNil(_state);
    XCTAssertNotNil(_ccpaState);
}

- (void)testDefaultState {
    XCTAssertNotNil([_globalState gdprConsentState]);
    XCTAssertEqual([_globalState gdprConsentState].count, 0);
}

- (void)testAddAndRetrieveState {
    [_globalState addGDPRConsentState:_state purpose:@"test purpose"];
    NSDictionary<NSString *, MPGDPRConsent *> *stateDictionary = [_globalState gdprConsentState];
    XCTAssertNotNil(stateDictionary);
    XCTAssertEqual(stateDictionary.count, 1);
    MPGDPRConsent *state = stateDictionary[@"test purpose"];
    XCTAssertNotNil(state);
}

- (void)testDeleteState {
    [_globalState addGDPRConsentState:_state purpose:@"test purpose"];
    [_globalState removeGDPRConsentStateWithPurpose:@"test purpose"];
    NSDictionary<NSString *, MPGDPRConsent *> *stateDictionary = [_globalState gdprConsentState];
    XCTAssertNotNil(stateDictionary);
    XCTAssertEqual(stateDictionary.count, 0);
}

- (void)testAddNilAndNullState {
    NSDictionary<NSString *, MPGDPRConsent *> *stateDictionary;
    stateDictionary = [_globalState gdprConsentState];
    XCTAssertNotNil(stateDictionary);
    XCTAssertEqual(stateDictionary.count, 0);
    
    MPGDPRConsent *state = nil;
    
    [_globalState addGDPRConsentState:state purpose:@"test purpose"];
    stateDictionary = [_globalState gdprConsentState];
    XCTAssertNotNil(stateDictionary);
    XCTAssertEqual(stateDictionary.count, 0);
    
    state = (MPGDPRConsent *)[NSNull null];
    
    [_globalState addGDPRConsentState:state purpose:@"test purpose"];
    stateDictionary = [_globalState gdprConsentState];
    XCTAssertNotNil(stateDictionary);
    XCTAssertEqual(stateDictionary.count, 0);
}

- (void)testInvalidPurposes {
    NSDictionary<NSString *, MPGDPRConsent *> *stateDictionary;
    stateDictionary = [_globalState gdprConsentState];
    XCTAssertNotNil(stateDictionary);
    XCTAssertEqual(stateDictionary.count, 0);
    
    NSString *purpose = nil;
    [_globalState addGDPRConsentState:_state purpose:purpose];
    stateDictionary = [_globalState gdprConsentState];
    XCTAssertNotNil(stateDictionary);
    XCTAssertEqual(stateDictionary.count, 0);
    
    purpose = @"";
    [_globalState addGDPRConsentState:_state purpose:purpose];
    stateDictionary = [_globalState gdprConsentState];
    XCTAssertNotNil(stateDictionary);
    XCTAssertEqual(stateDictionary.count, 0);
    
    purpose = (NSString *)[NSNull null];
    [_globalState addGDPRConsentState:_state purpose:purpose];
    stateDictionary = [_globalState gdprConsentState];
    XCTAssertNotNil(stateDictionary);
    XCTAssertEqual(stateDictionary.count, 0);
}

- (void)testPurposeCanonicalization {
    [_globalState addGDPRConsentState:_state purpose:@"  TeSt pUrpose     "];
    NSDictionary<NSString *, MPGDPRConsent *> *stateDictionary = [_globalState gdprConsentState];
    XCTAssertNotNil(stateDictionary);
    XCTAssertEqual(stateDictionary.count, 1);
    MPGDPRConsent *state = stateDictionary[@"test purpose"];
    XCTAssertNotNil(state);
}

- (void)testGetSetCCPAState {
    XCTAssertNil([_globalState ccpaConsentState]);
    [_globalState setCCPAConsentState:_ccpaState];
    XCTAssertNotNil([_globalState ccpaConsentState]);
}

- (void)testRemoveCCPAState {
    [_globalState setCCPAConsentState:_ccpaState];
    XCTAssertNotNil([_globalState ccpaConsentState]);
    [_globalState removeCCPAConsentState];
    XCTAssertNil([_globalState ccpaConsentState]);
}

@end

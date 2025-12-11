#import <XCTest/XCTest.h>
#import "MPBracket.h"
#import "MPBaseTestCase.h"

@interface BracketTests : MPBaseTestCase

@end

@implementation BracketTests

- (MPBracket *)makeBracket {
    return [[MPBracket alloc] initWithMpId:LONG_MAX - 3141592 low:95 high:97];
}

- (void)testBracket {
    MPBracket *bracket = [[MPBracket alloc] initWithMpId:LONG_MAX - 3141592 low:95 high:97];
    XCTAssertTrue([bracket shouldForward], @"Bracket should be forwarding.");
    
    bracket.high = 96;
    XCTAssertFalse([bracket shouldForward], @"Bracket should not be forwarding.");
}

- (void)testBracketPointer {
    MPBracket *bracket = [[MPBracket alloc] initWithMpId:-(LONG_MAX - 271828182) low:40 high:41];
    XCTAssertTrue([bracket shouldForward], @"Bracket should be forwarding.");
    
    bracket.low = 41;
    XCTAssertFalse([bracket shouldForward], @"Bracket should not be forwarding.");
}

- (void)testCopyBracket {
    MPBracket *bracket = [[MPBracket alloc] initWithMpId:LONG_MAX - 3141592 low:95 high:97];
    MPBracket *bracketCopy = [[MPBracket alloc] initWithMpId:bracket.mpId low:bracket.low high:bracket.high];
    
    XCTAssertTrue([bracketCopy shouldForward], @"Bracket should be forwarding.");
    
    bracketCopy.high = 96;
    XCTAssertFalse([bracketCopy shouldForward], @"Bracket should not be forwarding.");
}

- (void)testMoveBracket {
    MPBracket *bracket = [self makeBracket];
    
    XCTAssertTrue([bracket shouldForward], @"Bracket should be forwarding.");
    
    bracket.high = 96;
    XCTAssertFalse([bracket shouldForward], @"Bracket should not be forwarding.");
}

- (void)testBracketComparison {
    MPBracket *bracket = [self makeBracket];
    MPBracket *bracketPtr = [[MPBracket alloc] initWithMpId:-(LONG_MAX - 271828182) low:40 high:41];
    XCTAssertFalse([bracket isEqualToBracket:bracketPtr], @"Brackets should have been different.");
    
    bracketPtr.mpId = LONG_MAX - 3141592;
    bracketPtr.low = 95;
    bracketPtr.high = 97;
    XCTAssertTrue([bracket isEqualToBracket:bracketPtr], @"Brackets should have been equal.");
}

- (void)testDifferent {
    MPBracket *bracket1 = [[MPBracket alloc] initWithMpId:LONG_MAX - 3141592 low:95 high:97];
    MPBracket *bracket2 = [[MPBracket alloc] initWithMpId:LONG_MAX - 2951413 low:59 high:79];
    XCTAssertFalse([bracket1 isEqualToBracket:bracket2], @"Should have been different.");
}

- (void)testInvalidBracket {
    MPBracket *bracket = [[MPBracket alloc] initWithMpId:0 low:0 high:0];
    XCTAssertFalse([bracket shouldForward], @"Should have been false.");
    
    bracket.mpId = LONG_MAX - 3141592;
    XCTAssertFalse([bracket shouldForward], @"Should have been false.");
}

@end

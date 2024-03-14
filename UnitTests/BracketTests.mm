#import <XCTest/XCTest.h>
#import "MPBracket.h"
#import "MPBaseTestCase.h"

@interface BracketTests : MPBaseTestCase

@end

@implementation BracketTests

mParticle::Bracket makeBracket() {
    mParticle::Bracket bracket(LONG_MAX - 3141592, 95, 97);
    return bracket;
}

- (void)testBracket {
    mParticle::Bracket bracket(LONG_MAX - 3141592, 95, 97);
    XCTAssertTrue(bracket.shouldForward(), @"Bracket should be forwarding.");
    
    bracket.high = 96;
    XCTAssertFalse(bracket.shouldForward(), @"Bracket should not be forwarding.");
}

- (void)testBracketPointer {
    std::shared_ptr<mParticle::Bracket> bracket = std::make_shared<mParticle::Bracket>(-(LONG_MAX - 271828182), 40, 41);
    XCTAssertTrue(bracket->shouldForward(), @"Bracket should be forwarding.");
    
    bracket->low = 41;
    XCTAssertFalse(bracket->shouldForward(), @"Bracket should not be forwarding.");
}

- (void)testCopyBracket {
    mParticle::Bracket bracket(LONG_MAX - 3141592, 95, 97);
    mParticle::Bracket bracketCopy = bracket;
    
    XCTAssertTrue(bracketCopy.shouldForward(), @"Bracket should be forwarding.");
    
    bracketCopy.high = 96;
    XCTAssertFalse(bracketCopy.shouldForward(), @"Bracket should not be forwarding.");
}

- (void)testMoveBracket {
    mParticle::Bracket bracket = makeBracket();
    
    XCTAssertTrue(bracket.shouldForward(), @"Bracket should be forwarding.");
    
    bracket.high = 96;
    XCTAssertFalse(bracket.shouldForward(), @"Bracket should not be forwarding.");
}

- (void)testBracketComparison {
    mParticle::Bracket bracket = makeBracket();
    std::shared_ptr<mParticle::Bracket> bracketPtr = std::make_shared<mParticle::Bracket>(-(LONG_MAX - 271828182), 40, 41);
    XCTAssertFalse(bracket == *bracketPtr, @"Brackets should have been different.");
    
    bracketPtr->mpId = LONG_MAX - 3141592;
    bracketPtr->low = 95;
    bracketPtr->high = 97;
    XCTAssertFalse(bracket != *bracketPtr, @"Brackets should have been equal.");
}

- (void)testDifferent {
    mParticle::Bracket bracket1(LONG_MAX - 3141592, 95, 97);
    mParticle::Bracket bracket2(LONG_MAX - 2951413, 59, 79);
    XCTAssertTrue(bracket1 != bracket2, @"Should have been different.");
}

- (void)testInvalidBracket {
    mParticle::Bracket bracket(0, 0, 0);
    XCTAssertFalse(bracket.shouldForward(), @"Should have been false.");
    
    bracket.mpId = LONG_MAX - 3141592;
    XCTAssertFalse(bracket.shouldForward(), @"Should have been false.");
}

@end

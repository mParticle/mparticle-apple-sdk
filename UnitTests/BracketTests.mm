//
//  BracketTests.mm
//
//  Copyright 2015 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <XCTest/XCTest.h>
#import "MPBracket.h"

@interface BracketTests : XCTestCase

@end

@implementation BracketTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

mParticle::Bracket makeBracket() {
    mParticle::Bracket bracket(LONG_MAX - 3141592, 95, 97);
    return bracket;
}

- (void)testBracket {
    mParticle::Bracket bracket(LONG_MAX - 3141592, 95, 97);
    XCTAssertTrue(bracket.shouldForward(), @"Backet should be forwarding.");
    
    bracket.high = 96;
    XCTAssertFalse(bracket.shouldForward(), @"Backet should not be forwarding.");
}

- (void)testBracketPointer {
    shared_ptr<mParticle::Bracket> bracket = make_shared<mParticle::Bracket>(-(LONG_MAX - 271828182), 40, 41);
    XCTAssertTrue(bracket->shouldForward(), @"Backet should be forwarding.");
    
    bracket->low = 41;
    XCTAssertFalse(bracket->shouldForward(), @"Backet should not be forwarding.");
}

- (void)testCopyBracket {
    mParticle::Bracket bracket(LONG_MAX - 3141592, 95, 97);
    mParticle::Bracket bracketCopy = bracket;
    
    XCTAssertTrue(bracketCopy.shouldForward(), @"Backet should be forwarding.");
    
    bracketCopy.high = 96;
    XCTAssertFalse(bracketCopy.shouldForward(), @"Backet should not be forwarding.");
}

- (void)testMoveBracket {
    mParticle::Bracket bracket = move(makeBracket());
    
    XCTAssertTrue(bracket.shouldForward(), @"Backet should be forwarding.");
    
    bracket.high = 96;
    XCTAssertFalse(bracket.shouldForward(), @"Backet should not be forwarding.");
}

- (void)testBracketComparison {
    mParticle::Bracket bracket = move(makeBracket());
    shared_ptr<mParticle::Bracket> bracketPtr = make_shared<mParticle::Bracket>(-(LONG_MAX - 271828182), 40, 41);
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

//
//  MPSearchAdsAttributionTests.m
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
#import "MPSearchAdsAttribution.h"

@interface MPSearchAdsAttributionTests : XCTestCase
@property (nonatomic) MPSearchAdsAttribution *searchAttribution;
@end

@implementation MPSearchAdsAttributionTests

- (void)setUp {
    [super setUp];
    _searchAttribution = [[MPSearchAdsAttribution alloc] init];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testTimeUntilCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test that callback is called quickly"];
    [self.searchAttribution requestAttributionDetailsWithBlock:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.01 handler:nil];
}

- (void)testNumberOfCallsToHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test that callback is called only once"];
    __block int counter = 0;
    [self.searchAttribution requestAttributionDetailsWithBlock:^{
        counter += 1;
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        XCTAssertEqual(counter, 1);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.01 handler:nil];
}

- (void)testResults {
    XCTAssertNil([self.searchAttribution dictionaryRepresentation]);
    [self.searchAttribution requestAttributionDetailsWithBlock:^{
        XCTAssertNil([self.searchAttribution dictionaryRepresentation]);
    }];
}

@end

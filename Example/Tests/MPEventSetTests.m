//
//  MPEventSetTests.m
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
#import "MPEventSet.h"
#import "MPEvent.h"

@interface MPEventSetTests : XCTestCase

@end

@implementation MPEventSetTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testEventSet {
    MPEventSet *eventSet = [[MPEventSet alloc] initWithCapacity:1];
    XCTAssertEqual(eventSet.count, 0, @"The event count should have been 0.");
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dino Pet" type:MPEventTypeTransaction];
    XCTAssertNotNil(event, @"Event is not being instantiated.");
    
    [eventSet addEvent:event];
    XCTAssertEqual(eventSet.count, 1, @"There should be 1 stored event.");
    [eventSet addEvent:nil];
    XCTAssertEqual(eventSet.count, 1, @"There should be 1 stored event.");
    
    event = [[MPEvent alloc] initWithName:@"T-Rex Trainer" type:MPEventTypeSearch];
    [eventSet addEvent:event];
    
    [eventSet removeEventWithName:nil];
    XCTAssertEqual(eventSet.count, 2, @"There should be 2 stored event.");
    
    BOOL containsEvent = [eventSet containsEvent:event];
    XCTAssertTrue(containsEvent, @"Event should have been contained in the set.");
    
    containsEvent = [eventSet containsEventWithName:@"Dino Pet"];
    XCTAssertTrue(containsEvent, @"Event should have been contained in the set.");
    
    [eventSet removeEventWithName:@"Dino Pet"];
    XCTAssertEqual(eventSet.count, 1, @"The event count should have been 1.");
    
    [eventSet removeEvent:event];
    XCTAssertEqual(eventSet.count, 0, @"The event count should have been 0.");
}

@end

//
//  HasherTests.mm
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
#import "MPHasher.h"
#import "MPEnums.h"
#import "MPEvent.h"

@interface HasherTests : XCTestCase

@end

@implementation HasherTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testHashingString {
    NSString *referenceString = @"The Quick Brown Fox Jumped Over the Lazy Dog.";
    NSString *hashedString = [NSString stringWithCString:mParticle::Hasher::hashString([[referenceString lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                                encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(hashedString, @"1836604153", @"Hasher is not hashing strings properly.");
    
    referenceString = @"";
    hashedString = [NSString stringWithCString:mParticle::Hasher::hashString([referenceString cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                      encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(hashedString, @"", @"Hashing an empty string.");
}

- (void)testHashingPerformance {
    [self measureBlock:^{
        NSString *referenceString = @"The Quick Brown Fox Jumped Over the Lazy Dog.";
        mParticle::Hasher::hashString([referenceString cStringUsingEncoding:NSUTF8StringEncoding]);
    }];
}

- (void)testHashAllEventTypes {
    NSString *hashedEventType;
    
    vector<string> hashedAllEventTypes = mParticle::Hasher::hashedAllEventTypes();
    NSMutableArray *mHashedEventTypes = [[NSMutableArray alloc] initWithCapacity:hashedAllEventTypes.size()];
    
    for_each(hashedAllEventTypes.begin(), hashedAllEventTypes.end(),
             [&mHashedEventTypes](string str) {
                 NSString *nsstr = [NSString stringWithUTF8String:str.c_str()];
                 [mHashedEventTypes addObject:nsstr];
             });
    
    NSArray *hashedEventTypes = (NSArray *)mHashedEventTypes;
    
    hashedEventType = hashedEventTypes[MPEventTypeNavigation];
    XCTAssertEqualObjects(hashedEventType, @"49", @"Hashed event type navigation is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeLocation];
    XCTAssertEqualObjects(hashedEventType, @"50", @"Hashed event type location is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeSearch];
    XCTAssertEqualObjects(hashedEventType, @"51", @"Hashed event type search is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeTransaction];
    XCTAssertEqualObjects(hashedEventType, @"52", @"Hashed event type transaction is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeUserContent];
    XCTAssertEqualObjects(hashedEventType, @"53", @"Hashed event type user content is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeUserPreference];
    XCTAssertEqualObjects(hashedEventType, @"54", @"Hashed event type user preference is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeSocial];
    XCTAssertEqualObjects(hashedEventType, @"55", @"Hashed event type social is incorrect.");
    
    hashedEventType = hashedEventTypes[MPEventTypeOther];
    XCTAssertEqualObjects(hashedEventType, @"56", @"Hashed event type other is incorrect.");
}

- (void)testHashSomeEventTypes {
    vector<int> eventTypes = {MPEventTypeNavigation, MPEventTypeTransaction, MPEventTypeOther};
    vector<string> hashedAllEventTypes = mParticle::Hasher::hashedEventTypes(eventTypes);
    NSMutableArray *mHashedEventTypes = [[NSMutableArray alloc] initWithCapacity:hashedAllEventTypes.size()];
    
    for_each(hashedAllEventTypes.begin(), hashedAllEventTypes.end(),
             [&mHashedEventTypes](string str) {
                 NSString *nsstr = [NSString stringWithUTF8String:str.c_str()];
                 [mHashedEventTypes addObject:nsstr];
             });
    
    NSArray *hashedEventTypes = (NSArray *)mHashedEventTypes;
    
    XCTAssertTrue([hashedEventTypes containsObject:@"49"], @"Not hashing event type navigation.");
    XCTAssertTrue([hashedEventTypes containsObject:@"52"], @"Not hashing event type transaction.");
    XCTAssertTrue([hashedEventTypes containsObject:@"56"], @"Not hashing event type other.");
}

- (void)testRampHash {
    NSString *rampString = @"E1492888-3B7C-4FB2-98A5-6C483BF9EBEB";
    NSData *rampData = [rampString dataUsingEncoding:NSUTF8StringEncoding];
    uint64_t rampHash = mParticle::Hasher::hashFNV1a((const char *)[rampData bytes], (int)[rampData length]);
    
    XCTAssertEqual(rampHash, 8288906072899054792, @"Ramp hash is being calculated incorrectly.");
}

@end

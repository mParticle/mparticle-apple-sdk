//
//  MPEventTests.mm
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
#import "MPEvent.h"
#import "MPEvent+Internal.h"
#import "MPConstants.h"
#import "MPStateMachine.h"
#import "MPSession.h"

@interface MPEventTests : XCTestCase

@end

@implementation MPEventTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInstance {
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dinosaur Run" type:MPEventTypeOther];
    
    XCTAssertNotNil(event, @"Event is not being allocated.");
    XCTAssertEqualObjects(event.typeName, @"Other", @"Type name should have been 'other.'");
    
    NSArray *typeNames = @[@"Reserved - Not Used", @"Navigation", @"Location", @"Search", @"Transaction", @"UserContent", @"UserPreference", @"Social", @"Other"];
    for (NSUInteger type = MPEventTypeNavigation; type < MPEventTypeOther; ++type) {
        event.type = (MPEventType)type;
        XCTAssertEqualObjects(event.typeName, typeNames[type], @"Type name does not correspond to type enum.");
    }
    
    NSDictionary *eventInfo = @{@"speed":@25,
                                @"modality":@"sprinting"};
    
    event.info = eventInfo;
    event.category = @"Olympic Games";
    
    MPEvent *copyEvent = [event copy];
    XCTAssertEqualObjects(copyEvent, event, @"Copied event object should not have been different.");
    
    copyEvent.type = MPEventTypeNavigation;
    XCTAssertNotEqualObjects(copyEvent, event, @"Copied event object should have been different.");
    
    copyEvent.type = event.type;
    copyEvent.name = @"Run Dinosaur";
    XCTAssertNotEqualObjects(copyEvent, event, @"Copied event object should have been different.");
    
    copyEvent.name = event.name;
    copyEvent.info = nil;
    XCTAssertNotEqualObjects(copyEvent, event, @"Copied event object should have been different.");
    
    copyEvent.info = event.info;
    copyEvent.duration = @1;
    XCTAssertNotEqualObjects(copyEvent, event, @"Copied event object should have been different.");
    
    copyEvent.duration = event.duration;
    copyEvent.category = nil;
    XCTAssertNotEqualObjects(copyEvent, event, @"Copied event object should have been different.");
}

- (void)testEventTiming {
    MPEvent *event = [[MPEvent alloc] initWithName:@"Timing Dinosaur" type:MPEventTypeOther];
    
    [event beginTiming];
    
    unsigned int sleepTimer = 1;
    sleep(sleepTimer);
    
    [event endTiming];
    
    XCTAssertNotNil(event.startTime, @"Event start time should not have been nil.");
    XCTAssertNotNil(event.endTime, @"Event end time should not have been nil.");
    XCTAssertGreaterThan([event.duration doubleValue], (sleepTimer * 1000 - 1), @"Timing of an event is not being done properly.");
}

- (void)testInvalidNames {
    NSString *longName = @"The quick brown fox jumped over the lazy dog. The quick brown fox jumped over the lazy dog. The quick brown fox jumped over the lazy dog. The quick brown fox jumped over the lazy dog. The quick brown fox jumped over the lazy dog. The quick brown fox jumped over the lazy dog.";
    
    MPEvent *event = [[MPEvent alloc] initWithName:nil type:MPEventTypeOther];
    XCTAssertNil(event, @"Event cannot be created with a nil name.");
    
    event = [[MPEvent alloc] initWithName:longName type:MPEventTypeOther];
    XCTAssertNil(event, @"Event cannot be created with a name longer than 100 characters.");
    
    event = [[MPEvent alloc] initWithName:@"" type:MPEventTypeOther];
    XCTAssertNil(event, @"Event cannot be created with an empty name.");
    
    event = [[MPEvent alloc] initWithName:@"Dino" type:MPEventTypeOther];
    event.name = nil;
    XCTAssertEqualObjects(event.name, @"Dino", @"Cannot set a nil name.");
    
    event.name = @"";
    XCTAssertEqualObjects(event.name, @"Dino", @"Cannot set an empty name.");
    
    event.name = longName;
    XCTAssertEqualObjects(event.name, @"Dino", @"Cannot set an event name longer than 100 characters.");
}

- (void)testInvalidTypes {
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dino Type" type:(MPEventType)99];
    XCTAssertEqual(event.type, MPEventTypeOther, @"Invalid type should have defaulted to 'other.'");
    
    event.type = MPEventTypeNavigation;
    XCTAssertEqual(event.type, MPEventTypeNavigation, @"Type should had been set to 'nagigation.'");
    
    event.type = (MPEventType)88;
    XCTAssertEqual(event.type, MPEventTypeOther, @"Invalid type should have defaulted to 'other.'");
}

- (void)testDictionaryRepresentation {
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970]];
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.currentSession = session;
    
    NSNumber *eventDuration = @2;
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dinosaur Run" type:MPEventTypeOther];
    event.duration = eventDuration;
    event.info = @{@"speed":@25,
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";
    
    [session incrementCounter];
    [session incrementCounter];
    [session incrementCounter];
    
    NSDictionary *dictionaryRepresentation = [event dictionaryRepresentation];
    XCTAssertNotNil(dictionaryRepresentation, @"Dictionary representation should not have been nil.");
    XCTAssertEqualObjects(dictionaryRepresentation[kMPEventNameKey], @"Dinosaur Run", @"Name is not correct.");
    XCTAssertNotNil(dictionaryRepresentation[kMPEventStartTimestamp], @"Start timestamp should not have been nil.");
    XCTAssertEqualObjects(dictionaryRepresentation[kMPEventTypeKey], @"Other", @"Type should have been 'Other.'");
    XCTAssertEqualObjects(dictionaryRepresentation[kMPEventLength], @2, @"Length should have been 2.");
    XCTAssertEqualObjects(dictionaryRepresentation[kMPEventCounterKey], @3, @"Event counter should have been 3.");
    
    NSDictionary *attributes = @{@"speed":@25,
                                 @"modality":@"sprinting",
                                 @"$Category":@"Olympic Games",
                                 @"EventLength":eventDuration};
    XCTAssertEqualObjects(dictionaryRepresentation[kMPAttributesKey], attributes, @"Attributes are not being set correctly.");
}

- (void)testBreadcrumbDictionaryRepresentation {
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dinosaur Run" type:MPEventTypeNavigation];
    event.info = @{@"speed":@25,
                   @"modality":@"sprinting"};
    
    NSDictionary *dictionaryRepresentation = [event breadcrumbDictionaryRepresentation];
    XCTAssertNotNil(dictionaryRepresentation, @"Breadcrumb dictionary representation should not have been nil.");
    XCTAssertEqualObjects(dictionaryRepresentation[kMPLeaveBreadcrumbsKey], @"Dinosaur Run", @"Name is not correct.");
    XCTAssertNotNil(dictionaryRepresentation[kMPEventStartTimestamp], @"Start timestamp should not have been nil.");
    XCTAssertNil(dictionaryRepresentation[kMPEventTypeKey], @"Type should have been nil for screen events.");
    XCTAssertNil(dictionaryRepresentation[kMPEventLength], @"Length should have been nil.");
    XCTAssertNil(dictionaryRepresentation[kMPEventCounterKey], @"Counter should have been nil for screen events.");
    XCTAssertEqualObjects(dictionaryRepresentation[kMPAttributesKey], event.info, @"Attributes are not being set correctly.");
}

- (void)testScreenDictionaryRepresentation {
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dinosaur Run" type:MPEventTypeNavigation];
    
    NSDictionary *dictionaryRepresentation = [event screenDictionaryRepresentation];
    XCTAssertNotNil(dictionaryRepresentation, @"Screen dictionary representation should not have been nil.");
    XCTAssertEqualObjects(dictionaryRepresentation[kMPEventNameKey], @"Dinosaur Run", @"Name is not correct.");
    XCTAssertNotNil(dictionaryRepresentation[kMPEventStartTimestamp], @"Start timestamp should not have been nil.");
    XCTAssertNil(dictionaryRepresentation[kMPEventTypeKey], @"Type should have been nil for screen events.");
    XCTAssertEqualObjects(dictionaryRepresentation[kMPEventLength], @0, @"Length should have been 0.");
    XCTAssertNil(dictionaryRepresentation[kMPEventCounterKey], @"Counter should have been nil for screen events.");
    XCTAssertEqualObjects(dictionaryRepresentation[kMPAttributesKey], @{@"EventLength":@0}, @"Attributes contains more key/value pairs then it should.");
}

- (void)testCustomFlags {
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dinosaur Jogging" type:MPEventTypeTransaction];
    
    [event addCustomFlags:nil withKey:@"key"];
    XCTAssertNil(event.customFlags, @"Should have been nil.");
    
    [event addCustomFlags:(NSArray *)[NSNull null] withKey:@"key"];
    XCTAssertNil(event.customFlags, @"Should have been nil.");
    
    [event addCustomFlags:@[@"Flag 1"] withKey:nil];
    XCTAssertNil(event.customFlags, @"Should have been nil.");
    
    [event addCustomFlags:@[@"Flag 1"] withKey:(NSString *)[NSNull null]];
    XCTAssertNil(event.customFlags, @"Should have been nil.");
    
    [event addCustomFlags:@[@"Flag 1"] withKey:@"key1"];
    XCTAssertNotNil(event.customFlags, @"Should not have been nil.");
    
    NSDictionary *dictionaryRepresentation = [event dictionaryRepresentation];
    NSMutableDictionary *expectedDictionary = [@{@"key1":@[@"Flag 1"]} mutableCopy];
    XCTAssertEqualObjects(dictionaryRepresentation[@"flags"], expectedDictionary, @"Should have been equal.");
}

@end

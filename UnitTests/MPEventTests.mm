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
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "MPSession.h"
#import "MPProduct.h"

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

    XCTAssertNotNil(event.category, @"Should not have been nil.");
    event.category = @"Bacon ipsum dolor amet mollit reprehenderit occaecat shankle officia fatback, enim corned beef ham sunt adipisicing swine. Frankfurter duis ground round shoulder nostrud do jowl ea adipisicing exercitation fugiat. Tempor consectetur chicken anim pork belly pancetta et. Venison deserunt cillum sed aliqua ipsum landjaeger rump et qui.";
    XCTAssertNil(event.category, @"Should have been nil.");
    
    XCTAssertNotNil(event.info, @"Should not have been nil.");
    NSDictionary *copyEventInfo = [eventInfo copy];
    event.info = copyEventInfo;
    XCTAssertEqualObjects(event.info, eventInfo, @"Should have been equal.");
    
    event = [[MPEvent alloc] init];
    XCTAssertNotNil(event, @"Should not have been nil.");
}

- (void)testEventTiming {
    MPEvent *event = [[MPEvent alloc] initWithName:@"Timing Dinosaur" type:MPEventTypeOther];
    
    [event beginTiming];
    
    unsigned int sleepTimer = 1;
    sleep(sleepTimer);
    
    [event endTiming];
    
    XCTAssertNotNil(event.startTime);
    XCTAssertNotNil(event.endTime);
    double referenceDuration = (sleepTimer * 1000.0 - 1.0);
    XCTAssertGreaterThan([event.duration doubleValue], referenceDuration);
}

- (void)testInvalidNames {
    NSString *longName = @"The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.";
    
    NSString *nilName = nil;
    
    MPEvent *event = [[MPEvent alloc] initWithName:nilName type:MPEventTypeOther];
    XCTAssertNil(event, @"Event cannot be created with a nil name.");
    
    event = [[MPEvent alloc] initWithName:longName type:MPEventTypeOther];
    XCTAssertNil(event, @"Event cannot be created with a name longer than 100 characters.");
    
    event = [[MPEvent alloc] initWithName:@"" type:MPEventTypeOther];
    XCTAssertNil(event, @"Event cannot be created with an empty name.");
    
    event = [[MPEvent alloc] initWithName:@"Dino" type:MPEventTypeOther];
    event.name = nilName;
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
    event.messageType = MPMessageTypeBreadcrumb;
    
    NSDictionary *dictionaryRepresentation = [event dictionaryRepresentation];
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
    event.messageType = MPMessageTypeScreenView;
    
    NSDictionary *dictionaryRepresentation = [event dictionaryRepresentation];
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
    NSArray *customFlags = nil;
    NSString *customFlagKey = @"Era";
    NSString *customFlagValue = @"Mesozoic";

    [event addCustomFlags:customFlags withKey:customFlagKey];
    XCTAssertNil(event.customFlags, @"Should have been nil.");
    
    customFlags = (NSArray *)[NSNull null];
    [event addCustomFlags:customFlags withKey:customFlagKey];
    XCTAssertNil(event.customFlags, @"Should have been nil.");
    
    customFlagKey = nil;
    [event addCustomFlags:@[@"Flag 1"] withKey:customFlagKey];
    XCTAssertNil(event.customFlags, @"Should have been nil.");
    
    customFlagKey = (NSString *)[NSNull null];
    [event addCustomFlags:@[@"Flag 1"] withKey:customFlagKey];
    XCTAssertNil(event.customFlags, @"Should have been nil.");
    
    customFlagKey = @"Era";
    customFlags = @[customFlagValue];
    [event addCustomFlags:customFlags withKey:customFlagKey];
    XCTAssertNotNil(event.customFlags, @"Should not have been nil.");
    
    NSDictionary *dictionaryRepresentation = [event dictionaryRepresentation];
    NSMutableDictionary *expectedDictionary = [@{customFlagKey:customFlags} mutableCopy];
    XCTAssertEqualObjects(dictionaryRepresentation[@"flags"], expectedDictionary, @"Should have been equal.");

    event = [[MPEvent alloc] initWithName:@"Dinosaur Jogging" type:MPEventTypeNavigation];
    customFlagValue = nil;
    [event addCustomFlag:customFlagValue withKey:customFlagKey];
    XCTAssertNil(event.customFlags, @"Should have been nil.");

    customFlagValue = (NSString *)[NSNull null];
    [event addCustomFlag:customFlagValue withKey:customFlagKey];
    XCTAssertNil(event.customFlags, @"Should have been nil.");
    
    customFlagKey = nil;
    customFlagValue = @"Mesozoic";
    [event addCustomFlag:customFlagValue withKey:customFlagKey];
    XCTAssertNil(event.customFlags, @"Should have been nil.");
    
    customFlagKey = (NSString *)[NSNull null];
    [event addCustomFlag:customFlagValue withKey:customFlagKey];
    XCTAssertNil(event.customFlags, @"Should have been nil.");

    customFlagKey = @"Era";
    [event addCustomFlag:customFlagValue withKey:customFlagKey];
    XCTAssertNotNil(event.customFlags, @"Should not have been nil.");
    
    dictionaryRepresentation = [event dictionaryRepresentation];
    XCTAssertEqualObjects(dictionaryRepresentation[@"flags"], expectedDictionary, @"Should have been equal.");
}

- (void)testEquality {
    MPEvent *event1 = [[MPEvent alloc] initWithName:@"Dinosaur Run" type:MPEventTypeNavigation];
    event1.info = @{@"Shoes":@"Sneakers"};
    
    MPEvent *event2 = [[MPEvent alloc] initWithName:@"Dinosaur Run" type:MPEventTypeNavigation];
    XCTAssertNotEqualObjects(event1, event2, @"Should not have been equal.");
    XCTAssertNotEqualObjects(event2, event1, @"Should not have been equal.");
    
    event1.duration = @1;
    event2.info = @{@"Shoes":@"Sneakers"};
    XCTAssertNotEqualObjects(event1, event2, @"Should not have been equal.");
    XCTAssertNotEqualObjects(event2, event1, @"Should not have been equal.");
    
    event1.category = @"Sports";
    event2.duration = @1;
    XCTAssertNotEqualObjects(event1, event2, @"Should not have been equal.");
    XCTAssertNotEqualObjects(event2, event1, @"Should not have been equal.");
    
    event2.category = @"Sports";
    XCTAssertEqualObjects(event1, event2, @"Should have been equal.");
    XCTAssertEqualObjects(event2, event1, @"Should have been equal.");
}

- (void)testEventWithProduct {
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    
    NSDictionary *expectedEventInfo = @{
                                        @"id":@"OutATime",
                                        @"nm":@"DeLorean",
                                        @"pr":@"4.32",
                                        @"qt":@"1",
                                        @"tpa":@"4.32"
                                        };
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Jump In Time" type:MPEventTypeNavigation];
    event.info = (NSDictionary *)product;
    XCTAssertNotNil(event.info, @"Should not have been nil.");
    XCTAssertEqualObjects(event.info, expectedEventInfo, @"Should have been equal.");
}

@end

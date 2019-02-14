#import <XCTest/XCTest.h>
#import "OCMock.h"
#import "MPEvent.h"
#import "MPEvent+Internal.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "MPSession.h"
#import "MPProduct.h"
#import "MPPersistenceController.h"
#import "MParticle.h"
#import "MPBackendController.h"
#import "MPBaseTestCase.h"

#pragma mark - MParticle+Tests category
@interface MParticle (Tests)

@property (nonatomic, strong, nonnull) MPBackendController *backendController;
@property (nonatomic, strong) MPStateMachine *stateMachine;

@end

@interface MPEventTests : MPBaseTestCase

@end

@implementation MPEventTests

- (void)setUp {
    [super setUp];
    
    [MParticle sharedInstance].stateMachine = [[MPStateMachine alloc] init];
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
    id mock = [OCMockObject mockForClass:[NSString class]];
    OCMStub([mock length]).andReturn(LIMIT_ATTR_VALUE_LENGTH+1);
    event.category = mock;
    
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
    
    NSTimeInterval sleepTimer = 0.002;
    double value = sleepTimer*1000000.0;
    usleep(value);
    
    [event endTiming];
    
    NSTimeInterval secondsElapsed = [event.endTime timeIntervalSince1970] - [event.startTime timeIntervalSince1970];
    NSNumber *duration = @(trunc((secondsElapsed) * 1000));
    XCTAssertNotEqualObjects(duration, @0);
    XCTAssertEqualObjects(duration, event.duration);
}

- (void)testInvalidNames {
    NSString *nilName = nil;
    
    MPEvent *event = [[MPEvent alloc] initWithName:nilName type:MPEventTypeOther];
    XCTAssertNil(event, @"Event cannot be created with a nil name.");
    
    id mockLongName = [OCMockObject mockForClass:[NSString class]];
    OCMStub([mockLongName length]).andReturn(LIMIT_ATTR_KEY_LENGTH+1);
    
    event = [[MPEvent alloc] initWithName:mockLongName type:MPEventTypeOther];
    XCTAssertNil(event, @"Event cannot be created with a name longer than 100 characters.");
    
    event = [[MPEvent alloc] initWithName:@"" type:MPEventTypeOther];
    XCTAssertNil(event, @"Event cannot be created with an empty name.");
    
    event = [[MPEvent alloc] initWithName:@"Dino" type:MPEventTypeOther];
    event.name = nilName;
    XCTAssertEqualObjects(event.name, @"Dino", @"Cannot set a nil name.");
    
    event.name = @"";
    XCTAssertEqualObjects(event.name, @"Dino", @"Cannot set an empty name.");
    
    event.name = mockLongName;
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
    MPSession *session = [[MPSession alloc] initWithStartTime:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
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

- (void)testSetEventAttributes {
    MPEvent *event = [[MPEvent alloc] initWithName:@"foo" type:MPEventTypeNavigation];
    XCTAssertNil(event.info);
    id mockLongValue = [OCMockObject mockForClass:[NSString class]];
    OCMStub([mockLongValue length]).andReturn(LIMIT_ATTR_VALUE_LENGTH); //just short enough
    event.info = @{@"foo-attribute-key":mockLongValue};
    XCTAssertNotNil(event.info);
}

- (void)testSetLongEventAttributes {
    MPEvent *event = [[MPEvent alloc] initWithName:@"foo" type:MPEventTypeNavigation];
    XCTAssertNil(event.info);
    id mockLongValue = [OCMockObject mockForClass:[NSString class]];
    OCMStub([mockLongValue length]).andReturn(LIMIT_ATTR_VALUE_LENGTH+1); //just a bit too long
    event.info = @{@"foo-attribute-key":mockLongValue};
    XCTAssertNil(event.info);
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

- (void)testDescription {
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dinosaur Jogging" type:MPEventTypeNavigation];
    NSString *description = [event description];
    XCTAssertNotNil(description, @"Should not have been nil.");
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

#if TARGET_OS_IOS == 1
- (void)testWebEvent {
    NSURL *oddURL = [[NSURL alloc] initWithString:@"mp-sdk://logEvent/%7B%22EventName%22:%22selected%20my%20response%22,%22EventCategory%22:1,%22UserAttributes%22:%7B%7D,%22UserIdentities%22:%7B%7D,%22Store%22:%7B%7D,%22EventAttributes%22:%7B%22question%20id%22:4644,%22question%20text%22:%22Do%20you%20want%20to%20build%20a%20snowman%3F%22,%22user%20response%22:%22no%22,%22debug_platform%22:%22ios%22%7D,%22SDKVersion%22:%222.3.3%22,%22SessionId%22:%22305b36bb-0eff-4fc1-a20a-7296264da842%22,%22EventDataType%22:4,%22Debug%22:false,%22Location%22:null,%22OptOut%22:null,%22ExpandedEventCount%22:0,%22ClientGeneratedId%22:%221e9c5dec-5171-4780-aa20-16bd6d16aac8%22,%22DeviceId%22:%22a571153f-aad2-4956-be9e-3d7b83051fc3%22,%22MPID%22:0,%22Timestamp%22:1524610824707%7D"];
    
    id mockBackendController = OCMClassMock([MPBackendController class]);
    [MParticle sharedInstance].backendController = mockBackendController;
    
    MPEvent *testEvent = [[MPEvent alloc] init];
    testEvent.name = @"selected my response";
    testEvent.type = MPEventTypeNavigation;
    testEvent.info = @{
                       @"debug_platform": @"ios",
                       @"question id": @4644,
                       @"question text": @"Do you want to build a snowman?",
                       @"user response": @"no"
                       };
    
    [[[mockBackendController expect] ignoringNonObjectArgs] logEvent:[OCMArg checkWithBlock:^BOOL(id value) {
        MPEvent *returnedEvent = ((MPEvent *)value);
        XCTAssertEqualObjects(returnedEvent.name, testEvent.name);
        XCTAssertEqual(returnedEvent.type, testEvent.type);
        XCTAssertEqualObjects(returnedEvent.info, testEvent.info);
        
        return YES;
    }]
                                                   completionHandler:[OCMArg any]];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[MParticle sharedInstance] processWebViewLogEvent: oddURL];
#pragma clang diagnostic pop

    [mockBackendController verifyWithDelay:2];
    
    [mockBackendController stopMocking];
}
#endif

@end

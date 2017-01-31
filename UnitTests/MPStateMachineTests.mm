//
//  MPStateMachineTests.mm
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
#import "MPStateMachine.h"
#import "MPHasher.h"
#import "MPConsumerInfo.h"
#import "MPLaunchInfo.h"

#pragma mark - MPStateMachine category
@interface MPStateMachine(Tests)

- (void)handleApplicationDidEnterBackground:(NSNotification *)notification;
- (void)handleApplicationWillEnterForeground:(NSNotification *)notification;
- (void)handleApplicationWillTerminate:(NSNotification *)notification;
- (void)handleMemoryWarningNotification:(NSNotification *)notification;
- (void)resetRampPercentage;
- (void)resetTriggers;

@end


#pragma mark - MPStateMachineTests
@interface MPStateMachineTests : XCTestCase

@end

@implementation MPStateMachineTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testMPID {
    NSNumber *mpid = @(-7370019784850138375);
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.consumerInfo.mpId = mpid;
    
    XCTAssertEqualObjects(stateMachine.consumerInfo.mpId, mpid, @"mpIds are different.");
    
    stateMachine.consumerInfo.mpId = mpid;
    XCTAssertNotNil(stateMachine.consumerInfo.mpId, @"mpId is not retaining its value.");
}

- (void)testGenerateMPID {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.consumerInfo.mpId = @0; // Reset mpId
    XCTAssertNotNil(stateMachine.consumerInfo.mpId, @"mpId is not being generated.");
    
    NSNumber *mpIdCopy = [stateMachine.consumerInfo.mpId copy];
    stateMachine.consumerInfo.mpId = @0; // Reset mpId
    XCTAssertNotEqualObjects(mpIdCopy, stateMachine.consumerInfo.mpId, @"Regenerating the same mpId.");
}

- (void)testOptOut {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.optOut = YES;
    XCTAssertTrue(stateMachine.optOut, @"OptOut is not being set.");
    
    stateMachine.optOut = NO;
    XCTAssertFalse(stateMachine.optOut, @"OptOut is not being reset.");
}

- (void)testRamp {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    [stateMachine configureRampPercentage:@100];
    XCTAssertFalse(stateMachine.dataRamped, @"Data ramp is not respecting 100 percent upper limit.");
    
    [stateMachine configureRampPercentage:@0];
    XCTAssertTrue(stateMachine.dataRamped, @"Data is not being ramped.");
    
    [stateMachine configureRampPercentage:nil];
    XCTAssertFalse(stateMachine.dataRamped, @"Data ramp is not being reset.");
}

- (void)testConfigureTriggers {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    NSString *hashEvent1 = [NSString stringWithCString:mParticle::Hasher::hashEvent([@"Button Tapped" cStringUsingEncoding:NSUTF8StringEncoding], [@"Transaction" cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                              encoding:NSUTF8StringEncoding];
    
    NSString *hashEvent2 = [NSString stringWithCString:mParticle::Hasher::hashEvent([@"Post Liked" cStringUsingEncoding:NSUTF8StringEncoding], [@"Social" cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                              encoding:NSUTF8StringEncoding];
    
    NSDictionary *triggerDictionary = @{@"tri":@{@"dts":@[@"e", @"pm"],
                                                 @"evts":@[hashEvent1, hashEvent2]
                                                 }
                                        };
    
    [stateMachine configureTriggers:triggerDictionary[@"tri"]];
    
    XCTAssertNotNil(stateMachine.triggerEventTypes, @"Trigger event types are not being set.");
    XCTAssertNotNil(stateMachine.triggerMessageTypes, @"Trigger message types are not being set.");
    
    XCTAssertEqual([stateMachine.triggerEventTypes count], 2, @"Number of stored trigger event types is incorrect.");
    XCTAssertTrue([stateMachine.triggerEventTypes containsObject:hashEvent1], @"Trigger events not being stored properly.");
    XCTAssertTrue([stateMachine.triggerEventTypes containsObject:hashEvent2], @"Trigger events not being stored properly.");
    
    XCTAssertEqual([stateMachine.triggerMessageTypes count], 3, @"Number of stored trigger message types is incorrect.");
    XCTAssertTrue([stateMachine.triggerMessageTypes containsObject:@"e"], @"Trigger messages not being stored properly.");
    XCTAssertTrue([stateMachine.triggerMessageTypes containsObject:@"pm"], @"Trigger messages not being stored properly.");
}

- (void)testNullConfigureTriggers {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    NSString *hashEvent1 = [NSString stringWithCString:mParticle::Hasher::hashEvent([@"Button Tapped" cStringUsingEncoding:NSUTF8StringEncoding], [@"Transaction" cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                              encoding:NSUTF8StringEncoding];
    
    NSString *hashEvent2 = [NSString stringWithCString:mParticle::Hasher::hashEvent([@"Post Liked" cStringUsingEncoding:NSUTF8StringEncoding], [@"Social" cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                              encoding:NSUTF8StringEncoding];
    
    NSDictionary *triggerDictionary = @{@"tri":[NSNull null]
                                        };
    
    [stateMachine configureTriggers:triggerDictionary[@"tri"]];
    
    XCTAssertNil(stateMachine.triggerEventTypes, @"Trigger event types are being set from a null value.");
    XCTAssertEqual(stateMachine.triggerMessageTypes.count, 1, @"Incorrect count.");
    
    triggerDictionary = @{@"tri":@{@"dts":[NSNull null],
                                   @"evts":@[hashEvent1, hashEvent2]
                                   }
                          };
    
    [stateMachine configureTriggers:triggerDictionary[@"tri"]];
    
    XCTAssertNotNil(stateMachine.triggerEventTypes, @"Trigger event types are not being set.");
    XCTAssertEqual(stateMachine.triggerMessageTypes.count, 1, @"Incorrect count.");
    
    triggerDictionary = @{@"tri":@{@"dts":@[@"e", @"pm"],
                                   @"evts":[NSNull null]
                                   }
                          };
    
    [stateMachine configureTriggers:triggerDictionary[@"tri"]];
    
    XCTAssertNil(stateMachine.triggerEventTypes, @"Trigger event types are being set from a null value.");
    XCTAssertNotNil(stateMachine.triggerMessageTypes, @"Trigger message types are not being set.");
    
    triggerDictionary = @{@"tri":@{@"dts":[NSNull null],
                                   @"evts":[NSNull null]
                                   }
                          };
    
    [stateMachine configureTriggers:triggerDictionary[@"tri"]];
    
    XCTAssertNil(stateMachine.triggerEventTypes, @"Trigger event types are being set from a null value.");
    XCTAssertEqual(stateMachine.triggerMessageTypes.count, 1, @"Incorrect count.");
}

- (void)testStateTransitions {
    XCTestExpectation *expectation = [self expectationWithDescription:@"State transitions"];
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    MPLaunchInfo *launchInfo = [[MPLaunchInfo alloc] initWithURL:[NSURL URLWithString:@"http://mparticle.com"]
                                                         options:@{@"Launching":@"WooHoo"}];
    stateMachine.launchInfo = launchInfo;
    XCTAssertFalse(stateMachine.backgrounded, @"Should have been false.");
    XCTAssertNotNil(stateMachine.launchInfo, @"Should not have been nil.");
    XCTAssertFalse([MPStateMachine runningInBackground], @"Should have been false.");
    
    [stateMachine handleApplicationDidEnterBackground:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MPStateMachine setRunningInBackground:YES];
        XCTAssertTrue(stateMachine.backgrounded, @"Should have been true.");
        XCTAssertNil(stateMachine.launchInfo, @"Should have been nil.");
        XCTAssertTrue([MPStateMachine runningInBackground], @"Should have been true.");
        
        [stateMachine handleApplicationWillEnterForeground:nil];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            [MPStateMachine setRunningInBackground:NO];
            XCTAssertFalse(stateMachine.backgrounded, @"Should have been false.");
            XCTAssertFalse([MPStateMachine runningInBackground], @"Should have been false.");
            [expectation fulfill];
        });
    });
    
    [stateMachine handleApplicationWillTerminate:nil];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRamping {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    [stateMachine configureRampPercentage:@0];
    XCTAssertTrue(stateMachine.dataRamped, @"Should have been true.");
    
    [stateMachine resetRampPercentage];
    XCTAssertFalse(stateMachine.dataRamped, @"Should have been false.");
}

- (void)testEventAndMessageTriggers {
    NSDictionary *configuration = @{@"evts":@[@"events"],
                                    @"dts":@[@"messages"]};
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    [stateMachine configureTriggers:configuration];
    XCTAssertNotNil(stateMachine.triggerEventTypes, @"Should not have been nil.");
    XCTAssertNotNil(stateMachine.triggerMessageTypes, @"Should not have been nil.");
    
    [stateMachine resetTriggers];
    XCTAssertNil(stateMachine.triggerEventTypes, @"Should have been nil.");
    XCTAssertNil(stateMachine.triggerMessageTypes, @"Should have been nil.");
}

- (void)testEnvironment {
    [MPStateMachine setEnvironment:MPEnvironmentAutoDetect];
    MPEnvironment environment = [MPStateMachine environment];
    XCTAssertEqual(environment, MPEnvironmentDevelopment, @"Should have been equal.");
    
    [MPStateMachine setEnvironment:MPEnvironmentDevelopment];
    environment = [MPStateMachine environment];
    XCTAssertEqual(environment, MPEnvironmentDevelopment, @"Should have been equal.");
}

@end

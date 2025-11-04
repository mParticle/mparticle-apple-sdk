#ifndef MPARTICLE_LOCATION_DISABLE
@import mParticle_Apple_SDK;
#else
@import mParticle_Apple_SDK_NoLocation;
#endif

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MPBaseTestCase.h"
#import "MPStateMachine.h"
#import "MPKitContainer.h"
#import "MParticleSwift.h"

#pragma mark - MPStateMachine category
@interface MPStateMachine_PRIVATE(Tests)

- (void)handleApplicationDidEnterBackground:(NSNotification *)notification;
- (void)handleApplicationWillEnterForeground:(NSNotification *)notification;
- (void)handleApplicationWillTerminate:(NSNotification *)notification;
- (void)resetRampPercentage;
- (void)resetTriggers;

@end

@interface MParticle ()

@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;

@end

#pragma mark - MPStateMachineTests
@interface MPStateMachineTests : MPBaseTestCase

@end

@implementation MPStateMachineTests

- (void)testOptOut {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    stateMachine.optOut = YES;
    XCTAssertTrue(stateMachine.optOut, @"OptOut is not being set.");
    
    stateMachine.optOut = NO;
    XCTAssertFalse(stateMachine.optOut, @"OptOut is not being reset.");
}

- (void)testRamp {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    [stateMachine configureRampPercentage:@100];
    XCTAssertFalse(stateMachine.dataRamped, @"Data ramp is not respecting 100 percent upper limit.");
    
    [stateMachine configureRampPercentage:@0];
    XCTAssertTrue(stateMachine.dataRamped, @"Data is not being ramped.");
    
    [stateMachine configureRampPercentage:nil];
    XCTAssertFalse(stateMachine.dataRamped, @"Data ramp is not being reset.");
}

- (void)testConfigureTriggers {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSString *hashEvent1 = [MPIHasher hashTriggerEventName:@"Button Tapped" eventType:@"Transaction"];
    NSString *hashEvent2 = [MPIHasher hashTriggerEventName:@"Post Liked" eventType:@"Social"];
    
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
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSString *hashEvent1 = [MPIHasher hashTriggerEventName:@"Button Tapped" eventType:@"Transaction"];
    NSString *hashEvent2 = [MPIHasher hashTriggerEventName:@"Post Liked" eventType:@"Social"];
    
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
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    MPLaunchInfo *launchInfo = [[MPLaunchInfo alloc] initWithURL:[NSURL URLWithString:@"http://mparticle.com"]
                                                         options:@{@"Launching":@"WooHoo"}];
    stateMachine.launchInfo = launchInfo;
    XCTAssertFalse(stateMachine.backgrounded, @"Should have been false.");
    XCTAssertNotNil(stateMachine.launchInfo, @"Should not have been nil.");
    XCTAssertFalse([MPStateMachine_PRIVATE runningInBackground], @"Should have been false.");
    
    [stateMachine handleApplicationDidEnterBackground:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MPStateMachine_PRIVATE setRunningInBackground:YES];
        XCTAssertTrue(stateMachine.backgrounded, @"Should have been true.");
        XCTAssertNil(stateMachine.launchInfo, @"Should have been nil.");
        XCTAssertTrue([MPStateMachine_PRIVATE runningInBackground], @"Should have been true.");
        
        [stateMachine handleApplicationWillEnterForeground:nil];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            [MPStateMachine_PRIVATE setRunningInBackground:NO];
            XCTAssertFalse(stateMachine.backgrounded, @"Should have been false.");
            XCTAssertFalse([MPStateMachine_PRIVATE runningInBackground], @"Should have been false.");
            [expectation fulfill];
        });
    });
    
    [stateMachine handleApplicationWillTerminate:nil];
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testRamping {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    [stateMachine configureRampPercentage:@0];
    XCTAssertTrue(stateMachine.dataRamped, @"Should have been true.");
    
    [stateMachine resetRampPercentage];
    XCTAssertFalse(stateMachine.dataRamped, @"Should have been false.");
}

- (void)testEventAndMessageTriggers {
    NSDictionary *configuration = @{@"evts":@[@"events"],
                                    @"dts":@[@"messages"]};
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    [stateMachine configureTriggers:configuration];
    XCTAssertNotNil(stateMachine.triggerEventTypes, @"Should not have been nil.");
    XCTAssertNotNil(stateMachine.triggerMessageTypes, @"Should not have been nil.");
    
    [stateMachine resetTriggers];
    XCTAssertNil(stateMachine.triggerEventTypes, @"Should have been nil.");
    XCTAssertNil(stateMachine.triggerMessageTypes, @"Should have been nil.");
}

- (void)testEnvironment {
    [MPStateMachine_PRIVATE setEnvironment:MPEnvironmentAutoDetect];
    MPEnvironment environment = [MPStateMachine_PRIVATE environment];
    XCTAssertEqual(environment, MPEnvironmentDevelopment, @"Should have been equal.");
    
    [MPStateMachine_PRIVATE setEnvironment:MPEnvironmentDevelopment];
    environment = [MPStateMachine_PRIVATE environment];
    XCTAssertEqual(environment, MPEnvironmentDevelopment, @"Should have been equal.");
}

- (void)testSetLocation {
#if TARGET_OS_IOS == 1
#ifndef MPARTICLE_LOCATION_DISABLE
    id mockKitContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [MParticle sharedInstance].kitContainer_PRIVATE = mockKitContainer;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Set Location"];
    MPKitContainer_PRIVATE *kitContainer = [MParticle sharedInstance].kitContainer_PRIVATE;
    
    [MParticle sharedInstance].location = [[CLLocation alloc] init];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        OCMVerify([kitContainer forwardSDKCall:@selector(setLocation:)
                                         event:OCMOCK_ANY
                                    parameters:OCMOCK_ANY
                                   messageType:MPMessageTypeEvent
                                      userInfo:OCMOCK_ANY
                   ]);
        [expectation fulfill];
    });


    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
#endif
#endif
}

#if TARGET_OS_IOS == 1
- (void)testRequestAttribution {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request Attribution"];
    void (^searchAdsCompletion)(void) = ^{
        [expectation fulfill];
    };
    
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    [stateMachine requestAttributionDetailsWithBlock:searchAdsCompletion requestsCompleted:0];
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}
#endif

@end

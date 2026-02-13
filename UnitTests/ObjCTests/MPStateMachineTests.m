@import mParticle_Apple_SDK;

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MPBaseTestCase.h"
#import "MPStateMachine.h"
#import "MPKitContainer.h"
@import mParticle_Apple_SDK_Swift;

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
    MParticle* mparticle = MParticle.sharedInstance;
    MPLog* logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
    logger.customLogger = mparticle.customLogger;
    MPIHasher* hasher = [[MPIHasher alloc] initWithLogger:logger];
    NSString *hashEvent1 = [hasher hashTriggerEventName:@"Button Tapped" eventType:@"Transaction"];
    NSString *hashEvent2 = [hasher hashTriggerEventName:@"Post Liked" eventType:@"Social"];
    
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
    MParticle* mparticle = MParticle.sharedInstance;
    MPLog* logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
    logger.customLogger = mparticle.customLogger;
    MPIHasher* hasher = [[MPIHasher alloc] initWithLogger:logger];
    NSString *hashEvent1 = [hasher hashTriggerEventName:@"Button Tapped" eventType:@"Transaction"];
    NSString *hashEvent2 = [hasher hashTriggerEventName:@"Post Liked" eventType:@"Social"];
    
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
    
    MParticle* mparticle = MParticle.sharedInstance;
    MPLog* logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
    logger.customLogger = mparticle.customLogger;
    
    MPLaunchInfo *launchInfo = [[MPLaunchInfo alloc] initWithURL:[NSURL URLWithString:@"http://mparticle.com"]
                                                         options:@{@"Launching":@"WooHoo"} logger:logger];
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

#pragma mark - Thread Safety Tests

- (void)testApiKeySecretThreadSafety {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;

    NSString *originalApiKey = stateMachine.apiKey;
    NSString *originalSecret = stateMachine.secret;
    [self addTeardownBlock:^{
        stateMachine.apiKey = originalApiKey;
        stateMachine.secret = originalSecret;
    }];

    stateMachine.apiKey = @"initial_api_key_value_that_is_long_enough_to_force_heap_allocation";
    stateMachine.secret = @"initial_secret_value_that_is_long_enough_to_force_heap_allocation";

    XCTestExpectation *expectation = [self expectationWithDescription:@"Thread safety stress test"];

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.mparticle.test.statemachine.concurrent", DISPATCH_QUEUE_CONCURRENT);

    NSInteger iterations = 10000;
    __block BOOL encounteredError = NO;

    for (NSInteger i = 0; i < 4; i++) {
        dispatch_group_async(group, concurrentQueue, ^{
            for (NSInteger j = 0; j < iterations && !encounteredError; j++) {
                @try {
                    NSString *key = stateMachine.apiKey;
                    NSString *sec = stateMachine.secret;
                    (void)[key length];
                    (void)[sec length];
                } @catch (NSException *exception) {
                    encounteredError = YES;
                }
            }
        });
    }

    dispatch_group_async(group, concurrentQueue, ^{
        for (NSInteger j = 0; j < iterations && !encounteredError; j++) {
            @try {
                // Use long format strings to force heap-allocated NSString (not tagged pointers)
                stateMachine.apiKey = [NSString stringWithFormat:@"api_key_value_for_thread_safety_test_iteration_%ld", (long)j];
                stateMachine.secret = [NSString stringWithFormat:@"secret_value_for_thread_safety_test_iteration_%ld", (long)j];
            } @catch (NSException *exception) {
                encounteredError = YES;
            }
        }
    });

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        XCTAssertFalse(encounteredError, @"Thread safety test should complete without errors");
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:30 handler:nil];
}

@end

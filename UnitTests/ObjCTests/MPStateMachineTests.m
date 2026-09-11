@import mParticle_Apple_SDK;

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MPBaseTestCase.h"
#import "MPKitContainer+MParticlePrivate.h"
#import "MPUserDefaultsConnector.h"
#import "MPIConstants.h"
#if TARGET_OS_IOS == 1
    #import <AdServices/AAAttribution.h>
#endif
@import mParticle_Apple_SDK_Swift;

// -requestAttributionDetailsWithBlock:requestsCompleted: has no public declaration; it moved to
// MPBackendController_PRIVATE with the state machine wrapper's deletion.
@interface MPBackendController_PRIVATE(Tests)
- (void)requestAttributionDetailsWithBlock:(void (^ _Nonnull)(void))completionHandler requestsCompleted:(int)requestsCompleted;
- (NSURLSession *)attributionURLSession;
@end

@interface MParticle ()

@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

+ (dispatch_queue_t)messageQueue;

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
    id<MPUserDefaultsConnectorProtocol> connector = (id<MPUserDefaultsConnectorProtocol>)[[MPUserDefaultsConnector alloc] init];
    [connector configureRampPercentage:@100];
    XCTAssertFalse(stateMachine.dataRamped, @"Data ramp is not respecting 100 percent upper limit.");
    
    [connector configureRampPercentage:@0];
    XCTAssertTrue(stateMachine.dataRamped, @"Data is not being ramped.");
    
    [connector configureRampPercentage:nil];
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
    
    [stateMachine applyTriggers:triggerDictionary[@"tri"]];
    
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
    
    [stateMachine applyTriggers:triggerDictionary[@"tri"]];
    
    XCTAssertNil(stateMachine.triggerEventTypes, @"Trigger event types are being set from a null value.");
    XCTAssertEqual(stateMachine.triggerMessageTypes.count, 1, @"Incorrect count.");
    
    triggerDictionary = @{@"tri":@{@"dts":[NSNull null],
                                   @"evts":@[hashEvent1, hashEvent2]
                                   }
                          };
    
    [stateMachine applyTriggers:triggerDictionary[@"tri"]];
    
    XCTAssertNotNil(stateMachine.triggerEventTypes, @"Trigger event types are not being set.");
    XCTAssertEqual(stateMachine.triggerMessageTypes.count, 1, @"Incorrect count.");
    
    triggerDictionary = @{@"tri":@{@"dts":@[@"e", @"pm"],
                                   @"evts":[NSNull null]
                                   }
                          };
    
    [stateMachine applyTriggers:triggerDictionary[@"tri"]];
    
    XCTAssertNil(stateMachine.triggerEventTypes, @"Trigger event types are being set from a null value.");
    XCTAssertNotNil(stateMachine.triggerMessageTypes, @"Trigger message types are not being set.");
    
    triggerDictionary = @{@"tri":@{@"dts":[NSNull null],
                                   @"evts":[NSNull null]
                                   }
                          };
    
    [stateMachine applyTriggers:triggerDictionary[@"tri"]];
    
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
    id<MPUserDefaultsConnectorProtocol> connector = (id<MPUserDefaultsConnectorProtocol>)[[MPUserDefaultsConnector alloc] init];
    [connector configureRampPercentage:@0];
    XCTAssertTrue(stateMachine.dataRamped, @"Should have been true.");
    
    [stateMachine resetRampPercentage];
    XCTAssertFalse(stateMachine.dataRamped, @"Should have been false.");
}

- (void)testEventAndMessageTriggers {
    NSDictionary *configuration = @{@"evts":@[@"events"],
                                    @"dts":@[@"messages"]};
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    [stateMachine applyTriggers:configuration];
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
    
    [MParticle sharedInstance].backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
    [[MParticle sharedInstance].backendController requestAttributionDetailsWithBlock:searchAdsCompletion
                                                                  requestsCompleted:0];
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

// Pins the defect this test file could not see: -dataTaskWithRequest:completionHandler: hands back
// a suspended task, so without -resume the attribution request was never sent and the completion
// handler never ran. Invisible on the simulator, where AAAttribution fails and the early return
// fires the handler before a request is ever built.
- (void)testRequestAttributionResumesTheDataTask {
    id attribution = OCMClassMock([AAAttribution class]);
    [[[attribution stub] andReturn:@"attribution-token"] attributionTokenWithError:[OCMArg anyObjectRef]];

    id dataTask = OCMClassMock([NSURLSessionDataTask class]);
    id session = OCMClassMock([NSURLSession class]);
    [[[session stub] andReturn:dataTask] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    MPBackendController_PRIVATE *controller =
        [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
    id controllerMock = OCMPartialMock(controller);
    [[[controllerMock stub] andReturn:session] attributionURLSession];

    XCTestExpectation *resumed = [self expectationWithDescription:@"attribution data task resumed"];
    [[[dataTask stub] andDo:^(NSInvocation *invocation) {
        [resumed fulfill];
    }] resume];

    [controller requestAttributionDetailsWithBlock:^{} requestsCompleted:0];

    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];

    [controllerMock stopMocking];
    [attribution stopMocking];
}
#endif

#pragma mark - Data blocking configuration

// The data-planning payload comes off the configuration response, so its shape is untrusted.
// MPIsNull only rejects nil and NSNull; keyed subscripting a non-dictionary raises.
- (void)testConfigureDataBlockingToleratesMalformedShapes {
    id<MPUserDefaultsConnectorProtocol> connector =
        (id<MPUserDefaultsConnectorProtocol>)[[MPUserDefaultsConnector alloc] init];

    // Hoisted into locals: collection literals contain commas, which XCTAssertNoThrow would
    // otherwise parse as macro argument separators.
    NSDictionary *nullPlan = @{kMPRemoteConfigDataPlanning: [NSNull null]};
    NSDictionary *stringPlan = @{kMPRemoteConfigDataPlanning: @"not a dictionary"};
    NSDictionary *arrayPlan = @{kMPRemoteConfigDataPlanning: @[@1, @2]};
    NSDictionary *stringBlock = @{kMPRemoteConfigDataPlanning: @{kMPRemoteConfigDataPlanningBlock: @"not a dictionary"}};
    NSDictionary *arrayBlock = @{kMPRemoteConfigDataPlanning: @{kMPRemoteConfigDataPlanningBlock: @[@1, @2]}};

    XCTAssertNoThrow([connector configureDataBlocking:nil]);
    XCTAssertNoThrow([connector configureDataBlocking:(NSDictionary *)[NSNull null]]);
    XCTAssertNoThrow([connector configureDataBlocking:@{}]);
    XCTAssertNoThrow([connector configureDataBlocking:nullPlan]);
    XCTAssertNoThrow([connector configureDataBlocking:stringPlan]);
    XCTAssertNoThrow([connector configureDataBlocking:arrayPlan]);
    XCTAssertNoThrow([connector configureDataBlocking:stringBlock]);
    XCTAssertNoThrow([connector configureDataBlocking:arrayBlock]);
}

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

#pragma mark - Background UserDefaults Serialization Tests

- (void)testUpdateLastUseDateSerializedWithMessageQueueWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Serialized background access"];

    [MParticle sharedInstance].backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
    [MPPersistenceUtilities setMpid:@12345];

    MPUserDefaults *defaults = MPUserDefaultsConnector.userDefaults;

    dispatch_queue_t sdkMessageQueue = [MParticle messageQueue];
    dispatch_group_t group = dispatch_group_create();
    NSInteger iterations = 500;

    for (NSInteger i = 0; i < iterations; i++) {
        dispatch_group_async(group, sdkMessageQueue, ^{
            [MPApplication_PRIVATE updateLastUseDate:[NSDate date] userDefaults:(id<MPApplicationMPUserDefaultsProtocol>)MPUserDefaultsConnector.userDefaults];
        });

        dispatch_group_async(group, sdkMessageQueue, ^{
            [defaults setMPObject:@(i) forKey:@"testBg" userId:[MPPersistenceUtilities mpId]];
        });

        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSNumber *mpId = [MPPersistenceUtilities mpId];
            (void)mpId;
        });
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        MPUserDefaults *ud = MPUserDefaultsConnector.userDefaults;
        NSNumber *lastUseDate = ud[MPApplicationKeys.kMPAppLastUseDateKey];
        XCTAssertNotNil(lastUseDate, @"lastUseDate must be persisted after background transition");
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testSubscriptAccessorThreadSafety {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Subscript thread safety"];

    [MParticle sharedInstance].backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
    [MPPersistenceUtilities setMpid:@42];

    MPUserDefaults *defaults = MPUserDefaultsConnector.userDefaults;

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.mparticle.test.subscript.concurrent", DISPATCH_QUEUE_CONCURRENT);
    NSInteger iterations = 1000;

    for (NSInteger i = 0; i < iterations; i++) {
        dispatch_group_async(group, concurrentQueue, ^{
            id value = defaults[@"lud"];
            (void)value;
        });

        dispatch_group_async(group, concurrentQueue, ^{
            defaults[@"lud"] = @(1234567890 + i);
        });

        dispatch_group_async(group, concurrentQueue, ^{
            id mpidValue = defaults[@"mpid"];
            (void)mpidValue;
        });

        dispatch_group_async(group, concurrentQueue, ^{
            defaults[@"mpid"] = @(i % 100);
        });
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testUpdateLastUseDateWithNilDate {
    [MParticle sharedInstance].backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
    [MPPersistenceUtilities setMpid:@1];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [MPApplication_PRIVATE updateLastUseDate:nil userDefaults:(id<MPApplicationMPUserDefaultsProtocol>)MPUserDefaultsConnector.userDefaults];
#pragma clang diagnostic pop

    MPUserDefaults *defaults = MPUserDefaultsConnector.userDefaults;
    NSNumber *lastUseDate = defaults[MPApplicationKeys.kMPAppLastUseDateKey];
    XCTAssertNotNil(lastUseDate);
    XCTAssertEqualObjects(lastUseDate, @0);
}

@end

@import mParticle_Apple_SDK;

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <objc/runtime.h>
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

/// Regression guard for #578. `MPURLRequestBuilder` reads `apiKey` and `secret` on every signed
/// request, from background queues. Declared `nonatomic`, the synthesized getter returns the ivar
/// without retaining it, so a concurrent setter can release the string in the window before the
/// reader retains it — a use-after-free inside request signing. `atomic` is the fix, because
/// `objc_getProperty` retains and autoreleases before returning.
///
/// Asserted against the declaration rather than by racing threads: the fault is a memory error, not
/// an `NSException`, so it can only ever kill the test runner. `testApiKeySecretThreadSafety` below
/// exercises the same contract at runtime, but only this assertion can name the regression.
- (void)testApiKeySecretAccessorsAreAtomic {
    [self assertPropertyIsAtomic:@"apiKey" onClass:[MPStateMachine_PRIVATE class]];
    [self assertPropertyIsAtomic:@"secret" onClass:[MPStateMachine_PRIVATE class]];
}

- (void)assertPropertyIsAtomic:(NSString *)propertyName onClass:(Class)aClass {
    objc_property_t property = class_getProperty(aClass, propertyName.UTF8String);
    if (property == NULL) {
        XCTFail(@"%@ declares no property named %@", NSStringFromClass(aClass), propertyName);
        return;
    }

    NSString *attributes = @(property_getAttributes(property));
    BOOL isNonatomic = [[attributes componentsSeparatedByString:@","] containsObject:@"N"];
    XCTAssertFalse(isNonatomic,
                   @"%@.%@ must stay atomic: a nonatomic strong getter returns the ivar unretained, "
                   @"letting a concurrent setter free the value under a reader that is signing a "
                   @"request. Attributes were \"%@\".",
                   NSStringFromClass(aClass), propertyName, attributes);
}

/// Exercises the accessors under contention. The state machine is this test's own rather than
/// `[MParticle sharedInstance].stateMachine`, so the readers are not competing with the SDK's own
/// background work and a failure here cannot hand the next test a key it would sign a request with.
- (void)testApiKeySecretThreadSafety {
    MPStateMachine_PRIVATE *stateMachine = [[MPStateMachine_PRIVATE alloc] init];

    NSString *apiKeyPrefix = @"api_key_value_for_thread_safety_test_iteration_";
    NSString *secretPrefix = @"secret_value_for_thread_safety_test_iteration_";

    stateMachine.apiKey = [apiKeyPrefix stringByAppendingString:@"initial"];
    stateMachine.secret = [secretPrefix stringByAppendingString:@"initial"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Thread safety stress test"];

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.mparticle.test.statemachine.concurrent", DISPATCH_QUEUE_CONCURRENT);

    NSInteger iterations = 10000;
    NSMutableArray<NSString *> *unpublishedValues = [NSMutableArray array];
    NSLock *unpublishedValuesLock = [[NSLock alloc] init];

    void (^recordUnlessPublished)(NSString *, NSString *) = ^(NSString *value, NSString *expectedPrefix) {
        if ([value hasPrefix:expectedPrefix]) {
            return;
        }
        [unpublishedValuesLock lock];
        if (unpublishedValues.count < 10) {
            [unpublishedValues addObject:value ?: @"(nil)"];
        }
        [unpublishedValuesLock unlock];
    };

    for (NSInteger i = 0; i < 4; i++) {
        dispatch_group_async(group, concurrentQueue, ^{
            for (NSInteger j = 0; j < iterations; j++) {
                recordUnlessPublished(stateMachine.apiKey, apiKeyPrefix);
                recordUnlessPublished(stateMachine.secret, secretPrefix);
            }
        });
    }

    dispatch_group_async(group, concurrentQueue, ^{
        for (NSInteger j = 0; j < iterations; j++) {
            // Values long enough to be heap allocated rather than tagged pointers, drained every
            // iteration so the string the setter replaces is really deallocated. Without the drain
            // the writer's autorelease pool keeps every value alive to the end of the loop, and
            // nothing is ever freed under a reader — the failure this looks for cannot happen.
            @autoreleasepool {
                stateMachine.apiKey = [apiKeyPrefix stringByAppendingFormat:@"%ld", (long)j];
                stateMachine.secret = [secretPrefix stringByAppendingFormat:@"%ld", (long)j];
            }
        }
    });

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
    XCTAssertEqualObjects(unpublishedValues, @[], @"Readers saw values the writer never published");
}

/// The singleton path on its own, without a stress loop: the SDK reads these through
/// `[MParticle sharedInstance].stateMachine`, so a write on one queue has to be visible on another.
/// The originals go back in the body as well as from a teardown block, so neither a failure nor a
/// crash here leaves a test key behind for whatever runs next.
- (void)testSingletonApiKeySecretVisibleAcrossQueues {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    NSString *originalApiKey = stateMachine.apiKey;
    NSString *originalSecret = stateMachine.secret;
    [self addTeardownBlock:^{
        stateMachine.apiKey = originalApiKey;
        stateMachine.secret = originalSecret;
    }];

    NSString *apiKey = @"api_key_value_long_enough_to_be_heap_allocated";
    NSString *secret = @"secret_value_long_enough_to_be_heap_allocated";
    stateMachine.apiKey = apiKey;
    stateMachine.secret = secret;

    XCTestExpectation *expectation = [self expectationWithDescription:@"Read from a background queue"];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        MPStateMachine_PRIVATE *sharedStateMachine = [MParticle sharedInstance].stateMachine;
        XCTAssertEqualObjects(sharedStateMachine.apiKey, apiKey);
        XCTAssertEqualObjects(sharedStateMachine.secret, secret);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];

    stateMachine.apiKey = originalApiKey;
    stateMachine.secret = originalSecret;
}

#pragma mark - Background UserDefaults Serialization Tests

- (void)testUpdateLastUseDateSerializedWithMessageQueueWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Serialized background access"];

    [MParticle sharedInstance].backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
    [MPPersistenceController_PRIVATE setMpid:@12345];

    MPUserDefaults *defaults = MPUserDefaultsConnector.userDefaults;

    dispatch_queue_t sdkMessageQueue = [MParticle messageQueue];
    dispatch_group_t group = dispatch_group_create();
    NSInteger iterations = 500;

    for (NSInteger i = 0; i < iterations; i++) {
        dispatch_group_async(group, sdkMessageQueue, ^{
            [MPApplication_PRIVATE updateLastUseDate:[NSDate date]];
        });

        dispatch_group_async(group, sdkMessageQueue, ^{
            [defaults setMPObject:@(i) forKey:@"testBg" userId:[MPPersistenceController_PRIVATE mpId]];
        });

        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSNumber *mpId = [MPPersistenceController_PRIVATE mpId];
            (void)mpId;
        });
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        MPUserDefaults *ud = MPUserDefaultsConnector.userDefaults;
        NSNumber *lastUseDate = ud[kMPAppLastUseDateKey];
        XCTAssertNotNil(lastUseDate, @"lastUseDate must be persisted after background transition");
        [expectation fulfill];
    });

    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testSubscriptAccessorThreadSafety {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Subscript thread safety"];

    [MParticle sharedInstance].backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
    [MPPersistenceController_PRIVATE setMpid:@42];

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
    [MPPersistenceController_PRIVATE setMpid:@1];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [MPApplication_PRIVATE updateLastUseDate:nil];
#pragma clang diagnostic pop

    MPUserDefaults *defaults = MPUserDefaultsConnector.userDefaults;
    NSNumber *lastUseDate = defaults[kMPAppLastUseDateKey];
    XCTAssertNotNil(lastUseDate);
    XCTAssertEqualObjects(lastUseDate, @0);
}

@end

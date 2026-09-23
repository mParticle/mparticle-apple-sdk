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

// Redeclared rather than imported from MParticle+PrivateMethods.h: that header is written for the
// Swift bridging header and its other declarations do not resolve from an ObjC translation unit.
// Typed id to avoid pulling in the filter protocol for what is only a nil check.
@interface MParticle (MPStateMachineTests)
@property (nonatomic, strong, nullable) id dataPlanFilter;
@end

// -requestAttributionDetailsWithBlock:requestsCompleted: has no public declaration; it moved to
// MPBackendController_PRIVATE with the state machine wrapper's deletion.
@interface MPBackendController_PRIVATE(Tests)
- (void)requestAttributionDetailsWithBlock:(void (^ _Nonnull)(void))completionHandler requestsCompleted:(int)requestsCompleted;
- (NSURLSession *)attributionURLSession;
- (dispatch_block_t)singleShotBlock:(dispatch_block_t)block;
@end

@interface MParticle ()

@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

+ (dispatch_queue_t)messageQueue;
+ (BOOL)isMessageQueue;

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

#pragma mark - Malformed server configuration

- (void)testConfigureCustomModulesSkipsMalformedEntries {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSArray *customModuleSettings = @[
                                      @1,
                                      @"Not a dictionary.",
                                      [NSNull null],
                                      @{@"id":@22,
                                        @"pr":@[
                                                @{@"f":@"NSUserDefaults",
                                                  @"m":@0,
                                                  @"ps":@[
                                                          @1,
                                                          @"Not a dictionary.",
                                                          [NSNull null],
                                                          @{@"k":@"WELL_FORMED_KEY", @"t":@1, @"n":@"vid", @"d":@"0"}
                                                          ]
                                                  }
                                                ]
                                        }
                                      ];
    
    XCTAssertNoThrow([stateMachine configureCustomModules:customModuleSettings]);
    XCTAssertEqual(stateMachine.customModules.count, 1, @"Only the well-formed module should have been configured.");
    
    MPCustomModule *customModule = stateMachine.customModules.firstObject;
    XCTAssertEqualObjects(customModule.customModuleId, @22, @"Should have been equal.");
    XCTAssertEqual(customModule.preferences.count, 1, @"The malformed preference settings should have been skipped.");
}

- (void)testConfigureCustomModulesWithNonArrayIsIgnored {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    for (id malformed in @[@1, @"Not an array.", @{@"a":@"b"}]) {
        XCTAssertNoThrow([stateMachine configureCustomModules:malformed], @"Threw on cms %@.", malformed);
    }
}

// configureTriggers: and configureDataBlocking: moved off the state machine and onto the
// connector, which now applies every configuration section inside an exception boundary. Driving
// them through the connector exercises the same path the configuration response takes.
- (void)testConfigureTriggersIgnoresWrongTypedValues {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    id<MPUserDefaultsConnectorProtocol> connector = (id<MPUserDefaultsConnectorProtocol>)[[MPUserDefaultsConnector alloc] init];
    
    for (id malformed in @[@"Not an array.", @5, @{@"a":@"b"}, @[@[]]]) {
        XCTAssertNoThrow(([connector configureTriggers:@{@"evts":malformed, @"dts":malformed}]), @"Threw on %@.", malformed);
        
        if ([malformed isKindOfClass:[NSArray class]]) {
            continue;
        }
        XCTAssertNil(stateMachine.triggerEventTypes, @"A non-array evts must not be stored (%@).", malformed);
        XCTAssertEqual(stateMachine.triggerMessageTypes.count, 1, @"A non-array dts must be ignored (%@).", malformed);
    }
    
    XCTAssertNoThrow([connector configureTriggers:(NSDictionary *)@"Not a dictionary."]);
    
    [stateMachine resetTriggers];
}

- (void)testConfigureTriggersRecoversFromWrongTypedEventTypes {
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    id<MPUserDefaultsConnectorProtocol> connector = (id<MPUserDefaultsConnectorProtocol>)[[MPUserDefaultsConnector alloc] init];
    
    [connector configureTriggers:@{@"evts":@"Not an array."}];
    XCTAssertNil(stateMachine.triggerEventTypes, @"A non-array evts must not be stored.");
    
    NSArray *eventTypes = @[@"3941658766", @"1560839252"];
    XCTAssertNoThrow(([connector configureTriggers:@{@"evts":eventTypes, @"dts":@[@"e"]}]), @"A well-formed configuration must be able to follow a malformed one.");
    XCTAssertEqualObjects(stateMachine.triggerEventTypes, eventTypes, @"Should have been equal.");
    
    [stateMachine resetTriggers];
}

- (void)testConfigureDataBlockingIgnoresWrongTypedValues {
    id<MPUserDefaultsConnectorProtocol> connector = (id<MPUserDefaultsConnectorProtocol>)[[MPUserDefaultsConnector alloc] init];
    
    NSArray<NSDictionary *> *malformedSettings = @[
                                                   @{@"dtpn":@"Not a dictionary."},
                                                   @{@"dtpn":@5},
                                                   @{@"dtpn":[NSNull null]},
                                                   @{@"dtpn":@[]},
                                                   @{@"dtpn":@{@"blok":@"Not a dictionary."}},
                                                   @{@"dtpn":@{@"blok":@[]}},
                                                   @{@"dtpn":@{@"blok":[NSNull null]}},
                                                   @{@"dtpn":@{@"blok":@{@"ev":[NSNull null], @"ea":@[], @"ua":@{}, @"id":@"true"}}},
                                                   @{@"dtpn":@{@"vers":@"Not a dictionary."}},
                                                   @{@"dtpn":@{@"vers":@[]}},
                                                   @{@"dtpn":@{@"vers":[NSNull null]}}
                                                   ];
    
    for (NSDictionary *malformed in malformedSettings) {
        XCTAssertNoThrow([connector configureDataBlocking:malformed], @"Threw on dpr %@.", malformed);
    }
    
    XCTAssertNoThrow([connector configureDataBlocking:(NSDictionary *)@"Not a dictionary."]);
    
    [connector configureDataBlocking:@{}];
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

    // Every mock has to be stopped, the two class mocks included: OCMClassMock swizzles the class
    // itself, so leaving NSURLSession or NSURLSessionDataTask mocked would intercept networking in
    // whatever test runs next in this process.
    [controllerMock stopMocking];
    [session stopMocking];
    [dataTask stopMocking];
    [attribution stopMocking];
}
// The data task's completion handler runs on the URL session's delegate queue, not the SDK's
// serial message queue. Everything searchAdsCompletion goes on to do - forwarding install/update
// to kits, the config request, the upload cycle - assumes the message queue, so the completion has
// to hop back before running.
- (void)testAttributionCompletionRunsOnTheMessageQueue {
    id attribution = OCMClassMock([AAAttribution class]);
    [[[attribution stub] andReturn:@"attribution-token"] attributionTokenWithError:[OCMArg anyObjectRef]];

    // Capture the handler the SDK hands to -dataTaskWithRequest:completionHandler: so the test can
    // invoke it from a queue that is definitely not the message queue.
    __block void (^capturedHandler)(NSData *, NSURLResponse *, NSError *) = nil;
    id dataTask = OCMClassMock([NSURLSessionDataTask class]);
    id session = OCMClassMock([NSURLSession class]);
    [[[[session stub] andReturn:dataTask] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^handler)(NSData *, NSURLResponse *, NSError *) = nil;
        [invocation getArgument:&handler atIndex:3];
        capturedHandler = [handler copy];
    }] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    MPBackendController_PRIVATE *controller =
        [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
    id controllerMock = OCMPartialMock(controller);
    [[[controllerMock stub] andReturn:session] attributionURLSession];

    XCTestExpectation *handlerCaptured = [self expectationWithDescription:@"data task built"];
    [[[dataTask stub] andDo:^(NSInvocation *invocation) {
        [handlerCaptured fulfill];
    }] resume];

    XCTestExpectation *completed = [self expectationWithDescription:@"attribution completion ran"];
    __block BOOL ranOnMessageQueue = NO;
    [controller requestAttributionDetailsWithBlock:^{
        ranOnMessageQueue = [MParticle isMessageQueue];
        [completed fulfill];
    } requestsCompleted:0];

    [self waitForExpectations:@[handlerCaptured] timeout:DEFAULT_TIMEOUT];
    XCTAssertNotNil(capturedHandler);

    // ADClientErrorLimitAdTracking: the shortest path to the completion, no retry, no JSON.
    NSError *limitAdTracking = [NSError errorWithDomain:@"ADClientErrorDomain" code:1 userInfo:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertFalse([MParticle isMessageQueue], @"the test must drive the handler off the message queue");
        capturedHandler(nil, nil, limitAdTracking);
    });

    [self waitForExpectations:@[completed] timeout:DEFAULT_TIMEOUT];
    XCTAssertTrue(ranOnMessageQueue, @"the attribution completion must run on the SDK message queue");

    [controllerMock stopMocking];
    [session stopMocking];
    [dataTask stopMocking];
    [attribution stopMocking];
}

// NSURLSession reports no error for a non-2xx response, so before the status check a 500 fell into
// the success branch: it parsed nothing, stored an empty searchAdsInfo and completed without ever
// retrying. Resuming the data task is what made that branch reachable.
- (void)testAttributionRetriesOnAnHTTPErrorInsteadOfCompleting {
    id attribution = OCMClassMock([AAAttribution class]);
    [[[attribution stub] andReturn:@"attribution-token"] attributionTokenWithError:[OCMArg anyObjectRef]];

    __block void (^capturedHandler)(NSData *, NSURLResponse *, NSError *) = nil;
    id dataTask = OCMClassMock([NSURLSessionDataTask class]);
    id session = OCMClassMock([NSURLSession class]);
    [[[[session stub] andReturn:dataTask] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^handler)(NSData *, NSURLResponse *, NSError *) = nil;
        [invocation getArgument:&handler atIndex:3];
        capturedHandler = [handler copy];
    }] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    MPBackendController_PRIVATE *controller =
        [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
    id controllerMock = OCMPartialMock(controller);
    [[[controllerMock stub] andReturn:session] attributionURLSession];

    XCTestExpectation *built = [self expectationWithDescription:@"data task built"];
    [[[dataTask stub] andDo:^(NSInvocation *invocation) {
        [built fulfill];
    }] resume];

    // Inverted: a retryable response must schedule another attempt, not finish the flow.
    XCTestExpectation *completed = [self expectationWithDescription:@"completion must not run"];
    completed.inverted = YES;
    [controller requestAttributionDetailsWithBlock:^{
        [completed fulfill];
    } requestsCompleted:0];

    [self waitForExpectations:@[built] timeout:DEFAULT_TIMEOUT];
    XCTAssertNotNil(capturedHandler);

    NSHTTPURLResponse *serverError = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://api-adservices.apple.com/api/v1/"]
                                                                 statusCode:500
                                                                HTTPVersion:@"HTTP/1.1"
                                                               headerFields:nil];
    capturedHandler([@"{}" dataUsingEncoding:NSUTF8StringEncoding], serverError, nil);

    // The retry is scheduled SEARCH_ADS_ATTRIBUTION_DELAY_BEFORE_RETRY out, so a shorter wait here
    // proves the completion did not fire on the spot.
    [self waitForExpectations:@[completed] timeout:1.0];

    [controllerMock stopMocking];
    [session stopMocking];
    [dataTask stopMocking];
    [attribution stopMocking];
}

// Apple answers 404 while a freshly minted token becomes resolvable, and documents a re-poll. The
// body is a well-formed JSON object on purpose: the later "not an object" guard cannot catch this
// one, so only the status check keeps an error body from being mapped as attribution data.
- (void)testAttributionRetriesOnA404CarryingAJSONObject {
    [self assertAttributionRetriesForStatusCode:404
                                           body:[@"{\"error\":\"not found\"}" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)testAttributionRetriesWhenTheBodyIsEmpty {
    [self assertAttributionRetriesForStatusCode:200 body:nil];
}

// A 200 whose body is not a JSON object. The old code subscripted it for nine keys, so an array
// root raised on objectForKeyedSubscript: and a non-object parse result reached the literal as nil.
- (void)testAttributionRetriesWhenTheBodyIsNotAJSONObject {
    [self assertAttributionRetriesForStatusCode:200 body:[@"[1,2]" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)assertAttributionRetriesForStatusCode:(NSInteger)statusCode body:(NSData *)body {
    id attribution = OCMClassMock([AAAttribution class]);
    [[[attribution stub] andReturn:@"attribution-token"] attributionTokenWithError:[OCMArg anyObjectRef]];

    __block void (^capturedHandler)(NSData *, NSURLResponse *, NSError *) = nil;
    id dataTask = OCMClassMock([NSURLSessionDataTask class]);
    id session = OCMClassMock([NSURLSession class]);
    [[[[session stub] andReturn:dataTask] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^handler)(NSData *, NSURLResponse *, NSError *) = nil;
        [invocation getArgument:&handler atIndex:3];
        capturedHandler = [handler copy];
    }] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    MPBackendController_PRIVATE *controller =
        [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
    id controllerMock = OCMPartialMock(controller);
    [[[controllerMock stub] andReturn:session] attributionURLSession];

    XCTestExpectation *built = [self expectationWithDescription:@"data task built"];
    [[[dataTask stub] andDo:^(NSInvocation *invocation) {
        [built fulfill];
    }] resume];

    XCTestExpectation *completed = [self expectationWithDescription:@"completion must not run"];
    completed.inverted = YES;
    [controller requestAttributionDetailsWithBlock:^{
        [completed fulfill];
    } requestsCompleted:0];

    [self waitForExpectations:@[built] timeout:DEFAULT_TIMEOUT];
    XCTAssertNotNil(capturedHandler);

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://api-adservices.apple.com/api/v1/"]
                                                              statusCode:statusCode
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:nil];
    XCTAssertNoThrow(capturedHandler(body, response, nil));

    // Shorter than SEARCH_ADS_ATTRIBUTION_DELAY_BEFORE_RETRY, so this proves a retry was scheduled
    // rather than the flow being finished on the spot.
    [self waitForExpectations:@[completed] timeout:1.0];

    [controllerMock stopMocking];
    [session stopMocking];
    [dataTask stopMocking];
    [attribution stopMocking];
}

// The finding's stated verification for the retry criterion: a 404 followed by a 200 must retry,
// then record attribution, and run the completion exactly once.
- (void)testAttributionRecordsTheResultAfterRetryingA404 {
    id attribution = OCMClassMock([AAAttribution class]);
    [[[attribution stub] andReturn:@"attribution-token"] attributionTokenWithError:[OCMArg anyObjectRef]];

    __block void (^capturedHandler)(NSData *, NSURLResponse *, NSError *) = nil;
    id dataTask = OCMClassMock([NSURLSessionDataTask class]);
    id session = OCMClassMock([NSURLSession class]);
    [[[[session stub] andReturn:dataTask] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained void (^handler)(NSData *, NSURLResponse *, NSError *) = nil;
        [invocation getArgument:&handler atIndex:3];
        capturedHandler = [handler copy];
    }] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    MPBackendController_PRIVATE *controller =
        [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
    id controllerMock = OCMPartialMock(controller);
    [[[controllerMock stub] andReturn:session] attributionURLSession];

    // The retry builds a second task from the same stubbed session, replacing capturedHandler.
    XCTestExpectation *firstAttempt = [self expectationWithDescription:@"first data task built"];
    XCTestExpectation *retryAttempt = [self expectationWithDescription:@"retry data task built"];
    __block NSUInteger resumeCount = 0;
    [[[dataTask stub] andDo:^(NSInvocation *invocation) {
        resumeCount += 1;
        [(resumeCount == 1 ? firstAttempt : retryAttempt) fulfill];
    }] resume];

    [MParticle sharedInstance].stateMachine.searchAdsInfo = @{};

    XCTestExpectation *completed = [self expectationWithDescription:@"attribution completion ran"];
    __block NSUInteger completionCount = 0;
    [controller requestAttributionDetailsWithBlock:^{
        completionCount += 1;
        [completed fulfill];
    } requestsCompleted:0];

    [self waitForExpectations:@[firstAttempt] timeout:DEFAULT_TIMEOUT];
    NSHTTPURLResponse *notFound = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://api-adservices.apple.com/api/v1/"]
                                                              statusCode:404
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:nil];
    // A parseable body, so only the status check can send this down the retry path.
    capturedHandler([@"{\"error\":\"not found\"}" dataUsingEncoding:NSUTF8StringEncoding], notFound, nil);

    [self waitForExpectations:@[retryAttempt] timeout:DEFAULT_TIMEOUT];
    NSHTTPURLResponse *success = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://api-adservices.apple.com/api/v1/"]
                                                             statusCode:200
                                                            HTTPVersion:@"HTTP/1.1"
                                                           headerFields:nil];
    NSData *payload = [@"{\"attribution\":true,\"orgId\":12,\"campaignId\":34}" dataUsingEncoding:NSUTF8StringEncoding];
    capturedHandler(payload, success, nil);

    [self waitForExpectations:@[completed] timeout:DEFAULT_TIMEOUT];

    NSDictionary *recorded = [MParticle sharedInstance].stateMachine.searchAdsInfo[@"Version4.0"];
    XCTAssertEqualObjects(recorded[@"iad-org-id"], @"12");
    XCTAssertEqualObjects(recorded[@"iad-campaign-id"], @"34");
    XCTAssertEqual(completionCount, 1, @"The completion must run once across both attempts");

    [controllerMock stopMocking];
    [session stopMocking];
    [dataTask stopMocking];
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

// The tolerance tests above are satisfied by the exception boundary alone, so they stay green even
// with the per-flag guard removed. This one binds to the guard: a malformed flag must be treated
// as absent rather than raising, because a raise aborts the whole section and takes the
// well-formed flags and the data plan down with it.
- (void)testMalformedBlockFlagDoesNotDiscardTheRestOfTheDataPlan {
    MParticle.sharedInstance.dataPlanFilter = nil;

    id<MPUserDefaultsConnectorProtocol> connector =
        (id<MPUserDefaultsConnectorProtocol>)[[MPUserDefaultsConnector alloc] init];

    NSDictionary *settings = @{kMPRemoteConfigDataPlanning: @{
                                   kMPRemoteConfigDataPlanningBlock: @{
                                       kMPRemoteConfigDataPlanningBlockUnplannedEvents: @[],
                                       kMPRemoteConfigDataPlanningBlockUnplannedEventAttributes: @YES
                                   },
                                   kMPRemoteConfigDataPlanningDataPlanVersionValue: @{@"version_document": @{}}
                               }};

    XCTAssertNoThrow([connector configureDataBlocking:settings]);
    XCTAssertNotNil(MParticle.sharedInstance.dataPlanFilter,
                    @"An array where a block flag belongs must not abort the data plan section.");

    MParticle.sharedInstance.dataPlanFilter = nil;
}

#pragma mark - Search Ads completion

// The attribution completion has two triggers that are never mutually cancelled: the request
// itself and a 30s global timeout. -processDidFinishLaunching is not idempotent, so the block has
// to run once regardless of how many fire.
- (void)testSingleShotBlockRunsOnlyOnce {
    MPBackendController_PRIVATE *controller =
        [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];

    __block NSInteger runCount = 0;
    dispatch_block_t once = [controller singleShotBlock:^{
        runCount += 1;
    }];

    once();
    once();
    once();

    XCTAssertEqual(runCount, 1, @"The wrapped block must run exactly once.");
}

- (void)testSingleShotBlockRunsOnlyOnceUnderConcurrentCallers {
    MPBackendController_PRIVATE *controller =
        [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];

    // The two real triggers fire on different queues, so the guard has to hold across threads.
    NSLock *countLock = [[NSLock alloc] init];
    __block NSInteger runCount = 0;
    dispatch_block_t once = [controller singleShotBlock:^{
        [countLock lock];
        runCount += 1;
        [countLock unlock];
    }];

    dispatch_queue_t concurrentQueue =
        dispatch_queue_create("com.mparticle.test.singleshot", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    for (NSInteger i = 0; i < 200; i++) {
        dispatch_group_async(group, concurrentQueue, ^{
            once();
        });
    }
    dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)));

    [countLock lock];
    NSInteger finalCount = runCount;
    [countLock unlock];
    XCTAssertEqual(finalCount, 1, @"The wrapped block must run exactly once across concurrent callers.");
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

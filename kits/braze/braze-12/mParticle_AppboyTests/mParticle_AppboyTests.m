@import mParticle_Apple_SDK;
@import mParticle_Appboy;
@import XCTest;
@import OCMock;
#if TARGET_OS_IOS
    @import BrazeKitCompat;
    @import BrazeUI;
#else
    @import BrazeKitCompat;
#endif

@interface MPKitAppboy ()

- (Braze *)appboyInstance;
- (void)setAppboyInstance:(Braze *)instance;
- (NSMutableDictionary<NSString *, NSNumber *> *)optionsDictionary;
+ (id<BrazeInAppMessageUIDelegate>)inAppMessageControllerDelegate;
- (void)setEnableTypeDetection:(BOOL)enableTypeDetection;
+ (BOOL)shouldDisableNotificationHandling;
+ (Braze *)brazeInstance;
+ (MPKitExecStatus *)updateUser:(FilteredMParticleUser *)user request:(NSDictionary<NSNumber *,NSString *> *)userIdentities;
+ (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value;

@end

@interface mParticle_AppboyTests : XCTestCase

@end

@implementation mParticle_AppboyTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [MPKitAppboy setBrazeInstance:nil];
    [MPKitAppboy setURLDelegate:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testStartwithSimpleConfig {
    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
    
    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42
                                       };
    
    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
    
    NSDictionary *testOptionsDictionary = @{ABKEnableAutomaticLocationCollectionKey:@(YES),
                                            ABKSDKFlavorKey:@7
                                       };
    
    NSDictionary *optionsDictionary = [appBoy optionsDictionary];
    XCTAssertEqualObjects(optionsDictionary, testOptionsDictionary);
}

- (void)testStartwithAdvancedConfig {
    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
    
    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42,
                                       @"ABKCollectIDFA":@"true",
                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
                                       @"ABKFlushIntervalOptionKey":@"2",
                                       @"ABKSessionTimeoutKey":@"3",
                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
                                       @"userIdentificationType":@"CustomerId"
                                       };
    
    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
    
    NSDictionary *testOptionsDictionary = @{ABKEnableAutomaticLocationCollectionKey:@(YES),
                                            ABKSDKFlavorKey:@7,
                                            @"ABKRquestProcessingPolicy": @(1),
                                            @"ABKFlushInterval":@(2),
                                            @"ABKSessionTimeout":@(3),
                                            @"ABKMinimumTriggerTimeInterval":@(4)
                                            };
    
    NSDictionary *optionsDictionary = [appBoy optionsDictionary];
    XCTAssertEqualObjects(optionsDictionary, testOptionsDictionary);
}

- (void)testMpidForwardingOnStartUserIdZero {
    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42,
                                       @"ABKCollectIDFA":@"true",
                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
                                       @"ABKFlushIntervalOptionKey":@"2",
                                       @"ABKSessionTimeoutKey":@"3",
                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
                                       @"userIdentificationType":@"MPID"
                                       };
    
    MPKitAppboy *kitInstance = [[MPKitAppboy alloc] init];
    
    [kitInstance didFinishLaunchingWithConfiguration:kitConfiguration];
    
    MParticleUser *testUser = [[MParticleUser alloc] init];
    [testUser setValue:@(0) forKey:@"userId"];
    
    FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:testUser kitConfiguration:kitConfiguration];
    id mockKitApi = OCMClassMock([MPKitAPI class]);
    OCMStub([mockKitApi getCurrentUserWithKit:kitInstance]).andReturn(filteredUser);
    kitInstance.kitApi = mockKitApi;
    
    id mockKitInstance = OCMPartialMock(kitInstance);
    [[mockKitInstance reject] updateUser:[OCMArg any] request:[OCMArg any]];
    [kitInstance start];
    [mockKitInstance verify];
}

- (void)testMpidForwardingOnStartUserIdPositive {
    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42,
                                       @"ABKCollectIDFA":@"true",
                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
                                       @"ABKFlushIntervalOptionKey":@"2",
                                       @"ABKSessionTimeoutKey":@"3",
                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
                                       @"userIdentificationType":@"MPID"
                                       };
    
    MPKitAppboy *kitInstance = [[MPKitAppboy alloc] init];
    
    [kitInstance didFinishLaunchingWithConfiguration:kitConfiguration];
    
    MParticleUser *testUser = [[MParticleUser alloc] init];
    [testUser setValue:@(1) forKey:@"userId"];
    
    FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:testUser kitConfiguration:kitConfiguration];
    id mockKitApi = OCMClassMock([MPKitAPI class]);
    OCMStub([mockKitApi getCurrentUserWithKit:kitInstance]).andReturn(filteredUser);
    kitInstance.kitApi = mockKitApi;
    
    id mockKitInstance = OCMPartialMock(kitInstance);
    [[mockKitInstance expect] updateUser:[OCMArg any] request:[OCMArg any]];
    [kitInstance start];
    [mockKitInstance verify];
}

- (void)testMpidForwardingOnStartUserIdNegative {
    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42,
                                       @"ABKCollectIDFA":@"true",
                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
                                       @"ABKFlushIntervalOptionKey":@"2",
                                       @"ABKSessionTimeoutKey":@"3",
                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
                                       @"userIdentificationType":@"MPID"
                                       };
    
    MPKitAppboy *kitInstance = [[MPKitAppboy alloc] init];
    
    [kitInstance didFinishLaunchingWithConfiguration:kitConfiguration];
    
    MParticleUser *testUser = [[MParticleUser alloc] init];
    [testUser setValue:@(-1) forKey:@"userId"];
    
    FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:testUser kitConfiguration:kitConfiguration];
    id mockKitApi = OCMClassMock([MPKitAPI class]);
    OCMStub([mockKitApi getCurrentUserWithKit:kitInstance]).andReturn(filteredUser);
    kitInstance.kitApi = mockKitApi;
    
    id mockKitInstance = OCMPartialMock(kitInstance);
    [[mockKitInstance expect] updateUser:[OCMArg any] request:[OCMArg any]];
    [kitInstance start];
    [mockKitInstance verify];
}

- (void)testEmailSubscribtionUserAttribute {
    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42,
                                       @"ABKCollectIDFA":@"true",
                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
                                       @"ABKFlushIntervalOptionKey":@"2",
                                       @"ABKSessionTimeoutKey":@"3",
                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
                                       @"userIdentificationType":@"MPID"
                                       };
    MPKitAppboy *kitInstance = [[MPKitAppboy alloc] init];
    [kitInstance didFinishLaunchingWithConfiguration:kitConfiguration];
    
    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    id mockClient = OCMPartialMock(testClient);
    [kitInstance setAppboyInstance:mockClient];
    XCTAssertEqualObjects(mockClient, [kitInstance appboyInstance]);
    
    // Should succeed since opted_in is a valid value
    MPKitExecStatus *execStatus1 = [kitInstance setUserAttribute:@"email_subscribe" value:@"opted_in"];
    XCTAssertEqual(execStatus1.returnCode, MPKitReturnCodeSuccess);
    // Should fail since testValue is an invalid value
    MPKitExecStatus *execStatus2 = [kitInstance setUserAttribute:@"email_subscribe" value:@"testValue"];
    XCTAssertEqual(execStatus2.returnCode, MPKitReturnCodeFail);

    [mockClient verify];

    [mockClient stopMocking];
}

- (void)testPushSubscribtionUserAttribute {
    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42,
                                       @"ABKCollectIDFA":@"true",
                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
                                       @"ABKFlushIntervalOptionKey":@"2",
                                       @"ABKSessionTimeoutKey":@"3",
                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
                                       @"userIdentificationType":@"MPID"
                                       };
    MPKitAppboy *kitInstance = [[MPKitAppboy alloc] init];
    [kitInstance didFinishLaunchingWithConfiguration:kitConfiguration];
    
    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    id mockClient = OCMPartialMock(testClient);
    [kitInstance setAppboyInstance:mockClient];
    XCTAssertEqualObjects(mockClient, [kitInstance appboyInstance]);
    
    // Should succeed since opted_in is a valid value
    MPKitExecStatus *execStatus1 = [kitInstance setUserAttribute:@"push_subscribe" value:@"opted_in"];
    XCTAssertEqual(execStatus1.returnCode, MPKitReturnCodeSuccess);
    // Should fail since testValue is an invalid value
    MPKitExecStatus *execStatus2 = [kitInstance setUserAttribute:@"push_subscribe" value:@"testValue"];
    XCTAssertEqual(execStatus2.returnCode, MPKitReturnCodeFail);

    [mockClient verify];

    [mockClient stopMocking];
}

- (void)testSubscriptionGroupIdsMappedUserAttributes {
    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42,
                                       @"ABKCollectIDFA":@"true",
                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
                                       @"ABKFlushIntervalOptionKey":@"2",
                                       @"ABKSessionTimeoutKey":@"3",
                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
                                       @"userIdentificationType":@"MPID",
                                       @"subscriptionGroupMapping" : @"[{\"jsmap\":null,\"map\":\"testAttribute1\",\"maptype\":\"UserAttributeClass.Name\",\"value\":\"00000000-0000-0000-0000-00000000000\"},{\"jsmap\":null,\"map\":\"testAttribute2\",\"maptype\":\"UserAttributeClass.Name\",\"value\":\"00000000-0000-0000-0000-00000000001\"}]"
                                       };
    
    MPKitAppboy *kitInstance = [[MPKitAppboy alloc] init];
    [kitInstance didFinishLaunchingWithConfiguration:kitConfiguration];
    
    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    id mockClient = OCMPartialMock(testClient);
    [kitInstance setAppboyInstance:mockClient];
    XCTAssertEqualObjects(mockClient, [kitInstance appboyInstance]);
    
    // Should succeed since Bool false is a valid value
    MPKitExecStatus *execStatus1 = [kitInstance setUserAttribute:@"testAttribute1" value:@NO];
    XCTAssertEqual(execStatus1.returnCode, MPKitReturnCodeSuccess);
    // Should succeed since Bool true is a valid value
    MPKitExecStatus *execStatus2 = [kitInstance setUserAttribute:@"testAttribute2" value:@YES];
    XCTAssertEqual(execStatus2.returnCode, MPKitReturnCodeSuccess);
    // Should fail since testValue is not type BOOL
    MPKitExecStatus *execStatus3 = [kitInstance setUserAttribute:@"testAttribute2" value:@"testValue"];
    XCTAssertEqual(execStatus3.returnCode, MPKitReturnCodeFail);

    [mockClient verify];

    [mockClient stopMocking];
}


//- (void)testEndpointOverride {
//    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
//
//    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
//                                       @"host":@"https://foo.bar.com",
//                                       @"id":@42,
//                                       @"ABKCollectIDFA":@"true",
//                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
//                                       @"ABKFlushIntervalOptionKey":@"2",
//                                       @"ABKSessionTimeoutKey":@"3",
//                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
//                                       @"ABKCollectIDFA":@"true"
//                                       };
//
//    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
//
//    XCTAssertEqualObjects(@"https://foo.bar.com", [appBoy getApiEndpoint:@"https://original.com"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/param1", [appBoy getApiEndpoint:@"https://original.com/param1"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/param1/param2", [appBoy getApiEndpoint:@"https://original.com/param1/param2"]);
//
//    NSString *testEndpoint;
//    XCTAssertNil([appBoy getApiEndpoint:testEndpoint]);
//    XCTAssertEqualObjects(@"https://moo.far.com", [appBoy getApiEndpoint:@"moo.far.com"]);
//    XCTAssertEqualObjects(@"http://moo.far.com", [appBoy getApiEndpoint:@"http://moo.far.com"]);
//}
//
//- (void)testEndpointOverride2 {
//    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
//
//    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
//                                       @"host":@"http://foo.bar.com",
//                                       @"id":@42,
//                                       @"ABKCollectIDFA":@"true",
//                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
//                                       @"ABKFlushIntervalOptionKey":@"2",
//                                       @"ABKSessionTimeoutKey":@"3",
//                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
//                                       @"ABKCollectIDFA":@"true"
//                                       };
//
//    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
//
//    XCTAssertEqualObjects(@"http://foo.bar.com", [appBoy getApiEndpoint:@"https://original.com"]);
//    XCTAssertEqualObjects(@"http://foo.bar.com/param1", [appBoy getApiEndpoint:@"https://original.com/param1"]);
//    XCTAssertEqualObjects(@"http://foo.bar.com/param1/param2", [appBoy getApiEndpoint:@"https://original.com/param1/param2"]);
//
//    NSString *testEndpoint;
//    XCTAssertNil([appBoy getApiEndpoint:testEndpoint]);
//    XCTAssertEqualObjects(@"https://moo.far.com", [appBoy getApiEndpoint:@"moo.far.com"]);
//    XCTAssertEqualObjects(@"http://moo.far.com", [appBoy getApiEndpoint:@"http://moo.far.com"]);
//}
//
//- (void)testEndpointOverride3 {
//    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
//
//    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
//                                       @"host":@"foo.bar.com",
//                                       @"id":@42,
//                                       @"ABKCollectIDFA":@"true",
//                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
//                                       @"ABKFlushIntervalOptionKey":@"2",
//                                       @"ABKSessionTimeoutKey":@"3",
//                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
//                                       @"ABKCollectIDFA":@"true"
//                                       };
//
//    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
//
//    XCTAssertEqualObjects(@"https://foo.bar.com", [appBoy getApiEndpoint:@"https://original.com"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/param1", [appBoy getApiEndpoint:@"https://original.com/param1"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/param1/param2", [appBoy getApiEndpoint:@"https://original.com/param1/param2"]);
//
//
//    NSString *testEndpoint;
//    XCTAssertNil([appBoy getApiEndpoint:testEndpoint]);
//    XCTAssertEqualObjects(@"https://moo.far.com", [appBoy getApiEndpoint:@"moo.far.com"]);
//    XCTAssertEqualObjects(@"http://moo.far.com", [appBoy getApiEndpoint:@"http://moo.far.com"]);
//}
//
//- (void)testEndpointOverride4 {
//    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
//
//    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
//                                       @"host":@"https://foo.bar.com/baz",
//                                       @"id":@42,
//                                       @"ABKCollectIDFA":@"true",
//                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
//                                       @"ABKFlushIntervalOptionKey":@"2",
//                                       @"ABKSessionTimeoutKey":@"3",
//                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
//                                       @"ABKCollectIDFA":@"true"
//                                       };
//
//    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
//
//    XCTAssertEqualObjects(@"https://foo.bar.com/baz", [appBoy getApiEndpoint:@"https://original.com"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/baz/param1", [appBoy getApiEndpoint:@"https://original.com/param1"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/baz/param1/param2", [appBoy getApiEndpoint:@"https://original.com/param1/param2"]);
//
//
//    NSString *testEndpoint;
//    XCTAssertNil([appBoy getApiEndpoint:testEndpoint]);
//    XCTAssertEqualObjects(@"https://moo.far.com", [appBoy getApiEndpoint:@"moo.far.com"]);
//    XCTAssertEqualObjects(@"http://moo.far.com", [appBoy getApiEndpoint:@"http://moo.far.com"]);
//}
//
//- (void)testEndpointOverride5 {
//    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
//
//    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
//                                       @"host":@"https://foo.bar.com/baz/baz",
//                                       @"id":@42,
//                                       @"ABKCollectIDFA":@"true",
//                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
//                                       @"ABKFlushIntervalOptionKey":@"2",
//                                       @"ABKSessionTimeoutKey":@"3",
//                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
//                                       @"ABKCollectIDFA":@"true"
//                                       };
//
//    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
//
//    XCTAssertEqualObjects(@"https://foo.bar.com/baz/baz", [appBoy getApiEndpoint:@"https://original.com"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/baz/baz/param1", [appBoy getApiEndpoint:@"https://original.com/param1"]);
//    XCTAssertEqualObjects(@"https://foo.bar.com/baz/baz/param1/param2", [appBoy getApiEndpoint:@"https://original.com/param1/param2"]);
//
//
//    NSString *testEndpoint;
//    XCTAssertNil([appBoy getApiEndpoint:testEndpoint]);
//    XCTAssertEqualObjects(@"https://moo.far.com", [appBoy getApiEndpoint:@"moo.far.com"]);
//    XCTAssertEqualObjects(@"http://moo.far.com", [appBoy getApiEndpoint:@"http://moo.far.com"]);
//}
//
//- (void)testEndpointOverrideNilHost {
//    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
//
//    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
//                                       @"id":@42,
//                                       @"ABKCollectIDFA":@"true",
//                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
//                                       @"ABKFlushIntervalOptionKey":@"2",
//                                       @"ABKSessionTimeoutKey":@"3",
//                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
//                                       @"ABKCollectIDFA":@"true"
//                                       };
//
//    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
//
//    XCTAssertEqualObjects(@"https://original.com", [appBoy getApiEndpoint:@"https://original.com"]);
//    XCTAssertEqualObjects(@"https://original.com/param1", [appBoy getApiEndpoint:@"https://original.com/param1"]);
//    XCTAssertEqualObjects(@"https://original.com/param1/param2", [appBoy getApiEndpoint:@"https://original.com/param1/param2"]);
//
//
//    NSString *testEndpoint;
//    XCTAssertNil([appBoy getApiEndpoint:testEndpoint]);
//    XCTAssertEqualObjects(@"moo.far.com", [appBoy getApiEndpoint:@"moo.far.com"]);
//    XCTAssertEqualObjects(@"http://moo.far.com", [appBoy getApiEndpoint:@"http://moo.far.com"]);
//}

- (void)testSetMessageDelegate {
    id<BrazeInAppMessageUIDelegate> delegate = (id)[NSObject new];
    
    XCTAssertNil([MPKitAppboy inAppMessageControllerDelegate]);
    
    [MPKitAppboy setInAppMessageControllerDelegate:delegate];
    
    XCTAssertEqualObjects([MPKitAppboy inAppMessageControllerDelegate], delegate);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssertEqualObjects([MPKitAppboy inAppMessageControllerDelegate], delegate);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testStrongMessageDelegate {
    id<BrazeInAppMessageUIDelegate> delegate = (id)[NSObject new];
    
    [MPKitAppboy setInAppMessageControllerDelegate:delegate];
    
    delegate = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssertNotNil([MPKitAppboy inAppMessageControllerDelegate]);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testSetDisableNotificationHandling {
    XCTAssertEqual([MPKitAppboy shouldDisableNotificationHandling], NO);
    
    [MPKitAppboy setShouldDisableNotificationHandling:YES];
    
    XCTAssertEqual([MPKitAppboy shouldDisableNotificationHandling], YES);
    
    [MPKitAppboy setShouldDisableNotificationHandling:NO];
    
    XCTAssertEqual([MPKitAppboy shouldDisableNotificationHandling], NO);
}

- (void)testSetBrazeInstance {
    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    
    XCTAssertEqualObjects([MPKitAppboy brazeInstance], nil);

    [MPKitAppboy setBrazeInstance:testClient];
    
    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];
    
    XCTAssertEqualObjects(appBoy.appboyInstance, nil);
    XCTAssertEqualObjects(appBoy.providerKitInstance, nil);
    XCTAssertEqualObjects([MPKitAppboy brazeInstance], testClient);

    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42,
                                       @"ABKCollectIDFA":@"true",
                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
                                       @"ABKFlushIntervalOptionKey":@"2",
                                       @"ABKSessionTimeoutKey":@"3",
                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
                                       @"userIdentificationType":@"CustomerId"
                                       };

    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
    
    XCTAssertEqualObjects(appBoy.appboyInstance, testClient);
    XCTAssertEqualObjects(appBoy.providerKitInstance, testClient);
    XCTAssertEqualObjects([MPKitAppboy brazeInstance], testClient);
}

- (void)testUserIdCustomerId {
    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];

    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42,
                                       @"ABKCollectIDFA":@"true",
                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
                                       @"ABKFlushIntervalOptionKey":@"2",
                                       @"ABKSessionTimeoutKey":@"3",
                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
                                       @"userIdentificationType":@"CustomerId"
                                       };

    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
    
    XCTAssertEqual(appBoy.configuration[@"userIdentificationType"], @"CustomerId");
}

- (void)testUserIdMPID {
    MPKitAppboy *appBoy = [[MPKitAppboy alloc] init];

    NSDictionary *kitConfiguration = @{@"apiKey":@"BrazeID",
                                       @"id":@42,
                                       @"ABKCollectIDFA":@"true",
                                       @"ABKRequestProcessingPolicyOptionKey": @"1",
                                       @"ABKFlushIntervalOptionKey":@"2",
                                       @"ABKSessionTimeoutKey":@"3",
                                       @"ABKMinimumTriggerTimeIntervalKey":@"4",
                                       @"userIdentificationType":@"MPID"
                                       };

    [appBoy didFinishLaunchingWithConfiguration:kitConfiguration];
    
    XCTAssertEqual(appBoy.configuration[@"userIdentificationType"], @"MPID");
}

- (void)testlogCommerceEvent {
    MPKitAppboy *kit = [[MPKitAppboy alloc] init];
    kit.configuration = @{@"bundleCommerceEventData" : @0};

    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    id mockClient = OCMPartialMock(testClient);
    [kit setAppboyInstance:mockClient];

    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);

    MPProduct *product = [[MPProduct alloc] initWithName:@"product1" sku:@"1131331343" quantity:@1 price:@13];

    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionClick product:product];
    event.customAttributes = @{@"testKey" : @"testCustomAttValue"};
    
    MPTransactionAttributes *attributes = [[MPTransactionAttributes alloc] init];
    attributes.transactionId = @"foo-transaction-id";
    attributes.revenue = @13.00;
    attributes.tax = @3;
    attributes.shipping = @3;

    event.transactionAttributes = attributes;

    [[mockClient expect] logCustomEvent:@"eCommerce - click - Item"
                          properties:@{@"Id" : @"1131331343",
                                       @"Item Price" : @"13",
                                       @"Name" : @"product1",
                                       @"Quantity" : @"1",
                                       @"Total Product Amount" : @"13",
                                       @"testKey" : @"testCustomAttValue"
                       }];

    MPKitExecStatus *execStatus = [kit logBaseEvent:event];

    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);

    [mockClient verify];

    [mockClient stopMocking];
}

- (void)testlogCommerceEventWithBundledProducts {
    MPKitAppboy *kit = [[MPKitAppboy alloc] init];
    kit.configuration = @{@"bundleCommerceEventData" : @1};

    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    id mockClient = OCMPartialMock(testClient);
    [kit setAppboyInstance:mockClient];

    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);

    MPProduct *product = [[MPProduct alloc] initWithName:@"product1" sku:@"1131331343" quantity:@1 price:@13];

    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionClick product:product];
    event.customAttributes = @{@"testKey" : @"testCustomAttValue"};

    MPTransactionAttributes *attributes = [[MPTransactionAttributes alloc] init];
    attributes.transactionId = @"foo-transaction-id";
    attributes.revenue = @13.00;
    attributes.tax = @3;
    attributes.shipping = @3;

    event.transactionAttributes = attributes;

    [[mockClient expect] logCustomEvent:@"eCommerce - click"
                          properties:@{@"Attributes" : @{@"testKey" : @"testCustomAttValue"},
                                       @"products" : @[@{
                                           @"Id" : @"1131331343",
                                           @"Item Price" : @"13",
                                           @"Name" : @"product1",
                                           @"Quantity" : @"1",
                                           @"Total Product Amount" : @"13"
                                          }
                                       ]
                       }];

    MPKitExecStatus *execStatus = [kit logBaseEvent:event];

    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);

    [mockClient verify];

    [mockClient stopMocking];
}

- (void)testlogPurchaseCommerceEvent {
    MPKitAppboy *kit = [[MPKitAppboy alloc] init];
    kit.configuration = @{@"bundleCommerceEventData" : @0};

    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    id mockClient = OCMPartialMock(testClient);
    [kit setAppboyInstance:mockClient];

    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);

    MPProduct *product = [[MPProduct alloc] initWithName:@"product1" sku:@"1131331343" quantity:@1 price:@13];
    product.category = @"category1";

    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    event.customAttributes = @{@"testKey" : @"testCustomAttValue"};

    MPTransactionAttributes *attributes = [[MPTransactionAttributes alloc] init];
    attributes.transactionId = @"foo-transaction-id";
    attributes.revenue = @13.00;
    attributes.tax = @3;
    attributes.shipping = @3;

    event.transactionAttributes = attributes;

    [[mockClient expect] logPurchase:@"1131331343"
                            currency:@"USD"
                               price:[@"13" doubleValue]
                            quantity:1
                          properties:@{@"Shipping Amount" : @3,
                                       @"Total Amount" : @13.00,
                                       @"Total Product Amount" : @"13",
                                       @"Tax Amount" : @3,
                                       @"Transaction Id" : @"foo-transaction-id",
                                       @"Name" : @"product1",
                                       @"Category" : @"category1",
                                       @"testKey" : @"testCustomAttValue"
                       }];

    MPKitExecStatus *execStatus = [kit logBaseEvent:event];

    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);

    [mockClient verify];

    [mockClient stopMocking];
}

- (void)testlogPurchaseCommerceEventSendingProductName {
    MPKitAppboy *kit = [[MPKitAppboy alloc] init];
    kit.configuration = @{@"bundleCommerceEventData" : @0,
                          @"replaceSkuWithProductName": @"True"};

    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    id mockClient = OCMPartialMock(testClient);
    [kit setAppboyInstance:mockClient];

    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);

    MPProduct *product = [[MPProduct alloc] initWithName:@"product1" sku:@"1131331343" quantity:@1 price:@13];
    product.category = @"category1";

    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    event.customAttributes = @{@"testKey" : @"testCustomAttValue"};

    MPTransactionAttributes *attributes = [[MPTransactionAttributes alloc] init];
    attributes.transactionId = @"foo-transaction-id";
    attributes.revenue = @13.00;
    attributes.tax = @3;
    attributes.shipping = @3;

    event.transactionAttributes = attributes;

    [[mockClient expect] logPurchase:@"product1"
                            currency:@"USD"
                               price:[@"13" doubleValue]
                            quantity:1
                          properties:@{@"Shipping Amount" : @3,
                                       @"Total Amount" : @13.00,
                                       @"Total Product Amount" : @"13",
                                       @"Tax Amount" : @3,
                                       @"Transaction Id" : @"foo-transaction-id",
                                       @"Name" : @"product1",
                                       @"Category" : @"category1",
                                       @"testKey" : @"testCustomAttValue"
                       }];

    MPKitExecStatus *execStatus = [kit logBaseEvent:event];

    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);

    [mockClient verify];

    [mockClient stopMocking];
}

- (void)testlogPurchaseCommerceEventWithBundledProducts {
    MPKitAppboy *kit = [[MPKitAppboy alloc] init];
    kit.configuration = @{@"bundleCommerceEventData" : @1};

    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    id mockClient = OCMPartialMock(testClient);
    [kit setAppboyInstance:mockClient];

    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);

    MPProduct *product = [[MPProduct alloc] initWithName:@"product1" sku:@"1131331343" quantity:@1 price:@13];

    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    event.customAttributes = @{@"testKey" : @"testCustomAttValue"};

    MPTransactionAttributes *attributes = [[MPTransactionAttributes alloc] init];
    attributes.transactionId = @"foo-transaction-id";
    attributes.revenue = @13.00;
    attributes.tax = @3;
    attributes.shipping = @3;

    event.transactionAttributes = attributes;

    NSDictionary *testResultDict = @{@"Attributes" : @{@"testKey" : @"testCustomAttValue"},
                                     @"Shipping Amount" : @3,
                                     @"Total Amount" : @13.00,
                                     @"Tax Amount" : @3,
                                     @"Transaction Id" : @"foo-transaction-id",
                                     @"products" : @[@{
                                         @"Id" : @"1131331343",
                                         @"Item Price" : @"13",
                                         @"Name" : @"product1",
                                         @"Quantity" : @"1",
                                         @"Total Product Amount" : @"13"
                                        }
                                     ]
    };
    BOOL (^testBlock)(id value) = ^BOOL(id value) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            for (NSString *key in [(NSDictionary *)value allKeys]) {
                if ([key isEqualToString: @"products"]) {
                    NSArray *productArray = (NSArray *)((NSDictionary *)value[key]);
                    for (int i = 0; i < productArray.count; i++) {
                        NSDictionary *productDict = productArray[i];
                        for (NSString *productDictKey in [productDict allKeys]) {
                            if (![productDict[productDictKey] isEqual:testResultDict[key][i][productDictKey]]) {
                                NSLog(@"Invalid Object in Product: %@ Key: %@", productDict, productDictKey);
                                return false;
                            }
                        }
                    }
                }
                if (![(NSDictionary *)value[key] isEqual:testResultDict[key]]) {
                    NSLog(@"Invalid Object in Key: %@", key);
                    return false;
                }
            }
            return true;
        }
        return false;
    };
    
    OCMExpect(([mockClient logPurchase:@"eCommerce - purchase"
                              currency:@"USD"
                                 price:[@"13" doubleValue]
                            properties:[OCMArg checkWithBlock:testBlock]
               ]));
              
    MPKitExecStatus *execStatus = [kit logBaseEvent:event];

    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);

    OCMVerifyAll(mockClient);

    [mockClient stopMocking];
}

- (void)testlogCommerceEventWithMultipleBundledProducts {
    MPKitAppboy *kit = [[MPKitAppboy alloc] init];
    kit.configuration = @{@"bundleCommerceEventData" : @1};

    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    id mockClient = OCMPartialMock(testClient);
    [kit setAppboyInstance:mockClient];

    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);

    MPProduct *product1 = [[MPProduct alloc] initWithName:@"product1" sku:@"1131331343" quantity:@1 price:@13];
    MPProduct *product2 = [[MPProduct alloc] initWithName:@"product2" sku:@"1131331888" quantity:@1 price:@13];
    product2.userDefinedAttributes[@"testKey"] = @"testCustomAttValue";

    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase];
    [event addProducts:@[product1, product2]];
    event.customAttributes = @{@"testKey" : @"testCustomAttValue"};

    MPTransactionAttributes *attributes = [[MPTransactionAttributes alloc] init];
    attributes.transactionId = @"foo-transaction-id";
    attributes.revenue = @26.00;
    attributes.tax = @3;
    attributes.shipping = @3;

    event.transactionAttributes = attributes;

    NSDictionary *testResultDict = @{@"Attributes" : @{@"testKey" : @"testCustomAttValue"},
                                     @"Shipping Amount" : @3,
                                     @"Total Amount" : @26.00,
                                     @"Tax Amount" : @3,
                                     @"Transaction Id" : @"foo-transaction-id",
                                     @"products" : @[@{
                                                         @"Id" : @"1131331343",
                                                         @"Item Price" : @"13",
                                                         @"Name" : @"product1",
                                                         @"Quantity" : @"1",
                                                         @"Total Product Amount" : @"13"
                                                    },
                                                     @{
                                                         @"Id" : @"1131331888",
                                                         @"Item Price" : @"13",
                                                         @"Name" : @"product2",
                                                         @"Quantity" : @"1",
                                                         @"Total Product Amount" : @"13",
                                                         @"Attributes" : @{@"testKey" : @"testCustomAttValue"}
                                                     }
                                     ]
    };
    BOOL (^testBlock)(id value) = ^BOOL(id value) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            for (NSString *key in [(NSDictionary *)value allKeys]) {
                if ([key isEqualToString: @"products"]) {
                    NSArray *productArray = (NSArray *)((NSDictionary *)value[key]);
                    for (int i = 0; i < productArray.count; i++) {
                        NSDictionary *productDict = productArray[i];
                        for (NSString *productDictKey in [productDict allKeys]) {
                            if (![productDict[productDictKey] isEqual:testResultDict[key][i][productDictKey]]) {
                                NSLog(@"Invalid Object in Product: %@ Key: %@", productDict, productDictKey);
                                return false;
                            }
                        }
                    }
                }
                if (![(NSDictionary *)value[key] isEqual:testResultDict[key]]) {
                    NSLog(@"Invalid Object in Key: %@", key);
                    return false;
                }
            }
            return true;
        }
        return false;
    };
    
    OCMExpect(([mockClient logPurchase:@"eCommerce - purchase"
                              currency:@"USD"
                                 price:[@"26" doubleValue]
                            properties:[OCMArg checkWithBlock:testBlock]
               ]));
              
    MPKitExecStatus *execStatus = [kit logBaseEvent:event];

    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);

    OCMVerifyAll(mockClient);

    [mockClient stopMocking];
}

- (void)testlogPromotionCommerceEventWithBundledProducts {
    MPKitAppboy *kit = [[MPKitAppboy alloc] init];
    kit.configuration = @{@"bundleCommerceEventData" : @1};

    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    id mockClient = OCMPartialMock(testClient);
    [kit setAppboyInstance:mockClient];

    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);

    MPPromotion *promotion = [[MPPromotion alloc] init];
    promotion.promotionId = @"my_promo_1";
    promotion.creative = @"sale_banner_1";
    promotion.name = @"App-wide 50% off sale";
    promotion.position = @"dashboard_bottom";

    MPPromotionContainer *container =
        [[MPPromotionContainer alloc] initWithAction:MPPromotionActionView
                                           promotion:promotion];
    
    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithPromotionContainer:container];
    event.customAttributes = @{@"testKey" : @"testCustomAttValue"};

    [[mockClient expect] logCustomEvent:@"eCommerce - view"
                          properties:@{@"Attributes" : @{@"testKey" : @"testCustomAttValue"},
                                       @"promotions" : @[@{
                                           @"Creative" : @"sale_banner_1",
                                           @"Name" : @"App-wide 50% off sale",
                                           @"Position" : @"dashboard_bottom",
                                           @"Id" : @"my_promo_1"
                                          }
                                       ]
                       }];

    MPKitExecStatus *execStatus = [kit logBaseEvent:event];

    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);

    [mockClient verify];

    [mockClient stopMocking];
}

- (void)testlogImpressionCommerceEventWithBundledProducts {
    MPKitAppboy *kit = [[MPKitAppboy alloc] init];
    kit.configuration = @{@"bundleCommerceEventData" : @1};

    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    id mockClient = OCMPartialMock(testClient);
    [kit setAppboyInstance:mockClient];

    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);

    MPProduct *product = [[MPProduct alloc] initWithName:@"product1" sku:@"1131331343" quantity:@1 price:@13];
    product.userDefinedAttributes = [@{@"productTestKey" : @"productTestCustomAttValue"} mutableCopy];

    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithImpressionName:@"Suggested Products List" product:product];
    event.customAttributes = @{@"testKey" : @"testCustomAttValue"};

    [[mockClient expect] logCustomEvent:@"eCommerce - impression"
                          properties:@{@"Attributes" : @{@"testKey" : @"testCustomAttValue"},
                                       @"impressions" : @[@{
                                           @"Product Impression List" : @"Suggested Products List",
                                           @"products" : @[@{
                                               @"Id" : @"1131331343",
                                               @"Item Price" : @"13",
                                               @"Name" : @"product1",
                                               @"Quantity" : @"1",
                                               @"Total Product Amount" : @"13",
                                               @"Attributes" : @{@"productTestKey" : @"productTestCustomAttValue"}
                                              }
                                           ]
                                          }
                                       ]
                       }];

    MPKitExecStatus *execStatus = [kit logBaseEvent:event];

    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);

    [mockClient verify];

    [mockClient stopMocking];
}

//- (void)testTypeDetection {
//    MPKitAppboy *kit = [[MPKitAppboy alloc] init];
//
//    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
//    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
//    id mockClient = OCMPartialMock(testClient);
//    [kit setAppboyInstance:mockClient];
//
//    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);
//
//
//    MPEvent *event = [[MPEvent alloc] initWithName:@"test event" type:MPEventTypeNavigation];
//    event.customAttributes = @{@"foo":@"5.0", @"bar": @"true", @"baz": @"abc", @"qux": @"-3", @"quux": @"1970-01-01T00:00:00Z"};
//
//    [kit setEnableTypeDetection:YES];
//    [[mockClient expect] logCustomEvent:event.name withProperties:@{@"foo":@5.0, @"bar": @YES, @"baz":@"abc", @"qux": @-3, @"quux": [NSDate dateWithTimeIntervalSince1970:0]}];
//
//    MPKitExecStatus *execStatus = [kit logBaseEvent:event];
//
//    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
//
//    [mockClient verify];
//
//    [mockClient stopMocking];
//}
//
//
//- (void)testTypeDetectionDisable {
//    MPKitAppboy *kit = [[MPKitAppboy alloc] init];
//
//    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
//    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
//    id mockClient = OCMPartialMock(testClient);
//    [kit setAppboyInstance:mockClient];
//
//    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);
//
//
//    MPEvent *event = [[MPEvent alloc] initWithName:@"test event" type:MPEventTypeNavigation];
//    event.customAttributes = @{@"foo":@"5.0", @"bar": @"true", @"baz": @"abc", @"quz": @"-3", @"qux": @"1970-01-01T00:00:00Z"};
//
//    [kit setEnableTypeDetection:NO];
//    [[mockClient expect] logCustomEvent:event.name withProperties:event.customAttributes];
//
//    MPKitExecStatus *execStatus = [kit logBaseEvent:event];
//
//    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
//
//    [mockClient verify];
//
//    [mockClient stopMocking];
//}

- (void)testEventWithEmptyProperties {
    MPKitAppboy *kit = [[MPKitAppboy alloc] init];

    BRZConfiguration *configuration = [[BRZConfiguration alloc] init];
    Braze *testClient = [[Braze alloc] initWithConfiguration:configuration];
    id mockClient = OCMPartialMock(testClient);
    [kit setAppboyInstance:mockClient];

    XCTAssertEqualObjects(mockClient, [kit appboyInstance]);


    MPEvent *event = [[MPEvent alloc] initWithName:@"test event" type:MPEventTypeNavigation];
    event.customAttributes = @{};

    [kit setEnableTypeDetection:NO];
    [[mockClient expect] logCustomEvent:event.name];

    MPKitExecStatus *execStatus = [kit logBaseEvent:event];

    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);

    [mockClient verify];

    [mockClient stopMocking];
}

@end

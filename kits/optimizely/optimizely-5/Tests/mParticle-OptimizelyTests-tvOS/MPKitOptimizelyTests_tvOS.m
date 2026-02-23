#import <XCTest/XCTest.h>
#import "MPKitOptimizely.h"
#import <OCMock/OCMock.h>

#if defined(__has_include) && __has_include(<Optimizely/Optimizely-Swift.h>)
#import <Optimizely/Optimizely-Swift.h>
#elif defined(__has_include) && __has_include(<Optimizely-Swift.h>)
#import "Optimizely-Swift.h"
#elif defined(__has_include) && __has_include(<Optimizely/Optimizely.h>)
#import <Optimizely/Optimizely.h>
#elif defined(__has_include) && __has_include(<Optimizely.h>)
#import "Optimizely.h"
#else
@import Optimizely;
#endif

#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
#import <mParticle_Apple_SDK/mParticle.h>
#else
#import "mParticle.h"
#endif

static NSString *const oiAPIKey = @"projectId";
static NSString *const oiEventInterval = @"eventInterval";
static NSString *const oiDataFileInterval = @"datafileInterval";
static NSString *const oiuserIdKey = @"userIdField";

static NSString *const oiuserIdCustomerIDValue = @"customerId";
static NSString *const oiuserIdEmailValue = @"email";
static NSString *const oiuserIdMPIDValue = @"mpid";
static NSString *const oiuserIdDeviceStampValue = @"deviceApplicationStamp";

@interface MPKitOptimizely ()

- (NSString *)userIdForOptimizely:(FilteredMParticleUser *)currentUser;

@end

@interface MPKitOptimizelyTests_tvOS : XCTestCase

@end

@implementation MPKitOptimizelyTests_tvOS

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testStarted {
    MPKitOptimizely *exampleKit = [[MPKitOptimizely alloc] init];
    [exampleKit didFinishLaunchingWithConfiguration:@{oiAPIKey:@"12345", oiEventInterval:@12345}];
    XCTAssertTrue(exampleKit.started);
}

- (void)testLaunch {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
}

- (void)testLaunchWithoutAPIKey {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiEventInterval:@23,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeRequirementsNotMet);
}

- (void)testLaunchWithInvalidInterval {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@"scsc",
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
}

- (void)testuserIdForOptimizelyDefaultWithoutUser {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(nil);
    
    kitInstance.kitApi = mockKitAPI;
    
    NSString *deviceId = [[[MParticle sharedInstance] identity] deviceApplicationStamp];
    
    XCTAssertEqualObjects([kitInstance userIdForOptimizely:[mockKitAPI getCurrentUserWithKit:kitInstance]], deviceId);
}

- (void)testuserIdForOptimizelyDefaultWithUser {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userId]).andReturn(@4);
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    NSString *deviceId = [[[MParticle sharedInstance] identity] deviceApplicationStamp];
    
    XCTAssertEqualObjects([kitInstance userIdForOptimizely:[mockKitAPI getCurrentUserWithKit:kitInstance]], deviceId);
}

- (void)testuserIdForOptimizelyMPID {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    oiuserIdKey:oiuserIdMPIDValue,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userId]).andReturn(@4);
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    XCTAssertEqualObjects([kitInstance userIdForOptimizely:[mockKitAPI getCurrentUserWithKit:kitInstance]], @"4");
}

- (void)testuserIdForOptimizelyEmail {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    oiuserIdKey:oiuserIdEmailValue,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userIdentities]).andReturn(@{
                                                   @(MPUserIdentityEmail):@"test@gmail.com"
                                                   });
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    XCTAssertEqualObjects([kitInstance userIdForOptimizely:[mockKitAPI getCurrentUserWithKit:kitInstance]], @"test@gmail.com");
}

- (void)testuserIdForOptimizelyCustomerID {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    oiuserIdKey:oiuserIdCustomerIDValue,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userIdentities]).andReturn(@{
                                                   @(MPUserIdentityCustomerId):@"user5560"
                                                   });
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    XCTAssertEqualObjects([kitInstance userIdForOptimizely:[mockKitAPI getCurrentUserWithKit:kitInstance]], @"user5560");
}

- (void)testSetManualClient {
    OptimizelyClient *testClient = [[OptimizelyClient alloc] initWithSdkKey:@"test"];
    [MPKitOptimizely setOptimizelyClient:testClient];
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    XCTAssertEqualObjects(testClient, [MPKitOptimizely optimizelyClient]);
}

- (void)testSetManualClientFail {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    OptimizelyClient *testClient;
    [MPKitOptimizely setOptimizelyClient:testClient];
    
    XCTAssertNotEqualObjects(testClient, [MPKitOptimizely optimizelyClient]);
}

- (void)testlogEvent {
    OptimizelyClient *testClient = [[OptimizelyClient alloc] initWithSdkKey:@"test"];
    id mockClient = OCMPartialMock(testClient);
    [MPKitOptimizely setOptimizelyClient:mockClient];
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    oiuserIdKey:oiuserIdMPIDValue,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    XCTAssertEqualObjects(mockClient, [MPKitOptimizely optimizelyClient]);
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"test" type:MPEventTypeClick];
    
    [[mockClient expect] trackWithEventKey:OCMOCK_ANY userId:OCMOCK_ANY attributes:OCMOCK_ANY eventTags:OCMOCK_ANY error:nil];
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userId]).andReturn(@4);
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    execStatus = [kitInstance logBaseEvent:event];
     
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    [mockClient verify];
    
    [mockClient stopMocking];
}

- (void)testlogEventFail {
    OptimizelyClient *testClient = [[OptimizelyClient alloc] initWithSdkKey:@"test"];
    id mockClient = OCMPartialMock(testClient);
    [MPKitOptimizely setOptimizelyClient:mockClient];
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    oiuserIdKey:oiuserIdMPIDValue,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    MPEvent *event;
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userId]).andReturn(@4);
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    [[mockClient expect] trackWithEventKey:OCMOCK_ANY userId:OCMOCK_ANY attributes:OCMOCK_ANY eventTags:OCMOCK_ANY error:nil];

    execStatus = [kitInstance logBaseEvent:event];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeFail);
    
    [mockClient reject];
    
    [mockClient stopMocking];
}

- (void)testlogEventWithCustomName {
    OptimizelyClient *testClient = [[OptimizelyClient alloc] initWithSdkKey:@"test"];
    id mockClient = OCMPartialMock(testClient);
    [MPKitOptimizely setOptimizelyClient:mockClient];
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    oiuserIdKey:oiuserIdMPIDValue,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    XCTAssertEqualObjects(mockClient, [MPKitOptimizely optimizelyClient]);
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"test" type:MPEventTypeClick];
    [event addCustomFlag:@"testMapping" withKey:MPKitOptimizelyEventName];
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userId]).andReturn(@4);
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    [[mockClient expect] trackWithEventKey:@"testMapping" userId:OCMOCK_ANY attributes:OCMOCK_ANY eventTags:OCMOCK_ANY error:nil];

    execStatus = [kitInstance logBaseEvent:event];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    [mockClient verify];
    
    [mockClient stopMocking];
}

- (void)testlogEventWithValue {
    OptimizelyClient *testClient = [[OptimizelyClient alloc] initWithSdkKey:@"test"];
    id mockClient = OCMPartialMock(testClient);
    [MPKitOptimizely setOptimizelyClient:mockClient];
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    oiuserIdKey:oiuserIdMPIDValue,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    XCTAssertEqualObjects(mockClient, [MPKitOptimizely optimizelyClient]);
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"test" type:MPEventTypeClick];
    [event addCustomFlag:@"3" withKey:MPKitOptimizelyEventKeyValue];
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userId]).andReturn(@4);
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    NSNumber *testValue = [NSNumber numberWithInt:3];
    [[mockClient expect] trackWithEventKey:OCMOCK_ANY userId:OCMOCK_ANY attributes:OCMOCK_ANY eventTags:@{@"value": testValue} error:nil];
    
    execStatus = [kitInstance logBaseEvent:event];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    [mockClient verify];
    
    [mockClient stopMocking];
}

- (void)testlogEventWithCustomId {
    OptimizelyClient *testClient = [[OptimizelyClient alloc] initWithSdkKey:@"test"];
    id mockClient = OCMPartialMock(testClient);
    [MPKitOptimizely setOptimizelyClient:mockClient];
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    oiuserIdKey:oiuserIdMPIDValue,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    XCTAssertEqualObjects(mockClient, [MPKitOptimizely optimizelyClient]);
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"test" type:MPEventTypeClick];
    [event addCustomFlag:@"3" withKey:MPKitOptimizelyEventKeyValue];
    [event addCustomFlag:@"User65656" withKey:MPKitOptimizelyCustomUserId];
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userId]).andReturn(@4);
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    NSNumber *testValue = [NSNumber numberWithInt:3];
    [[mockClient expect] trackWithEventKey:OCMOCK_ANY userId:@"User65656" attributes:OCMOCK_ANY eventTags:@{@"value": testValue} error:nil];
    
    execStatus = [kitInstance logBaseEvent:event];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    [mockClient verify];
    
    [mockClient stopMocking];
}

- (void)testlogCommerceEvent {
    OptimizelyClient *testClient = [[OptimizelyClient alloc] initWithSdkKey:@"test"];
    id mockClient = OCMPartialMock(testClient);
    [MPKitOptimizely setOptimizelyClient:mockClient];
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    oiuserIdKey:oiuserIdMPIDValue,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    XCTAssertEqualObjects(mockClient, [MPKitOptimizely optimizelyClient]);
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"product1" sku:@"1131331343" quantity:@1 price:@13];
    
    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userId]).andReturn(@4);
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    [[mockClient expect] trackWithEventKey:@"eCommerce - purchase - Item" userId:OCMOCK_ANY attributes:OCMOCK_ANY eventTags:OCMOCK_ANY error:nil];
    [[mockClient expect] trackWithEventKey:@"eCommerce - purchase - Total" userId:OCMOCK_ANY attributes:OCMOCK_ANY eventTags:OCMOCK_ANY error:nil];
    
    execStatus = [kitInstance logBaseEvent:event];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    [mockClient verify];
    
    [mockClient stopMocking];
}

- (void)testlogCommerceEventWithCustomNameAndRevenue {
    OptimizelyClient *testClient = [[OptimizelyClient alloc] initWithSdkKey:@"test"];
    id mockClient = OCMPartialMock(testClient);
    [MPKitOptimizely setOptimizelyClient:mockClient];
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    oiuserIdKey:oiuserIdMPIDValue,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    XCTAssertEqualObjects(mockClient, [MPKitOptimizely optimizelyClient]);
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"product1" sku:@"1131331343" quantity:@1 price:@13];
    
    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    MPTransactionAttributes *attributes = [[MPTransactionAttributes alloc] init];
    attributes.transactionId = @"foo-transaction-id";
    attributes.revenue = @13.00;
    attributes.tax = @3.00;
    attributes.shipping = @3;
    
    event.transactionAttributes = attributes;
    
    [event addCustomFlag:@"testMapping" withKey:MPKitOptimizelyEventName];
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userId]).andReturn(@4);
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    [[mockClient expect] trackWithEventKey:@"testMapping" userId:OCMOCK_ANY attributes:OCMOCK_ANY eventTags:[OCMArg checkWithBlock:^BOOL(NSDictionary<NSString *, NSString *> *value) {
        return [value[@"revenue"] isEqual:@1300];
    }] error:nil];
    
    execStatus = [kitInstance logBaseEvent:event];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    [mockClient verify];
    
    [mockClient stopMocking];
}

- (void)testlogCommerceEventWithCustomNameRevenueAndUserId {
    OptimizelyClient *testClient = [[OptimizelyClient alloc] initWithSdkKey:@"test"];
    id mockClient = OCMPartialMock(testClient);
    [MPKitOptimizely setOptimizelyClient:mockClient];
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    oiuserIdKey:oiuserIdMPIDValue,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    XCTAssertEqualObjects(mockClient, [MPKitOptimizely optimizelyClient]);
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"product1" sku:@"1131331343" quantity:@1 price:@13];
    
    MPCommerceEvent *event = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    MPTransactionAttributes *attributes = [[MPTransactionAttributes alloc] init];
    attributes.transactionId = @"foo-transaction-id";
    attributes.revenue = @13.00;
    attributes.tax = @3.00;
    attributes.shipping = @3;
    
    event.transactionAttributes = attributes;
    
    [event addCustomFlag:@"testMapping" withKey:MPKitOptimizelyEventName];
    [event addCustomFlag:@"User65656" withKey:MPKitOptimizelyCustomUserId];
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userId]).andReturn(@4);
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    [[mockClient expect] trackWithEventKey:@"testMapping" userId:@"User65656" attributes:OCMOCK_ANY eventTags:[OCMArg checkWithBlock:^BOOL(NSDictionary<NSString *, NSString *> *value)
    {
        return [value[@"revenue"] isEqual:@1300];
    }] error:nil];
    
    execStatus = [kitInstance logBaseEvent:event];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    [mockClient verify];
    
    [mockClient stopMocking];
}

- (void)testVariation {
    OptimizelyClient *testClient = [[OptimizelyClient alloc] initWithSdkKey:@"test"];
    id mockClient = OCMPartialMock(testClient);
    [MPKitOptimizely setOptimizelyClient:mockClient];
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    oiuserIdKey:oiuserIdMPIDValue,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    XCTAssertEqualObjects(mockClient, [MPKitOptimizely optimizelyClient]);
    
    [[mockClient expect] activateWithExperimentKey:@"variation" userId:@"4" attributes:OCMOCK_ANY error:nil];
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userId]).andReturn(@4);
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    [kitInstance activateWithExperimentKey:@"variation" customUserId:nil];
    
    [mockClient verify];
    
    [mockClient stopMocking];
}

- (void)testVariationWithCustomId {
    OptimizelyClient *testClient = [[OptimizelyClient alloc] initWithSdkKey:@"test"];
    id mockClient = OCMPartialMock(testClient);
    [MPKitOptimizely setOptimizelyClient:mockClient];
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    oiAPIKey:@"274279246429244297",
                                    oiEventInterval:@23,
                                    oiuserIdKey:oiuserIdMPIDValue,
                                    @"as":@{
                                            @"appId":@"MyAppId"
                                            }
                                    };
    
    MPKitOptimizely *kitInstance = [[MPKitOptimizely alloc] init];
    
    MPKitExecStatus *execStatus = [kitInstance didFinishLaunchingWithConfiguration:configuration];
    
    XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
    
    XCTAssertEqualObjects(mockClient, [MPKitOptimizely optimizelyClient]);
    
    [[mockClient expect] activateWithExperimentKey:@"variation" userId:@"loser" attributes:OCMOCK_ANY error:nil];
    
    MPKitAPI *kitAPI = [[MPKitAPI alloc] init];
    id mockKitAPI = OCMPartialMock(kitAPI);
    id mockUser = OCMClassMock([FilteredMParticleUser class]);
    
    OCMStub([mockUser userId]).andReturn(@4);
    
    OCMStub([mockKitAPI getCurrentUserWithKit:OCMOCK_ANY]).andReturn(mockUser);
    
    kitInstance.kitApi = mockKitAPI;
    
    [kitInstance activateWithExperimentKey:@"variation" customUserId:@"loser"];
    
    [mockClient verify];
    
    [mockClient stopMocking];
}

@end

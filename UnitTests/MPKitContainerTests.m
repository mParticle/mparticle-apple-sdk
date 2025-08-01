#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "mParticle.h"
#import "MPKitContainer.h"
#import "MPIConstants.h"
#import "MPForwardQueueItem.h"
#import "MPBaseEvent.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPProduct.h"
#import "MPKitProtocol.h"
#import "MPKitExecStatus.h"
#import "MPKitFilter.h"
#import "MPEvent.h"
#import "MPKitTestClass.h"
#import "MPKitSecondTestClass.h"
#import "MPKitAppsFlyerTest.h"
#import "MPStateMachine.h"
#import "MPKitRegister.h"
#import "MPConsumerInfo.h"
#import "MPTransactionAttributes.h"
#import "MPEventProjection.h"
#import "MPKitConfiguration.h"
#import "MPForwardQueueParameters.h"
#import "MPConsentKitFilter.h"
#import "MPPersistenceController.h"
#import "MPBaseTestCase.h"
#import "MPKitProtocol.h"
#import "MPKitTestClassSideloaded.h"
#import "MPApplication.h"
#import "MParticleSwift.h"

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;
@property (nonatomic, strong) MPBackendController_PRIVATE *backendController;

@end

@interface MParticleUser ()

@property(readwrite) BOOL isLoggedIn;

@end

#pragma mark - MPKitContainer category for unit tests
@interface MPKitContainer_PRIVATE(Tests)

@property (nonatomic, strong) NSMutableArray<MPForwardQueueItem *> *forwardQueue;
@property (nonatomic, unsafe_unretained) BOOL kitsInitialized;
@property (nonatomic, readonly) NSMutableDictionary<NSNumber *, MPKitConfiguration *> *kitConfigurations;

- (BOOL)isDisabledByBracketConfiguration:(NSDictionary *)bracketConfiguration;
- (BOOL)isDisabledByConsentKitFilter:(MPConsentKitFilter *)kitFilter;
- (void)replayQueuedItems;
- (id)transformValue:(NSString *)originalValue dataType:(MPDataType)dataType;
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification;
- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification;
- (nullable NSString *)nameForKitCode:(nonnull NSNumber *)integrationId;
- (id<MPKitProtocol>)startKit:(NSNumber *)integrationId configuration:(MPKitConfiguration *)kitConfiguration;
- (void)flushSerializedKits;
- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forEvent:(MPEvent *const)event selector:(SEL)selector;
- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forBaseEvent:(MPBaseEvent *const)event forSelector:(SEL)selector;
- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forUserAttributeKey:(NSString *)key value:(id)value;
- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forUserAttributes:(NSDictionary *)userAttributes;
- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forUserIdentityKey:(NSString *)key identityType:(MPUserIdentity)identityType;
- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forCommerceEvent:(MPCommerceEvent *const)commerceEvent;
- (void)attemptToLogEventToKit:(id<MPExtensionKitProtocol>)kitRegister kitFilter:(MPKitFilter *)kitFilter selector:(SEL)selector parameters:(nullable MPForwardQueueParameters *)parameters messageType:(MPMessageType)messageType userInfo:(NSDictionary *)userInfo;


@end


#pragma mark - MPKitContainerTests
@interface MPKitContainerTests : MPBaseTestCase {
    MPKitContainer_PRIVATE *kitContainer;
}

@end


@implementation MPKitContainerTests

- (void)setUp {
    [super setUp];
    
    [MParticle sharedInstance].stateMachine.apiKey = @"unit_test_app_key";
    [MParticle sharedInstance].stateMachine.secret = @"unit_test_secret";
    
    [MParticle sharedInstance].kitContainer_PRIVATE = [[MPKitContainer_PRIVATE alloc] init];
    kitContainer = [MParticle sharedInstance].kitContainer_PRIVATE;
    
    [MParticle sharedInstance].backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];

    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    if (!registeredKits) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
        [MPKitContainer_PRIVATE registerKit:kitRegister];
        
        kitRegister = [[MPKitRegister alloc] initWithName:@"KitSecondTest" className:@"MPKitSecondTestClass"];
        [MPKitContainer_PRIVATE registerKit:kitRegister];
        
        kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
        [MPKitContainer_PRIVATE registerKit:kitRegister];
        
        NSDictionary *configuration = @{
                                        @"id":@42,
                                        @"as":@{
                                                @"appId":@"MyAppId"
                                                }
                                        };
        
        MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
        [[kitContainer startKit:@42 configuration:kitConfiguration] start];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 92"];
    id kitAppsFlyer = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];
    if (!kitAppsFlyer) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
        [MPKitContainer_PRIVATE registerKit:kitRegister];
    }
}

- (void)tearDown {
    for (MPKitRegister *kitRegister in [MPKitContainer_PRIVATE registeredKits]) {
        kitRegister.wrapperInstance = nil;
    }
    kitContainer = nil;

    [super tearDown];
}

- (void)setUserAttributesAndIdentities {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSDictionary *userAttributes = @{@"Dinosaur":@"T-Rex",
                                     @"Arm length":@"Short",
                                     @"Height":@20,
                                     @"Keywords":@[@"Omnivore", @"Loud", @"Pre-historic"]};
    
    userDefaults[@"ua"] = userAttributes;
    
    NSArray *userIdentities = @[@{
                                    @"n":@(MPUserIdentityEmail),
                                    @"i":@"trex@shortarmsdinosaurs.com",
                                    @"dfs":MPCurrentEpochInMilliseconds,
                                    @"f":@NO
                                    },
                                @{
                                    @"n":@(MPUserIdentityCustomerId),
                                    @"i":@"trex@shortarmsdinosaurs.com",
                                    @"dfs":MPCurrentEpochInMilliseconds,
                                    @"f":@NO
                                    }
                                ];
    
    userDefaults[@"ui"] = userIdentities;
    
    [userDefaults synchronize];
}

- (void)testUpdateKitConfiguration {
    [self setUserAttributesAndIdentities];
    
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };
    
    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1, configuration2];
    
    NSString *eTag = @"1.618-2.718-3.141-42";
    NSDictionary __block *configuration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPRemoteConfigCustomModuleSettingsKey:[NSNull null],
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigTriggerKey:[NSNull null],
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    
    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration stateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController];

    NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:configuration eTag:eTag requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];
    
    XCTAssertEqualObjects(responseConfig.configuration, [MPUserDefaults restore].configuration);
    
    NSArray *directoryContents = [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getKitConfigurations];
    for (NSDictionary *kitConfigurationDictionary in directoryContents) {
        MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:kitConfigurationDictionary];
        if ([[kitConfiguration integrationId] isEqual:@(42)]){
            XCTAssertEqualObjects(@"cool app key", kitConfiguration.configuration[@"appId"]);
        }
        
        if ([[kitConfiguration integrationId] isEqual:@(312)]){
            
            XCTAssertEqualObjects(@"cool app key 2", kitConfiguration.configuration[@"appId"]);
        }
    }    
}

- (void)testRemoveKitConfiguration {
    static NSString *const kTestAppId1 = @"cool app key";
    static NSString *const kTestAppId2 = @"cool app key 2";
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] resetDefaults];
    [self setUserAttributesAndIdentities];
    
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":kTestAppId1
                                             }
                                     };
    
    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":kTestAppId2
                                             }
                                     };
    
    NSArray __block *kitConfigs = @[configuration1, configuration2];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test instance"];
    [MParticle sharedInstance];
    dispatch_async([MParticle messageQueue], ^{
        NSString *eTag = @"1.618-2.718-3.141-42";
        NSDictionary *configuration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                                kMPRemoteConfigCustomModuleSettingsKey:[NSNull null],
                                                kMPRemoteConfigRampKey:@100,
                                                kMPRemoteConfigTriggerKey:[NSNull null],
                                                kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                                kMPRemoteConfigSessionTimeoutKey:@112};
        
        MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration stateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController];

        NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
        [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:configuration eTag:eTag requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];
        
        XCTAssertEqualObjects(responseConfig.configuration, [MPUserDefaults restore].configuration);
        
        dispatch_sync(dispatch_get_main_queue(), ^{ });
        id appId = [self->kitContainer.kitConfigurations objectForKey:@(42)].configuration[@"appId"];
        if ([appId isKindOfClass:[NSData class]]) {
            appId = [[NSString alloc] initWithData:appId encoding:NSUTF8StringEncoding];
        }
        XCTAssertEqualObjects(kTestAppId1, appId);
        
        NSArray *directoryContents = [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getKitConfigurations];
        for (NSDictionary *kitConfigurationDictionary in directoryContents) {
            MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:kitConfigurationDictionary];
            if ([[kitConfiguration integrationId] isEqual:@(42)]){
                id appId = kitConfiguration.configuration[@"appId"];
                if ([appId isKindOfClass:[NSData class]]) {
                    appId = [[NSString alloc] initWithData:appId encoding:NSUTF8StringEncoding];
                }
                XCTAssertEqualObjects(kTestAppId1, appId);
            }
            
            if ([[kitConfiguration integrationId] isEqual:@(312)]){
                id appId = kitConfiguration.configuration[@"appId"];
                if ([appId isKindOfClass:[NSData class]]) {
                    appId = [[NSString alloc] initWithData:appId encoding:NSUTF8StringEncoding];
                }
                XCTAssertEqualObjects(kTestAppId2, appId);
            }
        }
        
        kitConfigs = @[configuration1];

        configuration = @{kMPRemoteConfigKitsKey:kitConfigs,
                          kMPRemoteConfigCustomModuleSettingsKey:[NSNull null],
                          kMPRemoteConfigRampKey:@100,
                          kMPRemoteConfigTriggerKey:[NSNull null],
                          kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                          kMPRemoteConfigSessionTimeoutKey:@112};
        
        responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration stateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController];

        requestTimestamp = [[NSDate date] timeIntervalSince1970];
        [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:configuration eTag:eTag requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];
        
        XCTAssertEqualObjects(responseConfig.configuration, [MPUserDefaults restore].configuration);
        
        id appId2 = [self->kitContainer.kitConfigurations objectForKey:@(42)].configuration[@"appId"];
        if ([appId2 isKindOfClass:[NSData class]]) {
            appId2 = [[NSString alloc] initWithData:appId2 encoding:NSUTF8StringEncoding];
        }
        XCTAssertEqualObjects(kTestAppId1, appId2);
        
        directoryContents = [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getKitConfigurations];
        for (NSDictionary *kitConfigurationDictionary in directoryContents) {
            MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:kitConfigurationDictionary];
            if ([[kitConfiguration integrationId] isEqual:@(42)]){
                id appId = kitConfiguration.configuration[@"appId"];
                if ([appId isKindOfClass:[NSData class]]) {
                    appId = [[NSString alloc] initWithData:appId encoding:NSUTF8StringEncoding];
                }
                XCTAssertEqualObjects(kTestAppId1, appId);
            }
            
            XCTAssertFalse([[kitConfiguration integrationId] isEqual:@(312)]);
        }
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testIsDisabledByBracketConfiguration {
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    userDefaults[@"mpid"] = @2;
    
    NSDictionary *bracketConfig = @{@"hi":@(0),@"lo":@(0)};
    XCTAssertTrue([kitContainer isDisabledByBracketConfiguration:bracketConfig]);
    
    bracketConfig = @{@"hi":@(100),@"lo":@(0)};
    XCTAssertFalse([kitContainer isDisabledByBracketConfiguration:bracketConfig]);    
}

- (void)testValueTransformation {
    id transformedValue;
    
    // String
    transformedValue = [kitContainer transformValue:@"The quick brown fox jumps over the lazy dog" dataType:MPDataTypeString];
    XCTAssertEqual(transformedValue, @"The quick brown fox jumps over the lazy dog", @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSString class]], @"Should have been true.");
    
    // Boolean
    transformedValue = [kitContainer transformValue:@"TRue" dataType:MPDataTypeBool];
    XCTAssertEqualObjects(transformedValue, @YES, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    transformedValue = [kitContainer transformValue:@"FaLSe" dataType:MPDataTypeBool];
    XCTAssertEqualObjects(transformedValue, @NO, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    transformedValue = [kitContainer transformValue:@"Just a String" dataType:MPDataTypeBool];
    XCTAssertEqualObjects(transformedValue, @NO, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    // Integer
    transformedValue = [kitContainer transformValue:@"1618033" dataType:MPDataTypeInt];
    XCTAssertEqualObjects(transformedValue, @1618033, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    transformedValue = [kitContainer transformValue:@"1.618033" dataType:MPDataTypeInt];
    XCTAssertEqualObjects(transformedValue, @1, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    transformedValue = [kitContainer transformValue:@"An Int string" dataType:MPDataTypeInt];
    XCTAssertEqualObjects(transformedValue, nil, @"Should have been equal.");
    
    // Long
    transformedValue = [kitContainer transformValue:@"161803398875" dataType:MPDataTypeLong];
    XCTAssertEqualObjects(transformedValue, @161803398875, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    transformedValue = [kitContainer transformValue:@"1.618033" dataType:MPDataTypeInt];
    XCTAssertEqualObjects(transformedValue, @1, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    transformedValue = [kitContainer transformValue:@"A Long string" dataType:MPDataTypeLong];
    XCTAssertEqualObjects(transformedValue, nil, @"Should have been equal.");
    
    // Float
    transformedValue = [kitContainer transformValue:@"1.5" dataType:MPDataTypeFloat];
    XCTAssertEqualObjects(transformedValue, @1.5, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    transformedValue = [kitContainer transformValue:@"A Float string" dataType:MPDataTypeLong];
    XCTAssertEqualObjects(transformedValue, nil, @"Should have been equal.");
    
    // Invalid values
    transformedValue = [kitContainer transformValue:nil dataType:MPDataTypeString];
    XCTAssertEqualObjects(transformedValue, nil, @"Should have been equal.");

    transformedValue = [kitContainer transformValue:(NSString *)[NSNull null] dataType:MPDataTypeString];
    XCTAssertEqualObjects(transformedValue, nil, @"Should have been equal.");

    transformedValue = [kitContainer transformValue:nil dataType:MPDataTypeBool];
    XCTAssertEqualObjects(transformedValue, @NO, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");

    transformedValue = [kitContainer transformValue:(NSString *)[NSNull null] dataType:MPDataTypeBool];
    XCTAssertEqualObjects(transformedValue, @NO, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    transformedValue = [kitContainer transformValue:nil dataType:MPDataTypeInt];
    XCTAssertEqualObjects(transformedValue, @0, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    transformedValue = [kitContainer transformValue:(NSString *)[NSNull null] dataType:MPDataTypeInt];
    XCTAssertEqualObjects(transformedValue, @0, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    transformedValue = [kitContainer transformValue:nil dataType:MPDataTypeLong];
    XCTAssertEqualObjects(transformedValue, @0, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    transformedValue = [kitContainer transformValue:(NSString *)[NSNull null] dataType:MPDataTypeLong];
    XCTAssertEqualObjects(transformedValue, @0, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    transformedValue = [kitContainer transformValue:nil dataType:MPDataTypeFloat];
    XCTAssertEqualObjects(transformedValue, @0, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
    
    transformedValue = [kitContainer transformValue:(NSString *)[NSNull null] dataType:MPDataTypeFloat];
    XCTAssertEqualObjects(transformedValue, @0, @"Should have been equal.");
    XCTAssertTrue([transformedValue isKindOfClass:[NSNumber class]], @"Should have been true.");
}

- (void)testForwardQueueEcommerce {
    XCTAssertNotNil(kitContainer.forwardQueue, @"Should not have been nil.");
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
    
    kitContainer.kitsInitialized = NO;
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"Sonic Screwdriver" sku:@"SNCDRV" quantity:@1 price:@3.14];
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];

    [kitContainer forwardCommerceEventCall:commerceEvent];
    MPForwardQueueItem *forwardQueueItem = [kitContainer.forwardQueue firstObject];
    XCTAssertEqual(kitContainer.forwardQueue.count, 1, @"Should have been equal.");
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeEcommerce, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.commerceEvent, commerceEvent, @"Should have been equal.");

    kitContainer.kitsInitialized = YES;
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
}

- (void)testForwardQueueEvent {
    XCTAssertNotNil(kitContainer.forwardQueue, @"Should not have been nil.");
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
    
    kitContainer.kitsInitialized = NO;

    SEL selector = @selector(logEvent:);
    MPEvent *event = [[MPEvent alloc] initWithName:@"Time travel" type:MPEventTypeNavigation];
    
    [kitContainer forwardSDKCall:selector event:event parameters:nil messageType:MPMessageTypeEvent userInfo:nil];
    MPForwardQueueItem *forwardQueueItem = [kitContainer.forwardQueue firstObject];
    XCTAssertEqual(kitContainer.forwardQueue.count, 1, @"Should have been equal.");
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeEvent, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.event, event, @"Should have been equal.");
    
    kitContainer.kitsInitialized = YES;
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
}

- (void)testForwardQueueInvalid {
    XCTAssertNotNil(kitContainer.forwardQueue, @"Should not have been nil.");
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
    
    kitContainer.kitsInitialized = NO;
    
    SEL selector = @selector(logEvent:);
    MPEvent *event = nil;
    
    [kitContainer forwardSDKCall:selector event:event parameters:nil messageType:MPMessageTypeEvent userInfo:nil];
    MPForwardQueueItem *forwardQueueItem = [kitContainer.forwardQueue firstObject];
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
    XCTAssertNil(forwardQueueItem, @"Should have been nil.");
}

- (void)testForwardQueueItem {
    XCTAssertNotNil(kitContainer.forwardQueue, @"Should not have been nil.");
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
    
    kitContainer.kitsInitialized = NO;
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    NSURL *url = [NSURL URLWithString:@"mparticle://baseurl?query"];
    [queueParameters addParameter:url];
    NSDictionary *options = @{@"key":@"val"};
    [queueParameters addParameter:options];
    
    [kitContainer forwardSDKCall:@selector(openURL:options:)
                           event:nil
                      parameters:queueParameters
                     messageType:MPMessageTypeUnknown
                        userInfo:nil];
    
    MPForwardQueueItem *forwardQueueItem = [kitContainer.forwardQueue firstObject];
    XCTAssertEqual(kitContainer.forwardQueue.count, 1);
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeGeneralPurpose);
    XCTAssertEqualObjects(forwardQueueItem.queueParameters, queueParameters);
    
    kitContainer.kitsInitialized = YES;
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
}

- (void)testFilterEventType {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"hs":@{
                                            @"mt":@{@"e":@0},
                                            @"et":@{@"42":@0},
                                            @"ec":@{@"1594525888":@0},
                                            @"ea":@{@"1217787541":@0},
                                            @"svec":@{@"1594525888":@0},
                                            @"svea":@{@"1217787541":@0}
                                            }
                                    }
                                ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dinosaur Run" type:MPEventTypeOther];
    event.duration = @2;
    event.customAttributes = @{@"speed":@25,
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";

    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    id registeredKit = [[registeredKits objectsPassingTest:^BOOL(id<MPExtensionProtocol>  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(MPExtensionKitProtocol)]) {
            id<MPExtensionKitProtocol> kitExtension = (id<MPExtensionKitProtocol>)obj;
            if (kitExtension.code.intValue == 42) {
                return YES;
            }
        }
        return NO;
    }] anyObject];

    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forEvent:event selector:@selector(logEvent:)];
    
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
    XCTAssertNil(kitFilter.filteredAttributes, @"Filtered attributes should have been nil.");
}

- (void)testForwardLoggedOutUser {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            }                                    }
                                ];
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    NSArray<id<MPExtensionKitProtocol>> *activeKits = [kitContainer activeKitsRegistry];
    
    XCTAssertEqual(activeKits.count, 1);
    XCTAssertEqualObjects(activeKits[0].code, @42);

    
    configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@true
                                    }
                                ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    activeKits = [kitContainer activeKitsRegistry];
    
    XCTAssertEqual(activeKits.count, 0);
    NSArray<NSNumber *> *configuredKits = [kitContainer configuredKitsRegistry];
    XCTAssertEqual(configuredKits.count, 1);
    XCTAssertTrue([configuredKits containsObject:@42]);
}

- (void)testForwardLoggedOutUserWithMultipleKits {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            }
                                    },
                                @{
                                    @"id":@314,
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    }
                                ];
    
    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configurations[1]];
    [[kitContainer startKit:@314 configuration:kitConfiguration] start];

    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    NSArray<id<MPExtensionKitProtocol>> *activeKits = [kitContainer activeKitsRegistry];
    
    XCTAssertEqual(activeKits.count, 2);
    
    configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@true
                                    },
                                @{
                                    @"id":@314,
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    }
                                ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    activeKits = [kitContainer activeKitsRegistry];
    XCTAssertEqual(activeKits.count, 1);
    XCTAssertEqualObjects(activeKits[0].code, @314);
    
    NSArray<NSNumber *> *configuredKits = [kitContainer configuredKitsRegistry];
    XCTAssertEqual(configuredKits.count, 2);
    XCTAssertTrue([configuredKits containsObject:@42]);
    XCTAssertTrue([configuredKits containsObject:@314]);
}

- (void)testConfiguredKits {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            }
                                    },
                                @{
                                    @"id":@314,
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    }
                                ];
    
    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configurations[1]];
    [[kitContainer startKit:@314 configuration:kitConfiguration] start];

    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    NSArray<id<MPExtensionKitProtocol>> *activeKits = [kitContainer activeKitsRegistry];
    
    XCTAssertEqual(activeKits.count, 2);
    NSArray<NSNumber *> *configuredKits = [kitContainer configuredKitsRegistry];
    XCTAssertEqual(configuredKits.count, 2);
    XCTAssertTrue([configuredKits containsObject:@42]);
    XCTAssertTrue([configuredKits containsObject:@314]);
    
    configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@true
                                    },
                                @{
                                    @"id":@314,
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    },
                                @{
                                    @"id":@92,
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    }
                                ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    activeKits = [kitContainer activeKitsRegistry];
    XCTAssertEqual(activeKits.count, 1);
    XCTAssertEqualObjects(activeKits[0].code, @314);
    
    configuredKits = [kitContainer configuredKitsRegistry];
    XCTAssertEqual(configuredKits.count, 3);
    XCTAssertTrue([configuredKits containsObject:@42]);
    XCTAssertTrue([configuredKits containsObject:@92]);
    XCTAssertTrue([configuredKits containsObject:@314]);

}

- (void)testActiveKitsWhenNotDisabled {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    },
                                @{
                                    @"id":@314,
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    }
                                ];

    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configurations[1]];
    NSNumber *kitId = configurations[1][@"id"];
    [[kitContainer startKit:kitId configuration:kitConfiguration] start];
    kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configurations[0]];
    kitId = configurations[0][@"id"];
    [[kitContainer startKit:kitId configuration:kitConfiguration] start];

    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];

    NSArray<id<MPExtensionKitProtocol>> *activeKits = [kitContainer activeKitsRegistry];
    XCTAssertEqual(activeKits.count, 2);
    XCTAssertEqualObjects(activeKits[0].code, @42);
    XCTAssertEqualObjects(activeKits[1].code, @314);
    NSArray<NSNumber *> *configuredKits = [kitContainer configuredKitsRegistry];
    XCTAssertEqual(configuredKits.count, 2);
    XCTAssertTrue([configuredKits containsObject:@42]);
    XCTAssertTrue([configuredKits containsObject:@314]);
}

- (void)testActiveKitsWhenDisabled {
    NSArray<NSNumber *> *disabledKitsId = @[@(42)];
    kitContainer.disabledKits = disabledKitsId;
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    },
                                @{
                                    @"id":@314,
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    }
                                ];

    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configurations[1]];
    NSNumber *kitId = configurations[1][@"id"];
    [[kitContainer startKit:kitId configuration:kitConfiguration] start];
    kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configurations[0]];
    kitId = configurations[0][@"id"];
    [[kitContainer startKit:kitId configuration:kitConfiguration] start];

    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];

    NSArray<id<MPExtensionKitProtocol>> *activeKits = [kitContainer activeKitsRegistry];
    XCTAssertEqual(activeKits.count, 1);
    XCTAssertEqualObjects(activeKits[0].code, @314);
    NSArray<NSNumber *> *configuredKits = [kitContainer configuredKitsRegistry];
    XCTAssertEqual(configuredKits.count, 2);
    XCTAssertTrue([configuredKits containsObject:@42]);
    XCTAssertTrue([configuredKits containsObject:@314]);
}

- (void)testDisableNonExistentKit {
    NSArray<NSNumber *> *disabledKitsId = @[@(14)];
    kitContainer.disabledKits = disabledKitsId;
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    },
                                @{
                                    @"id":@314,
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    }
                                ];

    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configurations[1]];
    NSNumber *kitId = configurations[1][@"id"];
    [[kitContainer startKit:kitId configuration:kitConfiguration] start];
    kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configurations[0]];
    kitId = configurations[0][@"id"];
    [[kitContainer startKit:kitId configuration:kitConfiguration] start];

    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];

    NSArray<id<MPExtensionKitProtocol>> *activeKits = [kitContainer activeKitsRegistry];
    XCTAssertEqual(activeKits.count, 2);
    XCTAssertEqualObjects(activeKits[0].code, @42);
    XCTAssertEqualObjects(activeKits[1].code, @314);
    NSArray<NSNumber *> *configuredKits = [kitContainer configuredKitsRegistry];
    XCTAssertEqual(configuredKits.count, 2);
    XCTAssertTrue([configuredKits containsObject:@42]);
    XCTAssertTrue([configuredKits containsObject:@314]);
}

- (void)testEmptyDisabledKitsArray {
    NSArray<NSNumber *> *disabledKitsId = @[];
    kitContainer.disabledKits = disabledKitsId;
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    },
                                @{
                                    @"id":@314,
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    }
                                ];

    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configurations[1]];
    NSNumber *kitId = configurations[1][@"id"];
    [[kitContainer startKit:kitId configuration:kitConfiguration] start];
    kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configurations[0]];
    kitId = configurations[0][@"id"];
    [[kitContainer startKit:kitId configuration:kitConfiguration] start];

    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];

    NSArray<id<MPExtensionKitProtocol>> *activeKits = [kitContainer activeKitsRegistry];
    XCTAssertEqual(activeKits.count, 2);
    XCTAssertEqualObjects(activeKits[0].code, @42);
    XCTAssertEqualObjects(activeKits[1].code, @314);
    NSArray<NSNumber *> *configuredKits = [kitContainer configuredKitsRegistry];
    XCTAssertEqual(configuredKits.count, 2);
    XCTAssertTrue([configuredKits containsObject:@42]);
    XCTAssertTrue([configuredKits containsObject:@314]);
}

- (void)testDisableMultipleKits {
    NSArray<NSNumber *> *disabledKitsId = @[@(42), @(400)];
    kitContainer.disabledKits = disabledKitsId;
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    },
                                @{
                                    @"id":@314,
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    },
                                @{
                                    @"id":@400,
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    }
                                ];

    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configurations[1]];
    NSNumber *kitId = configurations[1][@"id"];
    [[kitContainer startKit:kitId configuration:kitConfiguration] start];
    kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configurations[0]];
    kitId = configurations[0][@"id"];
    [[kitContainer startKit:kitId configuration:kitConfiguration] start];

    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];

    NSArray<id<MPExtensionKitProtocol>> *activeKits = [kitContainer activeKitsRegistry];
    XCTAssertEqual(activeKits.count, 1);
    XCTAssertEqualObjects(activeKits[0].code, @314);
    NSArray<NSNumber *> *configuredKits = [kitContainer configuredKitsRegistry];
    XCTAssertEqual(configuredKits.count, 2);
    XCTAssertTrue([configuredKits containsObject:@42]);
    XCTAssertTrue([configuredKits containsObject:@314]);
}

- (void)testForwardLoggedInUserWithMultipleKits {
    MParticleUser *currentUser = [MParticle sharedInstance].identity.currentUser;
    currentUser.isLoggedIn = true;
    
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            }
                                    },
                                @{
                                    @"id":@314,
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"eau":@false
                                    }
                                ];
    
    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configurations[1]];
    [[kitContainer startKit:@314 configuration:kitConfiguration] start];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    NSArray<id<MPExtensionKitProtocol>> *activeKits = [kitContainer activeKitsRegistry];
    
    XCTAssertEqual(activeKits.count, 2);
    XCTAssertTrue([activeKits[0].code integerValue] == 42 || [activeKits[0].code integerValue] == 314);
    XCTAssertTrue([activeKits[1].code integerValue] == 42 || [activeKits[1].code integerValue] == 314);
    
    NSArray<NSNumber *> *configuredKits = [kitContainer configuredKitsRegistry];
    XCTAssertEqual(configuredKits.count, 2);
    XCTAssertTrue([configuredKits containsObject:@42]);
    XCTAssertTrue([configuredKits containsObject:@314]);
    
    configurations = @[
                       @{
                           @"id":@(42),
                           @"as":@{
                                   @"secretKey":@"MySecretKey",
                                   @"sendTransactionData":@"true"
                                   },
                           @"eau":@true
                           },
                       @{
                           @"id":@314,
                           @"as":@{
                                   @"secretKey":@"MySecretKey",
                                   @"sendTransactionData":@"true"
                                   },
                           @"eau":@false
                           }
                       ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    activeKits = [kitContainer activeKitsRegistry];
    
    XCTAssertEqual(activeKits.count, 2);
    XCTAssertTrue([activeKits[0].code integerValue] == 42 || [activeKits[0].code integerValue] == 314);
    XCTAssertTrue([activeKits[1].code integerValue] == 42 || [activeKits[1].code integerValue] == 314);
    configuredKits = [kitContainer configuredKitsRegistry];
    XCTAssertEqual(configuredKits.count, 2);
    XCTAssertTrue([configuredKits containsObject:@42]);
    XCTAssertTrue([configuredKits containsObject:@314]);
}

- (void)testFilterMessageType {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"hs":@{
                                            @"mt":@{@"e":@0},
                                            @"et":@{@"52":@0},
                                            @"ec":@{@"1594525888":@0},
                                            @"ea":@{@"1217787541":@0},
                                            @"svec":@{@"1594525888":@0},
                                            @"svea":@{@"1217787541":@0}
                                            }
                                    }
                                ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dinosaur Run" type:MPEventTypeOther];
    event.duration = @2;
    event.customAttributes = @{@"speed":@25,
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    id registeredKit = [[registeredKits objectsPassingTest:^BOOL(id<MPExtensionProtocol>  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(MPExtensionKitProtocol)]) {
            id<MPExtensionKitProtocol> kitExtension = (id<MPExtensionKitProtocol>)obj;
            if (kitExtension.code.intValue == 42) {
                return YES;
            }
        }
        return NO;
    }] anyObject];
    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forEvent:event selector:@selector(logEvent:)];
    
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
    XCTAssertNil(kitFilter.filteredAttributes, @"Filtered attributes should have been nil.");
}

- (void)testFilterEventTypeNavigation {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey"
                                            },
                                    @"hs":@{
                                            @"et":@{@"49":@0}
                                            }
                                    }
                                ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dinosaur Run" type:MPEventTypeNavigation];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    id registeredKit = [[registeredKits objectsPassingTest:^BOOL(id<MPExtensionProtocol>  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(MPExtensionKitProtocol)]) {
            id<MPExtensionKitProtocol> kitExtension = (id<MPExtensionKitProtocol>)obj;
            if (kitExtension.code.intValue == 42) {
                return YES;
            }
        }
        return NO;
    }] anyObject];
    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forEvent:event selector:@selector(logScreen:)];
    
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertFalse(kitFilter.shouldFilter, @"Event type filtering should not be taking place for screen events.");
    
    kitFilter = [kitContainer filter:registeredKit forEvent:event selector:@selector(logEvent:)];
    
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertTrue(kitFilter.shouldFilter, @"Non-screen event should have been filtered by event type");
}

- (void)testFilterEventNameAndAttributes {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"hs":@{
                                            @"ec":@{@"-2049994443":@0}
                                            }
                                    }
                                ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Purchase" type:MPEventTypeTransaction];
    event.duration = @2;
    event.customAttributes = @{@"Product":@"Running shoes",
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    id registeredKit = [[registeredKits objectsPassingTest:^BOOL(id<MPExtensionProtocol>  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(MPExtensionKitProtocol)]) {
            id<MPExtensionKitProtocol> kitExtension = (id<MPExtensionKitProtocol>)obj;
            if (kitExtension.code.intValue == 42) {
                return YES;
            }
        }
        return NO;
    }] anyObject];
    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forEvent:event selector:@selector(logEvent:)];
    
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
    
    configurations = @[
                       @{
                           @"id":@(42),
                           @"as":@{
                                   @"secretKey":@"MySecretKey",
                                   @"sendTransactionData":@"true"
                                   },
                           @"hs":@{
                                   @"ea":@{@"484927002":@0}
                                   }
                           }
                       ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    event = [[MPEvent alloc] initWithName:@"Purchase" type:MPEventTypeTransaction];
    event.duration = @2;
    event.customAttributes = @{@"Product":@"Running shoes",
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";
    
    kitFilter = [kitContainer filter:registeredKit forEvent:event selector:@selector(logEvent:)];
    
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertEqual(kitFilter.filteredAttributes.count, 1, @"There should be only one attribute in the list.");
    XCTAssertEqualObjects(kitFilter.filteredAttributes[@"modality"], @"sprinting", @"Not filtering the correct attribute.");
}

- (void)testFilterForSelector {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"hs":@{
                                            @"mt":@{@"v":@0},
                                            @"et":@{@"52":@0},
                                            @"ec":@{@"1594525888":@0},
                                            @"ea":@{@"1217787541":@0},
                                            @"svec":@{@"1594525888":@0},
                                            @"svea":@{@"1217787541":@0}
                                            }
                                    }
                                ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 42"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];

    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forBaseEvent:(MPBaseEvent *)nil forSelector:@selector(logScreen:)];
    XCTAssertNotNil(kitFilter, @"Should not have been nil.");
}

- (void)testFilterForUserAttribute {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"hs":@{
                                            @"ua":@{@"1818103830":@0}
                                            }
                                    }
                                ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 42"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];

    NSString *key = @"Shoe Size";
    NSString *value = @"11";
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forUserAttributeKey:key value:value];
    XCTAssertNotNil(kitFilter);
    XCTAssertTrue(kitFilter.shouldFilter);
    
    key = @"teeth";
    value = @"sharp";
    kitFilter = [kitContainer filter:registeredKit forUserAttributeKey:key value:value];
    XCTAssertNil(kitFilter);
    
    key = nil;
    kitFilter = [kitContainer filter:registeredKit forUserAttributeKey:key value:value];
    XCTAssertNil(kitFilter);
    
    key = @"Shoe Size";
    NSMutableArray *values = [@[@"9", @"10", @"11"] mutableCopy];
    kitFilter = [kitContainer filter:registeredKit forUserAttributeKey:key value:values];
    XCTAssertNotNil(kitFilter);
    
    key = @"Dinosaur";
    values = [@[@"T-Rex", @"Short arms", @"Omnivore"] mutableCopy];
    
    [kitContainer forwardSDKCall:@selector(setUserAttribute:values:)
                userAttributeKey:key
                           value:values
                      kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPKitConfiguration *kitConfig) {
        XCTAssertNotNil(kit);
        
        MPKitExecStatus *execStatus = [kit setUserAttribute:key values:values];
        XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
        
    }];
}

- (void)testNotForwardUserAttributeList {    
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"hs":@{
                                            @"ua":@{@"1818103830":@0}
                                            }
                                    }
                                ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    NSString *key = @"Shoe Size";
    NSMutableArray *values = [@[@"9", @"10", @"11"] mutableCopy];

    [kitContainer forwardSDKCall:@selector(setUserAttribute:values:)
                userAttributeKey:key
                           value:values
                      kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPKitConfiguration *kitConfig) {
                          NSAssert(false, @"This line should never be executed.");
                      }];
}

- (void)testFilterForUserAttributes {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"sendAppVersion":@"True",
                                            @"rootUrl":@"http://survey.foreseeresults.com/survey/display",
                                            @"clientId":@"C0C39A5",
                                            @"surveyId":@"42"
                                            },
                                    @"hs":@{
                                            @"ua":@{
                                                    @"-44759723":@0, // member_since
                                                    @"1168987":@0 // $Age
                                                    }
                                            }
                                    }
                                ];
    
    NSDictionary *userAttributes = @{@"$Age":@24,
                                     @"member_since":[NSDate date],
                                     @"arms":@"short",
                                     @"growl":@"loud",
                                     @"teeth":@"sharp"};
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 42"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];

    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forUserAttributes:userAttributes];
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter user attribute.");
    XCTAssertEqual(kitFilter.filteredAttributes[@"arms"], @"short", @"User attribute should not have been filtered.");
    XCTAssertEqual(kitFilter.filteredAttributes[@"growl"], @"loud", @"User attribute should not have been filtered.");
    XCTAssertEqual(kitFilter.filteredAttributes[@"teeth"], @"sharp", @"User attribute should not have been filtered.");
    XCTAssertNil(kitFilter.filteredAttributes[@"$Age"], @"User attribute should have been filtered.");
    XCTAssertNil(kitFilter.filteredAttributes[@"member_since"], @"User attribute should have been filtered.");

    userAttributes = @{@"$Age":@24,
                       @"member_since":[NSDate date]
                       };
    
    kitFilter = [kitContainer filter:registeredKit forUserAttributes:userAttributes];
    XCTAssertNil(kitFilter, @"Filter should have been nil.");
    
    kitFilter = [kitContainer filter:registeredKit forUserAttributes:nil];
    XCTAssertNil(kitFilter, @"Filter should have been nil.");
}

- (void)testFilterForUserIdentity {
    NSString *identityTypeString = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)MPUserIdentityEmail];
    
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"hs":@{
                                            @"uid":@{identityTypeString:@0}
                                            }
                                    }
                                ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 42"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];

    NSString *identityString = @"earl.sinclair@shortarmsdinosaurs.com";
    MPUserIdentity identityType = MPUserIdentityEmail;
    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forUserIdentityKey:identityString identityType:identityType];
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter user identity.");
    
    identityType = MPUserIdentityCustomerId;
    kitFilter = [kitContainer filter:registeredKit forUserIdentityKey:identityString identityType:identityType];
    XCTAssertNil(kitFilter, @"Filter should have been nil.");
}

- (void)testFilterCommerceEvent_EventType {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"hs":@{
                                            @"et":@{@"1567":@0}
                                            }
                                    }
                                ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    id registeredKit = [registeredKits anyObject];

    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    product[@"key1"] = @"val1";
    product[@"key_number"] = @"1";
    product[@"key_bool"] = @"YES";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertEqual(commerceEvent.products.count, 1, @"Incorrect product count.");
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent.customAttributes = @{@"key_string": @"val_string", @"key_number": @"3.14"};
    
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Doctor";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @18;
    transactionAttributes.transactionId = @"42";
    commerceEvent.transactionAttributes = transactionAttributes;
    XCTAssertNotNil(commerceEvent.transactionAttributes, @"Transaction attributes should not have been nil.");

    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forCommerceEvent:commerceEvent];

    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
}

- (void)testFilterCommerceEvent_EntityType {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"hs":@{
                                            @"ent":@{@"1":@0}
                                            }
                                    }
                                ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    id registeredKit = [registeredKits anyObject];

    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    product[@"key1"] = @"val1";
    product[@"key_number"] = @"1";
    product[@"key_bool"] = @"YES";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertEqual(commerceEvent.products.count, 1, @"Incorrect product count.");
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent.customAttributes = @{@"key_string": @"val_string", @"key_number": @"3.14"};
    
    product = [[MPProduct alloc] initWithName:@"Tardis" sku:@"trds" quantity:@1 price:@7.89];
    product.brand = @"Gallifrey Tardis";
    product.category = @"Time Machine";
    product.position = 2;
    product.variant = @"Police Box";
    
    [commerceEvent addProduct:product];
    XCTAssertEqual(commerceEvent.products.count, 2, @"Incorrect product count.");
    
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Doctor";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @18;
    transactionAttributes.transactionId = @"42";
    commerceEvent.transactionAttributes = transactionAttributes;
    XCTAssertNotNil(commerceEvent.transactionAttributes, @"Transaction attributes should not have been nil.");

    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forCommerceEvent:commerceEvent];

    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
}

- (void)testFilterCommerceEvent_Other {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"hs":@{
                                            @"cea":@{@"-1031775261":@0},
                                            @"afa":@{@"1":@{@"93997959":@0}}
                                            }
                                    }
                                ];
    
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    id registeredKit = [registeredKits anyObject];
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    product[@"key1"] = @"val1";
    product[@"key_number"] = @"1";
    product[@"key_bool"] = @"YES";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertEqual(commerceEvent.products.count, 1, @"Incorrect product count.");
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent.customAttributes = @{@"key_string": @"val_string", @"key_number": @"3.14"};
    
    product = [[MPProduct alloc] initWithName:@"Tardis" sku:@"trds" quantity:@1 price:@7.89];
    product.brand = @"Gallifrey Tardis";
    product.category = @"Time Machine";
    product.position = 2;
    product.variant = @"Police Box";
    
    [commerceEvent addProduct:product];
    XCTAssertEqual(commerceEvent.products.count, 2, @"Incorrect product count.");
    
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Doctor";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @18;
    transactionAttributes.transactionId = @"42";
    commerceEvent.transactionAttributes = transactionAttributes;
    XCTAssertNotNil(commerceEvent.transactionAttributes, @"Transaction attributes should not have been nil.");
    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forCommerceEvent:commerceEvent];

    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
}

- (void)testFilterCommerceEvent_TransactionAttributes {
    NSArray *configurations = @[
                                @{
                                    @"id":@(42),
                                    @"as":@{
                                            @"secretKey":@"MySecretKey",
                                            @"sendTransactionData":@"true"
                                            },
                                    @"hs":@{
                                            @"cea":@{@"-94160813":@0, // Revenue
                                                     @"-1865890959":@0 // Affiliation
                                                     }
                                            }
                                    }
                                ];
    
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 42"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent);
    XCTAssertEqual(commerceEvent.products.count, 1);
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    
    product = [[MPProduct alloc] initWithName:@"Tardis" sku:@"trds" quantity:@1 price:@7.89];
    product.brand = @"Gallifrey Tardis";
    product.category = @"Time Machine";
    product.position = 2;
    product.variant = @"Police Box";
    
    [commerceEvent addProduct:product];
    XCTAssertEqual(commerceEvent.products.count, 2);
    
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Doctor";
    transactionAttributes.shipping = @3;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @18;
    transactionAttributes.transactionId = @"42";
    commerceEvent.transactionAttributes = transactionAttributes;
    XCTAssertNotNil(commerceEvent.transactionAttributes);
    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forCommerceEvent:commerceEvent];
    
    XCTAssertNotNil(kitFilter);
    XCTAssertNotNil(kitFilter.forwardCommerceEvent);
    XCTAssertNotNil(kitFilter.forwardCommerceEvent.transactionAttributes);
    XCTAssertNil(kitFilter.forwardCommerceEvent.transactionAttributes.affiliation);
    XCTAssertNil(kitFilter.forwardCommerceEvent.transactionAttributes.revenue);
    XCTAssertEqualObjects(kitFilter.forwardCommerceEvent.transactionAttributes.shipping, @3);
    XCTAssertEqualObjects(kitFilter.forwardCommerceEvent.transactionAttributes.tax, @4.56);
    XCTAssertEqualObjects(kitFilter.forwardCommerceEvent.transactionAttributes.transactionId, @"42");
    
}

- (void)testForwardAppsFlyerEvent {
    [self setUserAttributesAndIdentities];
    
    NSString *configurationStr =  @"{ \
                                        \"id\":92, \
                                        \"as\":{ \
                                            \"devKey\":\"INVALID_DEV_KEY\", \
                                            \"appleAppId\":\"INVALID_APPLE_APP_ID\" \
                                        }, \
                                        \"hs\":{ \
                                        }, \
                                        \"pr\":[ \
                                              { \
                                                  \"id\":144, \
                                                  \"pmmid\":24, \
                                                  \"matches\":[ \
                                                      { \
                                                          \"message_type\":4, \
                                                          \"event_match_type\":\"String\", \
                                                          \"event\":\"Subscription_success\", \
                                                          \"attribute_key\":\"Plan\", \
                                                          \"attribute_values\":[\"extra-premium\", \"Premium\"] \
                                                      }, \
                                                      { \
                                                          \"message_type\":4, \
                                                          \"event_match_type\":\"String\", \
                                                          \"event\":\"subscription_success\", \
                                                          \"attribute_key\":\"plan_color\", \
                                                          \"attribute_values\":[\"gold\", \"platinum\"] \
                                                      }, \
                                                      { \
                                                          \"message_type\":4, \
                                                          \"event_match_type\":\"String\", \
                                                          \"event\":\"subscription_success\", \
                                                          \"attribute_key\":\"boolean\", \
                                                          \"attribute_values\":[\"true\"] \
                                                      } \
                                                  ], \
                                                  \"behavior\":{ \
                                                      \"append_unmapped_as_is\":true \
                                                  }, \
                                                  \"action\":{ \
                                                      \"projected_event_name\":\"new_premium_subscriber\", \
                                                      \"attribute_maps\":[ \
                                                      ], \
                                                      \"outbound_message_type\":4 \
                                                  } \
                                              }, \
                                              { \
                                                  \"id\":166, \
                                                  \"matches\":[{ \
                                                      \"message_type\":4, \
                                                      \"event_match_type\":\"\", \
                                                      \"event\":\"\" \
                                                  }], \
                                                  \"behavior\":{ \
                                                      \"append_unmapped_as_is\":true, \
                                                      \"is_default\":true \
                                                  }, \
                                                  \"action\":{ \
                                                      \"projected_event_name\":\"\", \
                                                      \"attribute_maps\":[ \
                                                      ], \
                                                      \"outbound_message_type\":4 \
                                                  } \
                                              }, \
                                              { \
                                                  \"id\":156, \
                                                  \"pmid\":350, \
                                                  \"matches\":[{ \
                                                      \"message_type\":4, \
                                                      \"event_match_type\":\"Hash\", \
                                                      \"event\":\"-882445395\" \
                                                  }], \
                                                  \"behavior\":{ \
                                                      \"append_unmapped_as_is\":true \
                                                  }, \
                                                  \"action\":{ \
                                                      \"projected_event_name\":\"af_achievement_unlocked\", \
                                                      \"attribute_maps\":[ \
                                                                        { \
                                                                            \"projected_attribute_name\":\"af_description\", \
                                                                            \"match_type\":\"Hash\", \
                                                                            \"value\":\"995159031\", \
                                                                            \"data_type\":\"String\" \
                                                                        } \
                                                                        ], \
                                                      \"outbound_message_type\":4 \
                                                  } \
                                              } \
                                              ] \
                                    }";
    
    NSData *configurationData = [configurationStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *configurationDictionary = [NSJSONSerialization JSONObjectWithData:configurationData options:0 error:nil];
    NSArray *configurations = @[configurationDictionary];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"subscription_success" type:MPEventTypeTransaction];
    event.customAttributes = @{@"plan":@"premium", @"plan_color":@"gold", @"boolean":@YES};
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    MPKitFilter *kitFilter = [kitContainer filter:kitRegister forEvent:event selector:@selector(logEvent:)];
    MPEvent *eventCopy = (MPEvent *)kitFilter.originalEventCopy;
    

    XCTAssert([kitFilter.forwardEvent isKindOfClass:[MPEvent class]]);
    MPEvent *forwardEvent = (MPEvent *)kitFilter.forwardEvent;
    XCTAssertNotNil(forwardEvent);
    XCTAssertEqualObjects(forwardEvent.name, @"new_premium_subscriber");
    XCTAssertNotNil(forwardEvent.customAttributes);
    XCTAssertEqual(forwardEvent.customAttributes.count, 3);
    XCTAssertNotNil(kitFilter.appliedProjections);
    XCTAssertEqualObjects(eventCopy.name, @"subscription_success");
    XCTAssertNotNil(eventCopy.customAttributes);
    XCTAssertEqual(eventCopy.customAttributes.count, 3);
}

- (void)testForwardAppsFlyerCommerceEvent {
    [self setUserAttributesAndIdentities];

    NSString *configurationStr =  @"{ \
                                        \"id\":92, \
                                        \"as\":{ \
                                            \"devKey\":\"INVALID_DEV_KEY\", \
                                            \"appleAppId\":\"INVALID_APPLE_APP_ID\" \
                                        }, \
                                        \"hs\":{ \
                                        }, \
                                        \"pr\":[ \
                                              { \
                                                  \"id\":144, \
                                                  \"pmmid\":24, \
                                                  \"matches\":[{ \
                                                      \"message_type\":4, \
                                                      \"event_match_type\":\"String\", \
                                                      \"event\":\"Subscription_success\", \
                                                      \"attribute_key\":\"Plan\", \
                                                      \"attribute_values\":[\"Premium\"] \
                                                  }], \
                                                  \"behavior\":{ \
                                                      \"append_unmapped_as_is\":false \
                                                  }, \
                                                  \"action\":{ \
                                                      \"projected_event_name\":\"new_premium_subscriber\", \
                                                      \"attribute_maps\":[ \
                                                      ], \
                                                      \"outbound_message_type\":4 \
                                                  } \
                                              }, \
                                            { \
                                                \"id\":147, \
                                                \"pmid\":352, \
                                                \"matches\":[{ \
                                                    \"message_type\":16, \
                                                    \"event_match_type\":\"Hash\", \
                                                    \"event\":\"1567\" \
                                                }], \
                                                \"behavior\":{ \
                                                    \"append_unmapped_as_is\":true \
                                                }, \
                                                \"action\":{ \
                                                    \"projected_event_name\":\"af_add_to_cart\", \
                                                    \"attribute_maps\":[ \
                                                                      { \
                                                                          \"projected_attribute_name\":\"af_content_type\", \
                                                                          \"match_type\":\"Hash\", \
                                                                          \"value\":\"-1847184355\", \
                                                                          \"data_type\":\"String\", \
                                                                          \"property\":\"ProductField\" \
                                                                      }, \
                                                                      { \
                                                                          \"projected_attribute_name\":\"af_currency\", \
                                                                          \"match_type\":\"Hash\", \
                                                                          \"value\":\"-885836579\", \
                                                                          \"data_type\":\"String\", \
                                                                          \"property\":\"EventField\" \
                                                                      }, \
                                                                      { \
                                                                          \"projected_attribute_name\":\"af_content_id\", \
                                                                          \"match_type\":\"Hash\", \
                                                                          \"value\":\"1509242\", \
                                                                          \"data_type\":\"String\", \
                                                                          \"property\":\"ProductField\" \
                                                                      }, \
                                                                      { \
                                                                          \"projected_attribute_name\":\"af_price\", \
                                                                          \"match_type\":\"Hash\", \
                                                                          \"value\":\"2019141258\", \
                                                                          \"data_type\":\"Float\", \
                                                                          \"property\":\"ProductField\" \
                                                                      }, \
                                                                      { \
                                                                          \"projected_attribute_name\":\"af_quantity\", \
                                                                          \"match_type\":\"Hash\", \
                                                                          \"value\":\"1112267690\", \
                                                                          \"data_type\":\"Int\", \
                                                                          \"property\":\"ProductField\" \
                                                                      } \
                                                                      ], \
                                                    \"outbound_message_type\":4 \
                                                } \
                                            }, \
                                              { \
                                                  \"id\":166, \
                                                  \"matches\":[{ \
                                                      \"message_type\":4, \
                                                      \"event_match_type\":\"\", \
                                                      \"event\":\"\" \
                                                  }], \
                                                  \"behavior\":{ \
                                                      \"append_unmapped_as_is\":true, \
                                                      \"is_default\":true \
                                                  }, \
                                                  \"action\":{ \
                                                      \"projected_event_name\":\"\", \
                                                      \"attribute_maps\":[ \
                                                      ], \
                                                      \"outbound_message_type\":4 \
                                                  } \
                                              }, \
                                              { \
                                                  \"id\":156, \
                                                  \"pmid\":350, \
                                                  \"matches\":[{ \
                                                      \"message_type\":4, \
                                                      \"event_match_type\":\"Hash\", \
                                                      \"event\":\"-882445395\" \
                                                  }], \
                                                  \"behavior\":{ \
                                                      \"append_unmapped_as_is\":true \
                                                  }, \
                                                  \"action\":{ \
                                                      \"projected_event_name\":\"af_achievement_unlocked\", \
                                                      \"attribute_maps\":[ \
                                                                        { \
                                                                            \"projected_attribute_name\":\"af_description\", \
                                                                            \"match_type\":\"Hash\", \
                                                                            \"value\":\"995159031\", \
                                                                            \"data_type\":\"String\" \
                                                                        } \
                                                                        ], \
                                                      \"outbound_message_type\":4 \
                                                  } \
                                              } \
                                              ] \
                                    }";
    
    NSData *configurationData = [configurationStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *configurationDictionary = [NSJSONSerialization JSONObjectWithData:configurationData options:0 error:nil];
    NSArray *configurations = @[configurationDictionary];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];

    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Doctor";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @18;
    transactionAttributes.transactionId = @"42";
    commerceEvent.transactionAttributes = transactionAttributes;
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    MPKitFilter *kitFilter = [kitContainer filter:kitRegister forCommerceEvent:commerceEvent];
    MPEvent *commerceEventCopy = (MPEvent *)kitFilter.originalCommerceEventCopy;
    
    XCTAssert([kitFilter.forwardEvent isKindOfClass:[MPEvent class]]);
    MPEvent *event = (MPEvent *)kitFilter.forwardEvent;
    XCTAssertEqualObjects(event.customAttributes[@"af_quantity"], @"1");
    XCTAssertEqualObjects(event.customAttributes[@"af_content_id"], @"OutATime");
    XCTAssertEqualObjects(event.customAttributes[@"af_content_type"], @"Time Machine");
    XCTAssertEqualObjects(event.name, @"af_add_to_cart");
    XCTAssertNotNil(kitFilter.appliedProjections);
    XCTAssertEqual(commerceEventCopy.type, MPEventTypeAddToCart);
    
}

- (void)testMatchArrayProjection {
    [self setUserAttributesAndIdentities];

    NSString *configurationStr = @"{ \
                                     \"id\": 92, \
                                     \"as\": { \
                                       \"devKey\": \"INVALID_DEV_KEY\", \
                                       \"appleAppId\": \"INVALID_APPLE_APP_ID\" \
                                     }, \
                                     \"hs\": {}, \
                                     \"pr\": [ \
                                       { \
                                         \"id\": 170, \
                                         \"pmmid\": 29, \
                                         \"behavior\": { \
                                           \"append_unmapped_as_is\": true \
                                         }, \
                                         \"action\": { \
                                           \"projected_event_name\": \"X_NEW_SUBSCRIPTION\", \
                                           \"attribute_maps\": [], \
                                           \"outbound_message_type\": 4 \
                                         }, \
                                         \"matches\": [ \
                                           { \
                                             \"message_type\": 4, \
                                             \"event_match_type\": \"String\", \
                                             \"event\": \"SUBSCRIPTION_END\", \
                                             \"attribute_key\": \"outcome\", \
                                             \"attribute_values\": [ \
                                               \"new_subscription\" \
                                             ] \
                                           } \
                                         ] \
                                       }, \
                                       { \
                                         \"id\": 171, \
                                         \"pmmid\": 30, \
                                         \"behavior\": { \
                                           \"append_unmapped_as_is\": true \
                                         }, \
                                         \"action\": { \
                                           \"projected_event_name\": \"X_NEW_NOAH_SUBSCRIPTION\", \
                                           \"attribute_maps\": [], \
                                           \"outbound_message_type\": 4 \
                                         }, \
                                         \"matches\": [ \
                                           { \
                                             \"message_type\": 4, \
                                             \"event_match_type\": \"String\", \
                                             \"event\": \"SUBSCRIPTION_END\", \
                                             \"attribute_key\": \"Outcome\", \
                                             \"attribute_values\": [ \
                                               \"New_subscription\" \
                                             ] \
                                           }, \
                                           { \
                                             \"message_type\": 4, \
                                             \"event_match_type\": \"String\", \
                                             \"event\": \"SUBSCRIPTION_END\", \
                                             \"attribute_key\": \"plan_id\", \
                                             \"attribute_values\": [ \
                                               \"3\", \
                                               \"8\" \
                                             ] \
                                           } \
                                         ] \
                                       } \
                                     ] \
                                   }";
    
    NSData *configurationData = [configurationStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *configurationDictionary = [NSJSONSerialization JSONObjectWithData:configurationData options:0 error:nil];
    NSArray *configurations = @[configurationDictionary];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];

    MPEvent *event = [[MPEvent alloc] initWithName:@"SUBSCRIPTION_END" type:MPEventTypeTransaction];
    event.customAttributes = @{@"plan_id":@"3", @"outcome":@"new_subscription"};
    NSMutableArray<NSString *> *foundEventNames = [NSMutableArray arrayWithCapacity:2];

    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    MPKitFilter *kitFilter = [kitContainer filter:kitRegister forEvent:event selector:@selector(logEvent:)];

    XCTAssert([kitFilter.forwardEvent isKindOfClass:[MPEvent class]]);
    MPEvent *forwardEvent = (MPEvent *)kitFilter.forwardEvent;
    XCTAssertNotNil(forwardEvent);
    XCTAssertNotNil(forwardEvent.customAttributes);
    XCTAssertEqual(forwardEvent.customAttributes.count, 2);
    MPEvent *eventCopy = (MPEvent *)kitFilter.originalEventCopy;
    
    [foundEventNames addObject:forwardEvent.name];
    
    if (foundEventNames.count == 2) {
        XCTAssertTrue([foundEventNames containsObject:@"X_NEW_SUBSCRIPTION"]);
        XCTAssertTrue([foundEventNames containsObject:@"X_NEW_NOAH_SUBSCRIPTION"]);
    }
    XCTAssertNotNil(kitFilter.appliedProjections);
    XCTAssertEqual(kitFilter.appliedProjections.count, 2);
    XCTAssertEqualObjects(eventCopy.name, @"SUBSCRIPTION_END");
}

- (void)testScreenViewProjectionToBaseEvent {
    [self setUserAttributesAndIdentities];

    NSString *configurationStr = @"{ \
                                     \"id\": 92, \
                                     \"as\": { \
                                       \"devKey\": \"INVALID_DEV_KEY\", \
                                       \"appleAppId\": \"INVALID_APPLE_APP_ID\" \
                                     }, \
                                     \"hs\": {}, \
                                     \"pr\": [ \
                                       { \
                                         \"id\": 170, \
                                         \"pmmid\": 29, \
                                         \"behavior\": { \
                                           \"append_unmapped_as_is\": true \
                                         }, \
                                         \"action\": { \
                                           \"projected_event_name\": \"X_NEW_SUBSCRIPTION\", \
                                           \"attribute_maps\": [], \
                                           \"outbound_message_type\": 4 \
                                         }, \
                                         \"matches\": [ \
                                           { \
                                             \"message_type\": 3, \
                                             \"event_match_type\": \"String\", \
                                             \"event\": \"SUBSCRIPTION_END\", \
                                             \"attribute_key\": \"outcome\", \
                                             \"attribute_values\": [ \
                                               \"new_subscription\" \
                                             ] \
                                           } \
                                         ] \
                                       }, \
                                       { \
                                         \"id\": 171, \
                                         \"pmmid\": 30, \
                                         \"behavior\": { \
                                           \"append_unmapped_as_is\": true \
                                         }, \
                                         \"action\": { \
                                           \"projected_event_name\": \"X_NEW_NOAH_SUBSCRIPTION\", \
                                           \"attribute_maps\": [], \
                                           \"outbound_message_type\": 4 \
                                         }, \
                                         \"matches\": [ \
                                           { \
                                             \"message_type\": 4, \
                                             \"event_match_type\": \"String\", \
                                             \"event\": \"SUBSCRIPTION_END\", \
                                             \"attribute_key\": \"Outcome\", \
                                             \"attribute_values\": [ \
                                               \"New_subscription\" \
                                             ] \
                                           }, \
                                           { \
                                             \"message_type\": 4, \
                                             \"event_match_type\": \"String\", \
                                             \"event\": \"SUBSCRIPTION_END\", \
                                             \"attribute_key\": \"plan_id\", \
                                             \"attribute_values\": [ \
                                               \"3\", \
                                               \"8\" \
                                             ] \
                                           } \
                                         ] \
                                       } \
                                     ] \
                                   }";
    
    NSData *configurationData = [configurationStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *configurationDictionary = [NSJSONSerialization JSONObjectWithData:configurationData options:0 error:nil];
    NSArray *configurations = @[configurationDictionary];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];

    MPEvent *event = [[MPEvent alloc] initWithName:@"SUBSCRIPTION_END" type:MPEventTypeTransaction];
    event.customAttributes = @{@"plan_id":@"3", @"outcome":@"new_subscription"};

    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    
    id kitWrapperMock = OCMProtocolMock(@protocol(MPKitProtocol));
    id kitRegisterMock = OCMPartialMock(kitRegister);
    OCMStub([kitRegisterMock wrapperInstance]).andReturn(kitWrapperMock);
    
    [(id <MPKitProtocol>)[kitWrapperMock expect] logBaseEvent:OCMOCK_ANY];
    [(id <MPKitProtocol>)[kitWrapperMock reject] logScreen:OCMOCK_ANY];
    
    MPKitFilter *kitFilter = [kitContainer filter:kitRegister forEvent:event selector:@selector(logScreen:)];
    MPEvent *eventCopy = (MPEvent *)kitFilter.originalEventCopy;
    
    [kitWrapperMock verifyWithDelay:5.0];

    XCTAssert([kitFilter.forwardEvent isKindOfClass:[MPEvent class]]);
    XCTAssertNotNil(kitFilter.appliedProjections);
    XCTAssertEqualObjects(eventCopy.name, @"SUBSCRIPTION_END");
}

- (void)testNonMatchingMatchArrayProjection {
    [self setUserAttributesAndIdentities];

    NSString *configurationStr = @"{ \
                                     \"id\": 92, \
                                     \"as\": { \
                                       \"devKey\": \"INVALID_DEV_KEY\", \
                                       \"appleAppId\": \"INVALID_APPLE_APP_ID\" \
                                     }, \
                                     \"hs\": {}, \
                                     \"pr\": [ \
                                       { \
                                         \"id\": 170, \
                                         \"pmmid\": 29, \
                                         \"behavior\": { \
                                           \"append_unmapped_as_is\": true \
                                         }, \
                                         \"action\": { \
                                           \"projected_event_name\": \"X_NEW_MALE_SUBSCRIPTION\", \
                                           \"attribute_maps\": [], \
                                           \"outbound_message_type\": 4 \
                                         }, \
                                         \"matches\": [ \
                                           { \
                                             \"message_type\": 4, \
                                             \"event_match_type\": \"String\", \
                                             \"event\": \"SUBSCRIPTION_END\", \
                                             \"attribute_key\": \"outcome\", \
                                             \"attribute_values\": [ \
                                               \"new_subscription\" \
                                             ] \
                                           }, \
                                           { \
                                             \"message_type\": 4, \
                                             \"event_match_type\": \"String\", \
                                             \"event\": \"SUBSCRIPTION_END\", \
                                             \"attribute_key\": \"gender\", \
                                             \"attribute_values\": [ \
                                               \"male\" \
                                             ] \
                                           } \
                                         ] \
                                       } \
                                     ] \
                                   }";
    
    NSData *configurationData = [configurationStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *configurationDictionary = [NSJSONSerialization JSONObjectWithData:configurationData options:0 error:nil];
    NSArray *configurations = @[configurationDictionary];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];

    MPEvent *event = [[MPEvent alloc] initWithName:@"SUBSCRIPTION_END" type:MPEventTypeTransaction];
    event.customAttributes = @{@"plan_id":@"3", @"outcome":@"new_subscription", @"gender":@"female"};
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    MPKitFilter *kitFilter = [kitContainer filter:kitRegister forEvent:event selector:@selector(logEvent:)];
    
    XCTAssert([kitFilter.forwardEvent isKindOfClass:[MPEvent class]]);
    MPEvent *forwardEvent = (MPEvent *)kitFilter.forwardEvent;
    XCTAssertNotNil(forwardEvent);
    XCTAssertNotEqualObjects(forwardEvent.name, @"X_NEW_MALE_SUBSCRIPTION");
    XCTAssertEqualObjects(forwardEvent.name, @"SUBSCRIPTION_END");
}

- (void)testNonMatchingAttributeArrayProjection {
    [self setUserAttributesAndIdentities];

    NSString *configurationStr = @"{ \
                                     \"id\": 92, \
                                     \"as\": { \
                                       \"devKey\": \"INVALID_DEV_KEY\", \
                                       \"appleAppId\": \"INVALID_APPLE_APP_ID\" \
                                     }, \
                                     \"hs\": {}, \
                                     \"pr\": [ \
                                       { \
                                         \"id\": 170, \
                                         \"pmmid\": 29, \
                                         \"behavior\": { \
                                           \"append_unmapped_as_is\": true \
                                         }, \
                                         \"action\": { \
                                           \"projected_event_name\": \"X_NEW_SUBSCRIPTION\", \
                                           \"attribute_maps\": [], \
                                           \"outbound_message_type\": 4 \
                                         }, \
                                         \"matches\": [ \
                                           { \
                                             \"message_type\": 4, \
                                             \"event_match_type\": \"String\", \
                                             \"event\": \"SUBSCRIPTION_END\", \
                                             \"attribute_key\": \"outcome\", \
                                             \"attribute_values\": [ \
                                               \"new_subscription\" \
                                             ] \
                                           } \
                                         ] \
                                       } \
                                     ] \
                                   }";
    
    NSData *configurationData = [configurationStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *configurationDictionary = [NSJSONSerialization JSONObjectWithData:configurationData options:0 error:nil];
    NSArray *configurations = @[configurationDictionary];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];

    MPEvent *event = [[MPEvent alloc] initWithName:@"SUBSCRIPTION_END" type:MPEventTypeTransaction];
    event.customAttributes = @{@"outcome":@"not_new_subscription"};
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    MPKitFilter *kitFilter = [kitContainer filter:kitRegister forEvent:event selector:@selector(logEvent:)];
    
    XCTAssert([kitFilter.forwardEvent isKindOfClass:[MPEvent class]]);
    MPEvent *forwardEvent = (MPEvent *)kitFilter.forwardEvent;
    XCTAssertNotNil(forwardEvent);
    XCTAssertNotEqualObjects(forwardEvent.name, @"X_NEW_SUBSCRIPTION");
    XCTAssertEqualObjects(forwardEvent.name, @"SUBSCRIPTION_END");
}

- (void)testHashProjection {
    [self setUserAttributesAndIdentities];
    
    NSString *configurationStr =  @"{ \
                                        \"id\":92, \
                                        \"as\":{ \
                                            \"devKey\":\"INVALID_DEV_KEY\", \
                                            \"appleAppId\":\"INVALID_APPLE_APP_ID\" \
                                        }, \
                                        \"hs\":{ \
                                        }, \
                                        \"pr\":[ \
                                          { \
                                            \"id\": 146, \
                                            \"pmid\": 351, \
                                            \"behavior\": { \
                                              \"append_unmapped_as_is\": true \
                                            }, \
                                            \"action\": { \
                                              \"projected_event_name\": \"af_add_payment_info\", \
                                              \"attribute_maps\": [ \
                                                { \
                                                  \"projected_attribute_name\": \"af_success\", \
                                                  \"match_type\": \"Static\", \
                                                  \"value\": \"True\", \
                                                  \"data_type\": \"Bool\" \
                                                } \
                                              ], \
                                              \"outbound_message_type\": 4 \
                                            }, \
                                            \"matches\": [ \
                                              { \
                                                \"message_type\": 4, \
                                                \"event_match_type\": \"Hash\", \
                                                \"event\": \"-1602069210\" \
                                              } \
                                            ] \
                                          } \
                                        ] \
                                    }";
    
    NSData *configurationData = [configurationStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *configurationDictionary = [NSJSONSerialization JSONObjectWithData:configurationData options:0 error:nil];
    NSArray *configurations = @[configurationDictionary];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"test_string" type:MPEventTypeOther];
    event.customAttributes = @{@"plan":@"premium"};
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    MPKitFilter *kitFilter = [kitContainer filter:kitRegister forEvent:event selector:@selector(logEvent:)];
    
    XCTAssert([kitFilter.forwardEvent isKindOfClass:[MPEvent class]]);
    MPEvent *forwardEvent = (MPEvent *)kitFilter.forwardEvent;
    XCTAssertNotNil(forwardEvent);
    XCTAssertEqualObjects(forwardEvent.name, @"af_add_payment_info");
    XCTAssertNotNil(forwardEvent.customAttributes);
    XCTAssertEqual(forwardEvent.customAttributes.count, 2);
    XCTAssertEqualObjects(forwardEvent.customAttributes[@"af_success"], @"True");
}

- (void)testAttributeHashProjection {
    [self setUserAttributesAndIdentities];
    
    NSString *configurationStr =  @"{ \
                                        \"id\":92, \
                                        \"as\":{ \
                                            \"devKey\":\"INVALID_DEV_KEY\", \
                                            \"appleAppId\":\"INVALID_APPLE_APP_ID\" \
                                        }, \
                                        \"hs\":{ \
                                        }, \
                                        \"pr\":[ \
                                          { \
                                            \"id\": 156, \
                                            \"pmid\": 350, \
                                            \"behavior\": { \
                                              \"append_unmapped_as_is\": true \
                                            }, \
                                            \"action\": { \
                                              \"projected_event_name\": \"af_achievement_unlocked\", \
                                              \"attribute_maps\": [ \
                                                { \
                                                  \"projected_attribute_name\": \"af_description\", \
                                                  \"match_type\": \"Hash\", \
                                                  \"value\": \"-1289016075\", \
                                                  \"data_type\": \"String\" \
                                                } \
                                              ], \
                                              \"outbound_message_type\": 4 \
                                            }, \
                                            \"matches\": [ \
                                              { \
                                                \"message_type\": 4, \
                                                \"event_match_type\": \"Hash\", \
                                                \"event\": \"-1602069210\" \
                                              } \
                                            ] \
                                          } \
                                        ] \
                                    }";
    
    NSData *configurationData = [configurationStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *configurationDictionary = [NSJSONSerialization JSONObjectWithData:configurationData options:0 error:nil];
    NSArray *configurations = @[configurationDictionary];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"test_string" type:MPEventTypeOther];
    event.customAttributes = @{@"test_description":@"this is a description"};
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    MPKitFilter *kitFilter = [kitContainer filter:kitRegister forEvent:event selector:@selector(logEvent:)];
    
    XCTAssert([kitFilter.forwardEvent isKindOfClass:[MPEvent class]]);
    MPEvent *forwardEvent = (MPEvent *)kitFilter.forwardEvent;
    XCTAssertNotNil(forwardEvent);
    XCTAssertEqualObjects(forwardEvent.name, @"af_achievement_unlocked");
    XCTAssertNotNil(forwardEvent.customAttributes);
    XCTAssertEqual(forwardEvent.customAttributes.count, 1);
    XCTAssertEqualObjects(forwardEvent.customAttributes[@"af_description"], @"this is a description");
}

- (void)testAllocation {    
    MPKitContainer_PRIVATE *localKitContainer = [[MPKitContainer_PRIVATE alloc] init];
    XCTAssertNotNil(localKitContainer);
}

- (void)testExpandedCommerceEventProjection {
    [self setUserAttributesAndIdentities];
    
    NSString *configurationStr =  @"{ \
                                        \"id\":92, \
                                        \"as\":{ \
                                            \"devKey\":\"INVALID_DEV_KEY\", \
                                            \"appleAppId\":\"INVALID_APPLE_APP_ID\" \
                                        }, \
                                        \"hs\":{ \
                                        }, \
                                        \"pr\":[ \
                                          { \
                                            \"id\": 157, \
                                            \"pmid\": 504, \
                                            \"behavior\": { \
                                              \"append_unmapped_as_is\": true \
                                            }, \
                                            \"action\": { \
                                              \"projected_event_name\": \"af_content_view\", \
                                              \"attribute_maps\": [ \
                                                 { \
                                                    \"projected_attribute_name\":\"af_price\", \
                                                    \"match_type\":\"Hash\", \
                                                    \"value\":\"-1000582050\", \
                                                    \"data_type\":\"Float\", \
                                                    \"property\":\"ProductAttribute\" \
                                                 }, \
                                                 { \
                                                    \"projected_attribute_name\":\"af_content_type\", \
                                                    \"match_type\":\"Hash\", \
                                                    \"value\":\"-1702675751\", \
                                                    \"data_type\":\"String\", \
                                                    \"property\":\"ProductAttribute\" \
                                                 }, \
                                                 { \
                                                    \"projected_attribute_name\":\"af_currency\", \
                                                    \"match_type\":\"Hash\", \
                                                    \"value\":\"881337592\", \
                                                    \"data_type\":\"String\", \
                                                    \"property\":\"EventField\" \
                                                 }, \
                                                 { \
                                                    \"projected_attribute_name\":\"af_content_id\", \
                                                    \"match_type\":\"Hash\", \
                                                    \"value\":\"1788759301\", \
                                                    \"data_type\":\"String\", \
                                                    \"property\":\"ProductAttribute\" \
                                                 } \
                                              ], \
                                              \"outbound_message_type\": 4 \
                                            }, \
                                            \"matches\": [ \
                                              { \
                                                \"message_type\": 16, \
                                                \"event_match_type\": \"Hash\", \
                                                \"event\": \"1572\" \
                                              } \
                                            ] \
                                          } \
                                        ] \
                                    }";
    
    NSData *configurationData = [configurationStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *configurationDictionary = [NSJSONSerialization JSONObjectWithData:configurationData options:0 error:nil];
    NSArray *configurations = @[configurationDictionary];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"product name" sku:@"product sku" quantity:@1 price:@45];
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionViewDetail product:product];
    commerceEvent.customAttributes = @{ @"foo attr 1": @"foo attr value 1"};
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    MPKitFilter *kitFilter = [kitContainer filter:kitRegister forCommerceEvent:commerceEvent];
    
    XCTAssert([kitFilter.forwardEvent isKindOfClass:[MPEvent class]]);
    XCTAssertEqualObjects(((MPEvent *)kitFilter.forwardEvent).name, @"af_content_view");
    XCTAssertEqualObjects(((MPEvent *)kitFilter.forwardEvent).customAttributes, @{ @"foo attr 1": @"foo attr value 1"});
}

- (void)testShouldDelayUploadMaxTime {
    MPKitContainer_PRIVATE *localKitContainer = [[MPKitContainer_PRIVATE alloc] init];
    [localKitContainer setKitsInitialized:NO];
    XCTAssertFalse([localKitContainer shouldDelayUpload:0]);
    XCTAssertTrue([localKitContainer shouldDelayUpload:10000]);
}

- (void)testIsDisabledByConsentKitFilterGPDR {
    MPConsentKitFilter *filter = [[MPConsentKitFilter alloc] init];
    
    filter.shouldIncludeOnMatch = YES;
    
    MPConsentKitFilterItem *item = [[MPConsentKitFilterItem alloc] init];
    item.consented = YES;
    item.javascriptHash = -1729075708;
    
    NSMutableArray<MPConsentKitFilterItem *> *filterItems = [NSMutableArray array];
    [filterItems addObject:item];
    
    filter.filterItems = [filterItems copy];
    
    BOOL isDisabled = [[MParticle sharedInstance].kitContainer_PRIVATE isDisabledByConsentKitFilter:filter];
    XCTAssertTrue(isDisabled);
    
    filter.shouldIncludeOnMatch = NO;
    isDisabled = [[MParticle sharedInstance].kitContainer_PRIVATE isDisabledByConsentKitFilter:filter];
    XCTAssertFalse(isDisabled);
    
    filter.shouldIncludeOnMatch = YES;
    
    MPConsentState *state = [[MPConsentState alloc] init];
    
    NSMutableDictionary<NSString *,MPGDPRConsent *> *gdprState = [NSMutableDictionary dictionary];
    
    MPGDPRConsent *gdprConsent = [[MPGDPRConsent alloc] init];
    
    gdprConsent.consented = YES;
    gdprConsent.document = @"foo-document-1";
    
    NSDate *date = [NSDate date];
    gdprConsent.timestamp = date;
    
    gdprConsent.location = @"foo-location-1";
    gdprConsent.hardwareId = @"foo-hardware-id-1";
    
    gdprState[@"Processing"] = gdprConsent;
    
    [state setGDPRConsentState:[gdprState copy]];
    
    [MPPersistenceController_PRIVATE setConsentState:state forMpid:[MPPersistenceController_PRIVATE mpId]];
    MParticle.sharedInstance.identity.currentUser.consentState = state;
    
    isDisabled = [[MParticle sharedInstance].kitContainer_PRIVATE isDisabledByConsentKitFilter:filter];
    XCTAssertFalse(isDisabled);
    
    filter.shouldIncludeOnMatch = NO;
    isDisabled = [[MParticle sharedInstance].kitContainer_PRIVATE isDisabledByConsentKitFilter:filter];
    XCTAssertTrue(isDisabled);
}

- (void)testIsDisabledByConsentKitFilterCCPA {
    MPConsentKitFilter *filter = [[MPConsentKitFilter alloc] init];
    
    filter.shouldIncludeOnMatch = YES;
    
    MPConsentKitFilterItem *item = [[MPConsentKitFilterItem alloc] init];
    item.consented = YES;
    item.javascriptHash = -575335347;
    
    NSMutableArray<MPConsentKitFilterItem *> *filterItems = [NSMutableArray array];
    [filterItems addObject:item];
    
    filter.filterItems = [filterItems copy];
    
    MPConsentState *state = [[MPConsentState alloc] init];
        
    MPCCPAConsent *ccpaConsent = [[MPCCPAConsent alloc] init];
    
    ccpaConsent.consented = YES;
    ccpaConsent.document = @"foo-document-1";
    
    NSDate *date = [NSDate date];
    ccpaConsent.timestamp = date;
    
    ccpaConsent.location = @"foo-location-1";
    ccpaConsent.hardwareId = @"foo-hardware-id-1";
        
    [state setCCPAConsentState: [ccpaConsent copy]];
    
    [MPPersistenceController_PRIVATE setConsentState:state forMpid:[MPPersistenceController_PRIVATE mpId]];
    MParticle.sharedInstance.identity.currentUser.consentState = state;
    
    BOOL isDisabled = [[MParticle sharedInstance].kitContainer_PRIVATE isDisabledByConsentKitFilter:filter];
    XCTAssertFalse(isDisabled);
    
    filter.shouldIncludeOnMatch = NO;
    isDisabled = [[MParticle sharedInstance].kitContainer_PRIVATE isDisabledByConsentKitFilter:filter];
    XCTAssertTrue(isDisabled);
}

- (void)testInitializeKitsWhenNilSupportedKits {
    MPKitContainer_PRIVATE *kitContainer = [[MPKitContainer_PRIVATE alloc] init];
    MPKitContainer_PRIVATE *mockKitContainer = OCMPartialMock(kitContainer);
    [[[(id)mockKitContainer stub] andReturn:nil] supportedKits];
    [mockKitContainer initializeKits];
    XCTAssertTrue(mockKitContainer.kitsInitialized);
}

- (void)testInitializeKitsWhenEmptySupportedKits {
    MPKitContainer_PRIVATE *kitContainer = [[MPKitContainer_PRIVATE alloc] init];
    MPKitContainer_PRIVATE *mockKitContainer = OCMPartialMock(kitContainer);
    [[[(id)mockKitContainer stub] andReturn: @[] ] supportedKits];
    [mockKitContainer initializeKits];
    XCTAssertTrue(mockKitContainer.kitsInitialized);
}

- (void)testInitializeKitsWhenNonemptySupportedKits {
    MPKitContainer_PRIVATE *kitContainer = [[MPKitContainer_PRIVATE alloc] init];
    MPKitContainer_PRIVATE *mockKitContainer = OCMPartialMock(kitContainer);
    [[[(id)mockKitContainer stub] andReturn: @[@123] ] supportedKits];
    [mockKitContainer initializeKits];
    XCTAssertFalse(mockKitContainer.kitsInitialized);
}

#if TARGET_OS_IOS == 1
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)testAttemptToLogEventToKit {
    MPKitContainer_PRIVATE *localKitContainer = [[MPKitContainer_PRIVATE alloc] init];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"test_string" type:MPEventTypeOther];
    event.customAttributes = @{@"plan":@"premium"};
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    id kitWrapperMock = OCMProtocolMock(@protocol(MPKitProtocol));
    id kitRegisterMock = OCMPartialMock(kitRegister);
    OCMStub([kitRegisterMock wrapperInstance]).andReturn(kitWrapperMock);
    MPKitFilter *kitFilter = [kitContainer filter:kitRegisterMock forEvent:event selector:@selector(logEvent:)];
    
    [(id <MPKitProtocol>)[kitWrapperMock expect] logBaseEvent:OCMOCK_ANY];
    // MPKitAppsFlyerTest supports logBaseEvent: so only it should be called on the kit
    [(id <MPKitProtocol>)[kitWrapperMock reject] logEvent:OCMOCK_ANY];


    [localKitContainer attemptToLogEventToKit:kitRegister kitFilter:kitFilter selector:@selector(logEvent:) parameters:nil messageType:MPMessageTypeEvent userInfo:[[NSDictionary alloc] init]];
    
    [kitWrapperMock verifyWithDelay:5.0];
}
#pragma clang diagnostic pop

- (void)testAttemptToLogBaseEventToKit {
    MPKitContainer_PRIVATE *localKitContainer = [[MPKitContainer_PRIVATE alloc] init];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"test_string" type:MPEventTypeOther];
    event.customAttributes = @{@"plan":@"premium"};
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    id kitWrapperMock = OCMProtocolMock(@protocol(MPKitProtocol));
    id kitRegisterMock = OCMPartialMock(kitRegister);
    OCMStub([kitRegisterMock wrapperInstance]).andReturn(kitWrapperMock);
    MPKitFilter *kitFilter = [kitContainer filter:kitRegisterMock forEvent:event selector:@selector(logBaseEvent:)];
    
    [(id <MPKitProtocol>)[kitWrapperMock expect] logBaseEvent:OCMOCK_ANY];
    
    [localKitContainer attemptToLogEventToKit:kitRegister kitFilter:kitFilter selector:@selector(logBaseEvent:) parameters:nil messageType:MPMessageTypeEvent userInfo:[[NSDictionary alloc] init]];
    
    [kitWrapperMock verifyWithDelay:5.0];
}

- (void)testAttemptToLogBaseEventMediaTypeToKit {
    MPKitContainer_PRIVATE *localKitContainer = [[MPKitContainer_PRIVATE alloc] init];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"test_string" type:MPEventTypeMedia];
    event.customAttributes = @{@"plan":@"premium"};
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    id kitWrapperMock = OCMProtocolMock(@protocol(MPKitProtocol));
    id kitRegisterMock = OCMPartialMock(kitRegister);
    OCMStub([kitRegisterMock wrapperInstance]).andReturn(kitWrapperMock);
    MPKitFilter *kitFilter = [kitContainer filter:kitRegisterMock forEvent:event selector:@selector(logBaseEvent:)];
    
    [(id <MPKitProtocol>)[kitWrapperMock expect] logBaseEvent:OCMOCK_ANY];
    
    [localKitContainer attemptToLogEventToKit:kitRegister kitFilter:kitFilter selector:@selector(logBaseEvent:) parameters:nil messageType:MPMessageTypeEvent userInfo:[[NSDictionary alloc] init]];
    
    [kitWrapperMock verifyWithDelay:5.0];
}

- (void)testAttemptToSetOptOutToKitTrue {
    MPKitContainer_PRIVATE *localKitContainer = [[MPKitContainer_PRIVATE alloc] init];
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    id kitWrapperMock = OCMProtocolMock(@protocol(MPKitProtocol));
    id kitRegisterMock = OCMPartialMock(kitRegister);
    OCMStub([kitRegisterMock wrapperInstance]).andReturn(kitWrapperMock);
    MPKitFilter *kitFilter = [kitContainer filter:kitRegisterMock forEvent:nil selector:@selector(setOptOut:)];
    
    [(id <MPKitProtocol>)[kitWrapperMock expect] setOptOut:YES];
    
    MPForwardQueueParameters *optOutParameters = [[MPForwardQueueParameters alloc] init];
    [optOutParameters addParameter:@(1)];
    
    [localKitContainer attemptToLogEventToKit:kitRegister kitFilter:kitFilter selector:@selector(setOptOut:) parameters:optOutParameters messageType:MPMessageTypeOptOut userInfo:@{@"state":@(1)}];
    
    [kitWrapperMock verifyWithDelay:5.0];
}

- (void)testAttemptToSetOptOutToKitFalse {
    MPKitContainer_PRIVATE *localKitContainer = [[MPKitContainer_PRIVATE alloc] init];
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    id kitWrapperMock = OCMProtocolMock(@protocol(MPKitProtocol));
    id kitRegisterMock = OCMPartialMock(kitRegister);
    OCMStub([kitRegisterMock wrapperInstance]).andReturn(kitWrapperMock);
    MPKitFilter *kitFilter = [kitContainer filter:kitRegisterMock forEvent:nil selector:@selector(setOptOut:)];
    
    [(id <MPKitProtocol>)[kitWrapperMock expect] setOptOut:FALSE];
    
    MPForwardQueueParameters *optOutParameters = [[MPForwardQueueParameters alloc] init];
    NSNumber *optOutStatus = @(0);
    [optOutParameters addParameter:optOutStatus];
    
    [localKitContainer attemptToLogEventToKit:kitRegister kitFilter:kitFilter selector:@selector(setOptOut:) parameters:optOutParameters messageType:MPMessageTypeOptOut userInfo:@{@"state":optOutStatus}];
    
    [kitWrapperMock verifyWithDelay:5.0];
}

- (void)testAttemptToLegacyOpenURLToKit {
    MPKitContainer_PRIVATE *localKitContainer = [[MPKitContainer_PRIVATE alloc] init];
    SEL selector = @selector(openURL:sourceApplication:annotation:);
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    id kitWrapperMock = OCMProtocolMock(@protocol(MPKitProtocol));
    id kitRegisterMock = OCMPartialMock(kitRegister);
    OCMStub([kitRegisterMock wrapperInstance]).andReturn(kitWrapperMock);
    MPKitFilter *kitFilter = [kitContainer filter:kitRegisterMock forBaseEvent:nil forSelector:selector];
    
    [(id <MPKitProtocol>)[kitWrapperMock expect] openURL:OCMOCK_ANY sourceApplication:OCMOCK_ANY annotation:OCMOCK_ANY];
    
    NSArray *parameters = @[
                            [NSURL URLWithString:@"https://www.example.com"],
                            @"test-source-application-1",
                            @{@"test-annotation-key-1":@"test-annotation-value-1"}
                            ];
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] initWithParameters:parameters];
    [localKitContainer attemptToLogEventToKit:kitRegisterMock kitFilter:kitFilter selector:selector parameters:queueParameters messageType:MPMessageTypeUnknown userInfo:nil];
    [kitWrapperMock verifyWithDelay:5.0];
}

- (void)testAttemptToOpenURLToKit {
    MPKitContainer_PRIVATE *localKitContainer = [[MPKitContainer_PRIVATE alloc] init];
    SEL selector = @selector(openURL:options:);
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    id kitWrapperMock = OCMProtocolMock(@protocol(MPKitProtocol));
    id kitRegisterMock = OCMPartialMock(kitRegister);
    OCMStub([kitRegisterMock wrapperInstance]).andReturn(kitWrapperMock);
    MPKitFilter *kitFilter = [kitContainer filter:kitRegisterMock forBaseEvent:nil forSelector:selector];
    
    [(id <MPKitProtocol>)[kitWrapperMock expect] openURL:OCMOCK_ANY options:OCMOCK_ANY];
    
    MPForwardQueueParameters *queueParameters = nil;
    NSArray *parameters = @[
                            [NSURL URLWithString:@"https://www.example.com"],
                            @{
                                UIApplicationOpenURLOptionsSourceApplicationKey:@"test-source-application-1",
                                UIApplicationOpenURLOptionsAnnotationKey:@{@"test-annotation-key-1": @"test-annotation-value-1"}
                                }
                            ];
    queueParameters = [[MPForwardQueueParameters alloc] initWithParameters:parameters];
    
    [localKitContainer attemptToLogEventToKit:kitRegisterMock kitFilter:kitFilter selector:selector parameters:queueParameters messageType:MPMessageTypeUnknown userInfo:nil];
    [kitWrapperMock verifyWithDelay:5.0];
}

- (void)testAttemptToContinueUserActivityToKit {
    MPKitContainer_PRIVATE *localKitContainer = [[MPKitContainer_PRIVATE alloc] init];
    SEL selector = @selector(continueUserActivity:restorationHandler:);
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    id kitWrapperMock = OCMProtocolMock(@protocol(MPKitProtocol));
    id kitRegisterMock = OCMPartialMock(kitRegister);
    OCMStub([kitRegisterMock wrapperInstance]).andReturn(kitWrapperMock);
    MPKitFilter *kitFilter = [kitContainer filter:kitRegisterMock forBaseEvent:nil forSelector:selector];
    
    [(id <MPKitProtocol>)[kitWrapperMock expect] continueUserActivity:OCMOCK_ANY restorationHandler:OCMOCK_ANY];
    
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:@"test-activity-type-1"];
    userActivity.webpageURL = [NSURL URLWithString:@"https://www.example.com"];
    void(^restorationHandler)(NSArray * restorableObjects) = ^(NSArray * restorableObjects) {
        
    };
    NSArray *parameters = @[
                            userActivity,
                            restorationHandler
                            ];
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] initWithParameters:parameters];
    [localKitContainer attemptToLogEventToKit:kitRegisterMock kitFilter:kitFilter selector:selector parameters:queueParameters messageType:MPMessageTypeUnknown userInfo:nil];
    [kitWrapperMock verifyWithDelay:5.0];
}

- (void)testAttemptToSurveyToKit {
    MPKitContainer_PRIVATE *localKitContainer = [[MPKitContainer_PRIVATE alloc] init];
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    NSURL *url = [NSURL URLWithString:@"mparticle://baseurl?query"];
    [queueParameters addParameter:url];
    NSDictionary *options = @{@"key":@"val"};
    [queueParameters addParameter:options];
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    id kitWrapperMock = OCMProtocolMock(@protocol(MPKitProtocol));
    id kitRegisterMock = OCMPartialMock(kitRegister);
    OCMStub([kitRegisterMock wrapperInstance]).andReturn(kitWrapperMock);
    
    [(id <MPKitProtocol>)[kitWrapperMock expect] surveyURLWithUserAttributes:OCMOCK_ANY];
    
    [localKitContainer attemptToLogEventToKit:kitRegister kitFilter:nil selector:@selector(surveyURLWithUserAttributes:) parameters:queueParameters messageType:MPMessageTypeUnknown userInfo:[[NSDictionary alloc] init]];
    
    [kitWrapperMock verifyWithDelay:5.0];
}

- (void)testAttemptToShouldDelayEventToKit {
    MPKitContainer_PRIVATE *localKitContainer = [[MPKitContainer_PRIVATE alloc] init];
    
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
    id kitWrapperMock = OCMProtocolMock(@protocol(MPKitProtocol));
    id kitRegisterMock = OCMPartialMock(kitRegister);
    OCMStub([kitRegisterMock wrapperInstance]).andReturn(kitWrapperMock);
    
    [(id <MPKitProtocol>)[kitWrapperMock expect] shouldDelayMParticleUpload];
    
    [localKitContainer attemptToLogEventToKit:kitRegister kitFilter:nil selector:@selector(shouldDelayMParticleUpload) parameters:nil messageType:MPMessageTypeUnknown userInfo:[[NSDictionary alloc] init]];
    
    [kitWrapperMock verifyWithDelay:5.0];
}

- (void)testRegisterSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKit = [[MPKitTestClassSideloaded alloc] init];
    id sideloadedKitMock = OCMPartialMock(sideloadedKit);
    [(id <MPKitProtocol>)[sideloadedKitMock expect] didFinishLaunchingWithConfiguration:OCMOCK_ANY];
    
    kitContainer.sideloadedKits = @[[[MPSideloadedKit alloc] initWithKitInstance:sideloadedKit]];
    [kitContainer initializeKits];
    
    [sideloadedKitMock verifyWithDelay:5.0];
}

- (void)testRegisterMultipleSideloadedKits {
    MPKitTestClassSideloaded *sideloadedKit1 = [[MPKitTestClassSideloaded alloc] init];
    id sideloadedKitMock1 = OCMPartialMock(sideloadedKit1);
    [(id <MPKitProtocol>)[sideloadedKitMock1 expect] didFinishLaunchingWithConfiguration:OCMOCK_ANY];
    
    MPKitTestClassSideloaded *sideloadedKit2 = [[MPKitTestClassSideloaded alloc] init];
    id sideloadedKitMock2 = OCMPartialMock(sideloadedKit2);
    [(id <MPKitProtocol>)[sideloadedKitMock2 expect] didFinishLaunchingWithConfiguration:OCMOCK_ANY];
    
    MPKitTestClassSideloaded *sideloadedKit3 = [[MPKitTestClassSideloaded alloc] init];
    id sideloadedKitMock3 = OCMPartialMock(sideloadedKit3);
    [(id <MPKitProtocol>)[sideloadedKitMock3 expect] didFinishLaunchingWithConfiguration:OCMOCK_ANY];
    
    kitContainer.sideloadedKits = @[[[MPSideloadedKit alloc] initWithKitInstance:sideloadedKit1],
                                    [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKit2],
                                    [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKit3]];
    [kitContainer initializeKits];
    
    [sideloadedKitMock1 verifyWithDelay:5.0];
    [sideloadedKitMock2 verifyWithDelay:5.0];
    [sideloadedKitMock3 verifyWithDelay:5.0];
}

- (void)testConfigureKits {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addEventTypeFilterWithEventType:MPEventTypeClick];
    
    MPKitTestClassSideloaded *sideloadedKitInstance2 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit2 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance2];
    [sideloadedKit2 addScreenNameFilterWithScreenName:@"test"];
    
    MPKitTestClassSideloaded *sideloadedKitInstance3 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit3 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance3];
    [sideloadedKit3 addUserIdentityFilterWithUserIdentity:MPUserIdentityGoogle];
    
    kitContainer.sideloadedKits = @[sideloadedKit1,
                                    sideloadedKit2,
                                    sideloadedKit3];
    [kitContainer initializeKits];
    
    MPKitConfiguration *config1 = kitContainer.kitConfigurations[@1000000000];
    MPKitConfiguration *config2 = kitContainer.kitConfigurations[@1000000001];
    MPKitConfiguration *config3 = kitContainer.kitConfigurations[@1000000002];
    
    XCTAssertEqualObjects(config1.filters, [sideloadedKit1 getKitFilters]);
    XCTAssertEqualObjects(config2.filters, [sideloadedKit2 getKitFilters]);
    XCTAssertEqualObjects(config3.filters, [sideloadedKit3 getKitFilters]);
}

- (void)testForwardEventToSideloadedKit {
    MPEvent *event = [[MPEvent alloc] initWithName:@"test event" type:MPEventTypeOther];

    MPKitTestClassSideloaded *sideloadedKit = [[MPKitTestClassSideloaded alloc] init];
    id sideloadedKitMock = OCMPartialMock(sideloadedKit);
    [(id <MPKitProtocol>)[sideloadedKitMock expect] logBaseEvent:OCMOCK_ANY];
    
    // Must be dispatched async to main thread due to OCMock weirdness
    // NOTE: Without this, it runs fine alone but when running the all tests
    //       it fails. Seems to possibly have something to do with other tests
    //       calling [kitContainer configureKits:nil] even though that
    //       shouldn't matter since the whole thing is reconstructed in setUp...
    dispatch_async(dispatch_get_main_queue(), ^{
        self->kitContainer.sideloadedKits = @[[[MPSideloadedKit alloc] initWithKitInstance:sideloadedKit]];
        [self->kitContainer initializeKits];
        
        [[MParticle sharedInstance] logEvent:event];
    });
    
    [sideloadedKitMock verifyWithDelay:10.0];
}

- (void)testAppInfoContainsSideloadKitsFlag {
    [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setSideloadedKitsCount:3];
    
    NSDictionary *dict = [[[MPApplication_PRIVATE alloc] init] dictionaryRepresentation];
    
    XCTAssertEqualObjects(dict[@"sideloaded_kits_count"], @3);
}

- (void)testFilterEventTypeForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addEventTypeFilterWithEventType:MPEventTypeOther];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dinosaur Run" type:MPEventTypeOther];
    event.duration = @2;
    event.customAttributes = @{@"speed":@25,
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";

    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 1000000000"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];

    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forEvent:event selector:@selector(logEvent:)];
    
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
    XCTAssertNil(kitFilter.filteredAttributes, @"Filtered attributes should have been nil.");
}

- (void)testFilterMessageTypeForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addMessageTypeFilterWithMessageTypeConstant:kMPMessageTypeStringEvent];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dinosaur Run" type:MPEventTypeOther];
    event.duration = @2;
    event.customAttributes = @{@"speed":@25,
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 1000000000"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];
    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forEvent:event selector:@selector(logEvent:)];
    
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
    XCTAssertNil(kitFilter.filteredAttributes, @"Filtered attributes should have been nil.");
}

- (void)testFilterEventTypeNavigationForSideloadedKitForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addEventTypeFilterWithEventType:MPEventTypeNavigation];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Dinosaur Run" type:MPEventTypeNavigation];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 1000000000"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];
    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forEvent:event selector:@selector(logScreen:)];
    
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertFalse(kitFilter.shouldFilter, @"Event type filtering should not be taking place for screen events.");
    
    kitFilter = [kitContainer filter:registeredKit forEvent:event selector:@selector(logEvent:)];
    
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertTrue(kitFilter.shouldFilter, @"Non-screen event should have been filtered by event type");
}

- (void)testFilterEventNameForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addEventNameFilterWithEventType:MPEventTypeTransaction eventName:@"Purchase"];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Purchase" type:MPEventTypeTransaction];
    event.duration = @2;
    event.customAttributes = @{@"Product":@"Running shoes",
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 1000000000"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];
    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forEvent:event selector:@selector(logEvent:)];
    
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
}

- (void)testFilterEventNameAndAttributesForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addEventAttributeFilterWithEventType:(MPEventType)MPEventTypeTransaction eventName:@"Purchase" customAttributeKey:@"Product"];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];
    
    MPEvent *event = [[MPEvent alloc] initWithName:@"Purchase" type:MPEventTypeTransaction];
    event.duration = @2;
    event.customAttributes = @{@"Product":@"Running shoes",
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 1000000000"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];
    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forEvent:event selector:@selector(logEvent:)];
    
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertEqual(kitFilter.filteredAttributes.count, 1, @"There should be only one attribute in the list.");
    XCTAssertEqualObjects(kitFilter.filteredAttributes[@"modality"], @"sprinting", @"Not filtering the correct attribute.");
}

- (void)testFilterForSelectorForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addMessageTypeFilterWithMessageTypeConstant:kMPMessageTypeStringScreenView];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 1000000000"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];

    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forBaseEvent:(MPBaseEvent *)nil forSelector:@selector(logScreen:)];
    XCTAssertNotNil(kitFilter, @"Should not have been nil.");
}

- (void)testFilterForUserAttributeForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addUserAttributeFilterWithUserAttributeKey:@"Shoe Size"];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 1000000000"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];

    NSString *key = @"Shoe Size";
    NSString *value = @"11";
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forUserAttributeKey:key value:value];
    XCTAssertNotNil(kitFilter);
    XCTAssertTrue(kitFilter.shouldFilter);
    
    key = @"teeth";
    value = @"sharp";
    kitFilter = [kitContainer filter:registeredKit forUserAttributeKey:key value:value];
    XCTAssertNil(kitFilter);
    
    key = nil;
    kitFilter = [kitContainer filter:registeredKit forUserAttributeKey:key value:value];
    XCTAssertNil(kitFilter);
    
    key = @"Shoe Size";
    NSMutableArray *values = [@[@"9", @"10", @"11"] mutableCopy];
    kitFilter = [kitContainer filter:registeredKit forUserAttributeKey:key value:values];
    XCTAssertNotNil(kitFilter);
    
    key = @"Dinosaur";
    values = [@[@"T-Rex", @"Short arms", @"Omnivore"] mutableCopy];

    [kitContainer forwardSDKCall:@selector(setUserAttribute:values:)
                userAttributeKey:key
                           value:values
                      kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPKitConfiguration *kitConfig) {
        XCTAssertNotNil(kit);
        
        MPKitExecStatus *execStatus = [kit setUserAttribute:key values:values];
        XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess);
        
    }];
}

- (void)testNotForwardUserAttributeListForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addUserAttributeFilterWithUserAttributeKey:@"Shoe Size"];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];
    
    NSString *key = @"Shoe Size";
    NSMutableArray *values = [@[@"9", @"10", @"11"] mutableCopy];

    [kitContainer forwardSDKCall:@selector(setUserAttribute:values:)
                userAttributeKey:key
                           value:values
                      kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPKitConfiguration *kitConfig) {
                          NSAssert(false, @"This line should never be executed.");
                      }];
}

- (void)testFilterForUserAttributesForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addUserAttributeFilterWithUserAttributeKey:@"$Age"];
    [sideloadedKit1 addUserAttributeFilterWithUserAttributeKey:@"member_since"];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];

    
    NSDictionary *userAttributes = @{@"$Age":@24,
                                     @"member_since":[NSDate date],
                                     @"arms":@"short",
                                     @"growl":@"loud",
                                     @"teeth":@"sharp"};
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 1000000000"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];

    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forUserAttributes:userAttributes];
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter user attribute.");
    XCTAssertEqual(kitFilter.filteredAttributes[@"arms"], @"short", @"User attribute should not have been filtered.");
    XCTAssertEqual(kitFilter.filteredAttributes[@"growl"], @"loud", @"User attribute should not have been filtered.");
    XCTAssertEqual(kitFilter.filteredAttributes[@"teeth"], @"sharp", @"User attribute should not have been filtered.");
    XCTAssertNil(kitFilter.filteredAttributes[@"$Age"], @"User attribute should have been filtered.");
    XCTAssertNil(kitFilter.filteredAttributes[@"member_since"], @"User attribute should have been filtered.");

    userAttributes = @{@"$Age":@24,
                       @"member_since":[NSDate date]
                       };
    
    kitFilter = [kitContainer filter:registeredKit forUserAttributes:userAttributes];
    XCTAssertNil(kitFilter, @"Filter should have been nil.");
    
    kitFilter = [kitContainer filter:registeredKit forUserAttributes:nil];
    XCTAssertNil(kitFilter, @"Filter should have been nil.");
}

- (void)testFilterForUserIdentityForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addUserIdentityFilterWithUserIdentity:MPUserIdentityEmail];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 1000000000"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];

    NSString *identityString = @"earl.sinclair@shortarmsdinosaurs.com";
    MPUserIdentity identityType = MPUserIdentityEmail;
    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forUserIdentityKey:identityString identityType:identityType];
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter user identity.");
    
    identityType = MPUserIdentityCustomerId;
    kitFilter = [kitContainer filter:registeredKit forUserIdentityKey:identityString identityType:identityType];
    XCTAssertNil(kitFilter, @"Filter should have been nil.");
}

- (void)testFilterCommerceEvent_EventTypeForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addEventTypeFilterWithEventType:MPEventTypeAddToCart];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    id registeredKit = [registeredKits anyObject];

    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    product[@"key1"] = @"val1";
    product[@"key_number"] = @"1";
    product[@"key_bool"] = @"YES";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertEqual(commerceEvent.products.count, 1, @"Incorrect product count.");
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent.customAttributes = @{@"key_string": @"val_string", @"key_number": @"3.14"};
    
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Doctor";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @18;
    transactionAttributes.transactionId = @"42";
    commerceEvent.transactionAttributes = transactionAttributes;
    XCTAssertNotNil(commerceEvent.transactionAttributes, @"Transaction attributes should not have been nil.");

    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forCommerceEvent:commerceEvent];

    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
}

- (void)testFilterCommerceEvent_EntityTypeForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addCommerceEventEntityTypeFilterWithCommerceEventKind:MPCommerceEventKindProduct];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    id registeredKit = [registeredKits anyObject];

    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    product[@"key1"] = @"val1";
    product[@"key_number"] = @"1";
    product[@"key_bool"] = @"YES";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertEqual(commerceEvent.products.count, 1, @"Incorrect product count.");
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent.customAttributes = @{@"key_string": @"val_string", @"key_number": @"3.14"};
    
    product = [[MPProduct alloc] initWithName:@"Tardis" sku:@"trds" quantity:@1 price:@7.89];
    product.brand = @"Gallifrey Tardis";
    product.category = @"Time Machine";
    product.position = 2;
    product.variant = @"Police Box";
    
    [commerceEvent addProduct:product];
    XCTAssertEqual(commerceEvent.products.count, 2, @"Incorrect product count.");
    
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Doctor";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @18;
    transactionAttributes.transactionId = @"42";
    commerceEvent.transactionAttributes = transactionAttributes;
    XCTAssertNotNil(commerceEvent.transactionAttributes, @"Transaction attributes should not have been nil.");

    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forCommerceEvent:commerceEvent];

    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
}

- (void)testFilterCommerceEvent_OtherForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addCommerceEventAppFamilyAttributeFilterWithAttributeKey:@"key1"];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    id registeredKit = [registeredKits anyObject];
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    product[@"key1"] = @"val1";
    product[@"key_number"] = @"1";
    product[@"key_bool"] = @"YES";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertEqual(commerceEvent.products.count, 1, @"Incorrect product count.");
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent.customAttributes = @{@"key_string": @"val_string", @"key_number": @"3.14"};
    
    product = [[MPProduct alloc] initWithName:@"Tardis" sku:@"trds" quantity:@1 price:@7.89];
    product.brand = @"Gallifrey Tardis";
    product.category = @"Time Machine";
    product.position = 2;
    product.variant = @"Police Box";
    
    [commerceEvent addProduct:product];
    XCTAssertEqual(commerceEvent.products.count, 2, @"Incorrect product count.");
    
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Doctor";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @18;
    transactionAttributes.transactionId = @"42";
    commerceEvent.transactionAttributes = transactionAttributes;
    XCTAssertNotNil(commerceEvent.transactionAttributes, @"Transaction attributes should not have been nil.");
    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forCommerceEvent:commerceEvent];

    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
}

- (void)testFilterCommerceEvent_TransactionAttributesForSideloadedKit {
    MPKitTestClassSideloaded *sideloadedKitInstance1 = [[MPKitTestClassSideloaded alloc] init];
    MPSideloadedKit *sideloadedKit1 = [[MPSideloadedKit alloc] initWithKitInstance:sideloadedKitInstance1];
    [sideloadedKit1 addCommerceEventAttributeFilterWithEventType:MPEventTypeAddToCart eventAttributeKey:@"Affiliation"];
    [sideloadedKit1 addCommerceEventAttributeFilterWithEventType:MPEventTypeAddToCart eventAttributeKey:@"Total Amount"];
    kitContainer.sideloadedKits = @[sideloadedKit1];
    [kitContainer initializeKits];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 1000000000"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"DeLorean" sku:@"OutATime" quantity:@1 price:@4.32];
    product.brand = @"DLC";
    product.category = @"Time Machine";
    product.couponCode = @"88mph";
    product.position = 1;
    product.variant = @"It depends";
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent);
    XCTAssertEqual(commerceEvent.products.count, 1);
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    
    product = [[MPProduct alloc] initWithName:@"Tardis" sku:@"trds" quantity:@1 price:@7.89];
    product.brand = @"Gallifrey Tardis";
    product.category = @"Time Machine";
    product.position = 2;
    product.variant = @"Police Box";
    
    [commerceEvent addProduct:product];
    XCTAssertEqual(commerceEvent.products.count, 2);
    
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Doctor";
    transactionAttributes.shipping = @3;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @18;
    transactionAttributes.transactionId = @"42";
    commerceEvent.transactionAttributes = transactionAttributes;
    XCTAssertNotNil(commerceEvent.transactionAttributes);
    
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forCommerceEvent:commerceEvent];
    
    XCTAssertNotNil(kitFilter);
    XCTAssertNotNil(kitFilter.forwardCommerceEvent);
    XCTAssertNotNil(kitFilter.forwardCommerceEvent.transactionAttributes);
    XCTAssertNil(kitFilter.forwardCommerceEvent.transactionAttributes.affiliation);
    XCTAssertNil(kitFilter.forwardCommerceEvent.transactionAttributes.revenue);
    XCTAssertEqualObjects(kitFilter.forwardCommerceEvent.transactionAttributes.shipping, @3);
    XCTAssertEqualObjects(kitFilter.forwardCommerceEvent.transactionAttributes.tax, @4.56);
    XCTAssertEqualObjects(kitFilter.forwardCommerceEvent.transactionAttributes.transactionId, @"42");
}

#endif

@end

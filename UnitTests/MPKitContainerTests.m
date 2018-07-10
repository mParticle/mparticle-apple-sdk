#import <XCTest/XCTest.h>
#import "MPKitContainer.h"
#import "MPIConstants.h"
#import "MPForwardQueueItem.h"
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
#import "MPIUserDefaults.h"
#import "MPForwardQueueParameters.h"
#import "MPResponseConfig.h"
#import "MPConsentKitFilter.h"
#import "MPPersistenceController.h"
#import "MPKitInstanceValidator.h"
#import "MPBaseTestCase.h"

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong) MPKitContainer *kitContainer;

@end

@interface MPKitInstanceValidator(BackendControllerTests)
+ (void)includeUnitTestKits:(NSArray<NSNumber *> *)kitCodes;
@end

#pragma mark - MPKitContainer category for unit tests
@interface MPKitContainer(Tests)

@property (nonatomic, strong) NSMutableArray<MPForwardQueueItem *> *forwardQueue;
@property (nonatomic, unsafe_unretained) BOOL kitsInitialized;
@property (nonatomic, readonly) NSMutableDictionary<NSNumber *, MPKitConfiguration *> *kitConfigurations;

- (BOOL)isDisabledByBracketConfiguration:(NSDictionary *)bracketConfiguration;
- (BOOL)isDisabledByConsentKitFilter:(MPConsentKitFilter *)kitFilter;
- (void)replayQueuedItems;
- (NSDictionary *)validateAndTransformToSafeConfiguration:(NSDictionary *)configuration;
- (id)transformValue:(NSString *)originalValue dataType:(MPDataType)dataType;
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification;
- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification;
- (nullable NSString *)nameForKitCode:(nonnull NSNumber *)kitCode;
- (id<MPKitProtocol>)startKit:(NSNumber *)kitCode configuration:(MPKitConfiguration *)kitConfiguration;
- (void)flushSerializedKits;
- (NSDictionary *)methodMessageTypeMapping;
- (void)filter:(id<MPExtensionKitProtocol>)kitRegister forEvent:(MPEvent *const)event selector:(SEL)selector completionHandler:(void (^)(MPKitFilter *kitFilter, BOOL finished))completionHandler;
- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forSelector:(SEL)selector;
- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forUserAttributeKey:(NSString *)key value:(id)value;
- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forUserAttributes:(NSDictionary *)userAttributes;
- (MPKitFilter *)filter:(id<MPExtensionKitProtocol>)kitRegister forUserIdentityKey:(NSString *)key identityType:(MPUserIdentity)identityType;
- (void)filter:(id<MPExtensionKitProtocol>)kitRegister forCommerceEvent:(MPCommerceEvent *const)commerceEvent completionHandler:(void (^)(MPKitFilter *kitFilter, BOOL finished))completionHandler;

@end


#pragma mark - MPKitContainerTests
@interface MPKitContainerTests : MPBaseTestCase {
    MPKitContainer *kitContainer;
}

@end


@implementation MPKitContainerTests

- (void)setUp {
    [super setUp];
    
    [MParticle sharedInstance].stateMachine = [[MPStateMachine alloc] init];
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    stateMachine.apiKey = @"unit_test_app_key";
    stateMachine.secret = @"unit_test_secret";
    
    [MParticle sharedInstance].kitContainer = [[MPKitContainer alloc] init];
    kitContainer = [MParticle sharedInstance].kitContainer;

    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
    if (!registeredKits) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
        [MPKitContainer registerKit:kitRegister];
        
        kitRegister = [[MPKitRegister alloc] initWithName:@"KitSecondTest" className:@"MPKitSecondTestClass"];
        [MPKitContainer registerKit:kitRegister];
        
        kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
        [MPKitContainer registerKit:kitRegister];
        
        NSDictionary *configuration = @{
                                        @"id":@42,
                                        @"as":@{
                                                @"appId":@"MyAppId"
                                                }
                                        };
        
        MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
        [MPKitInstanceValidator includeUnitTestKits:@[@42]];
        [kitContainer startKit:@42 configuration:kitConfiguration];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 92"];
    id kitAppsFlyer = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];
    if (!kitAppsFlyer) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
        [MPKitContainer registerKit:kitRegister];
    }
}

- (void)tearDown {
    kitContainer = nil;

    [super tearDown];
}

- (void)setUserAttributesAndIdentities {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
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
    
    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];
    
    [MPResponseConfig save:responseConfig eTag:eTag];
        
    NSArray *directoryContents = [[MPIUserDefaults standardUserDefaults] getKitConfigurations];
    for (NSDictionary *kitConfigurationDictionary in directoryContents) {
        MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:kitConfigurationDictionary];
        if ([[kitConfiguration kitCode] isEqual:@(42)]){
            XCTAssertEqualObjects(@"cool app key", kitConfiguration.configuration[@"appId"]);
        }
        
        if ([[kitConfiguration kitCode] isEqual:@(312)]){
            
            XCTAssertEqualObjects(@"cool app key 2", kitConfiguration.configuration[@"appId"]);
        }
    }    
}

- (void)testRemoveKitConfiguration {
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
        
        MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];
        
        [MPResponseConfig save:responseConfig eTag:eTag];
        
        dispatch_sync(dispatch_get_main_queue(), ^{ });
        XCTAssertEqual(@"cool app key", [self->kitContainer.kitConfigurations objectForKey:@(42)].configuration[@"appId"]);
        
        NSArray *directoryContents = [[MPIUserDefaults standardUserDefaults] getKitConfigurations];
        for (NSDictionary *kitConfigurationDictionary in directoryContents) {
            MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:kitConfigurationDictionary];
            if ([[kitConfiguration kitCode] isEqual:@(42)]){
                XCTAssertEqualObjects(@"cool app key", kitConfiguration.configuration[@"appId"]);
            }
            
            if ([[kitConfiguration kitCode] isEqual:@(312)]){
                
                XCTAssertEqualObjects(@"cool app key 2", kitConfiguration.configuration[@"appId"]);
            }
        }
        
        kitConfigs = @[configuration1];

        configuration = @{kMPRemoteConfigKitsKey:kitConfigs,
                          kMPRemoteConfigCustomModuleSettingsKey:[NSNull null],
                          kMPRemoteConfigRampKey:@100,
                          kMPRemoteConfigTriggerKey:[NSNull null],
                          kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                          kMPRemoteConfigSessionTimeoutKey:@112};
        
        responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];
        
        [MPResponseConfig save:responseConfig eTag:eTag];
        
        XCTAssertEqual(@"cool app key", [self->kitContainer.kitConfigurations objectForKey:@(42)].configuration[@"appId"]);
        
        directoryContents = [[MPIUserDefaults standardUserDefaults] getKitConfigurations];
        for (NSDictionary *kitConfigurationDictionary in directoryContents) {
            MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:kitConfigurationDictionary];
            if ([[kitConfiguration kitCode] isEqual:@(42)]){
                XCTAssertEqualObjects(@"cool app key", kitConfiguration.configuration[@"appId"]);
            }
            
            XCTAssertFalse([[kitConfiguration kitCode] isEqual:@(312)]);
        }
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testIsDisabledByBracketConfiguration {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    userDefaults[@"mpid"] = @2;
    
    NSDictionary *bracketConfig = @{@"hi":@(0),@"lo":@(0)};
    XCTAssertTrue([kitContainer isDisabledByBracketConfiguration:bracketConfig]);
    
    bracketConfig = @{@"hi":@(100),@"lo":@(0)};
    XCTAssertFalse([kitContainer isDisabledByBracketConfiguration:bracketConfig]);    
}

- (void)testConfigurationValidation {
    NSDictionary *configuration = @{@"appKey":@"3141592"};
    
    NSDictionary *validatedConfiguration = [kitContainer validateAndTransformToSafeConfiguration:configuration];
    XCTAssertEqual(configuration, validatedConfiguration, @"Should have been equal.");
    
    configuration = @{@"appKey":@"3141592",
                      @"NullKey":[NSNull null]};
    validatedConfiguration = [kitContainer validateAndTransformToSafeConfiguration:configuration];
    XCTAssertNil(validatedConfiguration[@"NullKey"], @"Should have been nil.");
    XCTAssertEqual(validatedConfiguration.count, 1, @"Incorrect count.");
    
    configuration = @{@"NullKey":[NSNull null]};
    validatedConfiguration = [kitContainer validateAndTransformToSafeConfiguration:configuration];
    XCTAssertNil(validatedConfiguration, @"Should have been nil.");
    
    configuration = @{};
    validatedConfiguration = [kitContainer validateAndTransformToSafeConfiguration:configuration];
    XCTAssertNil(validatedConfiguration, @"Should have been nil.");
    
    configuration = nil;
    validatedConfiguration = [kitContainer validateAndTransformToSafeConfiguration:configuration];
    XCTAssertNil(validatedConfiguration, @"Should have been nil.");
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
    
    void (^kitHandler)(id<MPKitProtocol>, MPKitFilter *, MPKitExecStatus **) = ^(id<MPKitProtocol> kit, MPKitFilter *kitFilter, MPKitExecStatus **execStatus) {
    };

    [kitContainer forwardCommerceEventCall:commerceEvent kitHandler:kitHandler];
    MPForwardQueueItem *forwardQueueItem = [kitContainer.forwardQueue firstObject];
    XCTAssertEqual(kitContainer.forwardQueue.count, 1, @"Should have been equal.");
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeEcommerce, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.commerceEvent, commerceEvent, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.commerceEventCompletionHandler, kitHandler, @"Should have been equal.");

    kitContainer.kitsInitialized = YES;
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
}

- (void)testForwardQueueEvent {
    XCTAssertNotNil(kitContainer.forwardQueue, @"Should not have been nil.");
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
    
    kitContainer.kitsInitialized = NO;

    SEL selector = @selector(logEvent:);
    MPEvent *event = [[MPEvent alloc] initWithName:@"Time travel" type:MPEventTypeNavigation];
    
    void (^kitHandler)(id<MPKitProtocol>, MPEvent *, MPKitExecStatus **) = ^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
    };
    
    [kitContainer forwardSDKCall:selector event:event messageType:MPMessageTypeEvent userInfo:nil kitHandler:kitHandler];
    MPForwardQueueItem *forwardQueueItem = [kitContainer.forwardQueue firstObject];
    XCTAssertEqual(kitContainer.forwardQueue.count, 1, @"Should have been equal.");
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeEvent, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.event, event, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.eventCompletionHandler, kitHandler, @"Should have been equal.");
    
    kitContainer.kitsInitialized = YES;
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
}

- (void)testForwardQueueInvalid {
    XCTAssertNotNil(kitContainer.forwardQueue, @"Should not have been nil.");
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
    
    kitContainer.kitsInitialized = NO;
    
    SEL selector = @selector(logEvent:);
    MPEvent *event = nil;
    void (^kitHandler)(id<MPKitProtocol>, MPEvent *, MPKitExecStatus **) = nil;
    
    [kitContainer forwardSDKCall:selector event:event messageType:MPMessageTypeEvent userInfo:nil kitHandler:kitHandler];
    MPForwardQueueItem *forwardQueueItem = [kitContainer.forwardQueue firstObject];
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
    XCTAssertNil(forwardQueueItem, @"Should have been nil.");
}

- (void)testForwardQueueItem {
    XCTAssertNotNil(kitContainer.forwardQueue, @"Should not have been nil.");
    XCTAssertEqual(kitContainer.forwardQueue.count, 0, @"Should have been equal.");
    
    kitContainer.kitsInitialized = NO;
    
    void (^kitHandler)(id<MPKitProtocol>, MPForwardQueueParameters *, MPKitExecStatus **) = ^(id<MPKitProtocol> kit, MPForwardQueueParameters *forwardParameters, MPKitExecStatus **execStatus) {
    };
    
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] init];
    NSURL *url = [NSURL URLWithString:@"mparticle://baseurl?query"];
    [queueParameters addParameter:url];
    NSDictionary *options = @{@"key":@"val"};
    [queueParameters addParameter:options];
    
    [kitContainer forwardSDKCall:@selector(openURL:options:)
                      parameters:queueParameters
                     messageType:MPMessageTypeUnknown
                      kitHandler:kitHandler];
    
    MPForwardQueueItem *forwardQueueItem = [kitContainer.forwardQueue firstObject];
    XCTAssertEqual(kitContainer.forwardQueue.count, 1);
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeGeneralPurpose);
    XCTAssertEqualObjects(forwardQueueItem.queueParameters, queueParameters);
    XCTAssertEqualObjects(forwardQueueItem.generalPurposeCompletionHandler, kitHandler);
    
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
    event.info = @{@"speed":@25,
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
    id registeredKit = [[registeredKits objectsPassingTest:^BOOL(id<MPExtensionProtocol>  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(MPExtensionKitProtocol)]) {
            id<MPExtensionKitProtocol> kitExtension = (id<MPExtensionKitProtocol>)obj;
            if (kitExtension.code.intValue == 42) {
                return YES;
            }
        }
        return NO;
    }] anyObject];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Filtering event type"];
    [kitContainer filter:registeredKit
                forEvent:event
                selector:@selector(logEvent:)
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
           XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
           XCTAssertNil(kitFilter.filteredAttributes, @"Filtered attributes should have been nil.");
           [expectation fulfill];
       }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
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
    event.info = @{@"speed":@25,
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
    id registeredKit = [[registeredKits objectsPassingTest:^BOOL(id<MPExtensionProtocol>  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(MPExtensionKitProtocol)]) {
            id<MPExtensionKitProtocol> kitExtension = (id<MPExtensionKitProtocol>)obj;
            if (kitExtension.code.intValue == 42) {
                return YES;
            }
        }
        return NO;
    }] anyObject];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Filtering message type"];
    [kitContainer filter:registeredKit
                forEvent:event
                selector:@selector(logEvent:)
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
           XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
           XCTAssertNil(kitFilter.filteredAttributes, @"Filtered attributes should have been nil.");
           [expectation fulfill];
       }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
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
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
    id registeredKit = [[registeredKits objectsPassingTest:^BOOL(id<MPExtensionProtocol>  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(MPExtensionKitProtocol)]) {
            id<MPExtensionKitProtocol> kitExtension = (id<MPExtensionKitProtocol>)obj;
            if (kitExtension.code.intValue == 42) {
                return YES;
            }
        }
        return NO;
    }] anyObject];
    
    XCTestExpectation *notFilteringExpectation = [self expectationWithDescription:@"Not filtering screen events by event type"];
    [kitContainer filter:registeredKit
                forEvent:event
                selector:@selector(logScreen:)
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
           XCTAssertFalse(kitFilter.shouldFilter, @"Event type filtering should not be taking place for screen events.");
           [notFilteringExpectation fulfill];
       }];
    
    XCTestExpectation *filteringExpectation = [self expectationWithDescription:@"Filtering non-screen events by event type"];
    [kitContainer filter:registeredKit
                forEvent:event
                selector:@selector(logEvent:)
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
           XCTAssertTrue(kitFilter.shouldFilter, @"Non-screen event should have been filtered by event type");
           [filteringExpectation fulfill];
       }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
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
    event.info = @{@"Product":@"Running shoes",
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
    id registeredKit = [[registeredKits objectsPassingTest:^BOOL(id<MPExtensionProtocol>  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(MPExtensionKitProtocol)]) {
            id<MPExtensionKitProtocol> kitExtension = (id<MPExtensionKitProtocol>)obj;
            if (kitExtension.code.intValue == 42) {
                return YES;
            }
        }
        return NO;
    }] anyObject];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Filtering event name and attributes"];
    [kitContainer filter:registeredKit
                forEvent:event
                selector:@selector(logEvent:)
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
           XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
           [expectation1 fulfill];
       }];
    
    configurations = @[
                       @{
                           @"id":@(42),
                           @"as":@{
                                   @"secretKey":@"MySecretKey",
                                   @"sendTransactionData":@"true"
                                   },
                           @"hs":@{
                                   @"ea":@{@"1152562650":@0}
                                   }
                           }
                       ];
    
    [kitContainer configureKits:nil];
    [kitContainer configureKits:configurations];
    
    event = [[MPEvent alloc] initWithName:@"Purchase" type:MPEventTypeTransaction];
    event.duration = @2;
    event.info = @{@"Product":@"Running shoes",
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Filtering event name and attributes"];
    [kitContainer filter:registeredKit
                forEvent:event
                selector:@selector(logEvent:)
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
           XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
           XCTAssertEqual(kitFilter.filteredAttributes.count, 1, @"There should be only one attribute in the list.");
           XCTAssertEqualObjects(kitFilter.filteredAttributes[@"modality"], @"sprinting", @"Not filtering the correct attribute.");
           [expectation2 fulfill];
       }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
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
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"code == 42"];
    id registeredKit = [[registeredKits filteredSetUsingPredicate:predicate] anyObject];

    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forSelector:@selector(logScreen:)];
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
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
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

        [self->kitContainer forwardSDKCall:@selector(setUserAttribute:values:)
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
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
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
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
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
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
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
    commerceEvent[@"key_string"] = @"val_string";
    commerceEvent[@"key_number"] = @"3.14";
    
    MPTransactionAttributes *transactionAttributes = [[MPTransactionAttributes alloc] init];
    transactionAttributes.affiliation = @"Doctor";
    transactionAttributes.shipping = @1.23;
    transactionAttributes.tax = @4.56;
    transactionAttributes.revenue = @18;
    transactionAttributes.transactionId = @"42";
    commerceEvent.transactionAttributes = transactionAttributes;
    XCTAssertNotNil(commerceEvent.transactionAttributes, @"Transaction attributes should not have been nil.");

    [kitContainer filter:registeredKit
        forCommerceEvent:commerceEvent
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
       }];
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
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
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
    commerceEvent[@"key_string"] = @"val_string";
    commerceEvent[@"key_number"] = @"3.14";
    
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

    [kitContainer filter:registeredKit
        forCommerceEvent:commerceEvent
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
       }];
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
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
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
    commerceEvent[@"key_string"] = @"val_string";
    commerceEvent[@"key_number"] = @"3.14";
    
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
    
    [kitContainer filter:registeredKit
        forCommerceEvent:commerceEvent
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
       }];
}

- (void)testFilterCommerceEvent_TransactionAttributes {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Transaction attributes"];
    
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
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
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
    
    [kitContainer filter:registeredKit
        forCommerceEvent:commerceEvent
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter);
           XCTAssertNotNil(kitFilter.forwardCommerceEvent);
           XCTAssertNotNil(kitFilter.forwardCommerceEvent.transactionAttributes);
           XCTAssertNil(kitFilter.forwardCommerceEvent.transactionAttributes.affiliation);
           XCTAssertNil(kitFilter.forwardCommerceEvent.transactionAttributes.revenue);
           XCTAssertEqualObjects(kitFilter.forwardCommerceEvent.transactionAttributes.shipping, @3);
           XCTAssertEqualObjects(kitFilter.forwardCommerceEvent.transactionAttributes.tax, @4.56);
           XCTAssertEqualObjects(kitFilter.forwardCommerceEvent.transactionAttributes.transactionId, @"42");
           
           [expectation fulfill];
       }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
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
                                                          \"attribute_values\":[\"Y\"] \
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
    event.info = @{@"plan":@"premium", @"plan_color":@"gold", @"boolean":@YES};
    
    [self->kitContainer forwardSDKCall:@selector(logEvent:)
                           event:event
                     messageType:MPMessageTypeEvent
                        userInfo:nil
                      kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPEvent * _Nullable forwardEvent, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                          if ([[[kit class] kitCode] isEqualToNumber:@(MPKitInstanceAppsFlyer)]) {
                              XCTAssertNotNil(forwardEvent);
                              XCTAssertEqualObjects(forwardEvent.name, @"new_premium_subscriber");
                              XCTAssertNotNil(forwardEvent.info);
                              XCTAssertEqual(forwardEvent.info.count, 3);
                          }
                      }];
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

    [self->kitContainer forwardCommerceEventCall:commerceEvent
                                kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPKitFilter * _Nonnull kitFilter, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                                    if ([[[kit class] kitCode] isEqualToNumber:@(MPKitInstanceAppsFlyer)]) {
                                        MPEvent *event = kitFilter.forwardEvent;
                                        XCTAssertEqualObjects(event.info[@"af_quantity"], @"1");
                                        XCTAssertEqualObjects(event.info[@"af_content_id"], @"OutATime");
                                        XCTAssertEqualObjects(event.info[@"af_content_type"], @"Time Machine");
                                        XCTAssertEqualObjects(event.name, @"af_add_to_cart");
                                    }
                                }];
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
    event.info = @{@"plan_id":@"3", @"outcome":@"new_subscription"};
    __block NSMutableArray<NSString *> *foundEventNames = [NSMutableArray arrayWithCapacity:2];

        [self->kitContainer forwardSDKCall:@selector(logEvent:)
                               event:event
                         messageType:MPMessageTypeEvent
                            userInfo:nil
                          kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPEvent * _Nullable forwardEvent, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                              if ([[[kit class] kitCode] isEqualToNumber:@(MPKitInstanceAppsFlyer)]) {
                                  XCTAssertNotNil(forwardEvent);
                                  XCTAssertNotNil(forwardEvent.info);
                                  XCTAssertEqual(forwardEvent.info.count, 2);
                                  
                                  [foundEventNames addObject:forwardEvent.name];
                                  
                                  if (foundEventNames.count == 2) {
                                      XCTAssertTrue([foundEventNames containsObject:@"X_NEW_SUBSCRIPTION"]);
                                      XCTAssertTrue([foundEventNames containsObject:@"X_NEW_NOAH_SUBSCRIPTION"]);
                                  }
                              }}];
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
    event.info = @{@"plan_id":@"3", @"outcome":@"new_subscription", @"gender":@"female"};
    
    [self->kitContainer forwardSDKCall:@selector(logEvent:)
                           event:event
                     messageType:MPMessageTypeEvent
                        userInfo:nil
                      kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPEvent * _Nullable forwardEvent, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                          if ([[[kit class] kitCode] isEqualToNumber:@(MPKitInstanceAppsFlyer)]) {
                              XCTAssertNotNil(forwardEvent);
                              XCTAssertNotEqualObjects(forwardEvent.name, @"X_NEW_MALE_SUBSCRIPTION");
                              XCTAssertEqualObjects(forwardEvent.name, @"SUBSCRIPTION_END");
                          }
                      }];
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
    event.info = @{@"outcome":@"not_new_subscription"};
    
        [self->kitContainer forwardSDKCall:@selector(logEvent:)
                               event:event
                         messageType:MPMessageTypeEvent
                            userInfo:nil
                          kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPEvent * _Nullable forwardEvent, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                              if ([[[kit class] kitCode] isEqualToNumber:@(MPKitInstanceAppsFlyer)]) {
                                  XCTAssertNotNil(forwardEvent);
                                  XCTAssertNotEqualObjects(forwardEvent.name, @"X_NEW_SUBSCRIPTION");
                                  XCTAssertEqualObjects(forwardEvent.name, @"SUBSCRIPTION_END");
                              }
                          }];
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
    event.info = @{@"plan":@"premium"};
    
        [self->kitContainer forwardSDKCall:@selector(logEvent:)
                               event:event
                         messageType:MPMessageTypeEvent
                            userInfo:nil
                          kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPEvent * _Nullable forwardEvent, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                              if ([[[kit class] kitCode] isEqualToNumber:@(MPKitInstanceAppsFlyer)]) {
                                  XCTAssertNotNil(forwardEvent);
                                  XCTAssertEqualObjects(forwardEvent.name, @"af_add_payment_info");
                                  XCTAssertNotNil(forwardEvent.info);
                                  XCTAssertEqual(forwardEvent.info.count, 2);
                                  XCTAssertEqualObjects(forwardEvent.info[@"af_success"], @"True");
                              }
                          }];
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
    event.info = @{@"test_description":@"this is a description"};
    
        [self->kitContainer forwardSDKCall:@selector(logEvent:)
                               event:event
                         messageType:MPMessageTypeEvent
                            userInfo:nil
                          kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPEvent * _Nullable forwardEvent, MPKitExecStatus *__autoreleasing _Nonnull * _Nonnull execStatus) {
                              if ([[[kit class] kitCode] isEqualToNumber:@(MPKitInstanceAppsFlyer)]) {
                                  XCTAssertNotNil(forwardEvent);
                                  XCTAssertEqualObjects(forwardEvent.name, @"af_achievement_unlocked");
                                  XCTAssertNotNil(forwardEvent.info);
                                  XCTAssertEqual(forwardEvent.info.count, 1);
                                  XCTAssertEqualObjects(forwardEvent.info[@"af_description"], @"this is a description");
                              }
                          }];
}

- (void)testAllocation {    
    MPKitContainer *localKitContainer = [[MPKitContainer alloc] init];
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
    

        [self->kitContainer forwardCommerceEventCall:commerceEvent kitHandler:^(id<MPKitProtocol> _Nonnull kit, MPKitFilter * _Nonnull kitFilter, MPKitExecStatus *__autoreleasing  _Nonnull * _Nonnull execStatus) {
            if ([[[kit class] kitCode] isEqualToNumber:@(MPKitInstanceAppsFlyer)]) {
                XCTAssertEqualObjects(kitFilter.forwardEvent.name, @"af_content_view");
            }
        }];
}

- (void)testShouldDelayUploadMaxTime {
    MPKitContainer *localKitContainer = [[MPKitContainer alloc] init];
    [localKitContainer setKitsInitialized:NO];
    XCTAssertFalse([localKitContainer shouldDelayUpload:0]);
    XCTAssertTrue([localKitContainer shouldDelayUpload:10000]);
}

- (void)testIsDisabledByConsentKitFilter {
    
    MPConsentKitFilter *filter = [[MPConsentKitFilter alloc] init];
    
    filter.shouldIncludeOnMatch = YES;
    
    MPConsentKitFilterItem *item = [[MPConsentKitFilterItem alloc] init];
    item.consented = YES;
    item.javascriptHash = -1729075708;
    
    NSMutableArray<MPConsentKitFilterItem *> *filterItems = [NSMutableArray array];
    [filterItems addObject:item];
    
    filter.filterItems = [filterItems copy];
    
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
    
    [MPPersistenceController setConsentState:state forMpid:[MPPersistenceController mpId]];
    MParticle.sharedInstance.identity.currentUser.consentState = state;
    
    BOOL isDisabled = [[MParticle sharedInstance].kitContainer isDisabledByConsentKitFilter:filter];
    XCTAssertFalse(isDisabled);
    
    filter.shouldIncludeOnMatch = NO;
    isDisabled = [[MParticle sharedInstance].kitContainer isDisabledByConsentKitFilter:filter];
    XCTAssertTrue(isDisabled);
    
}

@end

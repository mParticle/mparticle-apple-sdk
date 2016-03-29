//
//  MPKitContainerTests.m
//
//  Copyright 2016 mParticle, Inc.
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
#import "MPKitContainer.h"
#import "MPIConstants.h"
#import "MPForwardQueueItem.h"
#import "MPCommerceEvent.h"
#import "MPProduct.h"
#import "MPKitProtocol.h"
#import "MPKitExecStatus.h"
#import "MPKitFilter.h"
#import "MPEvent.h"
#import "MPKitTestClass.h"
#import "MPStateMachine.h"
#import "MPKitRegister.h"
#import "MPConsumerInfo.h"
#import "MPTransactionAttributes.h"
#import "MPEventProjection.h"

#pragma mark - MPKitContainer category for unit tests
@interface MPKitContainer(Tests)

@property (nonatomic, strong) NSMutableArray<MPForwardQueueItem *> *forwardQueue;
@property (nonatomic, unsafe_unretained) BOOL kitsInitialized;

- (void)replayQueuedItems;
- (NSDictionary *)validateAndTransformToSafeConfiguration:(NSDictionary *)configuration;
- (id)transformValue:(NSString *)originalValue dataType:(MPDataType)dataType;
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification;
- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification;
- (nullable NSString *)nameForKitCode:(nonnull NSNumber *)kitCode;
- (id<MPKitProtocol>)startKit:(NSNumber *)kitCode configuration:(NSDictionary *)configuration;
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
@interface MPKitContainerTests : XCTestCase {
    MPKitContainer *kitContainer;
}

@end


@implementation MPKitContainerTests

- (void)setUp {
    [super setUp];
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.apiKey = @"unit_test_app_key";
    stateMachine.secret = @"unit_test_secret";
    stateMachine.consumerInfo.mpId = @(-986700791391657968);
    
    kitContainer = [MPKitContainer sharedInstance];
    
    if (![MPKitContainer registeredKits]) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClass" startImmediately:NO];
        [MPKitContainer registerKit:kitRegister];
        
        [kitContainer startKit:@42 configuration:@{@"appKey":@"🔑"}];
    }
}

- (void)tearDown {
    kitContainer = nil;
    
    [super tearDown];
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

- (void)testAssortedItems {
    NSNotification *notification = [[NSNotification alloc] initWithName:@"Test Launching"
                                                                 object:self
                                                               userInfo:@{@"deep":@"linking"}];
    
    [kitContainer handleApplicationDidFinishLaunching:notification];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
    id kit;
    for (kit in registeredKits) {
        id wrapperInstance = [kit wrapperInstance];
        NSDictionary *launchOptions = [(id<MPKitProtocol>)wrapperInstance launchOptions];
        XCTAssertNotNil(launchOptions, @"Should not have been nil.");
    }
    
    [kitContainer handleApplicationDidBecomeActive:nil];
    
    NSString *name = [kitContainer nameForKitCode:@42];
    kit = [registeredKits anyObject];
    XCTAssertEqualObjects(name, [kit name], @"Should have been equal.");

    NSDictionary *mapping = [kitContainer methodMessageTypeMapping];
    XCTAssertNotNil(mapping, @"Should not have been nil.");
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
    id registeredKit = [registeredKits anyObject];

    [kitContainer filter:registeredKit
                forEvent:event
                selector:@selector(logEvent:)
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
           XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
           XCTAssertNil(kitFilter.filteredAttributes, @"Filtered attributes should have been nil.");
       }];
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
    id registeredKit = [registeredKits anyObject];
    
    [kitContainer filter:registeredKit
                forEvent:event
                selector:@selector(logEvent:)
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
           XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
           XCTAssertNil(kitFilter.filteredAttributes, @"Filtered attributes should have been nil.");
       }];
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
    id registeredKit = [registeredKits anyObject];
    
    [kitContainer filter:registeredKit
                forEvent:event
                selector:@selector(logEvent:)
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
           XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
       }];
    
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
    event.info = @{@"Product":@"Running shoes",
                   @"modality":@"sprinting"};
    event.category = @"Olympic Games";
    
    [kitContainer filter:registeredKit
                forEvent:event
                selector:@selector(logEvent:)
       completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
           XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
           XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
           XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter event: %@", event);
           XCTAssertEqual(kitFilter.filteredAttributes.count, 1, @"There should be only one attribute in the list.");
           XCTAssertEqualObjects(kitFilter.filteredAttributes[@"modality"], @"sprinting", @"Not filtering the correct attribute.");
       }];
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
    id registeredKit = [registeredKits anyObject];

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
    id registeredKit = [registeredKits anyObject];

    NSString *key = @"Shoe Size";
    NSString *value = @"11";
    MPKitFilter *kitFilter = [kitContainer filter:registeredKit forUserAttributeKey:key value:value];
    XCTAssertNotNil(kitFilter, @"Filter should not have been nil.");
    XCTAssertTrue(kitFilter.shouldFilter, @"Filter should be signaling to filter user attribute.");
    
    key = @"teeth";
    value = @"sharp";
    kitFilter = [kitContainer filter:registeredKit forUserAttributeKey:key value:value];
    XCTAssertNil(kitFilter, @"Filter should have been nil.");
    
    key = nil;
    kitFilter = [kitContainer filter:registeredKit forUserAttributeKey:key value:value];
    XCTAssertNil(kitFilter, @"Filter should have been nil.");
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
    id registeredKit = [registeredKits anyObject];

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
    id registeredKit = [registeredKits anyObject];

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
    product[@"key_number"] = @1;
    product[@"key_bool"] = @YES;
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertEqual(commerceEvent.products.count, 1, @"Incorrect product count.");
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent[@"key_string"] = @"val_string";
    commerceEvent[@"key_number"] = @3.14;
    
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
    product[@"key_number"] = @1;
    product[@"key_bool"] = @YES;
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertEqual(commerceEvent.products.count, 1, @"Incorrect product count.");
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent[@"key_string"] = @"val_string";
    commerceEvent[@"key_number"] = @3.14;
    
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
    product[@"key_number"] = @1;
    product[@"key_bool"] = @YES;
    
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionAddToCart product:product];
    XCTAssertNotNil(commerceEvent, @"Commerce event should not have been nil.");
    XCTAssertEqual(commerceEvent.products.count, 1, @"Incorrect product count.");
    
    commerceEvent.checkoutOptions = @"option 1";
    commerceEvent.screenName = @"Time Traveling";
    commerceEvent.checkoutStep = 1;
    commerceEvent[@"key_string"] = @"val_string";
    commerceEvent[@"key_number"] = @3.14;
    
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

@end

//
//  MPForwardQueueItemTests.m
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
#import "MPForwardQueueItem.h"
#import "MPCommerceEvent.h"
#import "MPProduct.h"
#import "MPKitProtocol.h"
#import "MPKitExecStatus.h"
#import "MPKitFilter.h"
#import "MPEvent.h"
#import "MPForwardQueueParameters.h"

#define FORWARD_QUEUE_ITEM_TESTS_EXPECTATIONS_TIMEOUT 1

#pragma mark
@interface MPKitMockTest : NSObject <MPKitProtocol>

@property (nonatomic, unsafe_unretained, readonly) BOOL started;

- (nonnull instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration startImmediately:(BOOL)startImmediately;

+ (nonnull NSNumber *)kitCode;

@end


@implementation MPKitMockTest

+ (NSNumber *)kitCode {
    return @11235813;
}

- (nonnull instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration startImmediately:(BOOL)startImmediately {
    self = [super init];
    
    _started = startImmediately;
    
    return self;
}

@end


#pragma mark - MPForwardQueueItemTests
@interface MPForwardQueueItemTests : XCTestCase

@end


@implementation MPForwardQueueItemTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCommerceInstance {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Forward Queue Item Test (Ecommerce)"];
    MPProduct *product = [[MPProduct alloc] initWithName:@"Sonic Screwdriver" sku:@"SNCDRV" quantity:@1 price:@3.14];
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    
    void (^kitHandler)(id<MPKitProtocol>, MPForwardQueueParameters *, MPKitFilter *, MPKitExecStatus **) = ^(id<MPKitProtocol> kit, MPForwardQueueParameters *forwardParameters, MPKitFilter *kitFilter, MPKitExecStatus **execStatus) {
        XCTAssertEqual(kit.started, YES);
        XCTAssertEqualObjects(kitFilter.forwardCommerceEvent, commerceEvent);
        [expectation fulfill];
    };
    
    SEL commerceEventSelector = @selector(logCommerceEvent:);
    
    MPForwardQueueParameters *parameters = [[MPForwardQueueParameters alloc] init];
    [parameters addParameter:commerceEvent];
    
    MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:commerceEventSelector parameters:parameters messageType:MPMessageTypeCommerceEvent completionHandler:kitHandler];
    
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeEcommerce);
    XCTAssertEqualObjects(forwardQueueItem.queueParameters[0], commerceEvent);
    XCTAssertEqualObjects(forwardQueueItem.completionHandler, kitHandler);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MPKitMockTest *kitMockTest = [[MPKitMockTest alloc] initWithConfiguration:@{@"appKey":@"thisisaninvalidkey"} startImmediately:YES];
        MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:(MPCommerceEvent *)forwardQueueItem.queueParameters[0] shouldFilter:NO];
        MPKitExecStatus *execStatus = nil;
        
        forwardQueueItem.completionHandler(kitMockTest, nil, kitFilter, &execStatus);
    });
    
    [self waitForExpectationsWithTimeout:FORWARD_QUEUE_ITEM_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testEventInstance {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Forward Queue Item Test (Event)"];
    SEL selector = @selector(logEvent:);
    MPEvent *event = [[MPEvent alloc] initWithName:@"Time travel" type:MPEventTypeNavigation];
    
    void (^kitHandler)(id<MPKitProtocol>, MPForwardQueueParameters *, MPKitFilter *, MPKitExecStatus **) = ^(id<MPKitProtocol> kit, MPForwardQueueParameters *forwardParameters, MPKitFilter *forwardKitFilter, MPKitExecStatus **execStatus) {
        XCTAssertTrue(kit.started);
        XCTAssertEqualObjects(forwardKitFilter.forwardEvent, event);
        [expectation fulfill];
    };
    
    MPForwardQueueParameters *parameters = [[MPForwardQueueParameters alloc] init];
    [parameters addParameter:event];
    
    MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector parameters:parameters messageType:MPMessageTypeEvent completionHandler:kitHandler];
    
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeEvent);
    XCTAssertEqualObjects(forwardQueueItem.queueParameters[0], event);
    XCTAssertEqualObjects(forwardQueueItem.completionHandler, kitHandler);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MPKitMockTest *kitMockTest = [[MPKitMockTest alloc] initWithConfiguration:@{@"appKey":@"thisisaninvalidkey"} startImmediately:YES];
        MPKitExecStatus *execStatus = nil;
        
        MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithEvent:event shouldFilter:NO];
        
        forwardQueueItem.completionHandler(kitMockTest, forwardQueueItem.queueParameters, kitFilter, &execStatus);
    });
    
    [self waitForExpectationsWithTimeout:FORWARD_QUEUE_ITEM_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testInvalidInstances {
    // Ecommerce
    MPCommerceEvent *commerceEvent = nil;
    
    void (^ecommerceKitHandler)(id<MPKitProtocol>, MPForwardQueueParameters *, MPKitFilter *, MPKitExecStatus **) = ^(id<MPKitProtocol> kit, MPForwardQueueParameters *forwardParameters, MPKitFilter *kitFilter, MPKitExecStatus **execStatus) {
    };

    SEL commerceEventSelector = @selector(logCommerceEvent:);
    
    MPForwardQueueParameters *parameters = [[MPForwardQueueParameters alloc] init];
    [parameters addParameter:commerceEvent];
    
    MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:commerceEventSelector parameters:parameters messageType:MPMessageTypeCommerceEvent completionHandler:ecommerceKitHandler];

    XCTAssertNil(forwardQueueItem);
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"Sonic Screwdriver" sku:@"SNCDRV" quantity:@1 price:@3.14];
    commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];

    ecommerceKitHandler = nil;

    [parameters addParameter:commerceEvent];

    forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:commerceEventSelector parameters:parameters messageType:MPMessageTypeCommerceEvent completionHandler:ecommerceKitHandler];
    XCTAssertNil(forwardQueueItem);
    
    // Event
    SEL selector = nil;
    MPEvent *event = [[MPEvent alloc] initWithName:@"Time travel" type:MPEventTypeNavigation];
    
    void (^eventKitHandler)(id<MPKitProtocol>, MPForwardQueueParameters *, MPKitFilter *, MPKitExecStatus **) = ^(id<MPKitProtocol> kit, MPForwardQueueParameters *forwardParameters, MPKitFilter *forwardKitFilter, MPKitExecStatus **execStatus) {
    };
    
    parameters = [[MPForwardQueueParameters alloc] init];
    [parameters addParameter:event];
    
    forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector parameters:parameters messageType:MPMessageTypeEvent completionHandler:eventKitHandler];
    forwardQueueItem.queueItemType = MPQueueItemTypeEvent;

    XCTAssertNil(forwardQueueItem);
    
    selector = @selector(logEvent:);
    event = nil;
    parameters = [[MPForwardQueueParameters alloc] init];
    [parameters addParameter:event];
    
    forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector parameters:parameters messageType:MPMessageTypeEvent completionHandler:eventKitHandler];
    XCTAssertNil(forwardQueueItem);
    
    selector = @selector(logEvent:);
    event = [[MPEvent alloc] initWithName:@"Time travel" type:MPEventTypeNavigation];
    eventKitHandler = nil;
    
    forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector parameters:parameters messageType:MPMessageTypeEvent completionHandler:eventKitHandler];
    XCTAssertNil(forwardQueueItem);
}

- (void)testGeneralPurposeInstance {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Forward Queue Item Test (General)"];
    SEL selector = @selector(openURL:options:);
    
    void (^kitHandler)(id<MPKitProtocol>, MPForwardQueueParameters *, MPKitFilter *, MPKitExecStatus **) = ^(id<MPKitProtocol> kit, MPForwardQueueParameters *queueParameters, MPKitFilter *kitFilter, MPKitExecStatus **execStatus) {
        XCTAssertEqual(kit.started, YES, @"Should have been equal.");
        [expectation fulfill];
    };
    
    NSURL *url = [NSURL URLWithString:@"mparticle://launch/options"];
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] initWithParameters:@[url]];
    XCTAssertEqual(queueParameters.count, 1);
    
    MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector parameters:queueParameters messageType:MPMessageTypePushRegistration completionHandler:kitHandler];
    
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeGeneralPurpose, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.completionHandler, kitHandler, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.queueParameters, queueParameters, @"Should have been equal.");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MPKitMockTest *kitMockTest = [[MPKitMockTest alloc] initWithConfiguration:@{@"appKey":@"thisisaninvalidkey"} startImmediately:YES];
        MPKitExecStatus *execStatus = nil;
        
        forwardQueueItem.completionHandler(kitMockTest, queueParameters, nil, &execStatus);
    });
    
    [self waitForExpectationsWithTimeout:FORWARD_QUEUE_ITEM_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

@end

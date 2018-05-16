#import <XCTest/XCTest.h>
#import "MPForwardQueueItem.h"
#import "MPCommerceEvent.h"
#import "MPProduct.h"
#import "MPKitProtocol.h"
#import "MPKitExecStatus.h"
#import "MPKitFilter.h"
#import "MPEvent.h"
#import "MPForwardQueueParameters.h"
#import "MPKitInstanceValidator.h"

#define FORWARD_QUEUE_ITEM_TESTS_EXPECTATIONS_TIMEOUT 1

@interface MPKitInstanceValidator ()
+ (void)includeUnitTestKits:(NSArray<NSNumber *> *)kitCodes;
@end

#pragma mark
@interface MPKitMockTest : NSObject <MPKitProtocol>

@property (nonatomic, unsafe_unretained, readonly) BOOL started;

- (nonnull MPKitExecStatus *)didFinishLaunchingWithConfiguration:(nonnull NSDictionary *)configuration;

+ (nonnull NSNumber *)kitCode;

@end


@implementation MPKitMockTest

+ (NSNumber *)kitCode {
    return @11235813;
}

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;
    
    _started = YES;
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
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
    [MPKitInstanceValidator includeUnitTestKits:@[@11235813]];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Forward Queue Item Test (Ecommerce)"];
    MPProduct *product = [[MPProduct alloc] initWithName:@"Sonic Screwdriver" sku:@"SNCDRV" quantity:@1 price:@3.14];
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];
    
    void (^kitHandler)(id<MPKitProtocol>, MPKitFilter *, MPKitExecStatus **) = ^(id<MPKitProtocol> kit, MPKitFilter *kitFilter, MPKitExecStatus **execStatus) {
        XCTAssertEqual(kit.started, YES, @"Should have been equal.");
        XCTAssertEqualObjects(kitFilter.forwardCommerceEvent, commerceEvent, @"Should have been equal.");
        [expectation fulfill];
    };
    
    MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithCommerceEvent:commerceEvent completionHandler:kitHandler];
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeEcommerce, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.commerceEvent, commerceEvent, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.commerceEventCompletionHandler, kitHandler, @"Should have been equal.");
    XCTAssertNil(forwardQueueItem.event, @"Should have been nil.");
    XCTAssertNil(forwardQueueItem.eventCompletionHandler, @"Should have been nil.");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MPKitMockTest *kitMockTest = [[MPKitMockTest alloc] init];
        [kitMockTest didFinishLaunchingWithConfiguration:@{@"appKey":@"thisisaninvalidkey"}];
        MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:forwardQueueItem.commerceEvent shouldFilter:NO];
        MPKitExecStatus *execStatus = nil;
        
        forwardQueueItem.commerceEventCompletionHandler(kitMockTest, kitFilter, &execStatus);
    });
    
    [self waitForExpectationsWithTimeout:FORWARD_QUEUE_ITEM_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testEventInstance {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Forward Queue Item Test (Event)"];
    SEL selector = @selector(logEvent:);
    MPEvent *event = [[MPEvent alloc] initWithName:@"Time travel" type:MPEventTypeNavigation];
    
    void (^kitHandler)(id<MPKitProtocol>, MPEvent *, MPKitExecStatus **) = ^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
        XCTAssertEqual(kit.started, YES, @"Should have been equal.");
        XCTAssertEqualObjects(forwardEvent, event, @"Should have been equal.");
        [expectation fulfill];
    };
    
    MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector event:event messageType:MPMessageTypeEvent completionHandler:kitHandler];
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeEvent, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.event, event, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.eventCompletionHandler, kitHandler, @"Should have been equal.");
    XCTAssertNil(forwardQueueItem.commerceEvent, @"Should have been nil.");
    XCTAssertNil(forwardQueueItem.commerceEventCompletionHandler, @"Should have been nil.");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MPKitMockTest *kitMockTest = [[MPKitMockTest alloc] init];
        [kitMockTest didFinishLaunchingWithConfiguration:@{@"appKey":@"thisisaninvalidkey"}];
        MPKitExecStatus *execStatus = nil;
        
        forwardQueueItem.eventCompletionHandler(kitMockTest, forwardQueueItem.event, &execStatus);
    });
    
    [self waitForExpectationsWithTimeout:FORWARD_QUEUE_ITEM_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

- (void)testInvalidInstances {
    // Ecommerce
    MPCommerceEvent *commerceEvent = nil;
    
    void (^ecommerceKitHandler)(id<MPKitProtocol>, MPKitFilter *, MPKitExecStatus **) = ^(id<MPKitProtocol> kit, MPKitFilter *kitFilter, MPKitExecStatus **execStatus) {
    };

    MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithCommerceEvent:commerceEvent completionHandler:ecommerceKitHandler];
    XCTAssertNil(forwardQueueItem, @"Should have been nil.");
    
    MPProduct *product = [[MPProduct alloc] initWithName:@"Sonic Screwdriver" sku:@"SNCDRV" quantity:@1 price:@3.14];
    commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];

    ecommerceKitHandler = nil;
    
    forwardQueueItem = [[MPForwardQueueItem alloc] initWithCommerceEvent:commerceEvent completionHandler:ecommerceKitHandler];
    XCTAssertNil(forwardQueueItem, @"Should have been nil.");
    
    // Event
    SEL selector = nil;
    MPEvent *event = [[MPEvent alloc] initWithName:@"Time travel" type:MPEventTypeNavigation];
    
    void (^eventKitHandler)(id<MPKitProtocol>, MPEvent *, MPKitExecStatus **) = ^(id<MPKitProtocol> kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus) {
    };
    
    forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector event:event messageType:MPMessageTypeEvent completionHandler:eventKitHandler];
    XCTAssertNil(forwardQueueItem, @"Should have been nil.");
    
    selector = @selector(logEvent:);
    event = nil;
    
    forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector event:event messageType:MPMessageTypeEvent completionHandler:eventKitHandler];
    XCTAssertNil(forwardQueueItem, @"Should have been nil.");
    
    selector = @selector(logEvent:);
    event = [[MPEvent alloc] initWithName:@"Time travel" type:MPEventTypeNavigation];
    eventKitHandler = nil;
    
    forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector event:event messageType:MPMessageTypeEvent completionHandler:eventKitHandler];
    XCTAssertNil(forwardQueueItem, @"Should have been nil.");
}

- (void)testGeneralPurposeInstance {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Forward Queue Item Test (General)"];
    SEL selector = @selector(openURL:options:);
    
    void (^kitHandler)(id<MPKitProtocol>, MPForwardQueueParameters *, MPKitExecStatus **) = ^(id<MPKitProtocol> kit, MPForwardQueueParameters *queueParameters, MPKitExecStatus **execStatus) {
        XCTAssertEqual(kit.started, YES, @"Should have been equal.");
        [expectation fulfill];
    };
    
    NSURL *url = [NSURL URLWithString:@"mparticle://launch/options"];
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] initWithParameters:@[url]];
    XCTAssertEqual(queueParameters.count, 1);
    
    MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector parameters:queueParameters messageType:MPMessageTypePushRegistration completionHandler:kitHandler];
    
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeGeneralPurpose, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.generalPurposeCompletionHandler, kitHandler, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.queueParameters, queueParameters, @"Should have been equal.");
    XCTAssertNil(forwardQueueItem.commerceEvent, @"Should have been nil.");
    XCTAssertNil(forwardQueueItem.commerceEventCompletionHandler, @"Should have been nil.");
    XCTAssertNil(forwardQueueItem.event, @"Should have been nil.");
    XCTAssertNil(forwardQueueItem.eventCompletionHandler, @"Should have been nil.");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MPKitMockTest *kitMockTest = [[MPKitMockTest alloc] init];
        [kitMockTest didFinishLaunchingWithConfiguration:@{@"appKey":@"thisisaninvalidkey"}];
        MPKitExecStatus *execStatus = nil;
        
        forwardQueueItem.generalPurposeCompletionHandler(kitMockTest, queueParameters, &execStatus);
    });
    
    [self waitForExpectationsWithTimeout:FORWARD_QUEUE_ITEM_TESTS_EXPECTATIONS_TIMEOUT handler:nil];
}

@end

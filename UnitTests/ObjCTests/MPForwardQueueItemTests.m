#import <XCTest/XCTest.h>
#import "MPForwardQueueItem.h"
#import "MPCommerceEvent.h"
#import "MPProduct.h"
#import "MPKitProtocol.h"
#import "MPKitExecStatus.h"
#import "MPKitFilter.h"
#import "MPEvent.h"
#import "MPForwardQueueParameters.h"
#import "MPBaseTestCase.h"

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
@interface MPForwardQueueItemTests : MPBaseTestCase

@end


@implementation MPForwardQueueItemTests

- (void)testCommerceInstance {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Forward Queue Item Test (Ecommerce)"];
    MPProduct *product = [[MPProduct alloc] initWithName:@"Sonic Screwdriver" sku:@"SNCDRV" quantity:@1 price:@3.14];
    MPCommerceEvent *commerceEvent = [[MPCommerceEvent alloc] initWithAction:MPCommerceEventActionPurchase product:product];

    
    MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithCommerceEvent:commerceEvent];
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeEcommerce, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.commerceEvent, commerceEvent, @"Should have been equal.");
    XCTAssertNil(forwardQueueItem.event, @"Should have been nil.");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MPKitMockTest *kitMockTest = [[MPKitMockTest alloc] init];
        [kitMockTest didFinishLaunchingWithConfiguration:@{@"appKey":@"thisisaninvalidkey"}];
        MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:forwardQueueItem.commerceEvent shouldFilter:NO];
        
        XCTAssertEqualObjects(kitFilter.forwardCommerceEvent, forwardQueueItem.commerceEvent);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testEventInstance {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Forward Queue Item Test (Event)"];
    SEL selector = @selector(logEvent:);
    MPEvent *event = [[MPEvent alloc] initWithName:@"Time travel" type:MPEventTypeNavigation];
    
    MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector event:event messageType:MPMessageTypeEvent];
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeEvent, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.event, event, @"Should have been equal.");
    XCTAssertNil(forwardQueueItem.commerceEvent, @"Should have been nil.");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MPKitMockTest *kitMockTest = [[MPKitMockTest alloc] init];
        [kitMockTest didFinishLaunchingWithConfiguration:@{@"appKey":@"thisisaninvalidkey"}];
        MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithEvent:forwardQueueItem.event shouldFilter:NO];
        
        XCTAssertEqualObjects(kitFilter.forwardEvent, forwardQueueItem.event);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testInvalidInstances {
    // Event
    SEL selector = nil;
    MPEvent *event = [[MPEvent alloc] initWithName:@"Time travel" type:MPEventTypeNavigation];
        
    MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector event:event messageType:MPMessageTypeEvent];
    XCTAssertNil(forwardQueueItem, @"Should have been nil.");
    
    selector = @selector(logEvent:);
    event = nil;
    
    forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector event:event messageType:MPMessageTypeEvent];
    XCTAssertNil(forwardQueueItem, @"Should have been nil.");
}

- (void)testGeneralPurposeInstance {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Forward Queue Item Test (General)"];
    SEL selector = @selector(openURL:options:);
    
    NSURL *url = [NSURL URLWithString:@"mparticle://launch/options"];
    MPForwardQueueParameters *queueParameters = [[MPForwardQueueParameters alloc] initWithParameters:@[url]];
    XCTAssertEqual(queueParameters.count, 1);
    
    MPForwardQueueItem *forwardQueueItem = [[MPForwardQueueItem alloc] initWithSelector:selector parameters:queueParameters messageType:MPMessageTypePushRegistration];
    
    XCTAssertEqual(forwardQueueItem.queueItemType, MPQueueItemTypeGeneralPurpose, @"Should have been equal.");
    XCTAssertEqualObjects(forwardQueueItem.queueParameters, queueParameters, @"Should have been equal.");
    XCTAssertNil(forwardQueueItem.commerceEvent, @"Should have been nil.");
    XCTAssertNil(forwardQueueItem.event, @"Should have been nil.");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        MPKitMockTest *kitMockTest = [[MPKitMockTest alloc] init];
        [kitMockTest didFinishLaunchingWithConfiguration:@{@"appKey":@"thisisaninvalidkey"}];
        MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithEvent:forwardQueueItem.event shouldFilter:NO];
        
        XCTAssertEqualObjects(kitFilter.forwardEvent, forwardQueueItem.event);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

@end

#import "MPExtensionProtocol.h"
#import "MPKitContainer+MParticlePrivate.h"
#import "MPKitRegister.h"
#import "MPKitTestClassNoStartImmediately.h"
@import mParticle_Apple_SDK_Swift;
#import <XCTest/XCTest.h>
#import "MPBaseTestCase.h"
#import "MParticle.h"

@interface MParticle ()

@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;

@end

#pragma mark - MPKitContainer category for unit tests
@interface MPKitContainer_PRIVATE(Tests)

- (id<MPKitProtocol>)startKit:(NSNumber *)integrationId configuration:(MPKitConfiguration *)kitConfiguration;
+ (void)resetRegistry;

@end


#pragma mark - MPKitActivityTests
@interface MPKitActivityTests : MPBaseTestCase

@property (nonatomic, strong) MPKitActivity *kitActivity;

@end


@implementation MPKitActivityTests

- (void)setUp {
    [super setUp];

    // Resolve through MParticle so the lookups mParticle.m gives its own kit activity are the ones under test.
    _kitActivity = [[MPKitActivity alloc] initWithIsKitActive:^BOOL(NSNumber *integrationId) {
        return [[MParticle sharedInstance] isKitActive:integrationId];
    } kitInstance:^id(NSNumber *integrationId) {
        return [[MParticle sharedInstance] kitInstance:integrationId];
    }];
    
    [MParticle sharedInstance].stateMachine.apiKey = @"unit_test_app_key";
    [MParticle sharedInstance].stateMachine.secret = @"unit_test_secret";
    
    [MParticle sharedInstance].kitContainer_PRIVATE = [[MPKitContainer_PRIVATE alloc] init];
        
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
    [MPKitContainer_PRIVATE registerKit:kitRegister];
    NSDictionary *configuration = @{@"id": @42, @"as": @{@"appId":@"MyAppId"}};
    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    [[[MParticle sharedInstance].kitContainer_PRIVATE startKit:@42 configuration:kitConfiguration] start];
}

- (void)tearDown {
    _kitActivity = nil;
    
    // Ensure registeredKits is empty
    [MPKitContainer_PRIVATE resetRegistry];
    
    [super tearDown];
}

- (void)testCompletionHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"KitActivity completion handler"];
    
    [self.kitActivity kitInstance:@42 withHandler:^(id _Nullable kitInstance) {
        XCTAssertNotNil(kitInstance);
        XCTAssertTrue([kitInstance isKindOfClass:[MPKitTestClassNoStartImmediately class]]);
        
        BOOL isKitActive = [self.kitActivity isKitActive:@42];
        XCTAssertTrue(isKitActive);
        
        id syncKitInstance = [self.kitActivity kitInstance:@42];
        XCTAssertNotNil(syncKitInstance);
        XCTAssertTrue([syncKitInstance isKindOfClass:[MPKitTestClassNoStartImmediately class]]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testKitAlreadyStarted {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    @"as":@{
                                            @"appId":@"cool app key"
                                            }
                                    };
    
    NSArray *kitConfigs = @[configuration];
    [[MParticle sharedInstance].kitContainer_PRIVATE configureKits:nil];
    [[MParticle sharedInstance].kitContainer_PRIVATE configureKits:kitConfigs];
    
    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    [[MParticle sharedInstance].kitContainer_PRIVATE startKit:@42 configuration:kitConfiguration];
    
    BOOL isKitActive = [self.kitActivity isKitActive:@42];
    XCTAssertTrue(isKitActive);
    
    [self.kitActivity kitInstance:@42 withHandler:^(id _Nullable kitInstance) {
        XCTAssertNotNil(kitInstance);
        XCTAssertTrue([kitInstance isKindOfClass:[MPKitTestClassNoStartImmediately class]]);
        
        id syncKitInstance = [self.kitActivity kitInstance:@42];
        XCTAssertNotNil(syncKitInstance);
        XCTAssertTrue([syncKitInstance isKindOfClass:[MPKitTestClassNoStartImmediately class]]);
    }];
}

- (void)testPendingHandlerRunsWhenKitStartsDuringConfiguration {
    // Let the kit-active delivery queued by setUp's start run before a handler is pending.
    XCTestExpectation *drained = [self expectationWithDescription:@"Main queue drained"];
    dispatch_async(dispatch_get_main_queue(), ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:DEFAULT_TIMEOUT];

    // Registered but not started, so the handler stays pending.
    [MPKitContainer_PRIVATE resetRegistry];
    [MParticle sharedInstance].kitContainer_PRIVATE = [[MPKitContainer_PRIVATE alloc] init];
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
    [MPKitContainer_PRIVATE registerKit:kitRegister];
    XCTAssertFalse([self.kitActivity isKitActive:@42]);

    XCTestExpectation *expectation = [self expectationWithDescription:@"KitActivity pending handler"];
    [self.kitActivity kitInstance:@42 withHandler:^(id _Nullable kitInstance) {
        XCTAssertTrue([kitInstance isKindOfClass:[MPKitTestClassNoStartImmediately class]]);
        [expectation fulfill];
    }];

    // configureKits: starts the kit while it holds the container lock, and the test kit posts
    // the kit-active notification synchronously from start.
    [[MParticle sharedInstance].kitContainer_PRIVATE configureKits:@[@{@"id": @42, @"as": @{@"appId": @"MyAppId"}}]];

    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

@end

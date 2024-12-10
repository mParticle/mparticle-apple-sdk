#import "MPConsumerInfo.h"
#import "MPExtensionProtocol.h"
#import "MPKitActivity.h"
#import "MPKitConfiguration.h"
#import "MPKitContainer.h"
#import "MPKitRegister.h"
#import "MPKitTestClassNoStartImmediately.h"
#import "MPStateMachine.h"
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
+ (NSMutableSet <id<MPExtensionKitProtocol>> *)kitsRegistry;

@end


#pragma mark - MPKitActivityTests
@interface MPKitActivityTests : MPBaseTestCase

@property (nonatomic, strong) MPKitActivity *kitActivity;

@end


@implementation MPKitActivityTests

- (void)setUp {
    [super setUp];

    _kitActivity = [[MPKitActivity alloc] init];
    
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
    [MPKitContainer_PRIVATE.kitsRegistry removeAllObjects];
    
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

@end

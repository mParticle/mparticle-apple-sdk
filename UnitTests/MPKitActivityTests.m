#import "MPConsumerInfo.h"
#import "MPExtensionProtocol.h"
#import "MPKitActivity.h"
#import "MPKitConfiguration.h"
#import "MPKitContainer.h"
#import "MPKitRegister.h"
#import "MPKitTestClassNoStartImmediately.h"
#import "MPStateMachine.h"
#import "MPKitInstanceValidator.h"
#import <XCTest/XCTest.h>

@interface MPKitInstanceValidator ()
+ (void)includeUnitTestKits:(NSArray<NSNumber *> *)kitCodes;
@end

#pragma mark - MPKitContainer category for unit tests
@interface MPKitContainer(Tests)

- (id<MPKitProtocol>)startKit:(NSNumber *)kitCode configuration:(MPKitConfiguration *)kitConfiguration;

@end

#pragma mark - MPKitActivityTests
@interface MPKitActivityTests : XCTestCase

@property (nonatomic, strong) MPKitActivity *kitActivity;

@end


@implementation MPKitActivityTests

- (void)setUp {
    [super setUp];

    _kitActivity = [[MPKitActivity alloc] init];
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.apiKey = @"unit_test_app_key";
    stateMachine.secret = @"unit_test_secret";
    
    [MPKitInstanceValidator includeUnitTestKits:@[@42]];
    
    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
    if (!registeredKits) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
        [MPKitContainer registerKit:kitRegister];
        
        NSDictionary *configuration = @{
                                        @"id":@42,
                                        @"as":@{
                                                @"appId":@"MyAppId"
                                                }
                                        };
        
        MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
        [[MPKitContainer sharedInstance] startKit:@42 configuration:kitConfiguration];
    }
}

- (void)tearDown {
    _kitActivity = nil;
    
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
    
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    @"as":@{
                                            @"appId":@"cool app key"
                                            }
                                    };
    
    NSArray *kitConfigs = @[configuration];
    [[MPKitContainer sharedInstance] configureKits:nil];
    [[MPKitContainer sharedInstance] configureKits:kitConfigs];

    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    [[MPKitContainer sharedInstance] startKit:@42 configuration:kitConfiguration];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    [[MPKitContainer sharedInstance] configureKits:nil];
}

- (void)testKitAlreadyStarted {
    NSDictionary *configuration = @{
                                    @"id":@42,
                                    @"as":@{
                                            @"appId":@"cool app key"
                                            }
                                    };
    
    NSArray *kitConfigs = @[configuration];
    [[MPKitContainer sharedInstance] configureKits:nil];
    [[MPKitContainer sharedInstance] configureKits:kitConfigs];
    
    MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
    [[MPKitContainer sharedInstance] startKit:@42 configuration:kitConfiguration];
    
    BOOL isKitActive = [self.kitActivity isKitActive:@42];
    XCTAssertTrue(isKitActive);
    
    [self.kitActivity kitInstance:@42 withHandler:^(id _Nullable kitInstance) {
        XCTAssertNotNil(kitInstance);
        XCTAssertTrue([kitInstance isKindOfClass:[MPKitTestClassNoStartImmediately class]]);
        
        id syncKitInstance = [self.kitActivity kitInstance:@42];
        XCTAssertNotNil(syncKitInstance);
        XCTAssertTrue([syncKitInstance isKindOfClass:[MPKitTestClassNoStartImmediately class]]);
    }];
    
    [[MPKitContainer sharedInstance] configureKits:nil];
}

@end

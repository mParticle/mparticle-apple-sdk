#import <XCTest/XCTest.h>
#import "mParticle.h"
#import "MParticleSwift.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "MPBaseTestCase.h"

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MParticleOptions *options;
@property (nonatomic, strong) MPBackendController_PRIVATE *backendController;

@end

@interface MPResponseConfigTests : MPBaseTestCase

@end

@implementation MPResponseConfigTests

- (void)setUp {
    [super setUp];
    
    [MParticle sharedInstance].stateMachine.apiKey = @"unit_test_app_key";
    [MParticle sharedInstance].stateMachine.secret = @"unit_test_secret";
    
    [MParticle sharedInstance].backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
}
- (void)testInstance {
    NSDictionary *configuration = @{kMPRemoteConfigKitsKey:[NSNull null],
                                    kMPRemoteConfigCustomModuleSettingsKey:[NSNull null],
                                    kMPRemoteConfigRampKey:@100,
                                    kMPRemoteConfigTriggerKey:[NSNull null],
                                    kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeIgnore,
                                    kMPRemoteConfigSessionTimeoutKey:@112};
    
    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration stateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController];

    XCTAssertNotNil(responseConfig, @"Should not have been nil.");
}

- (void)testInvalidConfigurations {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test instance"];
    dispatch_async([MParticle messageQueue], ^{
        NSDictionary *configuration = nil;
        MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration stateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController];
        XCTAssertNil(responseConfig, @"Should have been nil.");
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testUpdateCustomModuleSettingsOnRestore {
    NSData *cmsData =   [@"[{\"id\":11,\"pr\":[{\"f\":\"NSUserDefaults\",\"m\":0,\"ps\":[{\"k\":\"APP_MEASUREMENT_VISITOR_ID\",\"d\":\"%gn%\",\"n\":\"vid\",\"t\":1},{\"k\":\"ADOBEMOBILE_STOREDDEFAULTS_AID\",\"d\":\"%oaid%\",\"n\":\"aid\",\"t\":1},{\"k\":\"ADB_LIFETIME_VALUE\",\"d\":\"0\",\"n\":\"ltv\",\"t\":1},{\"k\":\"OMCK1\",\"d\":\"%dt%\",\"n\":\"id\",\"t\":1},{\"k\":\"OMCK6\",\"d\":\"0\",\"n\":\"l\",\"t\":2},{\"k\":\"OMCK5\",\"d\":\"%dt%\",\"n\":\"lud\",\"t\":1}]}]}]"  dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *cmsDict = [NSJSONSerialization JSONObjectWithData:cmsData
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil];
    
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    stateMachine.customModules = nil;
    NSDictionary *configuration = @{kMPRemoteConfigKitsKey:[NSNull null],
                                    kMPRemoteConfigCustomModuleSettingsKey:cmsDict,
                                    kMPRemoteConfigRampKey:@100,
                                    kMPRemoteConfigTriggerKey:[NSNull null],
                                    kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                    kMPRemoteConfigSessionTimeoutKey:@112};
    
    XCTAssertNil(stateMachine.customModules);
    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration stateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController];
    XCTAssertNotNil(responseConfig);
    XCTAssertNotNil(stateMachine.customModules);
    XCTAssertEqual(1, [stateMachine.customModules count]);
    NSArray *customModules = stateMachine.customModules;
    NSDictionary *customModule = [[customModules objectAtIndex:0] dictionaryRepresentation];
    XCTAssertNotNil([customModule objectForKey: @"aid"]);
    XCTAssertNotNil([customModule objectForKey: @"vid"]);
}

- (void)testSaveRestore {    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test instance"];
    dispatch_async([MParticle messageQueue], ^{
        NSString *eTag = @"1.618-2.718-3.141-42";
        NSDictionary *configuration = @{kMPRemoteConfigRampKey:@100,
                                        kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                        kMPRemoteConfigSessionTimeoutKey:@112};
        
        NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
        [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:configuration eTag:eTag requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];

        configuration = @{kMPRemoteConfigRampKey:@100,
                          kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                          kMPRemoteConfigSessionTimeoutKey:@112};
        
        MPResponseConfig *restoredResponseConfig = [MPUserDefaults restore];
        XCTAssertNotNil(restoredResponseConfig);
        XCTAssertEqualObjects(restoredResponseConfig.configuration, configuration);
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testShouldDeleteDueToMaxConfigAgeWhenNil {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"test" secret:@"test"];
    options.configMaxAgeSeconds = nil;
    [MParticle sharedInstance].options = options;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test instance"];
    dispatch_async([MParticle messageQueue], ^{
        NSString *eTag = @"1.618-2.718-3.141-42";
        NSDictionary *configuration = @{kMPRemoteConfigRampKey:@100,
                                        kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                        kMPRemoteConfigSessionTimeoutKey:@112};
        
        NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
        [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:configuration eTag:eTag requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];
        XCTAssertFalse([MPUserDefaults isOlderThanConfigMaxAgeSeconds]);
        
        [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:configuration eTag:eTag requestTimestamp:(requestTimestamp - 10000.0) currentAge:0 maxAge:nil];
        XCTAssertFalse([MPUserDefaults isOlderThanConfigMaxAgeSeconds]);
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testShouldDeleteDueToMaxConfigAge {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"test" secret:@"test"];
    options.configMaxAgeSeconds = @60;
    [MParticle sharedInstance].options = options;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test instance"];
    dispatch_async([MParticle messageQueue], ^{
        NSString *eTag = @"1.618-2.718-3.141-42";
        NSDictionary *configuration = @{kMPRemoteConfigRampKey:@100,
                                        kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                        kMPRemoteConfigSessionTimeoutKey:@112};
        
        NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
        [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:configuration eTag:eTag requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];
        XCTAssertFalse([MPUserDefaults isOlderThanConfigMaxAgeSeconds]);
        
        [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:configuration eTag:eTag requestTimestamp:(requestTimestamp - 100.0) currentAge:0 maxAge:nil];
        XCTAssertTrue([MPUserDefaults isOlderThanConfigMaxAgeSeconds]);
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testDeleteDueToMaxConfigAge {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"test" secret:@"test"];
    options.configMaxAgeSeconds = @60;
    [MParticle sharedInstance].options = options;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test instance"];
    dispatch_async([MParticle messageQueue], ^{
        NSString *eTag = @"1.618-2.718-3.141-42";
        NSDictionary *configuration = @{kMPRemoteConfigRampKey:@100,
                                        kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                        kMPRemoteConfigSessionTimeoutKey:@112};
        
        XCTAssertNil([[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration]);
        NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970] - 100.0;
        [[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] setConfiguration:configuration eTag:eTag requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];
        XCTAssertNotNil([[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration]);
        
        XCTAssertTrue([MPUserDefaults isOlderThanConfigMaxAgeSeconds]);
        if ([MPUserDefaults isOlderThanConfigMaxAgeSeconds]) {
            [MPUserDefaults deleteConfig];
        }
        XCTAssertNil([[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] getConfiguration]);
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}


@end

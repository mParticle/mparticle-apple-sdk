#import <XCTest/XCTest.h>
#import "MPResponseConfig.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"
#import "mParticle.h"
#import "MPIUserDefaults.h"
#import "MPBaseTestCase.h"

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MParticleOptions *options;

@end

@interface MPResponseConfigTests : MPBaseTestCase

@end

@implementation MPResponseConfigTests

- (void)testInstance {
    NSDictionary *configuration = @{kMPRemoteConfigKitsKey:[NSNull null],
                                    kMPRemoteConfigCustomModuleSettingsKey:[NSNull null],
                                    kMPRemoteConfigRampKey:@100,
                                    kMPRemoteConfigTriggerKey:[NSNull null],
                                    kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeIgnore,
                                    kMPRemoteConfigSessionTimeoutKey:@112};
    
    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];
    XCTAssertNotNil(responseConfig, @"Should not have been nil.");
}

- (void)testInvalidConfigurations {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test instance"];
    dispatch_async([MParticle messageQueue], ^{
        NSDictionary *configuration = nil;
        MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];
        XCTAssertNil(responseConfig, @"Should have been nil.");
        
        configuration = (NSDictionary *)[NSNull null];
        responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];
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
    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration dataReceivedFromServer:NO];
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
        [[MPIUserDefaults standardUserDefaults] setConfiguration:configuration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];

        configuration = @{kMPRemoteConfigRampKey:@100,
                          kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                          kMPRemoteConfigSessionTimeoutKey:@112};
        
        MPResponseConfig *restoredResponseConfig = [MPResponseConfig restore];
        XCTAssertNotNil(restoredResponseConfig);
        XCTAssertEqualObjects(restoredResponseConfig.configuration, configuration);
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testResponseConfigEncoding {
    NSDictionary *configuration = @{kMPRemoteConfigRampKey:@100,
                                    kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                    kMPRemoteConfigSessionTimeoutKey:@112};
    
    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];
    
    MPResponseConfig *persistedResponseConfig = [self attemptSecureEncodingwithClass:[MPResponseConfig class] Object:responseConfig];
    XCTAssertEqualObjects(responseConfig.configuration, persistedResponseConfig.configuration, @"Response Config should have been a match.");
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
        [[MPIUserDefaults standardUserDefaults] setConfiguration:configuration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];
        XCTAssertFalse([MPResponseConfig isOlderThanConfigMaxAgeSeconds]);
        
        [[MPIUserDefaults standardUserDefaults] setConfiguration:configuration eTag:eTag requestTimestamp:(requestTimestamp - 10000.0) currentAge:@"0" maxAge:nil];
        XCTAssertFalse([MPResponseConfig isOlderThanConfigMaxAgeSeconds]);
        
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
        [[MPIUserDefaults standardUserDefaults] setConfiguration:configuration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];
        XCTAssertFalse([MPResponseConfig isOlderThanConfigMaxAgeSeconds]);
        
        [[MPIUserDefaults standardUserDefaults] setConfiguration:configuration eTag:eTag requestTimestamp:(requestTimestamp - 100.0) currentAge:@"0" maxAge:nil];
        XCTAssertTrue([MPResponseConfig isOlderThanConfigMaxAgeSeconds]);
        
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
        
        XCTAssertNil([[MPIUserDefaults standardUserDefaults] getConfiguration]);
        NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970] - 100.0;
        [[MPIUserDefaults standardUserDefaults] setConfiguration:configuration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];
        XCTAssertNotNil([[MPIUserDefaults standardUserDefaults] getConfiguration]);
        
        XCTAssertTrue([MPResponseConfig isOlderThanConfigMaxAgeSeconds]);
        if ([MPResponseConfig isOlderThanConfigMaxAgeSeconds]) {
            [MPResponseConfig deleteConfig];
        }
        XCTAssertNil([[MPIUserDefaults standardUserDefaults] getConfiguration]);
        
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}


@end

//
//  MPResponseConfigTests.m
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
#import "MPResponseConfig.h"
#import "MPIConstants.h"
#import "MPStateMachine.h"

@interface MPResponseConfigTests : XCTestCase

@end

@implementation MPResponseConfigTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInstance {
    NSDictionary *configuration = @{kMPRemoteConfigKitsKey:[NSNull null],
                                    kMPRemoteConfigCustomModuleSettingsKey:[NSNull null],
                                    kMPRemoteConfigRampKey:@100,
                                    kMPRemoteConfigTriggerKey:[NSNull null],
                                    kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeIgnore,
                                    kMPRemoteConfigNetworkPerformanceModeKey:kMPRemoteConfigForceFalse,
                                    kMPRemoteConfigSessionTimeoutKey:@112,
                                    kMPRemoteConfigUploadIntervalKey:@42};
    
    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];
    XCTAssertNotNil(responseConfig, @"Should not have been nil.");
}

- (void)testInvalidConfigurations {
    NSDictionary *configuration = nil;
    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];
    XCTAssertNil(responseConfig, @"Should have been nil.");
    
    configuration = (NSDictionary *)[NSNull null];
    responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];
    XCTAssertNil(responseConfig, @"Should have been nil.");
}

- (void)testUpdateCustomModuleSettingsOnRestore {
    NSData *cmsData =   [@"[{\"id\":11,\"pr\":[{\"f\":\"NSUserDefaults\",\"m\":0,\"ps\":[{\"k\":\"APP_MEASUREMENT_VISITOR_ID\",\"d\":\"%gn%\",\"n\":\"vid\",\"t\":1},{\"k\":\"ADOBEMOBILE_STOREDDEFAULTS_AID\",\"d\":\"%oaid%\",\"n\":\"aid\",\"t\":1},{\"k\":\"ADB_LIFETIME_VALUE\",\"d\":\"0\",\"n\":\"ltv\",\"t\":1},{\"k\":\"OMCK1\",\"d\":\"%dt%\",\"n\":\"id\",\"t\":1},{\"k\":\"OMCK6\",\"d\":\"0\",\"n\":\"l\",\"t\":2},{\"k\":\"OMCK5\",\"d\":\"%dt%\",\"n\":\"lud\",\"t\":1}]}]}]"  dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *cmsDict = [NSJSONSerialization JSONObjectWithData:cmsData
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil];
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.customModules = nil;
    NSDictionary *configuration = @{kMPRemoteConfigKitsKey:[NSNull null],
                                    kMPRemoteConfigCustomModuleSettingsKey:cmsDict,
                                    kMPRemoteConfigRampKey:@100,
                                    kMPRemoteConfigTriggerKey:[NSNull null],
                                    kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                    kMPRemoteConfigNetworkPerformanceModeKey:kMPRemoteConfigForceFalse,
                                    kMPRemoteConfigSessionTimeoutKey:@112,
                                    kMPRemoteConfigUploadIntervalKey:@42};
    
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
    NSDictionary *configuration = @{kMPRemoteConfigKitsKey:[NSNull null],
                                    kMPRemoteConfigCustomModuleSettingsKey:[NSNull null],
                                    kMPRemoteConfigRampKey:@100,
                                    kMPRemoteConfigTriggerKey:[NSNull null],
                                    kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                    kMPRemoteConfigNetworkPerformanceModeKey:kMPRemoteConfigForceFalse,
                                    kMPRemoteConfigSessionTimeoutKey:@112,
                                    kMPRemoteConfigUploadIntervalKey:@42};
    
    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];

    
    [MPResponseConfig save:responseConfig];
    
    MPResponseConfig *restoredResponseConfig = [MPResponseConfig restore];
    XCTAssertNotNil(restoredResponseConfig);
    XCTAssertEqualObjects(restoredResponseConfig.configuration, configuration);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *configurationPath = [stateMachineDirectoryPath stringByAppendingPathComponent:@"RequestConfig.cfg"];
    
    if ([fileManager fileExistsAtPath:configurationPath]) {
        [fileManager removeItemAtPath:configurationPath error:nil];
    }
}

- (void)testConfigSendSessionHistory {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    XCTAssertTrue(stateMachine.shouldUploadSessionHistory);

    NSDictionary *configuration = @{kMPRemoteConfigKitsKey:[NSNull null],
                                    kMPRemoteConfigCustomModuleSettingsKey:[NSNull null],
                                    kMPRemoteConfigRampKey:@100,
                                    kMPRemoteConfigTriggerKey:[NSNull null],
                                    kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                    kMPRemoteConfigNetworkPerformanceModeKey:kMPRemoteConfigForceFalse,
                                    kMPRemoteConfigSessionTimeoutKey:@112,
                                    kMPRemoteConfigUploadIntervalKey:@42,
                                    kMPRemoteConfigIncludeSessionHistory:@NO};

    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];
    XCTAssertNotNil(responseConfig);
    XCTAssertFalse(stateMachine.shouldUploadSessionHistory);

    configuration = @{kMPRemoteConfigKitsKey:[NSNull null],
                      kMPRemoteConfigCustomModuleSettingsKey:[NSNull null],
                      kMPRemoteConfigRampKey:@100,
                      kMPRemoteConfigTriggerKey:[NSNull null],
                      kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                      kMPRemoteConfigNetworkPerformanceModeKey:kMPRemoteConfigForceFalse,
                      kMPRemoteConfigSessionTimeoutKey:@112,
                      kMPRemoteConfigUploadIntervalKey:@42};
    
    responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration];
    XCTAssertTrue(stateMachine.shouldUploadSessionHistory);
}

@end

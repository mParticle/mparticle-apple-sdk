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
                                    kMPRemoteConfigLatestSDKVersionKey:kMParticleSDKVersion,
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

- (void)testSaveRestore {
    NSDictionary *configuration = @{kMPRemoteConfigKitsKey:[NSNull null],
                                    kMPRemoteConfigLatestSDKVersionKey:kMParticleSDKVersion,
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

@end
